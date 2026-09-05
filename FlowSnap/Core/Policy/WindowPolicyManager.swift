import ApplicationServices
import CoreGraphics
import Foundation

/// Manages per-app window placement policies.
///
/// Determines how a newly opened or activated window should
/// behave: stay on current space, float, remember position, etc.
/// See spec §37, US-WORK-013, US-WORK-014.
@MainActor
final class WindowPolicyManager {

    private let accessibilityService: AccessibilityService
    private let displayManager: any DisplayManaging
    private let preferencesStore: PreferencesStore?
    private let layoutEngine: LayoutEngine
    public let focusStack: SmartFocusStack
    public weak var workspaceManager: WorkspaceManager?

    private var policies: [String: WindowPolicy] = [:]

    /// The default policy for apps without a specific rule.
    public var defaultPolicy: WindowPolicy = .currentSpace

    public init(
        accessibilityService: AccessibilityService,
        displayManager: any DisplayManaging,
        preferencesStore: PreferencesStore? = nil,
        layoutEngine: LayoutEngine = LayoutEngine(),
        focusStack: SmartFocusStack = SmartFocusStack(),
        workspaceManager: WorkspaceManager? = nil
    ) {
        self.accessibilityService = accessibilityService
        self.displayManager = displayManager
        self.preferencesStore = preferencesStore
        self.layoutEngine = layoutEngine
        self.focusStack = focusStack
        self.workspaceManager = workspaceManager
    }

    /// Set the policy for a specific app (in-memory override).
    public func setPolicy(_ policy: WindowPolicy, forBundleID bundleID: String) {
        policies[bundleID] = policy
    }

    /// Get the policy for a specific app (checks PreferencesStore rules, then local overrides, falls back to default).
    public func policy(forBundleID bundleID: String) -> WindowPolicy {
        if let rule = preferencesStore?.appRules.first(where: { $0.bundleID.lowercased() == bundleID.lowercased() }) {
            return rule.policy
        }
        return policies[bundleID] ?? defaultPolicy
    }

    /// Apply the appropriate policy when a window appears.
    ///
    /// US-WORK-014: Full dispatching supporting `.currentSpace`, `.currentDisplay`,
    /// `.floating`, `.rememberPosition`, and `.assignedLayout(LayoutZone)`.
    public func applyPolicy(for window: ManagedWindow) async throws {
        // If a workspace is actively restoring, do not intercept newly launched windows
        if let workspaceManager, workspaceManager.isRestoring {
            return
        }

        let bundleID = window.bundleIdentifier
        // If the window belongs to the active workspace or any saved workspace, preserve workspace placement and do not force .currentSpace (snap full)
        if let bundleID {
            if let activeWorkspace = workspaceManager?.activeWorkspace,
               activeWorkspace.placements.contains(where: { $0.bundleIdentifier.lowercased() == bundleID.lowercased() }) {
                focusStack.recordFocus(windowID: window.id, isFloating: false)
                return
            }
            if let workspaces = workspaceManager?.workspaces,
               workspaces.contains(where: { ws in ws.placements.contains(where: { $0.bundleIdentifier.lowercased() == bundleID.lowercased() }) }) {
                focusStack.recordFocus(windowID: window.id, isFloating: false)
                return
            }
        }

        let resolvedPolicy = bundleID.map { self.policy(forBundleID: $0) } ?? defaultPolicy

        switch resolvedPolicy {
        case .currentSpace, .currentDisplay:
            focusStack.recordFocus(windowID: window.id, isFloating: false)
            try await applyCurrentSpace(for: window)

        case .floating:
            focusStack.recordFocus(windowID: window.id, isFloating: true)

        case .rememberPosition:
            focusStack.recordFocus(windowID: window.id, isFloating: false)
            try await applyRememberedPosition(for: window)

        case .assignedLayout(let zone):
            focusStack.recordFocus(windowID: window.id, isFloating: false)
            try await applyAssignedLayout(zone: zone, for: window)

        case .assignedWorkspace:
            focusStack.recordFocus(windowID: window.id, isFloating: false)
            return
        }
    }

    /// Resolves the hosting display for a frame, falling back to primaryDisplay.
    private func resolveDisplay(for frame: CGRect) async -> Display? {
        if !frame.isEmpty, let target = await displayManager.display(for: frame) {
            return target
        }
        return await displayManager.primaryDisplay
    }

    /// Resolve the current display's visible frame and apply it to the window.
    private func applyCurrentSpace(for window: ManagedWindow) async throws {
        let display = await resolveDisplay(for: window.frame)
        guard let frame = display?.visibleFrame else {
            throw AccessibilityError.cannotComplete
        }
        guard let element = accessibilityService.windowElement(for: window) else {
            throw AccessibilityError.windowNotFound
        }
        let targetFrame: CGRect
        if !window.isResizable {
            targetFrame = FrameClampingHelper.clamp(frame: window.frame, to: frame)
        } else {
            targetFrame = frame
        }
        try accessibilityService.setFrame(targetFrame, for: element)
    }

    /// Retrieve the remembered position for the app, clamp it to active screen bounds, and apply.
    private func applyRememberedPosition(for window: ManagedWindow) async throws {
        guard let bundleID = window.bundleIdentifier,
              let remembered = preferencesStore?.rememberedFrame(forBundleID: bundleID) else {
            // Fall back to default placement if no frame was saved yet
            try await applyCurrentSpace(for: window)
            return
        }
        var display = await resolveDisplay(for: remembered.frame)
        if display == nil {
            display = await resolveDisplay(for: window.frame)
        }
        guard let visibleFrame = display?.visibleFrame else {
            throw AccessibilityError.cannotComplete
        }
        guard let element = accessibilityService.windowElement(for: window) else {
            throw AccessibilityError.windowNotFound
        }
        let clamped = FrameClampingHelper.clamp(frame: remembered.frame, to: visibleFrame)
        try accessibilityService.setFrame(clamped, for: element)
    }

    /// Compute canonical layout zone frame using LayoutEngine and apply to window.
    private func applyAssignedLayout(zone: LayoutZone, for window: ManagedWindow) async throws {
        let display = await resolveDisplay(for: window.frame)
        guard let visibleFrame = display?.visibleFrame else {
            throw AccessibilityError.cannotComplete
        }
        guard let element = accessibilityService.windowElement(for: window) else {
            throw AccessibilityError.windowNotFound
        }
        let gap = preferencesStore?.windowGap ?? 0
        let targetFrame = layoutEngine.frame(for: zone, in: visibleFrame, gap: gap)
        try accessibilityService.setFrame(targetFrame, for: element)
    }

    /// Handles floating window dismissal and returns focus to preceding non-floating window.
    public func handleFloatingWindowClosed(windowID: CGWindowID) async {
        guard let restoreTargetID = focusStack.removeFloatingWindow(windowID: windowID) else {
            return
        }
        for window in accessibilityService.allVisibleManagedWindows() {
            if window.id == restoreTargetID, let element = accessibilityService.windowElement(for: window) {
                try? accessibilityService.raise(element)
                break
            }
        }
    }

    // MARK: - EventBus integration (T-013-B2 & T-014-05)

    private var appliedWindowIDs: Set<CGWindowID> = []

    /// Pre-populates existing windows at startup so pre-existing windows are not treated as newly created.
    public func prePopulateExistingWindows() {
        let currentIDs = accessibilityService.allVisibleManagedWindows().map(\.id)
        appliedWindowIDs.formUnion(currentIDs)
    }

    /// Marks a window as already handled (e.g. by workspace restore) so launch policies do not re-apply.
    public func markHandled(windowID: CGWindowID) {
        appliedWindowIDs.insert(windowID)
    }

    /// Marks multiple windows as already handled so launch policies do not re-apply.
    public func markHandled(windowIDs: Set<CGWindowID>) {
        appliedWindowIDs.formUnion(windowIDs)
    }

    /// Handle a `WindowEvent` from the shared `EventBus`.
    func handle(event: WindowEvent) async {
        switch event {
        case .applicationWindowCreated(let pid, let windowID):
            await applyForWindowID(windowID, pid: pid)
        default:
            return
        }
    }

    /// Resolve `windowID` to a `ManagedWindow` (AX-backed) and apply the resolved policy.
    private func applyForWindowID(_ windowID: CGWindowID, pid: pid_t) async {
        guard !appliedWindowIDs.contains(windowID) else {
            return
        }
        var resolved: [ResolvedWindow] = accessibilityService.resolvedWindows(of: pid)
        if resolved.isEmpty {
            try? await Task.sleep(nanoseconds: 50_000_000)
            resolved = accessibilityService.resolvedWindows(of: pid)
        }
        guard let match = resolved.first(where: { $0.window.id == windowID })
                ?? resolved.first(where: { $0.window.kind == .normal })
                ?? resolved.first else {
            return
        }
        guard !appliedWindowIDs.contains(match.window.id) else {
            return
        }
        appliedWindowIDs.insert(match.window.id)
        appliedWindowIDs.insert(windowID)
        do {
            try await applyPolicy(for: match.window)
        } catch {
            NSLog("[WindowPolicyManager] applyPolicy failed for window \(windowID): \(error.localizedDescription)")
        }
    }
}

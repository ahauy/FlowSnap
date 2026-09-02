import ApplicationServices
import CoreGraphics
import Foundation

/// Manages per-app window placement policies.
///
/// Determines how a newly opened or activated window should
/// behave: stay on current space, float, remember position, etc.
/// See spec §37, US-WORK-013.
@MainActor
final class WindowPolicyManager {

    private let accessibilityService: AccessibilityService
    private let displayManager: any DisplayManaging

    private var policies: [String: WindowPolicy] = [:]

    /// The default policy for apps without a specific rule.
    var defaultPolicy: WindowPolicy = .currentSpace

    init(
        accessibilityService: AccessibilityService,
        displayManager: any DisplayManaging
    ) {
        self.accessibilityService = accessibilityService
        self.displayManager = displayManager
    }

    /// Set the policy for a specific app.
    func setPolicy(_ policy: WindowPolicy, forBundleID bundleID: String) {
        policies[bundleID] = policy
    }

    /// Get the policy for a specific app (falls back to default).
    func policy(forBundleID bundleID: String) -> WindowPolicy {
        policies[bundleID] ?? defaultPolicy
    }

    /// Apply the appropriate policy when a window appears.
    ///
    /// US-WORK-013 scope: only `.currentSpace` and `.currentDisplay` are
    /// implemented. Both resolve to positioning the window on the current
    /// display using `DisplayManaging.visibleFrame`. All other policies
    /// remain no-ops (US-WORK-014 territory).
    func applyPolicy(for window: ManagedWindow) async throws {
        let bundleID = window.bundleIdentifier
        let policy = bundleID.map { self.policy(forBundleID: $0) } ?? defaultPolicy

        switch policy {
        case .currentSpace, .currentDisplay:
            try await applyCurrentSpace(for: window)
        case .floating, .rememberPosition, .assignedLayout, .assignedWorkspace:
            return
        }
    }

    /// Resolve the current display's visible frame and apply it to the window.
    ///
    /// The frame is taken from `DisplayManaging.primaryDisplay.visibleFrame`.
    /// The window's existing element from `AccessibilityService.windowElement(for:)`
    /// is preferred so the frame write lands on the exact element we measured.
    private func applyCurrentSpace(for window: ManagedWindow) async throws {
        let display = await displayManager.primaryDisplay
        guard let frame = display?.visibleFrame else {
            throw AccessibilityError.cannotComplete
        }
        guard let element = accessibilityService.windowElement(for: window) else {
            throw AccessibilityError.windowNotFound
        }
        try accessibilityService.setFrame(frame, for: element)
    }

    // MARK: - EventBus integration (T-013-B2)

    /// Handle a `WindowEvent` from the shared `EventBus`.
    ///
    /// Only `.applicationWindowCreated` is in scope for US-WORK-013 — the
    /// manager resolves the window id to a `ManagedWindow` via
    /// `AccessibilityService` and dispatches to `applyPolicy(for:)`. Other
    /// cases are ignored here (US-WORK-014 will add activation/termination
    /// re-application).
    func handle(event: WindowEvent) async {
        switch event {
        case .applicationWindowCreated(let pid, let windowID):
            await applyForWindowID(windowID, pid: pid)
        default:
            return
        }
    }

    /// Resolve `windowID` to a `ManagedWindow` (AX-backed) and apply the
    /// resolved policy. Failures are logged but never thrown — a window we
    /// cannot resolve is just left at its default position (partial-failure
    /// policy, plan §8).
    private func applyForWindowID(_ windowID: CGWindowID, pid: pid_t) async {
        let resolved: [ResolvedWindow] = accessibilityService.resolvedWindows(of: pid)
        guard let match = resolved.first(where: { $0.window.id == windowID }) else {
            return
        }
        do {
            try await applyPolicy(for: match.window)
        } catch {
            // Best-effort: log and move on. The window is already on screen.
            NSLog("[WindowPolicyManager] applyPolicy failed for window \(windowID): \(error.localizedDescription)")
        }
    }
}

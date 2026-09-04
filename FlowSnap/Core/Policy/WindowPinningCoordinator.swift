import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Orchestrates Always-On-Top window pinning and dynamic LIFO Z-stacking.
///
/// Implements `WindowPinningCoordinating` via public Accessibility APIs (`kAXRaiseAction`),
/// maintaining a dynamic LIFO Z-order without any private CGS APIs. See ADR-0015.
@MainActor
public final class WindowPinningCoordinator: WindowPinningCoordinating {

    // MARK: - Properties

    private let accessibilityService: AccessibilityService
    private let systemModalBundleIDs: Set<String>
    private final class TokenBox: @unchecked Sendable {
        let token: any NSObjectProtocol
        let notificationCenter: NotificationCenter

        init(_ token: any NSObjectProtocol, notificationCenter: NotificationCenter) {
            self.token = token
            self.notificationCenter = notificationCenter
        }

        deinit {
            notificationCenter.removeObserver(token)
        }
    }

    private var observerTokens: [TokenBox] = []

    public private(set) var pinnedWindows: [PinnedWindowRecord] = []

    public var isPinningActive: Bool {
        !pinnedWindows.isEmpty
    }

    // MARK: - Initialization

    public init(
        accessibilityService: AccessibilityService,
        systemModalBundleIDs: Set<String> = ["com.apple.SecurityAgent", "com.apple.CoreAuthUI"],
        workspaceNotificationCenter: NotificationCenter? = nil
    ) {
        self.accessibilityService = accessibilityService
        self.systemModalBundleIDs = systemModalBundleIDs

        if let nc = workspaceNotificationCenter {
            registerObservers(on: nc)
        }
    }

    public func startObservingWorkspace(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        registerObservers(on: notificationCenter)
    }

    private func registerObservers(on notificationCenter: NotificationCenter) {
        let activateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor in
                let focused = self.accessibilityService.focusedManagedWindow()
                await self.handleFocusChange(
                    activeWindowID: focused?.id,
                    activePID: app.processIdentifier,
                    activeBundleID: app.bundleIdentifier
                )
            }
        }

        let terminateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor in
                self.handleApplicationTerminated(processIdentifier: app.processIdentifier)
            }
        }

        observerTokens.append(TokenBox(activateObserver, notificationCenter: notificationCenter))
        observerTokens.append(TokenBox(terminateObserver, notificationCenter: notificationCenter))
    }

    // MARK: - Pin Management

    public func isPinned(windowID: CGWindowID) -> Bool {
        pinnedWindows.contains { $0.id == windowID }
    }

    @discardableResult
    public func togglePin(window: ManagedWindow) async -> Bool {
        if let existingIndex = pinnedWindows.firstIndex(where: { $0.id == window.id }) {
            pinnedWindows.remove(at: existingIndex)
            return false
        } else {
            let record = PinnedWindowRecord(
                id: window.id,
                pid: window.pid,
                bundleIdentifier: window.bundleIdentifier,
                title: window.title
            )
            pinnedWindows.insert(record, at: 0) // LIFO top
            accessibilityService.raise(window: window)
            return true
        }
    }

    public func unpin(windowID: CGWindowID) {
        pinnedWindows.removeAll { $0.id == windowID }
    }

    public func unpinAll() {
        pinnedWindows.removeAll()
    }

    // MARK: - Focus & Re-assertion

    public func handleFocusChange(
        activeWindowID: CGWindowID?,
        activePID: pid_t?,
        activeBundleID: String? = nil
    ) async {
        guard !pinnedWindows.isEmpty else { return }

        // System modal safety: pause re-assertion to prevent obscuring Touch ID/Keychain dialogs
        if let bundleID = activeBundleID, systemModalBundleIDs.contains(bundleID) {
            return
        }

        // If the active window is already one of the pinned windows, update its LIFO rank to top
        if let activeID = activeWindowID, let pinnedIndex = pinnedWindows.firstIndex(where: { $0.id == activeID }) {
            let record = pinnedWindows.remove(at: pinnedIndex)
            pinnedWindows.insert(record, at: 0)
            return
        }

        // An unpinned background window is active: re-assert all pinned windows from bottom to top
        await reassertPinnedWindows()
    }

    public func handleFocusChange(activeWindowID: CGWindowID?, activePID: pid_t?) async {
        await handleFocusChange(activeWindowID: activeWindowID, activePID: activePID, activeBundleID: nil)
    }

    public func handleApplicationTerminated(processIdentifier: pid_t) {
        pinnedWindows.removeAll { $0.pid == processIdentifier }
    }

    private func reassertPinnedWindows() async {
        let visibleWindows = accessibilityService.allVisibleManagedWindows()
        let visibleMap = Dictionary(uniqueKeysWithValues: visibleWindows.map { ($0.id, $0) })

        // Re-assert from bottom of LIFO stack up to the top
        let bottomToTopRecords = Array(pinnedWindows.reversed())
        var deadWindowIDs: [CGWindowID] = []

        for record in bottomToTopRecords {
            let windowToRaise: ManagedWindow
            if let found = visibleMap[record.id] {
                windowToRaise = found
            } else {
                windowToRaise = ManagedWindow(
                    id: record.id,
                    pid: record.pid,
                    bundleIdentifier: record.bundleIdentifier,
                    title: record.title,
                    frame: .zero,
                    kind: .normal
                )
            }

            let raised = accessibilityService.raise(window: windowToRaise)
            if !raised {
                deadWindowIDs.append(record.id)
            }
        }

        // Auto-purge dead windows only if their owning application has terminated
        for deadID in deadWindowIDs {
            if let record = pinnedWindows.first(where: { $0.id == deadID }) {
                let app = NSRunningApplication(processIdentifier: record.pid)
                if app == nil || app?.isTerminated == true {
                    pinnedWindows.removeAll { $0.id == deadID }
                }
            }
        }
    }
}

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Closure aliases for dependency injection and deterministic unit testing.
public typealias ApplicationHider = @MainActor @Sendable (pid_t) -> Bool
public typealias ApplicationActivator = @MainActor @Sendable (pid_t) -> Bool
public typealias ApplicationWindowCountProvider = @MainActor @Sendable (pid_t) -> Int

/// Orchestrates the Quake-style Quick Scratchpad lifecycle, instant summon, hybrid dismiss, and focus restoration.
///
/// Complies with Swift 6 Strict Concurrency, DDD, and John Ousterhout's Deep Modules principle. See ADR-0016.
@MainActor
public final class ScratchpadCoordinator: ScratchpadCoordinating {

    // MARK: - Dependencies

    private let accessibilityService: AccessibilityService
    private let preferencesStore: PreferencesStore
    private let applicationHider: ApplicationHider
    private let applicationActivator: ApplicationActivator
    private let windowCountProvider: ApplicationWindowCountProvider

    // MARK: - State

    public private(set) var state: ScratchpadState = .unassigned
    public private(set) var preSummonFocus: PreSummonFocus?
    public private(set) var cachedWindowFrame: CGRect?

    public var currentRecord: ScratchpadRecord? {
        state.record
    }

    public var isVisible: Bool {
        state.isVisible
    }

    // MARK: - Event Monitoring & Observers

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
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    // MARK: - Initialization

    public init(
        accessibilityService: AccessibilityService,
        preferencesStore: PreferencesStore,
        applicationHider: ApplicationHider? = nil,
        applicationActivator: ApplicationActivator? = nil,
        windowCountProvider: ApplicationWindowCountProvider? = nil,
        workspaceNotificationCenter: NotificationCenter? = nil
    ) {
        self.accessibilityService = accessibilityService
        self.preferencesStore = preferencesStore

        self.applicationHider = applicationHider ?? { pid in
            guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
            return app.hide()
        }

        self.applicationActivator = applicationActivator ?? { pid in
            guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
            return app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }

        self.windowCountProvider = windowCountProvider ?? { pid in
            guard let app = NSRunningApplication(processIdentifier: pid) else { return 0 }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowsValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
            guard result == .success, let windowsList = windowsValue as? [AXUIElement] else { return 1 }
            return windowsList.count
        }

        if let nc = workspaceNotificationCenter {
            registerObservers(on: nc)
        }
    }

    public func startObservingWorkspace(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        registerObservers(on: notificationCenter)
    }

    private func registerObservers(on notificationCenter: NotificationCenter) {
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

        observerTokens.append(TokenBox(terminateObserver, notificationCenter: notificationCenter))
    }

    // MARK: - Scratchpad Actions

    @discardableResult
    public func assignFocusedWindow() async -> Bool {
        guard let focused = accessibilityService.focusedManagedWindow() else {
            return false
        }

        let record = ScratchpadRecord(
            windowID: focused.id,
            pid: focused.pid,
            bundleID: focused.bundleIdentifier,
            appName: focused.title.isEmpty ? (focused.bundleIdentifier ?? "Application") : focused.title,
            windowTitle: focused.title
        )

        self.state = .visible(record: record)
        self.cachedWindowFrame = focused.frame
        startEventMonitors()
        return true
    }

    @discardableResult
    public func toggleScratchpad() async -> Bool {
        if isVisible {
            return await dismissScratchpad()
        } else {
            return await summonScratchpad()
        }
    }

    @discardableResult
    public func summonScratchpad() async -> Bool {
        guard let record = currentRecord else {
            return false
        }

        // Cache pre-summon focused application for clean focus return
        if let currentFrontmost = accessibilityService.focusedManagedWindow() {
            self.preSummonFocus = PreSummonFocus(pid: currentFrontmost.pid, windowID: currentFrontmost.id)
        } else if let frontApp = NSWorkspace.shared.frontmostApplication {
            self.preSummonFocus = PreSummonFocus(pid: frontApp.processIdentifier, windowID: nil)
        }

        let dummyWindow = ManagedWindow(
            id: record.windowID,
            pid: record.pid,
            bundleIdentifier: record.bundleID,
            title: record.windowTitle ?? "",
            frame: cachedWindowFrame ?? .zero,
            kind: .normal
        )

        let raiseSuccess = accessibilityService.raise(window: dummyWindow)
        guard raiseSuccess else {
            detachScratchpad()
            return false
        }

        let activateSuccess = applicationActivator(record.pid)
        guard activateSuccess else {
            detachScratchpad()
            return false
        }

        self.state = .visible(record: record)
        startEventMonitors()
        return true
    }

    @discardableResult
    public func dismissScratchpad() async -> Bool {
        guard case .visible(let record) = state else {
            return false
        }

        stopEventMonitors()

        let count = windowCountProvider(record.pid)
        if count <= 1 {
            _ = applicationHider(record.pid)
        }

        if let prevFocus = preSummonFocus {
            _ = applicationActivator(prevFocus.pid)
        }

        self.state = .hidden(record: record)
        return true
    }

    public func detachScratchpad() {
        stopEventMonitors()
        self.state = .unassigned
        self.preSummonFocus = nil
        self.cachedWindowFrame = nil
    }

    public func handleApplicationTerminated(processIdentifier: pid_t) {
        if currentRecord?.pid == processIdentifier {
            detachScratchpad()
        }
    }

    // MARK: - ESC & Outside Click Handling

    @discardableResult
    public func handleEscKey() async -> Bool {
        guard isVisible, preferencesStore.isScratchpadDismissOnEscEnabled else {
            return false
        }
        return await dismissScratchpad()
    }

    @discardableResult
    public func handleClickOutside(clickLocation: CGPoint) async -> Bool {
        guard isVisible, preferencesStore.isScratchpadDismissOnBlurEnabled else {
            return false
        }

        if let frame = cachedWindowFrame, !frame.contains(clickLocation) {
            return await dismissScratchpad()
        }
        return false
    }

    // MARK: - Monitor Setup & Teardown

    private func startEventMonitors() {
        stopEventMonitors()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 && self.preferencesStore.isScratchpadDismissOnEscEnabled { // ESC = 53
                Task { @MainActor in
                    _ = await self.handleEscKey()
                }
                return nil
            }
            return event
        }

        if preferencesStore.isScratchpadDismissOnBlurEnabled {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                guard let self else { return }
                let location = event.locationInWindow
                Task { @MainActor in
                    _ = await self.handleClickOutside(clickLocation: location)
                }
            }
        }
    }

    private func stopEventMonitors() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
}

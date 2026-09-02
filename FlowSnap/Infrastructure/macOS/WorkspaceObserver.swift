import AppKit
import Foundation

/// Observes application lifecycle events via NSWorkspace.
///
/// Publishes events when apps launch or terminate so
/// WindowPolicyManager can apply per-app rules.
/// See spec §36, US-WORK-013 §plan.md §3.3.
///
/// Flow:
/// ```
/// NSWorkspace notifications
///        ↓
///  WorkspaceObserver
///        ↓
///  EventBus (.applicationLaunched / .applicationTerminated)
///        ↓
///  WindowPolicyManager
/// ```
@MainActor
final class WorkspaceObserver {

    private let eventBus: EventBus
    private let notificationCenter: NotificationCenter
    private var launchToken: NSObjectProtocol?
    private var activateToken: NSObjectProtocol?
    private var terminateToken: NSObjectProtocol?

    init(eventBus: EventBus, notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.eventBus = eventBus
        self.notificationCenter = notificationCenter
    }

    /// Start observing NSWorkspace notifications.
    func startObserving() {
        guard launchToken == nil, activateToken == nil, terminateToken == nil else {
            return
        }
        let eventBus = self.eventBus
        launchToken = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else {
                return
            }
            let pid = app.processIdentifier
            let bundleID = app.bundleIdentifier
            Task { @MainActor in
                eventBus.publish(.applicationLaunched(pid, bundleID: bundleID))
            }
        }
        activateToken = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else {
                return
            }
            let pid = app.processIdentifier
            let bundleID = app.bundleIdentifier
            // US-LAUNCH-002: re-activation is a launch-shaped event for the
            // policy pipeline. ApplicationObserver's dedup window ensures we
            // do not register a fresh AXObserver for an already-watched pid.
            Task { @MainActor in
                eventBus.publish(.applicationLaunched(pid, bundleID: bundleID))
            }
        }
        terminateToken = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else {
                return
            }
            let pid = app.processIdentifier
            Task { @MainActor in
                eventBus.publish(.applicationTerminated(pid))
            }
        }
    }

    /// Stop observing.
    func stopObserving() {
        if let token = launchToken { notificationCenter.removeObserver(token) }
        if let token = activateToken { notificationCenter.removeObserver(token) }
        if let token = terminateToken { notificationCenter.removeObserver(token) }
        launchToken = nil
        activateToken = nil
        terminateToken = nil
    }
}

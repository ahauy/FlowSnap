import AppKit

/// Observes application lifecycle events via NSWorkspace.
///
/// Publishes events when apps launch or terminate so
/// WindowPolicyManager can apply per-app rules.
/// See spec §36.
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

    init(eventBus: EventBus) {
        self.eventBus = eventBus
    }

    /// Start observing NSWorkspace notifications.
    func startObserving() {
        // TODO: NSWorkspace.shared.notificationCenter
        // TODO: Observe didLaunchApplicationNotification
        // TODO: Observe didTerminateApplicationNotification
    }

    /// Stop observing.
    func stopObserving() {
        // TODO: Remove observers
    }
}

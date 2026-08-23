import CoreGraphics

/// All events that flow through FlowSnap's event system.
///
/// Services communicate through events instead of direct
/// dependencies. See spec §40.
enum WindowEvent: Hashable {
    // MARK: - Window Lifecycle

    case windowCreated(CGWindowID)
    case windowClosed(CGWindowID)
    case windowMoved(CGWindowID)
    case windowResized(CGWindowID)

    // MARK: - Application Lifecycle

    case applicationLaunched(pid_t)
    case applicationTerminated(pid_t)

    // MARK: - System

    case displayConfigurationChanged
    case activeSpaceChanged
}

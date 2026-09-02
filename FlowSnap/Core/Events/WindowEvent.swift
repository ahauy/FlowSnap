import CoreGraphics

/// All events that flow through FlowSnap's event system.
///
/// Services communicate through events instead of direct
/// dependencies. See spec §40.
enum WindowEvent: Hashable, Sendable {
    // MARK: - Window Lifecycle

    case windowCreated(CGWindowID)
    case windowClosed(CGWindowID)
    case windowMoved(CGWindowID)
    case windowResized(CGWindowID)

    // MARK: - Application Lifecycle

    /// A process was launched (or re-activated) and is ready to draw windows.
    ///
    /// US-WORK-013 §plan.md §10 decision 1: in-place replacement of the
    /// pre-US-WORK-013 `applicationLaunched(pid_t)` shape. The added
    /// `bundleID` allows downstream policy resolution without a second
    /// hop back to `NSWorkspace`.
    case applicationLaunched(pid_t, bundleID: String?)

    case applicationTerminated(pid_t)

    /// macOS created a window owned by `pid`. The window id is the
    /// `CGWindowID` reported by the AXObserver callback.
    case applicationWindowCreated(pid: pid_t, windowID: CGWindowID)

    // MARK: - System

    case displayConfigurationChanged
    case activeSpaceChanged
}

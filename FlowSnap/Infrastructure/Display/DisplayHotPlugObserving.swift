import Foundation

/// Events emitted when a display topology transition is detected and settled.
///
/// Traces to: US-DISP-016, REQ-DISP-001, REQ-DISP-002, BR-DISP-008.
public enum DisplayTopologyChangeEvent: Sendable, Equatable {
    case hotPlugConnected(newFingerprint: TopologyFingerprint, addedCount: Int)
    case hotUnplugDisconnected(newFingerprint: TopologyFingerprint, departingFingerprint: TopologyFingerprint)
    case geometryChanged(newFingerprint: TopologyFingerprint)
}

/// Protocol for observing system display parameter change notifications with debouncing.
///
/// Traces to: US-DISP-016, REQ-DISP-001, REQ-DISP-002, BR-DISP-008.
@MainActor
public protocol DisplayHotPlugObserving: AnyObject, Sendable {
    /// Callback closure invoked on `@MainActor` when a debounced topology change occurs.
    var onTopologyChanged: (@MainActor @Sendable (DisplayTopologyChangeEvent) -> Void)? { get set }

    /// Starts observing notifications.
    func startObserving()

    /// Stops observing notifications.
    func stopObserving()
}

import CoreGraphics
import Foundation

/// Outcomes emitted by `ApplicationObserving.events`.
///
/// `Sendable` so the `AsyncStream` can hand values across actor boundaries
/// without forcing a `MainActor` hop on the consumer side.
public enum LaunchObservationEvent: Sendable, Hashable {

    /// A window belonging to `pid` was created by macOS.
    ///
    /// The observer is released automatically after this event is published.
    case windowCreated(pid: pid_t, windowID: CGWindowID)

    /// No window appeared within `ApplicationObservingDefaults.windowCreationTimeout`.
    ///
    /// The observer is released after this event is published.
    case timeout(pid: pid_t)

    /// The observer could not be registered or failed mid-observation.
    case failed(pid: pid_t, reason: LaunchObservationFailure)
}

/// Failure reason for `.failed` events.
///
/// `AXErrorCode` is a tiny `Sendable` shim over the raw `AXError` `Int32`
/// returned by ApplicationServices. Keeping it here prevents Domain from
/// importing `ApplicationServices` (and its non-`Sendable` types) just to
/// talk about failure modes.
public enum LaunchObservationFailure: Sendable, Hashable {

    /// `AXObserverCreate` returned a non-zero `AXError`.
    case observerCreationFailed(code: AXErrorCode)

    /// `AXObserverAddNotification` returned a non-zero `AXError`.
    case addNotificationFailed(code: AXErrorCode)

    /// The ApplicationServices runtime is not available (e.g. Accessibility
    /// permission not granted — only observable at registration time).
    case accessibilityNotAuthorized
}

/// Minimal `Sendable` wrapper for `AXError` codes.
///
/// Domain must not import `ApplicationServices`, so we re-express the relevant
/// codes as an opaque integer. The concrete observer in Infrastructure maps
/// `AXError` → `AXErrorCode`.
public struct AXErrorCode: Sendable, Hashable, RawRepresentable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
}

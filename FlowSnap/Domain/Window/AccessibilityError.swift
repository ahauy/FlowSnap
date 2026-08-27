import Foundation

/// Typed errors representing Accessibility operations and boundary failures.
public enum AccessibilityError: Error, Equatable, Sendable {
    case notTrusted
    case applicationNotFound(pid_t)
    case windowNotFound
    case attributeUnsupported(String)
    case invalidGeometry
    case cannotComplete
    case systemFailure(Int32)
}

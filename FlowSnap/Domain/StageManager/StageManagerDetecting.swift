import Foundation

/// Defines the contract for inspecting macOS Stage Manager (WindowManager) status.
///
/// Implementations read the system preference `com.apple.WindowManager GloballyEnabled`.
public protocol StageManagerDetecting: Sendable {
    /// Returns `true` if macOS Stage Manager is currently enabled system-wide.
    var isStageManagerEnabled: Bool { get }
}

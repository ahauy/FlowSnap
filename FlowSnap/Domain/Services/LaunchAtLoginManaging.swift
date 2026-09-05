import Foundation

/// Domain status representing the registration state of FlowSnap as a macOS login item.
public enum LaunchAtLoginStatus: Sendable, Equatable {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
    case error(String)

    public var isEnabled: Bool {
        self == .enabled
    }

    public var requiresUserApproval: Bool {
        self == .requiresApproval
    }
}

/// Abstract protocol for managing login item lifecycle via SMAppService or test doubles.
@MainActor
public protocol LaunchAtLoginManaging: AnyObject, Sendable {
    /// Queries the current status of FlowSnap as a login item.
    func currentStatus() -> LaunchAtLoginStatus

    /// Registers FlowSnap to launch at user login.
    func register() throws

    /// Unregisters FlowSnap from launching at user login.
    func unregister() throws

    /// Directs the user to macOS System Settings > Login Items.
    func openSystemSettings()
}

import Foundation
@testable import FlowSnap

/// Test double for `LaunchAtLoginManaging` allowing tests to simulate macOS ServiceManagement states.
@MainActor
public final class MockLaunchAtLoginManager: LaunchAtLoginManaging, Sendable {
    public var status: LaunchAtLoginStatus
    public var registerError: (any Error)?
    public var unregisterError: (any Error)?

    public private(set) var registerCallCount: Int = 0
    public private(set) var unregisterCallCount: Int = 0
    public private(set) var openSystemSettingsCallCount: Int = 0

    public init(status: LaunchAtLoginStatus = .notRegistered) {
        self.status = status
    }

    public func currentStatus() -> LaunchAtLoginStatus {
        status
    }

    public func register() throws {
        if let registerError {
            throw registerError
        }
        registerCallCount += 1
        status = .enabled
    }

    public func unregister() throws {
        if let unregisterError {
            throw unregisterError
        }
        unregisterCallCount += 1
        status = .notRegistered
    }

    public func openSystemSettings() {
        openSystemSettingsCallCount += 1
    }
}

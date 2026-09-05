import AppKit
import Foundation
import OSLog
import ServiceManagement

private let logger = Logger(subsystem: "com.flowsnap.app", category: "SystemLaunchAtLoginManager")

/// System implementation of `LaunchAtLoginManaging` using macOS 13+ `SMAppService.mainApp`.
@MainActor
public final class SystemLaunchAtLoginManager: LaunchAtLoginManaging, Sendable {

    private static let loginItemsSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    )

    private static let fallbackSettingsURL = URL(
        string: "x-apple.systempreferences:"
    )

    public init() {}

    /// Queries the current status of FlowSnap as a login item via SMAppService.mainApp.
    public func currentStatus() -> LaunchAtLoginStatus {
        let systemStatus = SMAppService.mainApp.status
        switch systemStatus {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .notRegistered
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            logger.warning("Encountered unknown SMAppService status: \(String(describing: systemStatus))")
            return .notRegistered
        }
    }

    /// Registers FlowSnap with the ServiceManagement framework to launch at login.
    public func register() throws {
        logger.info("Registering FlowSnap with SMAppService.mainApp")
        do {
            try SMAppService.mainApp.register()
            logger.info("Successfully registered FlowSnap with SMAppService.mainApp")
        } catch {
            logger.error("Failed to register FlowSnap with SMAppService: \(error.localizedDescription)")
            throw error
        }
    }

    /// Unregisters FlowSnap from launching at login.
    public func unregister() throws {
        logger.info("Unregistering FlowSnap from SMAppService.mainApp")
        do {
            try SMAppService.mainApp.unregister()
            logger.info("Successfully unregistered FlowSnap from SMAppService.mainApp")
        } catch {
            logger.error("Failed to unregister FlowSnap from SMAppService: \(error.localizedDescription)")
            throw error
        }
    }

    /// Directs the user to macOS System Settings > Login Items & Extensions pane.
    @MainActor
    public func openSystemSettings() {
        if let url = Self.loginItemsSettingsURL, NSWorkspace.shared.open(url) {
            logger.info("Opened Login Items System Settings pane")
            return
        }

        if let fallbackURL = Self.fallbackSettingsURL {
            logger.info("Falling back to general System Settings")
            NSWorkspace.shared.open(fallbackURL)
        }
    }
}

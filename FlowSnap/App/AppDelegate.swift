import AppKit

/// Handles macOS application lifecycle events that SwiftUI doesn't cover.
///
/// Responsibilities:
/// - Bootstrap core services on launch
/// - Register global hotkeys
/// - Set up Accessibility observers
/// - Manage NSPanel overlays (snap preview)
final class AppDelegate: NSObject, NSApplicationDelegate {

    // TODO: Inject via AppDependencies
    // private let dependencies = AppDependencies()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Initialize core services
        // TODO: Check Accessibility & Input Monitoring permissions
        // TODO: Register global hotkeys
        // TODO: Start application observer
    }

    func applicationWillTerminate(_ notification: Notification) {
        // TODO: Clean up hotkeys, observers
    }
}

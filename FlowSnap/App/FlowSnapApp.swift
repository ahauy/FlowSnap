import SwiftUI

/// FlowSnap — Your Mac. Your Layout. Your Flow.
///
/// Menu bar application for macOS window and workspace management.
@main
struct FlowSnapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app — no main window
        MenuBarExtra("FlowSnap", systemImage: "rectangle.split.2x1") {
            MenuBarView()
        }

        Settings {
            SettingsView()
        }
    }
}

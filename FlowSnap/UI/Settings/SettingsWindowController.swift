import AppKit
import Foundation
import SwiftUI

/// Protocol governing presentation of the FlowSnap Settings window.
@MainActor
public protocol SettingsWindowPresenting: AnyObject, Sendable {
    /// Presents and focuses the settings window, bringing FlowSnap to the foreground.
    func showSettingsWindow()
    /// Presents and focuses the settings window at a specific tab.
    func showSettingsWindow(tab: SettingsTab)
}

public extension SettingsWindowPresenting {
    func showSettingsWindow(tab: SettingsTab) {
        showSettingsWindow()
    }
}

/// Floating panel subclass ensuring the settings panel can become key and accept user interactions.
final class SettingsFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Controller responsible for managing the lifecycle and presentation of the Settings window.
///
/// Ensures the window is properly brought to front and FlowSnap is activated via `NSApp.activate(ignoringOtherApps: true)`
/// so that settings presentation works reliably in accessory / menu bar extra mode.
@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate, SettingsWindowPresenting {

    // MARK: - Properties

    public private(set) var window: NSWindow?
    public let preferencesStore: PreferencesStore
    public let workspaceManager: WorkspaceManager?
    public let windowGroupManager: WindowGroupManager?
    public let presetResolver: (any PresetResolving)?
    public let commandDispatcher: CommandDispatcher?

    // MARK: - Initialization

    public init(
        preferencesStore: PreferencesStore,
        workspaceManager: WorkspaceManager? = nil,
        windowGroupManager: WindowGroupManager? = nil,
        presetResolver: (any PresetResolving)? = nil,
        commandDispatcher: CommandDispatcher? = nil
    ) {
        self.preferencesStore = preferencesStore
        self.workspaceManager = workspaceManager
        self.windowGroupManager = windowGroupManager
        self.presetResolver = presetResolver
        self.commandDispatcher = commandDispatcher
        super.init()
    }

    // MARK: - SettingsWindowPresenting

    /// Presents and focuses the settings window as a floating overlay above other windows.
    public func showSettingsWindow() {
        showSettingsWindow(tab: nil)
    }

    /// Presents and focuses the settings window at a specific tab.
    public func showSettingsWindow(tab: SettingsTab) {
        showSettingsWindow(tab: Optional(tab))
    }

    public func showSettingsWindow(tab: SettingsTab? = nil) {
        if let existingWindow = window {
            if let host = existingWindow.contentViewController as? NSHostingController<SettingsView> {
                host.rootView = SettingsView(
                    store: preferencesStore,
                    workspaceManager: workspaceManager,
                    windowGroupManager: windowGroupManager,
                    presetResolver: presetResolver,
                    commandDispatcher: commandDispatcher,
                    initialTab: tab ?? .general
                )
            }
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.level = .floating
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(
            store: preferencesStore,
            workspaceManager: workspaceManager,
            windowGroupManager: windowGroupManager,
            presetResolver: presetResolver,
            commandDispatcher: commandDispatcher,
            initialTab: tab ?? .general
        )
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = SettingsFloatingPanel(contentViewController: hostingController)
        newWindow.title = "FlowSnap Settings"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable, .nonactivatingPanel]
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.isFloatingPanel = true
        newWindow.becomesKeyOnlyIfNeeded = false
        newWindow.delegate = self
        newWindow.setContentSize(NSSize(width: 720, height: 520))
        newWindow.minSize = NSSize(width: 650, height: 460)
        newWindow.center()

        self.window = newWindow
        newWindow.orderFrontRegardless()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    // MARK: - NSWindowDelegate

    public func windowWillClose(_ notification: Notification) {
        // Window remains retained with isReleasedWhenClosed = false so it can be re-shown quickly.
    }
}

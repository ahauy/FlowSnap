import AppKit
import Foundation
import SwiftUI

/// Observable view model driving state and interactions for the FlowSnap Menu Bar interface.
///
/// Responsibilities:
/// - Evaluates Accessibility permission status and triggers onboarding alerts
/// - Tracks target window before menu activation to ensure correct snap dispatch
/// - Coordinates with CommandDispatcher to execute snap actions with auto-dismiss
@Observable
@MainActor
public final class MenuBarViewModel {

    // MARK: - Published State

    public private(set) var isAccessibilityTrusted: Bool = false
    public private(set) var lastFocusedWindow: ManagedWindow?

    // MARK: - Dismissal Callback

    public var dismissHandler: (() -> Void)?

    // MARK: - Dependencies

    private let accessibilityService: AccessibilityService
    private let commandDispatcher: CommandDispatcher
    private let windowManager: WindowManaging
    private let settingsWindowPresenter: (any SettingsWindowPresenting)?

    /// Workspace save/restore. `nil` when there is no workspace support (so the
    /// menu bar still constructs in contexts without it, and existing tests are
    /// unaffected); the Workspaces section hides itself when this is `nil`.
    public let workspaceViewModel: WorkspaceViewModel?

    // MARK: - Initialization

    public init(
        accessibilityService: AccessibilityService,
        commandDispatcher: CommandDispatcher,
        windowManager: WindowManaging,
        settingsWindowPresenter: (any SettingsWindowPresenting)? = nil,
        workspaceManager: WorkspaceManager? = nil
    ) {
        self.accessibilityService = accessibilityService
        self.commandDispatcher = commandDispatcher
        self.windowManager = windowManager
        self.settingsWindowPresenter = settingsWindowPresenter
        self.workspaceViewModel = workspaceManager.map { WorkspaceViewModel(manager: $0) }
        self.isAccessibilityTrusted = accessibilityService.isTrusted
    }

    // MARK: - Lifecycle & State Refresh

    public func refreshState() {
        self.isAccessibilityTrusted = accessibilityService.isTrusted
        Task { @MainActor in
            if let focused = await self.windowManager.focusedWindow() {
                self.lastFocusedWindow = focused
            }
        }
    }

    public func refreshStateAsync() async {
        self.isAccessibilityTrusted = accessibilityService.isTrusted
        if let focused = await self.windowManager.focusedWindow() {
            self.lastFocusedWindow = focused
        }
    }

    // MARK: - User Actions

    /// Dismisses any open MenuBarExtra window/panel so that settings or snapped windows receive focus.
    public func dismissMenuBarWindow() {
        for window in NSApp.windows {
            let isOverlay = window is SnapPreviewPanel || window is AdaptiveDividerOverlayPanel
            let isSettings = window === (settingsWindowPresenter as? SettingsWindowController)?.window
            if !isOverlay && !isSettings && window.isVisible {
                window.orderOut(nil)
            }
        }
        dismissHandler?()
    }

    /// Triggers a snap action asynchronously, awaiting command completion and invoking dismissal.
    public func triggerSnapAsync(_ action: MenuBarAction) async throws {
        guard isAccessibilityTrusted else {
            requestAccessibilityPermission()
            return
        }

        dismissMenuBarWindow()
        try await commandDispatcher.dispatch(.snap(action.snapTarget))
    }

    /// Triggers a snap action synchronously from UI events.
    public func triggerSnap(_ action: MenuBarAction) {
        guard isAccessibilityTrusted else {
            requestAccessibilityPermission()
            return
        }

        Task { @MainActor in
            try? await self.triggerSnapAsync(action)
        }
    }

    /// Opens macOS System Settings directly to Privacy & Security > Accessibility.
    public func requestAccessibilityPermission() {
        accessibilityService.openSystemSettings()
    }

    /// Opens the application settings window.
    public func openSettings() {
        dismissMenuBarWindow()
        if let settingsWindowPresenter {
            settingsWindowPresenter.showSettingsWindow()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Cleanly terminates the FlowSnap application.
    public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

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

    // MARK: - Initialization

    public init(
        accessibilityService: AccessibilityService,
        commandDispatcher: CommandDispatcher,
        windowManager: WindowManaging
    ) {
        self.accessibilityService = accessibilityService
        self.commandDispatcher = commandDispatcher
        self.windowManager = windowManager
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

    /// Triggers a snap action asynchronously, awaiting command completion and invoking dismissal.
    public func triggerSnapAsync(_ action: MenuBarAction) async throws {
        guard isAccessibilityTrusted else {
            requestAccessibilityPermission()
            return
        }

        try await commandDispatcher.dispatch(.snap(action.snapTarget))
        dismissHandler?()
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
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        dismissHandler?()
    }

    /// Cleanly terminates the FlowSnap application.
    public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

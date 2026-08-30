import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for MenuBarViewModel state management and user actions.
///
/// Traces to: US-SNAP-005, TC-MENU-001..004.
@MainActor
struct MenuBarViewModelTests {

    static func makeSimulatedEnvironment(
        isTrusted: Bool = true,
        mockWindow: ManagedWindow? = nil,
        mockSettingsPresenter: (any SettingsWindowPresenting)? = nil
    ) -> (MenuBarViewModel, MockAccessibilityService, MockWindowManaging, CommandDispatcher) {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let displayManager = DisplayManager(displayProvider: { [primary] })
        let accessibilityService = MockAccessibilityService(isTrusted: isTrusted)
        let windowRegistry = WindowRegistry()
        let snapEngine = SnapEngine(windowRegistry: windowRegistry, displayManager: displayManager)
        let windowManager = MockWindowManaging(mockFocusedWindow: mockWindow)
        let commandDispatcher = CommandDispatcher(
            windowManager: windowManager,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        let viewModel = MenuBarViewModel(
            accessibilityService: accessibilityService,
            commandDispatcher: commandDispatcher,
            windowManager: windowManager,
            settingsWindowPresenter: mockSettingsPresenter
        )
        return (viewModel, accessibilityService, windowManager, commandDispatcher)
    }

    @Test func accessibilityPermissionStateObservation() {
        // TC-MENU-001: Untrusted state
        let (untrustedVM, _, _, _) = Self.makeSimulatedEnvironment(isTrusted: false)
        #expect(untrustedVM.isAccessibilityTrusted == false)

        // Trusted state
        let (trustedVM, _, _, _) = Self.makeSimulatedEnvironment(isTrusted: true)
        #expect(trustedVM.isAccessibilityTrusted == true)
    }

    @Test func triggerSnapDispatchesCommandAndDismisses() async throws {
        // TC-MENU-002: Snap dispatch & auto-dismiss
        let window = ManagedWindow(
            id: 201,
            pid: 4567,
            title: "Safari",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            kind: .normal
        )
        let (viewModel, _, windowManager, dispatcher) = Self.makeSimulatedEnvironment(
            isTrusted: true,
            mockWindow: window
        )

        var dismissCount = 0
        viewModel.dismissHandler = {
            dismissCount += 1
        }

        try await viewModel.triggerSnapAsync(.leftHalf)

        #expect(dispatcher.lastExecutedCommand == .snap(.left))
        #expect(windowManager.moveCallCount == 1)
        #expect(dismissCount == 1)
    }

    @Test func triggerSnapWhenUntrustedRequestsPermission() async throws {
        // TC-MENU-001 / TC-MENU-002: Guard against untrusted snap
        let (viewModel, accessibilityService, windowManager, _) = Self.makeSimulatedEnvironment(isTrusted: false)

        var dismissCount = 0
        viewModel.dismissHandler = {
            dismissCount += 1
        }

        try await viewModel.triggerSnapAsync(.rightHalf)

        #expect(accessibilityService.openSettingsCallCount == 1)
        #expect(windowManager.moveCallCount == 0)
        #expect(dismissCount == 0)
    }

    @Test func requestAccessibilityPermissionDelegation() {
        // TC-MENU-003: Direct permission request
        let (viewModel, accessibilityService, _, _) = Self.makeSimulatedEnvironment(isTrusted: false)

        viewModel.requestAccessibilityPermission()
        #expect(accessibilityService.openSettingsCallCount == 1)
    }

    @Test func menuBarActionDomainMappingAndBadges() {
        // TC-MENU-004: Exhaustive action mappings
        let actions = MenuBarAction.allCases
        #expect(actions.count == 10)

        for action in actions {
            #expect(!action.iconName.isEmpty)
            #expect(!action.shortcutBadge.isEmpty)
            #expect(!action.rawValue.isEmpty)
        }

        #expect(MenuBarAction.leftHalf.snapTarget == .left)
        #expect(MenuBarAction.rightHalf.snapTarget == .right)
        #expect(MenuBarAction.topHalf.snapTarget == .top)
        #expect(MenuBarAction.bottomHalf.snapTarget == .bottom)
        #expect(MenuBarAction.maximize.snapTarget == .maximize)
        #expect(MenuBarAction.restore.snapTarget == .restore)
        #expect(MenuBarAction.topLeft.snapTarget == .topLeft)
        #expect(MenuBarAction.topRight.snapTarget == .topRight)
        #expect(MenuBarAction.bottomLeft.snapTarget == .bottomLeft)
        #expect(MenuBarAction.bottomRight.snapTarget == .bottomRight)
    }

    @Test func openSettingsDelegatesToSettingsPresenterAndDismisses() {
        let mockPresenter = MockSettingsWindowPresenter()
        let (viewModel, _, _, _) = Self.makeSimulatedEnvironment(
            isTrusted: true,
            mockSettingsPresenter: mockPresenter
        )

        var dismissCount = 0
        viewModel.dismissHandler = {
            dismissCount += 1
        }

        viewModel.openSettings()

        #expect(mockPresenter.showSettingsWindowCallCount == 1)
        #expect(dismissCount == 1)
    }
}

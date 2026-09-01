import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for MenuBarViewModel state management and user actions.
///
/// Traces to: US-SNAP-005, TC-MENU-001..004.
@MainActor
struct MenuBarViewModelTests {

    struct TestEnvironment {
        let viewModel: MenuBarViewModel
        let accessibilityService: MockAccessibilityService
        let windowManager: MockWindowManaging
        let commandDispatcher: CommandDispatcher
    }

    static func makeSimulatedEnvironment(
        isTrusted: Bool = true,
        mockWindow: ManagedWindow? = nil,
        mockSettingsPresenter: (any SettingsWindowPresenting)? = nil
    ) -> TestEnvironment {
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
        return TestEnvironment(
            viewModel: viewModel,
            accessibilityService: accessibilityService,
            windowManager: windowManager,
            commandDispatcher: commandDispatcher
        )
    }

    @Test func accessibilityPermissionStateObservation() {
        // TC-MENU-001: Untrusted state
        let untrustedEnv = Self.makeSimulatedEnvironment(isTrusted: false)
        #expect(untrustedEnv.viewModel.isAccessibilityTrusted == false)

        // Trusted state
        let trustedEnv = Self.makeSimulatedEnvironment(isTrusted: true)
        #expect(trustedEnv.viewModel.isAccessibilityTrusted == true)
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
        let env = Self.makeSimulatedEnvironment(
            isTrusted: true,
            mockWindow: window
        )

        var dismissCount = 0
        env.viewModel.dismissHandler = {
            dismissCount += 1
        }

        try await env.viewModel.triggerSnapAsync(.leftHalf)

        #expect(env.commandDispatcher.lastExecutedCommand == .snap(.left))
        #expect(env.windowManager.moveCallCount == 1)
        #expect(dismissCount == 1)
    }

    @Test func triggerSnapWhenUntrustedRequestsPermission() async throws {
        // TC-MENU-001 / TC-MENU-002: Guard against untrusted snap
        let env = Self.makeSimulatedEnvironment(isTrusted: false)

        var dismissCount = 0
        env.viewModel.dismissHandler = {
            dismissCount += 1
        }

        try await env.viewModel.triggerSnapAsync(.rightHalf)

        #expect(env.accessibilityService.openSettingsCallCount == 1)
        #expect(env.windowManager.moveCallCount == 0)
        #expect(dismissCount == 0)
    }

    @Test func requestAccessibilityPermissionDelegation() {
        // TC-MENU-003: Direct permission request
        let env = Self.makeSimulatedEnvironment(isTrusted: false)

        env.viewModel.requestAccessibilityPermission()
        #expect(env.accessibilityService.openSettingsCallCount == 1)
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
        let env = Self.makeSimulatedEnvironment(
            isTrusted: true,
            mockSettingsPresenter: mockPresenter
        )

        var dismissCount = 0
        env.viewModel.dismissHandler = {
            dismissCount += 1
        }

        env.viewModel.openSettings()

        #expect(mockPresenter.showSettingsWindowCallCount == 1)
        #expect(dismissCount == 1)
    }

    @Test func workspaceViewModelInitializedWhenWorkspaceManagerProvided() {
        let accessibilityService = MockAccessibilityService(isTrusted: true)
        let windowManager = MockWindowManaging()
        let displayManager = DisplayManager(displayProvider: { [] })
        let snapEngine = SnapEngine(windowRegistry: WindowRegistry(), displayManager: displayManager)
        let commandDispatcher = CommandDispatcher(
            windowManager: windowManager,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        let workspaceManager = WorkspaceManager(
            accessibilityService: accessibilityService,
            windowManager: windowManager,
            displayManager: displayManager,
            layoutEngine: LayoutEngine()
        )

        let viewModel = MenuBarViewModel(
            accessibilityService: accessibilityService,
            commandDispatcher: commandDispatcher,
            windowManager: windowManager,
            workspaceManager: workspaceManager
        )

        #expect(viewModel.workspaceViewModel != nil)
    }

    @Test func appDependenciesWiresWorkspaceManagerProperly() {
        let dependencies = AppDependencies()
        #expect(dependencies.menuBarViewModel.workspaceViewModel != nil)
        let controllerManager = dependencies.settingsWindowController.workspaceManager
        #expect(dependencies.workspaceManager === controllerManager)
    }
}

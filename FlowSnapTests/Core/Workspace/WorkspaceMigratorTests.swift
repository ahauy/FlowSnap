import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
@Suite("WorkspaceMigrator")
struct WorkspaceMigratorTests {

    private let display1 = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1400),
        scaleFactor: 2.0,
        isPrimary: true
    )

    private let display2 = Display(
        id: 2,
        frame: CGRect(x: 2560, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 2560, y: 0, width: 1920, height: 1040),
        scaleFactor: 2.0,
        isPrimary: false
    )

    private let display3 = Display(
        id: 3,
        frame: CGRect(x: 4480, y: 0, width: 1080, height: 1920),
        visibleFrame: CGRect(x: 4480, y: 0, width: 1080, height: 1880),
        scaleFactor: 1.0,
        isPrimary: false
    )

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapMigratorTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeWorkspaceManager(
        windows: [ManagedWindow],
        displays: [Display],
        stageManagerDetector: (any StageManagerDetecting)? = nil
    ) -> (WorkspaceManager, MockAccessibilityService, MockWindowManaging) {
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = windows
        for win in windows {
            let el = AXUIElementCreateSystemWide()
            accessibility.mockWindowElements[win.id] = el
        }
        let windowManager = MockWindowManaging()

        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: windowManager,
            displayManager: MockDisplayManager(displays: displays),
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            stageManagerDetector: stageManagerDetector ?? MockStageManagerDetector(isStageManagerEnabled: false),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        return (manager, accessibility, windowManager)
    }

    // MARK: - TC-MIG-001: 2-Window Migration (Stage Manager OFF)

    @Test("TC-MIG-001: 2-Window Workspace Migration across Displays")
    func migrateTwoWindows() async throws {
        let win1 = ManagedWindow(
            id: 101,
            pid: 1001,
            bundleIdentifier: "com.editor",
            title: "Code",
            frame: CGRect(x: 0, y: 0, width: 1536, height: 1400), // 60% of Display 1
            isMinimized: false,
            kind: .normal
        )
        let win2 = ManagedWindow(
            id: 102,
            pid: 1002,
            bundleIdentifier: "com.browser",
            title: "Web",
            frame: CGRect(x: 1536, y: 0, width: 1024, height: 1400), // 40% of Display 1
            isMinimized: false,
            kind: .normal
        )

        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [win1, win2],
            displays: [display1, display2]
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1, display2])
        let navigator = DisplayNavigator()
        let preferences = WorkspaceTestFixtures.preferences(gap: 0)

        // Save a workspace and activate it
        let workspace = try await manager.saveWorkspace(named: "Dev", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .left70_30, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightOneThird, orderIndex: 1)
        ])
        _ = try await manager.restoreWorkspace(id: workspace.id)

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: false),
            preferences: preferences
        )

        windowManager.mockFocusedWindow = win1

        let result = try await migrator.migrateActiveWorkspace(direction: .next)

        #expect(result == .success(windowsMigrated: 2, targetDisplayID: display2.id))
        #expect(windowManager.moveCallCount >= 2)
        #expect(cursor.warpedPoints.count >= 1)
    }

    // MARK: - TC-MIG-003: Stage Manager Active Migration

    @Test("TC-MIG-003: Multi-Window Migration with Stage Manager Active")
    func migrateWithStageManagerActive() async throws {
        let win1 = ManagedWindow(
            id: 101,
            pid: 1001,
            bundleIdentifier: "com.editor",
            title: "Code",
            frame: CGRect(x: 0, y: 0, width: 1536, height: 1400),
            isMinimized: false,
            kind: .normal
        )
        let win2 = ManagedWindow(
            id: 102,
            pid: 1002,
            bundleIdentifier: "com.browser",
            title: "Web",
            frame: CGRect(x: 1536, y: 0, width: 1024, height: 1400),
            isMinimized: false,
            kind: .normal
        )

        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [win1, win2],
            displays: [display1, display2],
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: true)
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1, display2])
        let navigator = DisplayNavigator()
        let preferences = WorkspaceTestFixtures.preferences(gap: 0)
        preferences.setStageManagerAutoGroupingEnabled(true)

        let workspace = try await manager.saveWorkspace(named: "Dev", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 1)
        ])
        _ = try await manager.restoreWorkspace(id: workspace.id)

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: true),
            preferences: preferences
        )

        windowManager.mockFocusedWindow = win1

        let result = try await migrator.migrateActiveWorkspace(direction: .next)

        #expect(result == .success(windowsMigrated: 2, targetDisplayID: display2.id))
        #expect(accessibility.raiseCallCount >= 2)
    }

    // MARK: - TC-MIG-004: Single Display Safe No-Op

    @Test("TC-MIG-004: Single Display Safe No-Op")
    func singleDisplayNoOp() async throws {
        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [],
            displays: [display1]
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1])
        let navigator = DisplayNavigator()

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: false),
            preferences: PreferencesStore()
        )

        let result = try await migrator.migrateActiveWorkspace(direction: .next)

        #expect(result == .noOp(reason: .singleDisplay))
        #expect(windowManager.moveCallCount == 0)
        #expect(cursor.warpedPoints.isEmpty)
    }

    // MARK: - TC-MIG-005: No Active Workspace Safe No-Op

    @Test("TC-MIG-005: No Active Workspace Safe No-Op")
    func noActiveWorkspaceNoOp() async throws {
        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [],
            displays: [display1, display2]
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1, display2])
        let navigator = DisplayNavigator()

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: false),
            preferences: PreferencesStore()
        )

        let result = try await migrator.migrateActiveWorkspace(direction: .next)

        #expect(result == .noOp(reason: .noActiveWorkspace))
        #expect(windowManager.moveCallCount == 0)
    }

    // MARK: - TC-MIG-006: Cyclic Navigation

    @Test("TC-MIG-006: Cyclic Navigation between 3 Displays")
    func cyclicNavigation() async throws {
        let win1 = ManagedWindow(
            id: 101,
            pid: 1001,
            bundleIdentifier: "com.editor",
            title: "Code",
            frame: display3.visibleFrame,
            isMinimized: false,
            kind: .normal
        )

        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [win1],
            displays: [display1, display2, display3]
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1, display2, display3])
        let navigator = DisplayNavigator()

        let workspace = try await manager.saveWorkspace(named: "Dev", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .maximize, orderIndex: 0)
        ])
        _ = try await manager.restoreWorkspace(id: workspace.id)

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: false),
            preferences: PreferencesStore()
        )

        windowManager.mockFocusedWindow = win1

        // From Display 3 (rightmost), .next wraps around to Display 1 (leftmost)
        let result = try await migrator.migrateActiveWorkspace(direction: .next)
        #expect(result == .success(windowsMigrated: 1, targetDisplayID: display1.id))
    }

    // MARK: - TC-MIG-002: 3-Window Migration with Two-Phase Move Ordering

    @Test("TC-MIG-002: 3-Window Migration with Two-Phase Move Ordering")
    func threeWindowMigration() async throws {
        let win1 = ManagedWindow(
            id: 101, pid: 1001, bundleIdentifier: "com.editor", title: "Code",
            frame: CGRect(x: 0, y: 0, width: 1280, height: 1400), isMinimized: false, kind: .normal
        )
        let win2 = ManagedWindow(
            id: 102, pid: 1002, bundleIdentifier: "com.terminal", title: "Term",
            frame: CGRect(x: 1280, y: 0, width: 640, height: 1400), isMinimized: false, kind: .normal
        )
        let win3 = ManagedWindow(
            id: 103, pid: 1003, bundleIdentifier: "com.browser", title: "Web",
            frame: CGRect(x: 1920, y: 0, width: 640, height: 1400), isMinimized: false, kind: .normal
        )

        let (manager, accessibility, windowManager) = makeWorkspaceManager(
            windows: [win1, win2, win3],
            displays: [display1, display2]
        )
        let cursor = MockCursorManager()
        let displayManager = MockDisplayManager(displays: [display1, display2])
        let navigator = DisplayNavigator()

        let workspace = try await manager.saveWorkspace(named: "Trio", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.terminal", zone: .rightOneThird, orderIndex: 1),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 2)
        ])
        _ = try await manager.restoreWorkspace(id: workspace.id)

        let migrator = WorkspaceMigrator(
            workspaceManager: manager,
            displayManager: displayManager,
            displayNavigator: navigator,
            windowManager: windowManager,
            accessibilityService: accessibility,
            cursorManager: cursor,
            stageManagerDetector: MockStageManagerDetector(isStageManagerEnabled: false),
            preferences: PreferencesStore()
        )

        windowManager.mockFocusedWindow = win1

        let result = try await migrator.migrateActiveWorkspace(direction: .next)
        #expect(result == .success(windowsMigrated: 3, targetDisplayID: display2.id))
        #expect(windowManager.moveCallCount >= 3)
    }

    // MARK: - TC-MIG-007: CommandDispatcher Dispatching

    @Test("TC-MIG-007: CommandDispatcher Dispatches .migrateWorkspace")
    func commandDispatcherDispatchesMigrateWorkspace() async throws {
        final class MockWorkspaceMigrator: WorkspaceMigrating, @unchecked Sendable {
            var lastDirection: MigrationDirection?
            var callCount = 0

            func migrateActiveWorkspace(direction: MigrationDirection) async throws -> MigrationResult {
                callCount += 1
                lastDirection = direction
                return .success(windowsMigrated: 2, targetDisplayID: 2)
            }
        }

        let mockMigrator = MockWorkspaceMigrator()
        let windowManager = MockWindowManaging()
        let snapEngine = SnapEngine(
            layoutEngine: LayoutEngine(),
            windowRegistry: WindowRegistry(),
            displayManager: MockDisplayManager(displays: [display1, display2]),
            preferencesStore: PreferencesStore()
        )
        let dispatcher = CommandDispatcher(
            windowManager: windowManager,
            snapEngine: snapEngine,
            displayManager: MockDisplayManager(displays: [display1, display2]),
            workspaceMigrator: mockMigrator
        )

        try await dispatcher.dispatch(.migrateWorkspace(.next))
        #expect(mockMigrator.callCount == 1)
        #expect(mockMigrator.lastDirection == .next)

        try await dispatcher.dispatch(.migrateWorkspace(.previous))
        #expect(mockMigrator.callCount == 2)
        #expect(mockMigrator.lastDirection == .previous)
    }
}

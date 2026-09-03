import AppKit
import CoreGraphics
import Foundation
import OSLog

private let migratorLogger = Logger(subsystem: "com.flowsnap.app", category: "WorkspaceMigrator")

/// Core coordinator executing atomic cross-display workspace migration.
///
/// Traces to: US-DISP-017, BR-MIG-001..005, ADR-0014.
@MainActor
public final class WorkspaceMigrator: WorkspaceMigrating {

    private let workspaceManager: WorkspaceManager
    private let displayManager: any DisplayManaging
    private let displayNavigator: any DisplayNavigating
    private let windowManager: any WindowManaging
    private let accessibilityService: any AccessibilityService
    private let cursorManager: any CursorWarping
    private let stageManagerDetector: any StageManagerDetecting
    private let preferences: PreferencesStore
    private weak var dividerCoordinator: AdaptiveDividerCoordinator?

    public init(
        workspaceManager: WorkspaceManager,
        displayManager: any DisplayManaging = DisplayManager(),
        displayNavigator: any DisplayNavigating = DisplayNavigator(),
        windowManager: any WindowManaging,
        accessibilityService: any AccessibilityService,
        cursorManager: any CursorWarping = CursorManager(),
        stageManagerDetector: (any StageManagerDetecting)? = nil,
        preferences: PreferencesStore = PreferencesStore(),
        dividerCoordinator: AdaptiveDividerCoordinator? = nil
    ) {
        self.workspaceManager = workspaceManager
        self.displayManager = displayManager
        self.displayNavigator = displayNavigator
        self.windowManager = windowManager
        self.accessibilityService = accessibilityService
        self.cursorManager = cursorManager
        self.stageManagerDetector = stageManagerDetector ?? StageManagerDetector()
        self.preferences = preferences
        self.dividerCoordinator = dividerCoordinator
    }

    /// Migrates the active workspace on the current display in the specified direction.
    public func migrateActiveWorkspace(
        direction: MigrationDirection
    ) async throws -> MigrationResult {
        guard accessibilityService.isTrusted else {
            return .noOp(reason: .accessibilityDenied)
        }

        let displays = await displayManager.displays
        guard displays.count > 1 else {
            migratorLogger.debug("Single display connected; migration is no-op.")
            return .noOp(reason: .singleDisplay)
        }

        // 1. Resolve source display
        let focusedWindow = await windowManager.focusedWindow()
        let sourceDisplay: Display?
        if let focusedWindow {
            sourceDisplay = await displayManager.display(for: focusedWindow.frame, cursorPoint: nil)
        } else {
            let mouseLocation = NSEvent.mouseLocation
            sourceDisplay = await displayManager.display(for: CGRect(origin: mouseLocation, size: .zero), cursorPoint: mouseLocation)
        }

        guard let sourceDisplay else {
            return .noOp(reason: .noActiveWorkspace)
        }

        // 2. Resolve target display
        let targetDisplay: Display?
        switch direction {
        case .next:
            targetDisplay = displayNavigator.nextDisplay(after: sourceDisplay, in: displays)
        case .previous:
            targetDisplay = displayNavigator.previousDisplay(before: sourceDisplay, in: displays)
        }

        guard let targetDisplay, targetDisplay.id != sourceDisplay.id else {
            return .noOp(reason: .singleDisplay)
        }

        // 3. Resolve active workspace on source display
        guard let workspace = resolveActiveWorkspace(on: sourceDisplay) else {
            return .noOp(reason: .noActiveWorkspace)
        }

        // 4. Resolve windows belonging to this workspace on sourceDisplay
        let visibleWindows = accessibilityService.allVisibleManagedWindows()
        let displayWindows = visibleWindows.filter { window in
            sourceDisplay.visibleFrame.intersects(window.frame)
        }

        struct MovingPair {
            let window: ManagedWindow
            let sourceFrame: CGRect
            let targetFrame: CGRect
        }

        var pairs: [MovingPair] = []
        for placement in workspace.orderedPlacements {
            let matching = displayWindows.filter {
                $0.bundleIdentifier == placement.bundleIdentifier
                    && $0.kind.isRestorable
                    && $0.frame.width > 0
                    && $0.frame.height > 0
            }
            if let targetWindow = matching.first {
                let scaled = RelativeFrameScaler.scale(
                    frame: targetWindow.frame,
                    from: sourceDisplay.visibleFrame,
                    to: targetDisplay.visibleFrame
                )
                pairs.append(MovingPair(window: targetWindow, sourceFrame: targetWindow.frame, targetFrame: scaled))
            }
        }

        guard !pairs.isEmpty else {
            return .noOp(reason: .noWindowsFound)
        }

        // 5. Execute move ordering
        let stageManagerActive = preferences.isStageManagerAutoGroupingEnabled && stageManagerDetector.isStageManagerEnabled
        let primaryHeight = await displayManager.primaryScreenHeight

        if stageManagerActive {
            let anchor = pairs[0]
            let anchorAX = CoordinateTransformer.toAX(rect: anchor.targetFrame, primaryScreenHeight: primaryHeight)
            try await windowManager.move(anchor.window, to: anchorAX)
            _ = accessibilityService.raise(window: anchor.window)

            for pair in pairs.dropFirst() {
                try? await Task.sleep(nanoseconds: 40_000_000) // 40ms stagger
                let pairAX = CoordinateTransformer.toAX(rect: pair.targetFrame, primaryScreenHeight: primaryHeight)
                try await windowManager.move(pair.window, to: pairAX)
                _ = accessibilityService.raise(window: pair.window)
            }

            // Final lock on anchor
            _ = accessibilityService.raise(window: anchor.window)
        } else {
            // 2-Phase move ordering: shrinking before expanding
            let shrinking = pairs.filter {
                ($0.targetFrame.width * $0.targetFrame.height) <= ($0.sourceFrame.width * $0.sourceFrame.height)
            }
            let expanding = pairs.filter {
                ($0.targetFrame.width * $0.targetFrame.height) > ($0.sourceFrame.width * $0.sourceFrame.height)
            }

            for pair in shrinking {
                let ax = CoordinateTransformer.toAX(rect: pair.targetFrame, primaryScreenHeight: primaryHeight)
                try await windowManager.move(pair.window, to: ax)
            }
            for pair in expanding {
                let ax = CoordinateTransformer.toAX(rect: pair.targetFrame, primaryScreenHeight: primaryHeight)
                try await windowManager.move(pair.window, to: ax)
            }
        }

        // 6. Post-migration cursor warping and focus retention
        let primaryTargetFrame = pairs[0].targetFrame
        let primaryCenterAX = CoordinateTransformer.toAX(
            point: CGPoint(x: primaryTargetFrame.midX, y: primaryTargetFrame.midY),
            primaryScreenHeight: primaryHeight
        )
        cursorManager.warpCursor(to: primaryCenterAX)
        try? await windowManager.focus(pairs[0].window)

        // 7. Reset divider coordinator so seam overlay refreshes on target display
        dividerCoordinator?.resetState()

        return .success(windowsMigrated: pairs.count, targetDisplayID: targetDisplay.id)
    }

    private func resolveActiveWorkspace(on display: Display) -> Workspace? {
        if let active = workspaceManager.activeWorkspace {
            return active
        }
        // Fallback: match visible windows on display against saved workspaces
        let visible = accessibilityService.allVisibleManagedWindows().filter {
            display.visibleFrame.intersects($0.frame)
        }
        let visibleBundleIDs = Set(visible.compactMap(\.bundleIdentifier))

        for ws in workspaceManager.workspaces {
            let wsBundleIDs = Set(ws.placements.map(\.bundleIdentifier))
            if !wsBundleIDs.isEmpty && wsBundleIDs.isSubset(of: visibleBundleIDs) {
                return ws
            }
        }
        return nil
    }
}

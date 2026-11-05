import AppKit
import CoreGraphics
import Foundation
import OSLog

private let migratorLogger = Logger(subsystem: "com.flowsnap.app", category: "WorkspaceMigrator")

/// Core coordinator executing cross-display workspace migration as one best-effort
/// pass: every window in the layout is attempted, refusals are recorded instead of
/// thrown, and the outcome comes back as a single reportable result.
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

        // 5. Execute move ordering — best effort, exactly like the restore pass.
        // A window that refuses to move is recorded and the pass continues: an
        // aborted pass would leave the windows already moved on the target display
        // with nothing to undo them as a unit, while a finished pass with recorded
        // failures still gives the user a layout and one honest summary line.
        let stageManagerActive = preferences.isStageManagerAutoGroupingEnabled && stageManagerDetector.isStageManagerEnabled
        let primaryHeight = await displayManager.primaryScreenHeight

        var moved: [MovingPair] = []
        var skipped: [SkippedApp] = []

        if stageManagerActive {
            let anchor = pairs[0]
            if let refusal = await movePair(anchor, primaryHeight: primaryHeight) {
                skipped.append(refusal)
            } else {
                moved.append(anchor)
                _ = accessibilityService.raise(window: anchor.window)
            }

            for pair in pairs.dropFirst() {
                try? await Task.sleep(nanoseconds: 40_000_000) // 40ms stagger
                if let refusal = await movePair(pair, primaryHeight: primaryHeight) {
                    skipped.append(refusal)
                } else {
                    moved.append(pair)
                    _ = accessibilityService.raise(window: pair.window)
                }
            }

            // Final lock on anchor
            if moved.contains(where: { $0.window.id == anchor.window.id }) {
                _ = accessibilityService.raise(window: anchor.window)
            }
        } else {
            // 2-Phase move ordering: shrinking before expanding
            let shrinking = pairs.filter {
                ($0.targetFrame.width * $0.targetFrame.height) <= ($0.sourceFrame.width * $0.sourceFrame.height)
            }
            let expanding = pairs.filter {
                ($0.targetFrame.width * $0.targetFrame.height) > ($0.sourceFrame.width * $0.sourceFrame.height)
            }

            for pair in shrinking + expanding {
                if let refusal = await movePair(pair, primaryHeight: primaryHeight) {
                    skipped.append(refusal)
                } else {
                    moved.append(pair)
                }
            }
        }

        guard let primary = moved.first else {
            return .noOp(reason: .allMovesFailed(attempted: pairs.count, skipped: skipped))
        }

        // 6. Post-migration cursor warping and focus retention, aimed at the first
        // window that actually landed — warping to a window left on the source
        // display would drop the cursor on empty desktop.
        let primaryCenterAX = CoordinateTransformer.toAX(
            point: CGPoint(x: primary.targetFrame.midX, y: primary.targetFrame.midY),
            primaryScreenHeight: primaryHeight
        )
        cursorManager.warpCursor(to: primaryCenterAX)
        try? await windowManager.focus(primary.window)

        // 7. Reset divider coordinator so seam overlay refreshes on target display
        dividerCoordinator?.resetState()

        diagPrint("[DIAG-MIG] pass complete moved=\(moved.count) skipped=\(skipped.count) targetDisplayID=\(targetDisplay.id)")
        return .success(windowsMigrated: moved.count, targetDisplayID: targetDisplay.id, skipped: skipped)
    }

    /// One window's leg of the pass: moves it, and returns the skip record when the
    /// window refuses rather than throwing — the caller has to keep going.
    private func movePair(_ pair: MovingPair, primaryHeight: CGFloat) async -> SkippedApp? {
        let ax = CoordinateTransformer.toAX(rect: pair.targetFrame, primaryScreenHeight: primaryHeight)
        do {
            try await windowManager.move(pair.window, to: ax)
            return nil
        } catch {
            let name = Self.summaryName(for: pair.window)
            migratorLogger.error("Migration move refused for \(name): \(error.localizedDescription)")
            diagPrint("[DIAG-MIG] move refused window=\(name) id=\(pair.window.id) error=\(error.localizedDescription)")
            return SkippedApp(bundleIdentifier: name, reason: .notMoved)
        }
    }

    /// The name a refused window is reported under: its bundle id when the
    /// WindowServer gave us one, otherwise its title.
    private static func summaryName(for window: ManagedWindow) -> String {
        if let bundleIdentifier = window.bundleIdentifier, !bundleIdentifier.isEmpty {
            return bundleIdentifier
        }
        return window.title.isEmpty ? "Window \(window.id)" : window.title
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

/// One window paired with the frame it measured on the source display and the frame
/// it is headed to on the target display, for a single migration pass.
private struct MovingPair {
    let window: ManagedWindow
    let sourceFrame: CGRect
    let targetFrame: CGRect
}

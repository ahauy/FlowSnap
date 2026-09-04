import AppKit
import CoreGraphics
import Foundation
import OSLog

private let dispatcherLogger = Logger(subsystem: "com.flowsnap", category: "CommandDispatcher")

/// Protocol abstraction for CommandDispatcher.
public protocol CommandDispatching: Sendable {
    func dispatch(_ command: WindowCommand) async throws
}

/// Central command router for all FlowSnap actions.
///
/// All input sources (hotkey, menu bar, automation) produce
/// WindowCommands that flow through this dispatcher.
/// See spec §35.
///
/// Flow:
/// ```
/// Keyboard / Menu Bar / Automation
///        ↓
///    WindowCommand
///        ↓
///    CommandDispatcher
///        ↓
///    SnapEngine / WindowManager / DisplayManager
/// ```
@MainActor
public final class CommandDispatcher: CommandDispatching {

    private let windowManager: WindowManaging
    private let snapEngine: SnapEngine
    private let displayManager: DisplayManaging
    private let presetResolver: (any PresetResolving)?
    private let cursorManager: any CursorWarping
    private let displayNavigator: any DisplayNavigating
    private let workspaceMigrator: (any WorkspaceMigrating)?
    private let windowPinningCoordinator: (any WindowPinningCoordinating)?
    private let scratchpadCoordinator: (any ScratchpadCoordinating)?
    private let accessibilityService: AccessibilityService?

    /// Active pending task for latest-wins debouncing (BR-HOTKEY-005).
    private var pendingTask: Task<Void, Error>?
    private var activeGeneration: Int = 0

    /// Last command successfully dispatched to a window (for observability and test assertions).
    public private(set) var lastExecutedCommand: WindowCommand?
    /// Last summary produced by preset restoration.
    public private(set) var lastRestoreSummary: RestoreSummary?

    public init(
        windowManager: WindowManaging,
        snapEngine: SnapEngine,
        displayManager: DisplayManaging,
        presetResolver: (any PresetResolving)? = nil,
        cursorManager: any CursorWarping = CursorManager(),
        displayNavigator: any DisplayNavigating = DisplayNavigator(),
        workspaceMigrator: (any WorkspaceMigrating)? = nil,
        windowPinningCoordinator: (any WindowPinningCoordinating)? = nil,
        scratchpadCoordinator: (any ScratchpadCoordinating)? = nil,
        accessibilityService: AccessibilityService? = nil
    ) {
        self.windowManager = windowManager
        self.snapEngine = snapEngine
        self.displayManager = displayManager
        self.presetResolver = presetResolver
        self.cursorManager = cursorManager
        self.displayNavigator = displayNavigator
        self.workspaceMigrator = workspaceMigrator
        self.windowPinningCoordinator = windowPinningCoordinator
        self.scratchpadCoordinator = scratchpadCoordinator
        self.accessibilityService = accessibilityService
    }

    /// Dispatch a command for asynchronous execution with latest-wins debouncing.
    public func dispatch(_ command: WindowCommand) async throws {
        // BR-HOTKEY-005: Cancel stale pending task if a new command arrives rapidly
        activeGeneration += 1
        let currentGeneration = activeGeneration
        pendingTask?.cancel()

        let task = Task { @MainActor [weak self] () throws in
            guard let self = self else { return }
            try Task.checkCancellation()
            let didExecute = try await self.execute(command)
            if didExecute && self.activeGeneration == currentGeneration {
                self.lastExecutedCommand = command
            }
        }

        self.pendingTask = task

        do {
            try await task.value
        } catch is CancellationError {
            dispatcherLogger.debug("Superseded command was cancelled cleanly by debouncer.")
        }
    }

    // MARK: - Private Execution Routing

    @discardableResult
    private func execute(_ command: WindowCommand) async throws -> Bool {
        switch command {
        case .snap(let target, let targetDisplayID):
            return try await executeSnap(target, targetDisplayID: targetDisplayID)

        case .maximize:
            return try await executeSnap(.zone(.maximize))

        case .restore:
            return try await executeSnap(.restore)

        case .moveToDisplay(let displayID):
            return try await executeMoveToDisplay(displayID)

        case .moveToNextDisplay:
            return try await executeCrossDisplayThrow(isNext: true)

        case .moveToPreviousDisplay:
            return try await executeCrossDisplayThrow(isNext: false)

        case .minimize:
            if let window = await windowManager.focusedWindow() {
                try await windowManager.minimize(window)
                return true
            }
            return false

        case .restorePreset(let presetID):
            guard let preset = BuiltinPresetFactory.preset(for: presetID) else {
                dispatcherLogger.warning("Preset not found for id '\(presetID)'")
                return false
            }
            guard let presetResolver = self.presetResolver else {
                dispatcherLogger.error("PresetResolver not configured in CommandDispatcher")
                return false
            }
            let summary = try await presetResolver.restore(preset: preset, on: nil)
            self.lastRestoreSummary = summary
            return summary.placedCount > 0

        case .migrateWorkspace(let direction):
            guard let migrator = self.workspaceMigrator else {
                dispatcherLogger.error("WorkspaceMigrator not configured in CommandDispatcher")
                return false
            }
            let result = try await migrator.migrateActiveWorkspace(direction: direction)
            switch result {
            case .success:
                return true
            case .noOp:
                return false
            }

        case .restoreWorkspace, .saveWorkspace:
            dispatcherLogger.info("Workspace commands will be routed in Epic 11.")
            return false

        case .togglePinFocusedWindow:
            guard let coordinator = self.windowPinningCoordinator else {
                dispatcherLogger.error("WindowPinningCoordinator not configured in CommandDispatcher")
                return false
            }
            var targetWindow = await windowManager.focusedWindow()
            if targetWindow == nil {
                let visible = accessibilityService?.allVisibleManagedWindows() ?? []
                targetWindow = visible.first { $0.pid != ProcessInfo.processInfo.processIdentifier }
            }
            guard let window = targetWindow else {
                dispatcherLogger.debug("No active focused window found to pin/unpin.")
                return false
            }
            let isNowPinned = await coordinator.togglePin(window: window)
            if isNowPinned {
                NSSound(named: "Pop")?.play()
            } else {
                NSSound(named: "Tink")?.play()
            }
            return true

        case .toggleScratchpad:
            guard let coordinator = self.scratchpadCoordinator else {
                dispatcherLogger.error("ScratchpadCoordinator not configured in CommandDispatcher")
                return false
            }
            return await coordinator.toggleScratchpad()

        case .assignScratchpad:
            guard let coordinator = self.scratchpadCoordinator else {
                dispatcherLogger.error("ScratchpadCoordinator not configured in CommandDispatcher")
                return false
            }
            let success = await coordinator.assignFocusedWindow()
            if success {
                NSSound(named: "Pop")?.play()
            }
            return success
        }
    }

    private func executeSnap(_ target: SnapTarget, targetDisplayID: CGDirectDisplayID? = nil) async throws -> Bool {
        guard let window = await windowManager.focusedWindow() else {
            dispatcherLogger.debug("No active focused window found. Aborting snap command.")
            return false
        }

        guard let targetDisplay = await resolveDisplay(targetDisplayID: targetDisplayID, for: window) else {
            dispatcherLogger.warning("Unable to resolve display for window \(window.id).")
            return false
        }

        let primaryHeight = await displayManager.primaryScreenHeight

        // Calculate target AX frame via SnapEngine
        guard let axFrame = await snapEngine.calculateAXFrame(
            for: target,
            window: window,
            on: targetDisplay,
            primaryScreenHeight: primaryHeight
        ) else {
            dispatcherLogger.debug("SnapEngine produced nil frame (e.g. restore with no cached frame).")
            return false
        }

        try Task.checkCancellation()

        let startAppKitFrame = window.frame
        let targetAppKitFrame = CoordinateTransformer.toAppKit(rect: axFrame, primaryScreenHeight: primaryHeight)

        // Launch GPU-accelerated Ghost Morph Glide concurrently with window movement
        async let morphTask: Void = GhostMorphPanel.shared.morph(
            from: startAppKitFrame,
            to: targetAppKitFrame,
            glideDuration: 0.16,
            fadeDuration: 0.10
        )

        // Move window via WindowManager atomically with smart ordering
        try await windowManager.move(window, to: axFrame)
        var updatedWindow = window
        updatedWindow.frame = targetAppKitFrame
        await snapEngine.windowRegistry.update(updatedWindow)

        dispatcherLogger.info("Executed snap \(String(describing: target)) on window \(window.id) -> frame \(String(describing: axFrame))")

        _ = await morphTask
        return true
    }

    private func executeMoveToDisplay(_ displayID: CGDirectDisplayID) async throws -> Bool {
        guard let window = await windowManager.focusedWindow() else { return false }
        let displays = await displayManager.displays
        guard let targetDisplay = displays.first(where: { $0.id == displayID }) else { return false }

        let primaryHeight = await displayManager.primaryScreenHeight
        guard let axFrame = await snapEngine.calculateAXFrame(
            for: .zone(.maximize),
            window: window,
            on: targetDisplay,
            primaryScreenHeight: primaryHeight
        ) else { return false }

        try Task.checkCancellation()
        try await windowManager.move(window, to: axFrame)
        return true
    }

    private func resolveDisplay(targetDisplayID: CGDirectDisplayID?, for window: ManagedWindow) async -> Display? {
        if let targetDisplayID = targetDisplayID,
           let matched = await displayManager.displays.first(where: { $0.id == targetDisplayID }) {
            return matched
        }
        return await displayManager.display(for: window.frame, cursorPoint: nil)
    }

    private func executeCrossDisplayThrow(isNext: Bool) async throws -> Bool {
        guard let window = await windowManager.focusedWindow() else { return false }
        let displays = await displayManager.displays
        guard displays.count > 1 else {
            dispatcherLogger.debug("Single display connected. Cross-display throw is no-op.")
            return false
        }

        guard let sourceDisplay = await displayManager.display(for: window.frame, cursorPoint: nil) else {
            return false
        }

        let targetDisplay: Display?
        if isNext {
            targetDisplay = displayNavigator.nextDisplay(after: sourceDisplay, in: displays)
        } else {
            targetDisplay = displayNavigator.previousDisplay(before: sourceDisplay, in: displays)
        }

        guard let targetDisplay else { return false }

        let primaryHeight = await displayManager.primaryScreenHeight
        let axFrame: CGRect

        // Evaluate whether the window is snapped to preserve semantic layout (BR-DISP-010)
        let normalized = ZoneInference.normalizedRect(of: window.frame, within: sourceDisplay.visibleFrame)
        let inferredZone = ZoneInference.inferZone(forNormalized: normalized)
        let score = ZoneInference.intersectionOverUnion(normalized, inferredZone.normalizedRect)

        if score >= 0.75 {
            guard let snapAX = await snapEngine.calculateAXFrame(
                for: .zone(inferredZone),
                window: window,
                on: targetDisplay,
                primaryScreenHeight: primaryHeight
            ) else { return false }
            axFrame = snapAX
        } else {
            let scaledAppKit = RelativeFrameScaler.scale(
                frame: window.frame,
                from: sourceDisplay.visibleFrame,
                to: targetDisplay.visibleFrame
            )
            axFrame = CoordinateTransformer.toAX(rect: scaledAppKit, primaryScreenHeight: primaryHeight)
        }

        try Task.checkCancellation()

        let startAppKitFrame = window.frame
        let targetAppKitFrame = CoordinateTransformer.toAppKit(rect: axFrame, primaryScreenHeight: primaryHeight)

        async let morphTask: Void = GhostMorphPanel.shared.morph(
            from: startAppKitFrame,
            to: targetAppKitFrame,
            glideDuration: 0.16,
            fadeDuration: 0.10
        )

        try await windowManager.move(window, to: axFrame)
        var updatedWindow = window
        updatedWindow.frame = targetAppKitFrame
        await snapEngine.windowRegistry.update(updatedWindow)

        // Warp mouse cursor to center of target window (BR-DISP-012)
        let targetCenter = CGPoint(x: axFrame.midX, y: axFrame.midY)
        cursorManager.warpCursor(to: targetCenter)

        // Maintain keyboard focus on target window
        try? await windowManager.focus(window)

        _ = await morphTask
        return true
    }
}

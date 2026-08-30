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

    /// Active pending task for latest-wins debouncing (BR-HOTKEY-005).
    private var pendingTask: Task<Void, Error>?
    private var activeGeneration: Int = 0

    /// Last command successfully dispatched to a window (for observability and test assertions).
    public private(set) var lastExecutedCommand: WindowCommand?

    public init(
        windowManager: WindowManaging,
        snapEngine: SnapEngine,
        displayManager: DisplayManaging
    ) {
        self.windowManager = windowManager
        self.snapEngine = snapEngine
        self.displayManager = displayManager
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

        case .minimize:
            if let window = await windowManager.focusedWindow() {
                try await windowManager.minimize(window)
                return true
            }
            return false

        case .restoreWorkspace, .saveWorkspace:
            dispatcherLogger.info("Workspace commands will be routed in Epic 11.")
            return false
        }
    }

    private func executeSnap(_ target: SnapTarget, targetDisplayID: CGDirectDisplayID? = nil) async throws -> Bool {
        // BR-HOTKEY-006: Guard against nil focused window
        guard let window = await windowManager.focusedWindow() else {
            dispatcherLogger.debug("No active focused window found. Aborting snap command.")
            return false
        }

        // Resolve active target display (Target-Lock with fallback)
        let display: Display?
        if let targetDisplayID = targetDisplayID,
           let matched = await displayManager.displays.first(where: { $0.id == targetDisplayID }) {
            display = matched
        } else {
            display = await displayManager.display(for: window.frame, cursorPoint: nil)
        }

        guard let targetDisplay = display else {
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
}

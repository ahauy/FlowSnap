import CoreGraphics
import Foundation
import OSLog

private let coordinatorLogger = Logger(subsystem: "com.flowsnap", category: "DragToSnapCoordinator")

/// Coordinates real-time mouse drag tracking, snap zone detection, HUD overlay preview, and window snap dispatch.
///
/// Implements adaptive dwell thresholds (100ms outer vs 250ms multi-monitor adjacent) and smooth preview dismissal.
/// Conforms to `@MainActor`. See spec §30, §32.
@MainActor
public final class DragToSnapCoordinator {

    private let mouseTracker: MouseDragTracking
    private let detector: SnapDetecting
    private let previewManager: SnapPreviewManaging
    private let commandDispatcher: CommandDispatching
    private let displayManager: DisplayManaging
    private let accessibilityService: AccessibilityService

    private var pendingDwellTask: Task<Void, Never>?
    public private(set) var activeDetectionResult: SnapDetectionResult?
    public private(set) var currentCandidateZone: SnapTarget?

    public init(
        mouseTracker: MouseDragTracking,
        detector: SnapDetecting = SnapDetector(),
        previewManager: SnapPreviewManaging,
        commandDispatcher: CommandDispatching,
        displayManager: DisplayManaging,
        accessibilityService: AccessibilityService
    ) {
        self.mouseTracker = mouseTracker
        self.detector = detector
        self.previewManager = previewManager
        self.commandDispatcher = commandDispatcher
        self.displayManager = displayManager
        self.accessibilityService = accessibilityService
    }

    /// Starts observing drag-to-snap interactions.
    public func start() {
        guard !mouseTracker.isTracking else { return }
        coordinatorLogger.info("Starting DragToSnapCoordinator")

        mouseTracker.startTracking(
            onDrag: { [weak self] point in
                Task { @MainActor [weak self] in
                    await self?.handleDrag(at: point)
                }
            },
            onRelease: { [weak self] point in
                Task { @MainActor [weak self] in
                    await self?.handleRelease(at: point)
                }
            }
        )
    }

    /// Stops observing interactions and dismisses any active preview overlay.
    public func stop() {
        coordinatorLogger.info("Stopping DragToSnapCoordinator")
        mouseTracker.stopTracking()
        pendingDwellTask?.cancel()
        pendingDwellTask = nil
        currentCandidateZone = nil
        if activeDetectionResult != nil {
            activeDetectionResult = nil
            previewManager.hidePreview(animated: false)
        }
    }

    // MARK: - Event Handling

    public func handleDrag(at point: CGPoint) async {
        guard accessibilityService.isTrusted else { return }

        let displays = await displayManager.displays
        guard let activeDisplay = await displayManager.display(
            for: CGRect(origin: point, size: CGSize(width: 1, height: 1)),
            cursorPoint: point
        ) ?? displays.first else {
            return
        }

        let adjacentDisplays = displays.filter { $0.id != activeDisplay.id }
        let result = detector.detectZone(at: point, on: activeDisplay, adjacentDisplays: adjacentDisplays)

        if let result {
            if currentCandidateZone == result.target && (activeDetectionResult != nil || pendingDwellTask != nil) {
                return
            }

            currentCandidateZone = result.target
            pendingDwellTask?.cancel()

            // Adaptive dwell: 50ms for outer boundary vs 150ms for internal adjacent monitor border
            let dwellNanos: UInt64 = result.isAdjacentEdge ? 150_000_000 : 50_000_000

            pendingDwellTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: dwellNanos)
                guard let self, !Task.isCancelled else { return }
                self.activeDetectionResult = result
                self.previewManager.showPreview(frame: result.previewFrame, displayID: result.displayID)
            }
        } else {
            // Not within any edge trigger zone -> cancel and dismiss smoothly
            if currentCandidateZone != nil || activeDetectionResult != nil {
                pendingDwellTask?.cancel()
                pendingDwellTask = nil
                currentCandidateZone = nil
                if activeDetectionResult != nil {
                    activeDetectionResult = nil
                    previewManager.hidePreview(animated: true)
                }
            }
        }
    }

    public func handleRelease(at point: CGPoint) async {
        pendingDwellTask?.cancel()
        pendingDwellTask = nil
        currentCandidateZone = nil

        if let activeResult = activeDetectionResult {
            activeDetectionResult = nil
            previewManager.hidePreview(animated: false)
            previewManager.flashSnapSuccess(frame: activeResult.previewFrame)

            // Target-Lock: Explicitly snap onto the active preview display
            try? await commandDispatcher.dispatch(.snap(activeResult.target, targetDisplayID: activeResult.displayID))
        }
    }
}

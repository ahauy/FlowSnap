import CoreGraphics
import Foundation
import OSLog

private let coordinatorLogger = Logger(subsystem: "com.flowsnap", category: "DragToSnapCoordinator")

/// Coordinates real-time mouse drag tracking, snap zone detection, HUD overlay preview, and window snap dispatch.
///
/// Implements adaptive dwell thresholds (100ms outer vs 250ms multi-monitor adjacent) and smooth preview dismissal.
/// Conforms to `@MainActor`. See spec §30, §32, US-SNAP-010.
@MainActor
public final class DragToSnapCoordinator {

    private let mouseTracker: MouseDragTracking
    private let detector: SnapDetecting
    private let previewManager: SnapPreviewManaging
    private let layoutPickerManager: SnapLayoutPickerManaging
    private let layoutEngine: LayoutCalculating
    private let commandDispatcher: CommandDispatching
    private let displayManager: DisplayManaging
    private let accessibilityService: AccessibilityService
    private let preferencesStore: PreferencesStore?

    private var pendingDwellTask: Task<Void, Never>?
    public private(set) var activeDetectionResult: SnapDetectionResult?
    public private(set) var currentCandidateZone: SnapTarget?

    public init(
        mouseTracker: MouseDragTracking,
        detector: SnapDetecting = SnapDetector(),
        previewManager: SnapPreviewManaging,
        layoutPickerManager: SnapLayoutPickerManaging = SnapLayoutPickerManager.shared,
        layoutEngine: LayoutCalculating = LayoutEngine(),
        commandDispatcher: CommandDispatching,
        displayManager: DisplayManaging,
        accessibilityService: AccessibilityService,
        preferencesStore: PreferencesStore? = nil
    ) {
        self.mouseTracker = mouseTracker
        self.detector = detector
        self.previewManager = previewManager
        self.layoutPickerManager = layoutPickerManager
        self.layoutEngine = layoutEngine
        self.commandDispatcher = commandDispatcher
        self.displayManager = displayManager
        self.accessibilityService = accessibilityService
        self.preferencesStore = preferencesStore
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

    /// Stops observing interactions and dismisses any active preview overlay or picker.
    public func stop() {
        coordinatorLogger.info("Stopping DragToSnapCoordinator")
        mouseTracker.stopTracking()
        pendingDwellTask?.cancel()
        pendingDwellTask = nil
        currentCandidateZone = nil
        if layoutPickerManager.isVisible {
            layoutPickerManager.hidePicker(animated: false)
        }
        if activeDetectionResult != nil {
            activeDetectionResult = nil
            previewManager.hidePreview(animated: false)
        }
    }

    // MARK: - Event Handling

    public func handleDrag(at point: CGPoint) async {
        guard accessibilityService.isTrusted else { return }
        guard preferencesStore?.isDragToSnapEnabled ?? true else { return }

        let displays = await displayManager.displays
        let resolvedDisplay: Display?
        if let direct = await displayManager.display(containing: point) {
            resolvedDisplay = direct
        } else {
            resolvedDisplay = await displayManager.display(
                for: CGRect(origin: point, size: CGSize(width: 1, height: 1)),
                cursorPoint: point
            )
        }

        guard let activeDisplay = resolvedDisplay ?? displays.first else {
            return
        }

        let defaultRatio = preferencesStore?.defaultRatio ?? .equal
        let windowGap = preferencesStore?.windowGap ?? 0
        let uniform = windowGap > 0

        // 1. If Layout Picker is currently visible, prioritize picker interaction
        if layoutPickerManager.isVisible {
            if let slot = layoutPickerManager.hitTestSlot(at: point) {
                let slotZone = slot.target.zone ?? .maximize
                let previewFrame = layoutEngine.frame(for: slotZone, in: activeDisplay.visibleFrame, gap: windowGap, uniform: uniform)
                currentCandidateZone = slot.target
                activeDetectionResult = SnapDetectionResult(
                    target: slot.target,
                    previewFrame: previewFrame,
                    displayID: activeDisplay.id,
                    isAdjacentEdge: false,
                    isTopCenterZone: true
                )
                previewManager.showPreview(frame: previewFrame, displayID: activeDisplay.id)
                return
            } else if let pickerFrame = layoutPickerManager.pickerFrame, pickerFrame.contains(point) {
                // Inside picker card area but not on a specific slot -> keep picker visible
                return
            } else if let pickerFrame = layoutPickerManager.pickerFrame, point.y < pickerFrame.minY - 24 {
                // Moved significantly below picker -> dismiss picker and revert to edge detection
                layoutPickerManager.hidePicker(animated: true)
                previewManager.hidePreview(animated: true)
                activeDetectionResult = nil
                currentCandidateZone = nil
            }
        }

        // 2. Evaluate edge snap targets
        let adjacentDisplays = displays.filter { $0.id != activeDisplay.id }
        let result = detector.detectZone(
            at: point,
            on: activeDisplay,
            adjacentDisplays: adjacentDisplays,
            defaultRatio: defaultRatio,
            windowGap: windowGap
        )

        if let result {
            if result.isTopCenterZone {
                // Trigger Layout Picker flyout
                pendingDwellTask?.cancel()
                pendingDwellTask = nil
                currentCandidateZone = result.target
                activeDetectionResult = result
                layoutPickerManager.showPicker(on: activeDisplay)
                previewManager.showPreview(frame: result.previewFrame, displayID: result.displayID)
                return
            }

            if layoutPickerManager.isVisible {
                layoutPickerManager.hidePicker(animated: true)
            }

            if currentCandidateZone == result.target && (activeDetectionResult != nil || pendingDwellTask != nil) {
                return
            }

            currentCandidateZone = result.target
            pendingDwellTask?.cancel()

            // Adaptive dwell: outer boundary vs internal adjacent monitor border
            let baseDwellSec = preferencesStore?.dragPreviewDwellDelay ?? 0.05
            let dwellNanos: UInt64 = result.isAdjacentEdge
                ? UInt64((baseDwellSec + 0.10) * 1_000_000_000)
                : UInt64(baseDwellSec * 1_000_000_000)

            pendingDwellTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: dwellNanos)
                guard let self, !Task.isCancelled else { return }
                self.activeDetectionResult = result
                self.previewManager.showPreview(frame: result.previewFrame, displayID: result.displayID)
            }
        } else {
            // Not within any edge trigger zone -> cancel and dismiss smoothly
            if layoutPickerManager.isVisible {
                layoutPickerManager.hidePicker(animated: true)
            }
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

        if layoutPickerManager.isVisible {
            let slot = layoutPickerManager.hitTestSlot(at: point)
            layoutPickerManager.hidePicker(animated: false)

            if let slot {
                let primary = await displayManager.primaryDisplay
                let resolvedDisplayID = activeDetectionResult?.displayID ?? (primary?.id ?? 1)
                let displays = await displayManager.displays
                let activeDisplay = displays.first(where: { $0.id == resolvedDisplayID }) ?? displays.first
                let visibleFrame = activeDisplay?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)

                let windowGap = preferencesStore?.windowGap ?? 0
                let uniform = windowGap > 0
                let zone = slot.target.zone ?? .maximize
                let snapFrame = layoutEngine.frame(for: zone, in: visibleFrame, gap: windowGap, uniform: uniform)

                activeDetectionResult = nil
                previewManager.hidePreview(animated: false)
                previewManager.flashSnapSuccess(frame: snapFrame)

                try? await commandDispatcher.dispatch(.snap(slot.target, targetDisplayID: resolvedDisplayID))
                return
            }
        }

        if let activeResult = activeDetectionResult {
            activeDetectionResult = nil
            previewManager.hidePreview(animated: false)
            previewManager.flashSnapSuccess(frame: activeResult.previewFrame)

            // Target-Lock: Explicitly snap onto the active preview display
            try? await commandDispatcher.dispatch(.snap(activeResult.target, targetDisplayID: activeResult.displayID))
        }
    }
}

import Foundation

/// Dependency injection container for FlowSnap services.
///
/// Centralizes creation and wiring of all core services.
/// Protocols allow swapping implementations for testing.
@MainActor
public final class AppDependencies {

    // MARK: - Infrastructure Services

    public lazy var accessibilityService: AccessibilityService = AXAccessibilityService()
    public lazy var displayManager: DisplayManaging = DisplayManager()
    public lazy var hotkeyManager: GlobalHotkeyManaging = GlobalHotkeyManager()

    // MARK: - Core Services

    public lazy var windowRegistry: WindowRegistry = WindowRegistry()
    public lazy var windowManager: WindowManaging = WindowManager(accessibilityService: accessibilityService)
    public lazy var layoutEngine: LayoutCalculating = LayoutEngine()
    public lazy var snapEngine: SnapEngine = SnapEngine(
        layoutEngine: layoutEngine,
        windowRegistry: windowRegistry,
        displayManager: displayManager
    )
    public lazy var commandDispatcher: CommandDispatcher = CommandDispatcher(
        windowManager: windowManager,
        snapEngine: snapEngine,
        displayManager: displayManager
    )

    // MARK: - View Models

    public lazy var menuBarViewModel: MenuBarViewModel = MenuBarViewModel(
        accessibilityService: accessibilityService,
        commandDispatcher: commandDispatcher,
        windowManager: windowManager
    )

    // MARK: - Drag to Snap

    public lazy var mouseDragTracker: MouseDragTracking = MouseDragTracker()
    public lazy var snapDetector: SnapDetecting = SnapDetector()
    public lazy var snapPreviewManager: SnapPreviewManaging = SnapPreviewPanel.shared
    public lazy var dragToSnapCoordinator: DragToSnapCoordinator = DragToSnapCoordinator(
        mouseTracker: mouseDragTracker,
        detector: snapDetector,
        previewManager: snapPreviewManager,
        commandDispatcher: commandDispatcher,
        displayManager: displayManager,
        accessibilityService: accessibilityService
    )

    public init() {}
}

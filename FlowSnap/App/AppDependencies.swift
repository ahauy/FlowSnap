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
    public lazy var preferencesStore: PreferencesStore = PreferencesStore()
    public lazy var settingsWindowController: SettingsWindowController = SettingsWindowController(preferencesStore: preferencesStore)

    // MARK: - Core Services

    public lazy var windowRegistry: WindowRegistry = WindowRegistry()
    public lazy var windowManager: WindowManaging = WindowManager(accessibilityService: accessibilityService)
    public lazy var layoutEngine: LayoutCalculating = LayoutEngine()
    public lazy var snapEngine: SnapEngine = SnapEngine(
        layoutEngine: layoutEngine,
        windowRegistry: windowRegistry,
        displayManager: displayManager,
        preferencesStore: preferencesStore
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
        windowManager: windowManager,
        settingsWindowPresenter: settingsWindowController
    )

    // MARK: - Drag to Snap

    public lazy var mouseDragTracker: MouseDragTracking = MouseDragTracker()
    public lazy var snapDetector: SnapDetecting = SnapDetector()
    public lazy var snapPreviewManager: SnapPreviewManaging = SnapPreviewPanel.shared
    public lazy var layoutPickerManager: SnapLayoutPickerManaging = SnapLayoutPickerManager(preferencesStore: preferencesStore)
    public lazy var dragToSnapCoordinator: DragToSnapCoordinator = DragToSnapCoordinator(
        mouseTracker: mouseDragTracker,
        detector: snapDetector,
        previewManager: snapPreviewManager,
        layoutPickerManager: layoutPickerManager,
        commandDispatcher: commandDispatcher,
        displayManager: displayManager,
        accessibilityService: accessibilityService,
        preferencesStore: preferencesStore
    )

    // MARK: - Adaptive Divider

    public lazy var collinearDetector: CollinearEdgeDetecting = CollinearEdgeDetector()
    public lazy var resizeThrottler: LiveResizeThrottling = LiveResizeThrottler(fps: 60.0)
    public lazy var adaptiveDividerCoordinator: AdaptiveDividerCoordinator = AdaptiveDividerCoordinator(
        detector: collinearDetector,
        windowManager: windowManager,
        displayManager: displayManager,
        throttler: resizeThrottler,
        preferencesStore: preferencesStore,
        accessibilityService: accessibilityService,
        windowRegistry: windowRegistry
    )

    public init() {}
}

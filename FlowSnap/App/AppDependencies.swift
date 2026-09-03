import Foundation

/// Dependency injection container for FlowSnap services.
///
/// Centralizes creation and wiring of all core services.
/// Protocols allow swapping implementations for testing.
@MainActor
public final class AppDependencies {

    // MARK: - Event Bus

    /// Single event bus shared by every service that publishes or subscribes
    /// to `WindowEvent`. US-WORK-013 wires `WorkspaceObserver` →
    /// `ApplicationObserver` → `WindowPolicyManager` through this bus.
    let eventBus: EventBus = EventBus()

    // MARK: - Infrastructure Services

    public lazy var accessibilityService: AccessibilityService = AXAccessibilityService()
    public lazy var displayManager: DisplayManaging = DisplayManager()
    public lazy var hotkeyManager: GlobalHotkeyManaging = GlobalHotkeyManager()
    public lazy var preferencesStore: PreferencesStore = PreferencesStore()
    public lazy var settingsWindowController: SettingsWindowController = SettingsWindowController(
        preferencesStore: preferencesStore,
        workspaceManager: workspaceManager,
        windowGroupManager: windowGroupManager,
        presetResolver: presetResolver,
        commandDispatcher: commandDispatcher
    )

    // MARK: - Presets & Window Groups (US-WORK-012)

    public lazy var windowGroupManager: WindowGroupManager = WindowGroupManager(
        accessibilityService: accessibilityService,
        windowManager: windowManager
    )

    public lazy var presetResolver: PresetResolver = PresetResolver(
        accessibilityService: accessibilityService,
        windowManager: windowManager,
        displayManager: displayManager,
        layoutEngine: layoutEngine,
        launcher: AppLauncher(accessibilityService: accessibilityService),
        preferencesStore: preferencesStore,
        windowGroupManager: windowGroupManager
    )

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
        displayManager: displayManager,
        presetResolver: presetResolver
    )

    // MARK: - Workspace

    /// Owns workspace capture/restore and publishes the saved list.
    ///
    /// Shares the app's `accessibilityService`, `windowManager` and
    /// `displayManager` rather than letting `WorkspaceManager` build its own, so
    /// there is a single AX connection and one window-cache lifecycle. `preferencesStore`
    /// is shared too, so restore recomputes geometry against the gap the user set
    /// in Settings (BR-WORK-007).
    ///
    public lazy var stageManagerDetector: any StageManagerDetecting = StageManagerDetector()

    public lazy var workspaceManager: WorkspaceManager = WorkspaceManager(
        accessibilityService: accessibilityService,
        windowManager: windowManager,
        displayManager: displayManager,
        layoutEngine: layoutEngine,
        launcher: AppLauncher(accessibilityService: accessibilityService),
        preferences: preferencesStore,
        stageManagerDetector: stageManagerDetector
    )

    // MARK: - View Models

    public lazy var menuBarViewModel: MenuBarViewModel = MenuBarViewModel(
        accessibilityService: accessibilityService,
        commandDispatcher: commandDispatcher,
        windowManager: windowManager,
        settingsWindowPresenter: settingsWindowController,
        workspaceManager: workspaceManager,
        preferencesStore: preferencesStore
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
    public lazy var adaptiveDividerOverlayPanel: AdaptiveDividerOverlayPanel = AdaptiveDividerOverlayPanel.shared
    public lazy var adaptiveDividerCoordinator: AdaptiveDividerCoordinator = AdaptiveDividerCoordinator(
        detector: collinearDetector,
        windowManager: windowManager,
        displayManager: displayManager,
        throttler: resizeThrottler,
        preferencesStore: preferencesStore,
        accessibilityService: accessibilityService,
        windowRegistry: windowRegistry,
        overlayManager: adaptiveDividerOverlayPanel,
        workspaceManager: workspaceManager
    )

    // MARK: - Launch & Window Policy (US-WORK-013)

    /// Bridges `NSWorkspace` lifecycle notifications to the shared `EventBus`.
    lazy var workspaceObserver: WorkspaceObserver = WorkspaceObserver(eventBus: eventBus)

    /// Wraps per-pid `AXObserver` registration for `kAXWindowCreatedNotification`.
    lazy var applicationObserver: ApplicationObserving = ApplicationObserver(eventBus: eventBus)

    /// Resolves per-app `WindowPolicy` and applies the default `.currentSpace`
    /// to a freshly created window by writing the current display's
    /// `visibleFrame` to the window's AX element.
    lazy var windowPolicyManager: WindowPolicyManager = WindowPolicyManager(
        accessibilityService: accessibilityService,
        displayManager: displayManager,
        preferencesStore: preferencesStore
    )

    // MARK: - Multi-Display Topology & Hot-Plug (US-DISP-016)

    public lazy var displayHotPlugObserver: any DisplayHotPlugObserving = DisplayHotPlugObserver()
    public lazy var topologyProfileManager: any TopologyProfileManaging = TopologyProfileManager(
        displayManager: displayManager,
        accessibilityService: accessibilityService,
        layoutEngine: layoutEngine,
        hotPlugObserver: displayHotPlugObserver
    )

    public init() {
        _ = self.workspaceManager
        _ = self.windowPolicyManager
        self.displayHotPlugObserver.startObserving()
        _ = self.topologyProfileManager
    }
}

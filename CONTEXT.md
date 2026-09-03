# CONTEXT.md — Shared Language (Ubiquitous Language)

> **Purpose:** A single "shared language" for human developers and AI agents. Agents read this file to decode project-specific jargon instead of guessing every time. This implements the Ubiquitous Language pattern (Eric Evans, _Domain-Driven Design_) — origin: `mattpocock/skills`.
>
> **Role in Framework:** `CONTEXT.md` serves as the "Data Plane" bridging the Control Plane (BA pipeline & governance) with execution. Whenever `domain-modeling` or an elicitation interview introduces or refines a domain concept, it must **update inline** this file. Nobody reinvents terminology across sessions.

## Usage Rules

1. **One-line concise definitions** for each term — do not replicate extensive documentation.
2. **Before / After** comparisons to demonstrate value: verbose phrase (Before) → concise shorthand (After).
3. **Naming consistency:** variables, functions, components, and files must strictly adhere to the terms established here.
4. **Update inline:** whenever a decision or definition surfaces during elicitation or domain modeling, add or update the entry immediately (link to the relevant ADR if it is an architectural decision).
5. **Soft immutability:** never delete terms already in use across the codebase; mark them as `deprecated → alias`.

## Tech Stack & System Components Overview

| Component / Layer          | Technology / Tool                   | Description & Role                                                                 |
| :------------------------- | :---------------------------------- | :--------------------------------------------------------------------------------- |
| **Primary Language**       | Swift 6.0                           | Strict concurrency, actor isolation, `@Observable` state management.               |
| **Target Platform**        | macOS 14.0+ (Sonoma / Sequoia)      | Native desktop application with Hardened Runtime enabled.                          |
| **UI Framework**           | SwiftUI & AppKit                    | Declarative UI for settings/menu bar combined with native NSWindow/NSPanel.        |
| **Build & Project Config** | XcodeGen (`project.yml`)            | Declarative Xcode project generation (`FlowSnap`, `FlowSnapTests`, `FlowSnapLab`). |
| **Window & System API**    | macOS Accessibility (`AXUIElement`) | Low-level OS window querying, repositioning, and resizing.                         |
| **Global Shortcuts**       | Carbon / CGEvent Hotkeys            | System-wide keyboard shortcut detection for instant window snapping.               |
| **Testing Framework**      | Swift Testing (`@Test`) & XCTest    | Modern protocol-based dependency injection with test mock doubles.                 |
| **Code Intelligence**      | `code-review-graph` (uvx)           | Local Tree-sitter AST & SQLite graph for call-hierarchy and blast-radius queries.  |

## Glossary (FlowSnap Ubiquitous Language)

| Term                         | Short definition                                      | Before (verbose)                               | After (concise)            | Notes                                           |
| :--------------------------- | :---------------------------------------------------- | :--------------------------------------------- | :------------------------- | :---------------------------------------------- |
| **Workspace**                | Saved intent of window arrangements across apps       | "A saved multi-window setup"                   | `Workspace`                | Spec §38, portable across displays              |
| **WindowPlacement**          | Logical layout assignment for an app window           | "Position and size of an app on screen"        | `WindowPlacement`          | Decoupled from pixel coordinates                |
| **SnapEngine**               | Coordinates snap zone calculations & trigger logic    | "The logic that moves windows to screen edges" | `SnapEngine`               | Core calculation module                         |
| **LayoutEngine**             | Geometric grid & split-screen partition math          | "Screen splitting calculation helper"          | `LayoutEngine`             | Halves, thirds, quarters math                   |
| **AccessibilityService**     | macOS AXUIElement adapter for window manipulation     | "Accessibility wrapper for OS windows"         | `AccessibilityService`     | Infrastructure adapter                          |
| **ManagedWindow**            | Snapshot of a window's state (ID, PID, frame, kind)   | "A tracked window object"                      | `ManagedWindow`            | Pure domain model, no AX refs                   |
| **WindowKind**               | Semantic category of a window (.normal, .dialog...)   | "Window type or window category"               | `WindowKind`               | Filters snappable vs modal windows              |
| **LayoutZone**               | Normalized rectangular partition (0...1 coordinates)  | "A screen tile or slot"                        | `LayoutZone`               | Halves, quarters, custom zones                  |
| **SnapTarget**               | Semantic destination enum (left, right, max...)       | "Where the window should snap"                 | `SnapTarget`               | Domain command target                           |
| **PreSnapFrame**             | Cached window bounds before snapping begins           | "The original window position before snapping" | `PreSnapFrame`             | Enables restore action                          |
| **CoordinateTransformer**    | Bidirectional AppKit ↔ AX coordinate conversion math  | "Coordinate flip math helper"                  | `CoordinateTransformer`    | Pure functional, zero system dependencies       |
| **DisplayManaging**          | Protocol for querying displays and active screens     | "Display manager interface"                    | `DisplayManaging`          | Mockable interface for DI                       |
| **DisplayManager**           | AppKit implementation observing screen changes        | "System screen tracker service"                | `DisplayManager`           | Tracks `NSScreen.screens` changes               |
| **KeyboardShortcut**         | Key code + modifier flags representation              | "Key binding or shortcut tuple"                | `KeyboardShortcut`         | Hashable, Codable shortcut model                |
| **GlobalHotkeyManaging**     | Protocol for system-wide hotkey interception          | "Global hotkey service interface"              | `GlobalHotkeyManaging`     | Abstracts Carbon Event Hotkeys                  |
| **GlobalHotkeyManager**      | Carbon Event Hotkeys implementation                   | "Low-level system hotkey listener"             | `GlobalHotkeyManager`      | Uses `RegisterEventHotKey`                      |
| **CommandDispatcher**        | Central router dispatching WindowCommands             | "Command execution controller"                 | `CommandDispatcher`        | Routes commands to SnapEngine asynchronously    |
| **WindowCommand**            | Semantic user intent enum (snap, maximize, restore)   | "Action or user command"                       | `WindowCommand`            | Decoupled command payload                       |
| **MenuBarManaging**          | Interface for managing status bar icon & popover      | "Status item controller interface"             | `MenuBarManaging`          | Protocol for Menu Bar lifecycle                 |
| **MenuBarViewModel**         | ViewModel driving reactive Menu Bar UI state          | "Menu bar state store"                         | `MenuBarViewModel`         | @Observable state for MenuBarView               |
| **MouseDragTracker**         | Service monitoring global drag & release events       | "Mouse movement & drag listener"               | `MouseDragTracker`         | Uses NSEvent global monitors                    |
| **SnapDetector**             | Evaluates cursor coords against display edge zones    | "Edge collision detection helper"              | `SnapDetector`             | Pure domain logic mapping point -> SnapTarget   |
| **SnapPreviewManaging**      | Protocol controlling the HUD snap preview overlay     | "Preview overlay manager interface"            | `SnapPreviewManaging`      | Manages non-activating NSPanel preview life     |
| **SnapLayoutPickerManaging** | Protocol controlling the Top-Edge Layout Picker panel | "Layout picker manager interface"              | `SnapLayoutPickerManaging` | Manages non-activating NSPanel picker life      |
| **LayoutTemplate**           | Predefined multi-window layout grouping in picker     | "Picker layout card or pattern"                | `LayoutTemplate`           | 50/50, 70/30, 3-column, 4-quarters              |
| **LayoutSlot**               | Interactive partition tile inside a LayoutTemplate    | "Picker layout tile or zone cell"              | `LayoutSlot`               | Hit-testable target mapping to SnapTarget       |
| **AppDependencies**          | Root DI container for services and stores             | "Global service locator or singleton list"     | `AppDependencies`          | @MainActor DI container                         |
| **PreferencesStore**         | Observable store persisting user settings and gaps    | "Settings manager or preferences controller"   | `PreferencesStore`         | ADR-0004, ADR-0005, @MainActor ObservableObject |
| **ShortcutAction**           | Canonical enum of configurable window snap actions    | "Action or shortcut trigger identifier"        | `ShortcutAction`           | ADR-0005, Codable, CaseIterable                 |
| **ShortcutRecorderField**    | Interactive UI control for capturing keystrokes       | "Shortcut recorder input or key capture view"  | `ShortcutRecorderField`    | ADR-0005, SwiftUI View with FSM                 |
| **ShortcutCategory**         | Grouping taxonomy for shortcut settings view          | "Shortcut group or section header"             | `ShortcutCategory`         | ADR-0005, CaseIterable taxonomy                 |

| **LayoutGraph** | Spatial constraint graph representing window layout boundaries | "Window layout tree or adjacency graph" | `LayoutGraph` | ADR-0005, BSP & adjacency model |
| **LayoutNode** | Node in a binary space partitioning tree (leaf/split) | "Layout tree node or branch" | `LayoutNode` | ADR-0005, recursive partition |
| **CollinearEdge** | Shared boundary line between adjacent windows in layout | "Shared divider or common border" | `CollinearEdge` | ADR-0005, multi-window span |
| **CollinearEdgeDetector** | Algorithm finding collinear shared edges between windows | "Divider detection helper" | `CollinearEdgeDetector` | Pure geometric detection |
| **LiveResizeThrottler** | Rate limits live window resizing events to 60fps | "Drag throttler or frame pacer" | `LiveResizeThrottler` | 16.6ms rate limiter |
| **AdaptiveDividerCoordinator**| Coordinates divider hover, cursor swapping, and live resize | "Divider drag controller" | `AdaptiveDividerCoordinator`| @MainActor coordination |

| **WorkspaceManager** | @MainActor orchestrator for workspace capture & restore | "Workspace save/restore service" | `WorkspaceManager` | US-WORK-011, ObservableObject, owns store+AX |
| **WorkspaceStore** | Actor persisting workspaces to JSON atomically | "workspaces.json reader/writer" | `WorkspaceStore` | US-WORK-011, corrupt-file parking |
| **ZoneInference** | Pure max-IoU match of a window frame to a LayoutZone | "Which zone is this window in?" | `ZoneInference` | US-WORK-011, deterministic tie-break |
| **RestoreSummary** | Outcome of one restore pass (placed count + skipped apps) | "What happened when I restored" | `RestoreSummary` | US-WORK-011, SkippedApp + SkipReason |
| **ApplicationLaunching** | Protocol to launch an app and await its first window | "App launcher abstraction" | `ApplicationLaunching` | US-WORK-011, NSWorkspace impl, public API only |
| **WorkspaceViewModel** | Thin façade holding workspace UI state over the manager | "Workspace sheet/settings state" | `WorkspaceViewModel` | US-WORK-011, keeps MenuBarViewModel thin |
| **WorkspacePreset** | Curated multi-window workflow template with fallback chains | "Workflow preset or layout template" | `WorkspacePreset` | US-WORK-012, ADR-0007, Codable, Sendable |
| **PresetAppSlot** | Categorized application slot in a preset with fallback bundle IDs| "Preset app role or placeholder" | `PresetAppSlot` | US-WORK-012, ADR-0007, Codable, Sendable |
| **PresetAppCategory** | Taxonomy of application archetypes (.editor, .browser...) | "App type or category" | `PresetAppCategory` | US-WORK-012, CaseIterable, Sendable |
| **BuiltinPresetFactory** | Immutable factory for standard presets (Coding, Research...) | "Default preset catalog" | `BuiltinPresetFactory` | US-WORK-012, 4 standard presets, zero-disk |
| **WindowGroup** | Dynamic linked association of ≥ 2 windows moving cohesively | "Linked window set or grouped windows" | `WindowGroup` | US-WORK-012, ADR-0007, minimum 2 members |
| **GroupSyncOptions** | Bitmask flags controlling group sync (minimize, focus, move) | "Group synchronization settings" | `GroupSyncOptions` | US-WORK-012, OptionSet, Sendable |
| **WindowGroupManager** | @MainActor coordinator for live window groups & re-entrancy lock | "Window group sync controller" | `WindowGroupManager` | US-WORK-012, ADR-0007, ObservableObject |
| **PresetResolver** | Engine resolving candidate apps and applying preset layouts | "Preset application service" | `PresetResolver` | US-WORK-012, ADR-0007, PresetResolving |
| **ApplicationObserving** | Sendable protocol abstracting per-pid AXObserver window-creation detection | "AX observer seam in Domain" | `ApplicationObserving` | US-WORK-013, ADR-0008 |
| **ApplicationObserver** | @MainActor concrete managing AXObserver lifecycle + 10s timeout + 5s dedup | "AX observer runtime" | `ApplicationObserver` | US-WORK-013, ADR-0008, Infrastructure |
| **LaunchObservationEvent** | Sendable enum: `.windowCreated`, `.timeout`, `.failed` | "AX observer result event" | `LaunchObservationEvent` | US-WORK-013, Hashable, AsyncStream payload |
| **LaunchObservationFailure** | Sendable enum: `.observerCreationFailed`, `.addNotificationFailed`, `.accessibilityNotAuthorized` | "AX observer failure reason" | `LaunchObservationFailure` | US-WORK-013, carries `AXErrorCode` |
| **AXErrorCode** | Sendable RawRepresentable Int32 shim over ApplicationServices `AXError` | "AX error code wrapper" | `AXErrorCode` | US-WORK-013, Domain-safe |
| **ApplicationObservingDefaults** | Compile-time constants: `windowCreationTimeout = 10s`, `launchDedupWindow = 5s` | "Default timeouts for app launch observer" | `ApplicationObservingDefaults` | US-WORK-013, Domain enum |
| **WorkspaceObserver** | @MainActor NSWorkspace bridge publishing `.applicationLaunched(pid, bundleID:)` | "Workspace lifecycle observer" | `WorkspaceObserver` | US-WORK-013, Infrastructure |
| **WindowPolicyManager** | @MainActor resolver applying `.currentSpace` / `.currentDisplay` policies via AccessibilityService | "Per-app policy applier" | `WindowPolicyManager` | US-WORK-013, ADR-0008 |
| **AppPolicyRule** | Configurable per-bundleID policy mapping entity | "App rule definition" | `AppPolicyRule` | US-WORK-014, ADR-0009, Codable, Identifiable |
| **RememberedFrameStore** | Component persisting last-closed window frames per app with bounds clamping | "Saved frame storage" | `RememberedFrameStore` | US-WORK-014, ADR-0009, @MainActor |
| **SmartFocusStack** | MRU focus tracking restoring focus to underlying tiled windows upon floating app dismissal | "Focus restoration stack" | `SmartFocusStack` | US-WORK-014, ADR-0009, @MainActor |
| **DisplayNavigator** | Spatial engine ordering displays left-to-right with cyclic wrap-around | "Display navigation helper" | `DisplayNavigator` | US-DISP-015, ADR-0010, Core |
| **RelativeFrameScaler** | Proportional geometric transformer mapping frames between displays | "Cross-display frame scaler" | `RelativeFrameScaler` | US-DISP-015, ADR-0010, Pure Geometric |
| **CursorWarping** | CoreGraphics cursor relocation to target window center maintaining focus | "Mouse warp on throw" | `CursorWarping` | US-DISP-015, ADR-0010, Infrastructure |
| **TopologyFingerprint** | Deterministic SHA-256 hash uniquely identifying a display configuration | "Display setup fingerprint or monitor hash" | `TopologyFingerprint` | US-DISP-016, ADR-0011, Domain |
| **DisplayTopologyProfile** | Saved window arrangement snapshot mapped to a TopologyFingerprint | "Multi-monitor workspace profile" | `DisplayTopologyProfile` | US-DISP-016, ADR-0011, Domain / Persistence |
| **DisplayHotPlugObserver** | Debounced observer listening to `didChangeScreenParametersNotification` | "Display plug/unplug listener" | `DisplayHotPlugObserver` | US-DISP-016, ADR-0011, Infrastructure |
| **FrameClampingHelper** | Geometric helper fitting window frames inside display bounds with safe titlebar | "Window frame bounds clamper" | `FrameClampingHelper` | US-DISP-016, ADR-0011, Core |
| **TopologyProfileManager** | Coordinator executing hot-unplug clamping and reconnect auto-restoration | "Display topology profile manager" | `TopologyProfileManager` | US-DISP-016, ADR-0011, Core |
| **FullScreenEscapeCoordinator** | Resilient multi-tier coordinator for native and Electron fullscreen exit | "Universal fullscreen exit helper" | `FullScreenEscapeCoordinator` | US-WORK-019, ADR-0012, Core / Infrastructure |
| **FullScreenEscapeTier** | Enum of escape strategies: fast attribute write, AX button press, CGEvent | "Escape tier strategy" | `FullScreenEscapeTier` | US-WORK-019, Domain |
| **StageManagerDetecting** | Protocol for querying macOS Stage Manager enabled state via `com.apple.WindowManager` | "Stage Manager detection protocol" | `StageManagerDetecting` | US-WORK-018, Domain / Infrastructure |
| **StageManagerDetector** | CFPreferences/UserDefaults implementation reading `GloballyEnabled` | "Stage Manager detector service" | `StageManagerDetector` | US-WORK-018, Infrastructure |
| **SmartStageCoordination** | Strategy coordinating primary app activation and secondary `kAXRaiseAction` on a single Stage | "Stage Manager auto-grouping strategy" | `SmartStageCoordination` | US-WORK-018, Core / Restore |

## Where to Look

- **Scan codebase** to identify existing implicit terms or jargon not yet cataloged here → add them to the table.
- **`adr/`** for load-bearing architectural decisions that require extensive rationale (link from the glossary where applicable).
- **`.specify/features/<slug>/`** for full business rules and finite state machines (this file is an index of ubiquitous language, not a substitute for formal SRS documents).

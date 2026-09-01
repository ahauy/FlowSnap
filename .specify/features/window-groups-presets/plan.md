# Implementation Plan: Window Groups & Workspace Presets (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Branch:** `feat/window-groups-presets`  
**Date:** 2026-09-01  
**Spec:** [.specify/features/window-groups-presets/spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/spec.md)  
**Baseline:** [.specify/features/window-groups-presets/baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/baseline.md)  
**Status:** Approved Implementation Plan

---

## 1. Summary

Implements **Window Groups & Workspace Presets (US-WORK-012)** for FlowSnap. Delivers 4 immutable curated workflow presets (`Coding` 60/25/15, `Research` 50/25/25, `Writing` 70/30, `Design` 70/30) with smart application category fallback resolution and bounded auto-launch (≤10.0s). Introduces the `WindowGroup` entity and `@MainActor WindowGroupManager` coordinator to synchronize minimize/un-minimize, focus (with z-order preservation), and movement across linked windows with re-entrancy locking and event-driven auto-pruning. Integrates preset triggers into Menu Bar and Settings Presets Gallery with shortcut collision prevention.

---

## 2. Technical Context

- **Language & Runtime**: Swift 6.0 (Strict Concurrency enabled, zero data-race warnings)
- **Frameworks**: SwiftUI + AppKit (macOS Native, Hardened Runtime, LSUIElement agent app)
- **Target Platform**: macOS 14.0+ (Sonoma / Sequoia)
- **Architecture**: Domain-Driven Design (DDD) & Deep Modules
- **Concurrency**: Actors (`WorkspaceStore`), `@MainActor` coordinators (`WindowGroupManager`, `WorkspaceManager`, `CommandDispatcher`), `Sendable` value objects
- **Persistence**: `PreferencesStore` (UserDefaults) for preset hotkeys & group sync preferences; immutable domain factory for built-in presets
- **Testing**: Swift Testing (`@Test`) + protocol-based dependency injection doubles
- **API Policy**: Zero Private API policy (100% public `AXUIElement`, `NSWorkspace`, `CGEventHotKey`)
- **DoD Rules**: File < 800 LOC, Function < 50 LOC, No `!`, `try!`, `as!`, `swiftlint lint --strict` 100% clean

---

## 3. Constitution Check & Gate Evaluation

| Gate Criterion                  | Status | Evaluation & Evidence                                                                                                                                                                                     |
| ------------------------------- | :----: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Gate 1 — Strict Concurrency** |  PASS  | All entities are `Sendable`; managers isolated to `@MainActor`; store is actor-backed; zero unchecked globals                                                                                             |
| **Gate 2 — Zero Private APIs**  |  PASS  | Uses only public AppKit, SwiftUI, `NSWorkspace.openApplication`, and `AXUIElement` APIs                                                                                                                   |
| **Gate 3 — Deep Modules**       |  PASS  | Clean separation of Domain (`WorkspacePreset`, `WindowGroup`), Core (`PresetResolver`, `WindowGroupManager`), Infrastructure (`AppLauncher`, `PreferencesStore`), UI (`PresetGalleryView`, `MenuBarView`) |
| **Gate 4 — Testability & DI**   |  PASS  | All external dependencies abstracted behind protocols (`PresetResolving`, `WindowGroupManaging`, `ApplicationLaunching`, `AccessibilityService`)                                                          |
| **Gate 5 — Non-Blocking UI**    |  PASS  | Fallback launches bounded by 10.0s timeout; hotkeys dispatched via latest-wins debouncer                                                                                                                  |

---

## 4. Component Architecture & Sequence Diagrams

### 4.1 Component Diagram

```mermaid
graph TD
    subgraph UI Layer
        MBV[MenuBarView + MenuBarViewModel]
        PGV[PresetGalleryView new]
        WGV[WindowGroupSettingsView new]
        SRF[ShortcutRecorderField existing]
    end

    subgraph Core Layer
        CD[CommandDispatcher router]
        PR[PresetResolver PresetResolving new]
        WGM[WindowGroupManager @MainActor new]
        WM[WindowManager WindowManaging existing]
        LE[LayoutEngine LayoutCalculating existing]
    end

    subgraph Domain Layer
        WP[WorkspacePreset Sendable new]
        PAS[PresetAppSlot / PresetAppCategory new]
        BPF[BuiltinPresetFactory new]
        WG[WindowGroup / GroupSyncOptions new]
        RS[RestoreSummary / SkippedApp existing]
    end

    subgraph Infrastructure Layer
        PS[PreferencesStore existing]
        AL[AppLauncher ApplicationLaunching existing]
        AS[AXAccessibilityService AccessibilityService existing]
        DM[DisplayManager DisplayManaging existing]
        GHM[GlobalHotkeyManager GlobalHotkeyManaging existing]
    end

    MBV --> PR
    MBV --> WGM
    PGV --> PR
    PGV --> PS
    WGV --> WGM
    CD --> PR
    GHM --> CD
    PR --> WP
    PR --> PAS
    PR --> BPF
    PR --> AL
    PR --> AS
    PR --> DM
    PR --> LE
    PR --> WM
    PR --> WGM
    WGM --> WG
    WGM --> AS
    WGM --> WM
```

### 4.2 Sequence Diagram: Preset Application & Smart Fallback Resolution

```mermaid
sequenceDiagram
    participant U as User / Hotkey
    participant CD as CommandDispatcher
    participant PR as PresetResolver
    participant AL as AppLauncher
    participant AS as AccessibilityService
    participant WM as WindowManager
    participant WGM as WindowGroupManager
    participant Toast as RestoreSummary Toast

    U->>CD: dispatch(.restorePreset("builtin.coding"))
    CD->>PR: restore(preset: codingPreset, on: nil)
    PR->>AS: isTrusted check
    PR->>PR: Resolve active display (visibleBounds, windowGap)
    loop For each PresetAppSlot (Editor, Browser, Terminal)
        PR->>AS: resolvedWindows(of: candidate) -> Check running
        alt App Running
            PR->>PR: Select running window
        else App Not Running
            PR->>AL: openApp(withBundleIdentifier: candidate)
            PR->>AL: waitForFirstWindow(pid:timeout:10.0s)
            alt Window Appeared ≤ 10s
                PR->>PR: Select newly launched window
            else Launch Timed Out / Not Installed
                PR->>PR: Record SkippedApp (launchTimeout / notInstalled)
            end
        end
        PR->>WM: move(window, to: computedAXFrame)
        PR->>PR: Track placed window CGWindowID
    end
    opt autoGroupWindows == true and placedCount >= 2
        PR->>WGM: createGroup(name: "Coding", windowIDs: placedIDs)
    end
    PR-->>CD: RestoreSummary(placed: 3, skipped: [])
    CD-->>Toast: Present "Restored Coding Preset (3/3 windows)"
```

### 4.3 Sequence Diagram: Window Group Synchronization & Re-Entrancy Guard

```mermaid
sequenceDiagram
    participant U as User
    participant App as Target App Window A
    participant Obs as WorkspaceObserver / EventHook
    participant WGM as WindowGroupManager
    participant WM as WindowManager
    participant AppB as Target App Window B

    U->>App: Click Minimize on Window A
    App->>Obs: Inbound AX Notification (kAXWindowMiniaturized)
    Obs->>WGM: handleWindowMinimize(triggerWindowID: A)
    Note over WGM: Check isSynchronizing == false -> Acquire Lock (isSynchronizing = true, gen++)
    WGM->>WM: minimize(Window B)
    WM->>AppB: AXUIElementSetAttributeValue(kAXMinimizedAttribute, true)
    AppB-->>Obs: Inbound Echo AX Notification (kAXWindowMiniaturized for B)
    Obs->>WGM: handleWindowMinimize(triggerWindowID: B)
    Note over WGM: isSynchronizing == true -> DROP ECHO EVENT (No cascade loop!)
    Note over WGM: Release Lock (isSynchronizing = false)
```

---

## 5. Architecture Decision Records (ADRs)

### ADR-0007: Separation of `WorkspacePreset` Templates from `Workspace` Instances

- **Status**: Accepted
- **Context**: Workspace snapshots (`Workspace`) persist exact user apps and counts. Presets (`WorkspacePreset`) are reusable role-based templates with fallback chains (`PresetAppSlot`) that work on any Mac regardless of software installation.
- **Decision**: Define `WorkspacePreset` as a dedicated domain entity with `BuiltinPresetFactory` supplying immutable standard workflows.
- **Consequences**: Zero schema coupling; pristine separation of concerns; zero disk migration risk.

### ADR-0008: `@MainActor WindowGroupManager` Coordinator with Generation Locking

- **Status**: Accepted
- **Context**: Synchronizing minimize/focus/move across windows triggers OS-level AX notifications which echo back to FlowSnap, risking infinite feedback loops and CPU spikes.
- **Decision**: Isolate `WindowGroupManager` to `@MainActor` and guard synchronization with `isSynchronizing` flag and generation token `syncGeneration`.
- **Consequences**: Deterministic thread safety; zero race conditions; elimination of cyclic event feedback.

### ADR-0009: Smart Category Fallback Resolution via `ApplicationLaunching`

- **Status**: Accepted
- **Context**: Presets must handle missing applications without blocking the UI or failing whole workflows.
- **Decision**: `PresetResolver` queries running windows, then installed apps via `NSWorkspace`, with a bounded 10.0s wait on cold launch, falling back to next candidate or recording typed `SkipReason`.
- **Consequences**: Highly resilient to diverse developer environments; unit testable via `MockApplicationLaunching`.

### ADR-0010: Preset Hotkey Dispatch & Collision Prevention

- **Status**: Accepted
- **Context**: Presets need global shortcuts (`⌃⌥C`, `⌃⌥R`, `⌃⌥W`, `⌃⌥D`) without colliding with snap shortcuts.
- **Decision**: Extend `WindowCommand` with `.restorePreset(String)`; integrate validation into `PreferencesStore.hasPresetConflict`.
- **Consequences**: Unified shortcut architecture; consistent latest-wins debouncing in `CommandDispatcher`.

---

## 6. Architecture Diagrams (C4 Model)

### C4 Level 1 — System Context

```mermaid
C4Context
    title System Context — FlowSnap Window Groups & Presets
    Person(user, "Mac User", "Software engineer or knowledge worker multitasking on macOS")
    System(flowsnap, "FlowSnap", "Native macOS window management & workflow organization application")
    System_Ext(apps, "macOS Applications", "VS Code, Xcode, Chrome, Safari, Terminal, Notes, etc.")
    System_Ext(ax, "macOS Accessibility API", "AXUIElement window positioning and state observation")
    System_Ext(nsws, "NSWorkspace", "Application discovery, metadata, and lifecycle launching")

    Rel(user, flowsnap, "Triggers presets (⌃⌥C) & manages window groups")
    Rel(flowsnap, apps, "Discovers, launches, positions, and coordinates")
    Rel(flowsnap, ax, "Queries frames, sets positions, raises, minimizes")
    Rel(flowsnap, nsws, "Checks installed apps and launches fallbacks")
```

### C4 Level 2 — Container View

```mermaid
C4Container
    title Container View — FlowSnap Internal Architecture
    Person(user, "User")
    Container(ui, "UI Layer", "SwiftUI + AppKit", "SettingsView (Presets Gallery, Window Groups), MenuBarView, Toast Banner")
    Container(core, "Core Layer", "Swift 6 @MainActor", "CommandDispatcher, PresetResolver, WindowGroupManager, WindowManager, LayoutEngine")
    Container(domain, "Domain Layer", "Pure Swift Models", "WorkspacePreset, PresetAppSlot, WindowGroup, GroupSyncOptions, RestoreSummary")
    Container(infra, "Infrastructure Layer", "System Adapters", "AXAccessibilityService, AppLauncher, GlobalHotkeyManager, PreferencesStore")

    Rel(user, ui, "Interacts with UI / Presses Hotkeys")
    Rel(ui, core, "Dispatches commands and observes published state")
    Rel(core, domain, "Instantiates, queries, and transforms domain models")
    Rel(core, infra, "Manipulates system windows, launches apps, persists settings")
```

---

## 7. Module Boundary Map & Placement (Deep Modules)

| Module / Component                           | Layer          | File Path                                                    | Responsibility                                   | Depends On                                                           |
| -------------------------------------------- | -------------- | ------------------------------------------------------------ | ------------------------------------------------ | -------------------------------------------------------------------- |
| `WorkspacePreset`                            | Domain         | `FlowSnap/Domain/Workspace/WorkspacePreset.swift`            | Preset entity & Codable template                 | `PresetAppSlot`, `LayoutRatio`, `KeyboardShortcut`                   |
| `PresetAppSlot`                              | Domain         | `FlowSnap/Domain/Workspace/PresetAppSlot.swift`              | Slot value object & Category enum                | `PresetAppCategory`, `LayoutZone`, `LayoutRatio`                     |
| `BuiltinPresetFactory`                       | Domain         | `FlowSnap/Domain/Workspace/BuiltinPresetFactory.swift`       | 4 immutable built-in presets                     | `WorkspacePreset`, `PresetAppSlot`                                   |
| `WindowGroup`                                | Domain         | `FlowSnap/Domain/Window/WindowGroup.swift`                   | Live window group aggregate entity               | `CGWindowID`, `GroupSyncOptions`                                     |
| `GroupSyncOptions`                           | Domain         | `FlowSnap/Domain/Window/GroupSyncOptions.swift`              | OptionSet for sync operations                    | —                                                                    |
| `PresetResolving` / `PresetResolver`         | Core           | `FlowSnap/Core/Workspace/PresetResolver.swift`               | Fallback resolution & preset layout execution    | `AccessibilityService`, `ApplicationLaunching`, `WindowGroupManager` |
| `WindowGroupManaging` / `WindowGroupManager` | Core           | `FlowSnap/Core/Window/WindowGroupManager.swift`              | Live group lifecycle & sync coordination         | `AccessibilityService`, `WindowManaging`                             |
| `CommandDispatcher+Presets`                  | Core           | `FlowSnap/Core/Commands/CommandDispatcher.swift`             | Routes `.restorePreset(id)`                      | `PresetResolving`                                                    |
| `PreferencesStore+Presets`                   | Infrastructure | `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` | Persists preset shortcuts & validates collisions | `BuiltinPresetFactory`, `KeyboardShortcut`                           |
| `PresetGalleryView`                          | UI             | `FlowSnap/UI/Settings/PresetGalleryView.swift`               | Settings Presets Gallery tab                     | `PreferencesStore`, `PresetResolving`                                |
| `WindowGroupSettingsView`                    | UI             | `FlowSnap/UI/Settings/WindowGroupSettingsView.swift`         | Settings Window Groups tab                       | `WindowGroupManaging`                                                |
| `MenuBarView+Presets`                        | UI             | `FlowSnap/UI/MenuBar/MenuBarView.swift`                      | Presets submenu in Menu Bar                      | `MenuBarViewModel`, `PresetResolving`                                |

---

## 8. Risks & Mitigations (from Risk Register)

- **Echo Feedback Loop (RISK-GROUP-001)**: Mitigated by `isSynchronizing` re-entrancy lock and `syncGeneration` counter in `WindowGroupManager`.
- **Dangling Window Handles (RISK-GROUP-002)**: Mitigated by event-driven auto-pruning on `kAXUIElementDestroyedNotification` and automatic dissolution when member count < 2.
- **Cold App Launch Hang (RISK-GROUP-003)**: Mitigated by strict 10.0s timeout per slot; timed-out slots marked `launchTimeout` and skipped gracefully.
- **Hotkey Collisions (RISK-GROUP-004)**: Mitigated by proactive validation in `PreferencesStore.hasPresetConflict` against all snap actions and presets.
- **Display Resolution Scaling (RISK-GROUP-005)**: Mitigated by normalized proportional zones and runtime `visibleBounds` recomputation.
- **Debounce Races (RISK-GROUP-006)**: Mitigated by `CommandDispatcher` latest-wins debouncing cancelling prior tasks.
- **Untrusted AX (RISK-GROUP-007)**: Mitigated by pre-flight `AXAccessibilityService.isTrusted` verification.
- **Z-Order Inversion (RISK-GROUP-008)**: Mitigated by deterministic raising order (background members first, anchor window last).

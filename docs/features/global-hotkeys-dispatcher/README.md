# Feature: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Feature Slug**: `global-hotkeys-dispatcher`
- **Epic**: `EPIC 04: Global Hotkeys & Command Dispatcher Daemon`
- **Sprint**: Sprint 1
- **Status**: Completed & Verified (`56/56` tests passing)

---

## 1. Background & Business Value

Power users and software engineers demand instant, keyboard-driven window management without reaching for the mouse or breaking focus.

`US-SNAP-004` establishes FlowSnap's system-wide global shortcut foundation:

1. **Carbon Event Hotkeys (`GlobalHotkeyManager`)**: Intercepts shortcuts system-wide without requiring macOS Accessibility Input Monitoring TCC permissions.
2. **Conflict Resilience (`BR-HOTKEY-002`)**: Bypasses collided shortcuts gracefully (`eventHotKeyExistsErr`) without crashing or blocking application launch.
3. **Sub-50ms Asynchronous Dispatch (`CommandDispatcher`)**: Bridges Carbon C callbacks into Swift 6 structured concurrency (`Task { @MainActor in ... }`), guaranteeing zero main thread blocking.
4. **Latest-Wins Debouncing (`BR-HOTKEY-005`)**: Coalesces rapid keystrokes within a 50ms window to cancel stale in-flight AX requests and prevent queue pile-up.
5. **Idempotent Execution (`BR-HOTKEY-004`)**: Repeated triggers for the current layout zone preserve window stability deterministically.

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph System ["macOS WindowServer & Carbon"]
        Event["kEventHotKeyPressed (Carbon Event)"]
    end

    subgraph Infrastructure ["Infrastructure Layer"]
        GHM["GlobalHotkeyManager (@unchecked Sendable, NSLock)"]
        WM["WindowManager (AXUIElement move/raise)"]
        DM["DisplayManager (@MainActor, NSScreen)"]
    end

    subgraph Core ["Core Layer"]
        CD["CommandDispatcher (@MainActor, Debouncer)"]
        SE["SnapEngine (Sendable)"]
    end

    subgraph Domain ["Domain Layer"]
        KS["KeyboardShortcut (Value Object)"]
        HB["HotkeyBinding (Entity)"]
        WC["WindowCommand (Enum)"]
    end

    Event --> GHM
    GHM -->|bridges async| CD
    CD -->|1. query window| WM
    CD -->|2. resolve display| DM
    CD -->|3. calculate AX frame| SE
    CD -->|4. apply frame| WM
    GHM ..> HB
    HB ..> KS
    HB ..> WC
```

---

## 3. Default Hotkey Layout

| Shortcut | Action           | Target Zone              | KeyCode |         Modifiers         |
| :------- | :--------------- | :----------------------- | :-----: | :-----------------------: |
| `⌃⌥←`    | Snap Left 50%    | `LayoutZone.leftHalf`    |   123   | `controlKey \| optionKey` |
| `⌃⌥→`    | Snap Right 50%   | `LayoutZone.rightHalf`   |   124   | `controlKey \| optionKey` |
| `⌃⌥↑`    | Maximize         | `LayoutZone.maximize`    |   126   | `controlKey \| optionKey` |
| `⌃⌥↓`    | Restore Pre-Snap | Restore cached frame     |   125   | `controlKey \| optionKey` |
| `⌃⌥1`    | Top-Left 25%     | `LayoutZone.topLeft`     |   18    | `controlKey \| optionKey` |
| `⌃⌥2`    | Top-Right 25%    | `LayoutZone.topRight`    |   19    | `controlKey \| optionKey` |
| `⌃⌥3`    | Bottom-Left 25%  | `LayoutZone.bottomLeft`  |   20    | `controlKey \| optionKey` |
| `⌃⌥4`    | Bottom-Right 25% | `LayoutZone.bottomRight` |   21    | `controlKey \| optionKey` |

---

## 4. Key Components & Implementation

### 4.1 `KeyboardShortcut` (`FlowSnap/Domain/Hotkeys/KeyboardShortcut.swift`)

- Value object encapsulating `keyCode: UInt32` and `carbonModifiers: UInt32`.
- Formats canonical macOS glyph strings (`displayString`), such as `"⌃⌥←"`, `"⌃⌥1"`.

### 4.2 `HotkeyBinding` (`FlowSnap/Domain/Hotkeys/HotkeyBinding.swift`)

- Connects `KeyboardShortcut` with `WindowCommand`.
- Manages registration status (`isRegistered: Bool`).

### 4.3 `GlobalHotkeyManaging` & `GlobalHotkeyManager` (`FlowSnap/Infrastructure/Hotkeys/`)

- Intercepts system events via `RegisterEventHotKey` and `InstallEventHandler`.
- Logs warnings and skips conflicts gracefully on `eventHotKeyExistsErr` (`OSStatus -9878`).
- Cleans up with `UnregisterEventHotKey` on `unregisterAll()` and `deinit`.

### 4.4 `CommandDispatcher` (`FlowSnap/Core/Commands/CommandDispatcher.swift`)

- Central routing hub coordinating `WindowManaging`, `DisplayManaging`, and `SnapEngine`.
- Evaluates active window guard (`BR-HOTKEY-006`).
- Applies latest-wins debouncing within a 50ms window (`BR-HOTKEY-005`).

---

## 5. Verification & Test Coverage

- **Suite Results**: `56 tests across 13 suites passed in 0.012 seconds`.
- **Unit Tests Added**:
  - `KeyboardShortcutTests`: Glyphs generation, modifier combinations, Codable round-trips.
  - `GlobalHotkeyManagerTests`: Default 8 hotkeys registration, collision tolerance, teardown lifecycle.
  - `CommandDispatcherTests`: Left snap, maximize & restore, nil window guard, rapid debouncing.

---

## 6. Next Milestone Integration

With `US-SNAP-004` complete, FlowSnap possesses full keyboard automation. The next step on the roadmap:
👉 **`US-SNAP-005: Menu Bar Status Item & Quick Snap Controls (EPIC 05)`**

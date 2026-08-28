# Feature Specification: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Feature**: `global-hotkeys-dispatcher`
- **Slug**: `global-hotkeys-dispatcher`
- **Epic**: `EPIC 04: Global Hotkeys & Command Dispatcher Daemon`
- **Target Sprint**: Sprint 1
- **Status**: Ready for Planning
- **Derived from**: [baseline.md](baseline.md) (SIGNED-OFF v1.0)

---

## 1. Feature Overview

Power users rely on keyboard shortcuts to snap, tile, maximize, and restore windows without interrupting typing or switching focus to mouse pointers.

FlowSnap introduces an asynchronous, low-latency command routing architecture:

1. **Carbon Event Hotkeys**: Low-level, system-wide key interception via `RegisterEventHotKey` that triggers without needing invasive macOS Input Monitoring TCC permissions.
2. **`GlobalHotkeyManaging`**: Protocol-abstracted manager tracking registered shortcuts, handling third-party collision errors gracefully, and managing event listener teardown.
3. **`CommandDispatching` / `CommandDispatcher`**: Central router coordinating active window lookup (`WindowManaging`), display resolution (`DisplayManaging`), target calculation (`SnapEngine`), and debounced asynchronous execution (< 50ms).
4. **Default Shortcut Map**: 8 ergonomic `Control + Option` (`⌃⌥`) shortcuts for left/right halves, maximize, restore, and 4 corner quarters.

---

## 2. Functional Requirements

### **REQ-HOTKEY-001: Default Shortcut Registration**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-HOTKEY-001`, `ASM-HOTKEY-001`, `ASM-HOTKEY-002`
- The system must register 8 default global shortcuts:
  - `⌃⌥←`: Snap Left 50%
  - `⌃⌥→`: Snap Right 50%
  - `⌃⌥↑`: Maximize
  - `⌃⌥↓`: Restore pre-snap frame
  - `⌃⌥1`: Top-Left 25%
  - `⌃⌥2`: Top-Right 25%
  - `⌃⌥3`: Bottom-Left 25%
  - `⌃⌥4`: Bottom-Right 25%

### **REQ-HOTKEY-002: Collision Tolerance & Resilience**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-HOTKEY-002`, `ASM-HOTKEY-003`
- If an individual shortcut registration fails (e.g. `eventHotKeyExistsErr`), the system must:
  - Log a structured warning.
  - Set `isRegistered = false` on that `HotkeyBinding`.
  - Continue registering all remaining valid shortcuts without throwing fatal errors or aborting launch.

### **REQ-HOTKEY-003: Sub-50ms Asynchronous Command Dispatch**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-HOTKEY-003`, `ASM-HOTKEY-004`
- Carbon event callbacks must not perform synchronous heavy work or blocking locks.
- Work is bridged into Swift structured concurrency (`Task { @MainActor in ... }`) and dispatches the corresponding `WindowCommand`.

### **REQ-HOTKEY-004: Execution Debouncing & Coalescing**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-HOTKEY-005`, `ASM-HOTKEY-006`
- If rapid consecutive hotkeys are received within 50ms, `CommandDispatcher` drops stale pending tasks and executes only the latest user intent.

### **REQ-HOTKEY-005: Idempotency & Active Window Guard**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-HOTKEY-004`, `BR-HOTKEY-006`
- Snapping a window to its existing zone is strictly idempotent.
- If `focusedWindow()` returns `nil`, dispatch completes as a safe no-op.

---

## 3. Non-Functional Requirements (NFR)

- **NFR-PERF-001**: Latency from keypress to AX command invocation < 50ms.
- **NFR-CONC-001**: Strict Concurrency (Swift 6.0) compliance; all actors and sendable closures properly annotated.
- **NFR-TEST-001**: 100% test coverage on `CommandDispatcher` routing logic with mock doubles.

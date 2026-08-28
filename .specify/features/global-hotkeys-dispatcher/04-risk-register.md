# Risk Register & Contradiction Scan: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Feature**: `global-hotkeys-dispatcher`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner (Bounded Task)

---

## 1. Risk Matrix

| Risk ID             | Description                                                                                                                                       | Severity | Likelihood | Mitigation Strategy                                                                                                                                                             |
| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------ | :------: | :--------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **RISK-HOTKEY-001** | **Shortcut collision with other apps (Rectangle, Raycast, Xcode)**: If a default hotkey is already registered, Carbon returns error.              |  Medium  |    High    | **Graceful Skip**: Log warning, mark binding inactive, continue registering remaining valid shortcuts. Zero crash or launch blocking.                                           |
| **RISK-HOTKEY-002** | **Swift 6 Strict Concurrency violation in Carbon C callback**: C function pointers passed to `InstallEventHandler` cannot capture context safely. |   High   |    Low     | Use `Unmanaged<AnyObject>.passUnretained(self).toOpaque()` in event handler user data, extract instance safely, and immediately hop into Swift `Task` with `@Sendable` closure. |
| **RISK-HOTKEY-003** | **AX Latency spike blocking keystrokes**: Slow AX calls from unresponsive target apps delaying system-wide event dispatch.                        |   High   |   Medium   | Execute all dispatch operations asynchronously in detached/actor tasks with a 50ms latest-wins debounce window. Carbon callback returns immediately (`noErr`).                  |
| **RISK-HOTKEY-004** | **Unfocused window or system dialog target**: Hotkey pressed while desktop, Spotlight, or modal dialog is active.                                 |   Low    |   Medium   | `CommandDispatcher` queries `focusedWindow()` and gracefully exits if window is non-snappable or nil.                                                                           |

---

## 2. Contradiction & Scope Lock (MoSCoW)

- **Must-Have**:
  - Carbon Event Hotkey registration for 8 default combinations (`⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`, `⌃⌥1..4`).
  - Asynchronous `CommandDispatcher` routing commands to `SnapEngine`.
  - Latency budget < 50ms per keypress.
  - Clean unregistration on app termination.
- **Won't-Have (in this Sprint / US-SNAP-004)**:
  - Custom user shortcut recorder UI (deferred to Epic 10: `US-SNAP-010`).
  - Cycling snap ratios on repeated keypresses (deferred to Epic 8: `US-SNAP-008`).
  - Moving across spaces/virtual desktops (out of scope for native public APIs).

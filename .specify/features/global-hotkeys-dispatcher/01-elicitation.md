# Elicitation Record: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Date**: 2026-08-28
- **Feature Slug**: `global-hotkeys-dispatcher`
- **Protocol Depth**: Bounded Task (Interactive Grilling Interview conducted, Stage 3 gap-analysis skipped)

---

## Stage 1 — Business Value

- **Problem & Pain Point**:
  Power users (especially software engineers and multi-taskers) require instant, muscle-memory keyboard shortcuts to manage windows without reaching for the mouse or breaking flow.
  Default macOS lacks native half/quarter snapping hotkeys. Existing tools can suffer from input lag, conflicting registrations, or heavy background event taps that require invasive permissions.
- **Target Personas**:
  - Persona A (Hải): Senior Software Engineer who demands sub-50ms shortcut response to snap VS Code, Chrome, and Terminal without keyboard lockups.
- **Success Metrics**:
  - End-to-end hotkey-to-dispatch latency under 50ms.
  - Zero main-thread blocking; Carbon event handler dispatches asynchronously.
  - 100% deterministic registration of default shortcuts (`⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`, `⌃⌥1..4`).

---

## Pillar 1 — Hotkey Registration & Collision Management

**Q1: Hotkey Collision & Registration Failure Policy**

- **Decision**: **Option A — Non-blocking Graceful Skip** (Confirmed by User).
  If a default shortcut (e.g., `⌃⌥←`) is already registered by another application (e.g., Rectangle, Raycast, Xcode), Carbon returns an error (e.g. `eventHotKeyExistsErr` / `-9870`).
  FlowSnap logs a structured warning, records the binding as inactive/conflicted, continues registering all other remaining valid shortcuts, and flags the status for Menu Bar visibility rather than failing fast or blocking application startup.

---

## Pillar 2 — Shortcut Repeat & Idempotency

**Q2: Consecutive Repeat Hotkey Behavior**

- **Decision**: **Option A — Idempotent Snap** (Confirmed by User).
  When a window is already snapped (e.g. Left Half), pressing `⌃⌥←` again deterministically re-asserts the Left Half position without state mutation or unintended movement.
  Multi-ratio cycling (e.g. 2/3, 1/3) and multi-screen hopping are deferred to Epic 8/Epic 10.

---

## Pillar 3 — Concurrency & Dispatch Latency Budget

**Q3: Dispatch Concurrency & Debouncing Policy**

- **Decision**: **Option A — Latest-Wins Debounce (50ms)** (Confirmed by User).
  If the user presses shortcuts in rapid succession faster than the macOS Accessibility API can complete window frame adjustments (~30-50ms per AX call), `CommandDispatcher` drops stale pending snap actions and executes only the latest command.
  This guarantees adherence to the < 50ms latency budget and prevents AX queue backpressure.

---

## Assumptions Confirmed

- **ASM-HOTKEY-001**: Carbon Event Hotkeys API (`RegisterEventHotKey` / `InstallEventHandler`) is used for system-wide shortcut listening, avoiding the need for invasive Input Monitoring TCC permissions.
- **ASM-HOTKEY-002**: Default hotkeys use the `Control + Option` (`⌃⌥`) modifier mask:
  - `⌃⌥←`: Snap Left 50%
  - `⌃⌥→`: Snap Right 50%
  - `⌃⌥↑`: Maximize
  - `⌃⌥↓`: Restore previous pre-snap frame
  - `⌃⌥1`: Top-Left 25%
  - `⌃⌥2`: Top-Right 25%
  - `⌃⌥3`: Bottom-Left 25%
  - `⌃⌥4`: Bottom-Right 25%
- **ASM-HOTKEY-003**: In case of shortcut registration collisions, non-colliding hotkeys remain fully operational and the collision is recorded gracefully.
- **ASM-HOTKEY-004**: Carbon C callbacks immediately bridge execution into Swift structured concurrency (`Task { @MainActor in ... }`), ensuring zero blocking on the Carbon event loop.
- **ASM-HOTKEY-005**: Hotkey snap execution is idempotent across all standard zones.
- **ASM-HOTKEY-006**: `CommandDispatcher` coalesces rapid consecutive dispatches using a latest-wins debounce strategy to prevent AX command stampedes.

---

## Open Questions

- _(None — all branches resolved in Stage 2 Elicitation interview)_.

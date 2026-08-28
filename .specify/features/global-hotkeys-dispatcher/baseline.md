# Domain Decision Baseline: Global Hotkeys & Command Dispatcher (US-SNAP-004)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0  
**Feature Slug**: `global-hotkeys-dispatcher`  
**Date**: 2026-08-28

---

## 1. Executive Summary

FlowSnap requires a low-latency, conflict-resilient system for global keyboard shortcut interception and command execution.

This baseline establishes:

1. **Carbon Event Hotkeys**: Low-level, system-wide key interception via `RegisterEventHotKey` without requiring macOS Input Monitoring TCC permissions.
2. **Conflict Resilience**: Graceful skip policy on shortcut collisions (`eventHotKeyExistsErr`), ensuring remaining shortcuts register successfully and app startup is never blocked.
3. **Idempotent Snapping**: Re-triggering a shortcut for an already-occupied layout zone deterministically reaffirms the zone without unintended movements.
4. **Sub-50ms Latency Budget & Latest-Wins Debouncing**: Carbon C callbacks bridge immediately into Swift structured concurrency (`Task { @MainActor in ... }`), and `CommandDispatcher` drops stale in-flight tasks within a 50ms window when rapid keystrokes occur.
5. **Decoupled Architecture**: `GlobalHotkeyManaging` delegates `WindowCommand` payloads to `CommandDispatcher`, which orchestrates `WindowManaging`, `DisplayManaging`, and `SnapEngine`.

---

## 2. Settled Elicitation & Grilling Decisions

| Item                                 | Decision                                  | Rationale                                                                                                                       |
| :----------------------------------- | :---------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| **Q1: Shortcut Collision Policy**    | **Option A (Non-blocking Graceful Skip)** | Log warning, set `isRegistered = false`, continue registering other valid shortcuts, and report status without blocking launch. |
| **Q2: Consecutive Repeat Hotkey**    | **Option A (Idempotent Snap)**            | Re-assert current layout zone deterministically. Preserves Sprint 1 scope; ratio cycling deferred to Epic 8.                    |
| **Q3: Concurrency & Latency Budget** | **Option A (Latest-Wins Debounce 50ms)**  | Drop stale in-flight snap actions during rapid keystrokes to ensure < 50ms latency budget and prevent AX command backpressure.  |

---

## 3. Core Business Rules

- **BR-HOTKEY-001 (Default Shortcuts)**: 8 default global shortcuts using `Control + Option` (`⌃⌥`):
  - `⌃⌥←`: Snap Left 50%
  - `⌃⌥→`: Snap Right 50%
  - `⌃⌥↑`: Maximize
  - `⌃⌥↓`: Restore pre-snap frame
  - `⌃⌥1`: Top-Left 25%
  - `⌃⌥2`: Top-Right 25%
  - `⌃⌥3`: Bottom-Left 25%
  - `⌃⌥4`: Bottom-Right 25%
- **BR-HOTKEY-002 (Collision Resilience)**: If Carbon returns an error on `RegisterEventHotKey`, mark the binding inactive and continue. Never crash.
- **BR-HOTKEY-003 (Sub-50ms Latency Budget)**: Carbon C callbacks must not perform synchronous I/O or blocking locks. Asynchronously dispatch via Swift concurrency.
- **BR-HOTKEY-004 (Idempotency)**: Re-triggering a shortcut for the current zone is a deterministic no-op.
- **BR-HOTKEY-005 (Latest-Wins Debouncing)**: Coalesce rapid consecutive keystrokes within 50ms to execute only the latest intent.
- **BR-HOTKEY-006 (Active Window Guard)**: If `focusedWindow()` is `nil`, dispatch exits cleanly with zero side-effects.

---

## 4. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - Carbon Event Hotkey integration for 8 default combinations.
  - Asynchronous `CommandDispatcher` routing commands to `SnapEngine`.
  - Latency budget < 50ms.
  - Safe teardown on app termination (`unregisterAll()`).
- **Won't-Have (US-SNAP-004 Scope)**:
  - Shortcut customization UI (deferred to Epic 10: `US-SNAP-010`).
  - Cycling snap ratios on repeated keypresses (deferred to Epic 8: `US-SNAP-008`).

# Handover Brief: Global Hotkeys & Command Dispatcher (US-SNAP-004)

**Baseline version**: 1.0 (Draft sign-off 2026-08-28)  
**Spec documents**: [spec.md](spec.md), [spec/user-stories.md](spec/user-stories.md)  
**Validation report**: [validation-report.md](validation-report.md)  
**Target Milestone**: Speckit Technical Planning & TDD Implementation

---

## 1. What Needs to Be Built

1. **`KeyboardShortcut` & `HotkeyBinding`**:
   - Carbon-compatible virtual keycodes (`kVK_LeftArrow`, `kVK_RightArrow`, `kVK_UpArrow`, `kVK_DownArrow`, `kVK_ANSI_1..4`) and modifiers (`controlKey + optionKey`).
   - Human-readable display string generation (e.g. `⌃⌥←`).
2. **`GlobalHotkeyManaging` & `GlobalHotkeyManager`**:
   - Concrete Carbon event handler using `RegisterEventHotKey` and `InstallEventHandler`.
   - Resilience against collisions (`eventHotKeyExistsErr`): non-blocking graceful skip.
   - Clean teardown with `UnregisterEventHotKey` on `unregisterAll()`.
3. **`CommandDispatcher`**:
   - Central router receiving `WindowCommand`.
   - Resolves `focusedWindow()` via `WindowManaging`, queries target display via `DisplayManaging`, calculates AX frame via `SnapEngine`, moves window via `windowManager.move(window, to: frame)`.
   - Latest-wins debouncing within 50ms window.
4. **`FlowSnapLab` Integration**:
   - Interactive shortcut monitor displaying active vs conflicted hotkeys.

---

## 2. What Is Explicitly Out of Scope (Won't-Have)

- **Shortcut Customization UI**: Custom recorder is deferred to Epic 10 (`US-SNAP-010`).
- **Multi-Ratio Cycling**: Advanced 2/3 and 1/3 cycling is deferred to Epic 8 (`US-SNAP-008`).

---

## 3. Handover Target

Ready for **Confirmation Gate 1** (Spec Sign-Off) and handoff to `system-architect` for Speckit Phase 2–4 (`spec.md`, `plan.md`, `data-model.md`, `contracts/`, `tasks.md`).

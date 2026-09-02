# Intake: App Launch Observer & Current Space Policy (US-WORK-013)

- **Date**: 2026-09-02
- **Requested by**: FlowSnap Product Roadmap / EPIC 11 (Application Launch Observer & Current Space Preservation)
- **Classification**: Full Feature
- **Classification signals**:
  - New/changed domain entities: 2 (new `ApplicationObserver` infrastructure service; expanded `WindowPolicyManager` with full `applyPolicy` implementation)
  - Existing persistence schema change: No (policies stored in-memory v1.0; `PreferencesStore` integration reserved for US-WORK-014)
  - Screens/flows touched: 1 (Application Rules tab in Settings — currently mockup-only, will connect to real `WindowPolicyManager`)
  - User roles affected: 1 (Mac power user / FlowSnap user)
  - Cross-cutting impact: Yes (Infrastructure `WorkspaceObserver` + `ApplicationObserver` → EventBus → Core `WindowPolicyManager` → `AccessibilityService` / `WindowManager` / `DisplayManager` → App `AppDependencies` / `AppDelegate`)
  - Estimated code lines changed: ~400-600 lines
  - Reversible without user impact: Yes (disabling observer reverts to default macOS behavior)
- **Protocol selected**: Bounded Task Pipeline (Stages 1 → 2 → 4 → 5 → 6 → 7 → 8; Stage 3 gap-analysis skipped since AS-IS stubs are fully mapped).
- **Override**: None (Matches roadmap Epic 11 / US-WORK-013 — Effort `L`, context-budget multi-session, Priority Must-Have P0).
- **Roadmap dependencies**: Depends-on `US-WORK-012` (delivered). Blocks `US-WORK-014` (Per-App Rules & Smart Floating Stack).

## Key roadmap constraints carried into Stage 2

- **100% Public APIs only**: No private CGS APIs (`CGSSetWindowSpaces`, `SLSGetWindowSpaces`). FlowSnap must remain forward-compatible with future macOS updates.
- **Current Space + Current Display policy**: New windows must appear on the current Space without triggering macOS Space switching. Use `.withoutActivating` or immediate frame adjustment.
- **Timing race condition**: App launches but window may take seconds to appear. AXObserver with `kAXWindowCreatedNotification` + timeout mechanism required.
- **Event-driven architecture**: All observation flows through `EventBus` pub-sub pattern (no direct service coupling).
- **Zero polling loops**: `CPU Idle: 0.0%` mandate — event-driven 100%, no `while(true)` timers.

## One-line problem statement

Detect when applications launch or activate on macOS and ensure their new windows appear on the user's current Space and display without triggering unwanted Space switching, using only public macOS APIs with an async observation pattern that handles the inherent timing race between process launch and window creation.

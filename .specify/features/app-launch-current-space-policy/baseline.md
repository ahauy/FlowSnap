# Domain Decision Baseline: App Launch Observer & Current Space Policy (US-WORK-013)

**Status**: SIGNED-OFF v1.0
**Version**: 1.0
**Feature Slug**: `app-launch-current-space-policy`
**Date**: 2026-09-02

This document is compiled incrementally by every stage of the Universal BA
Pipeline. Do not hand-edit sections owned by another skill.

## Stage 0 — Intake

See `00-intake.md`. Classified Bounded Task (Stages 1 → 2 → 4 → 5 → 6 → 7 → 8).
Depends on US-WORK-012 (delivered); blocks US-WORK-014.

## Stage 2 — Elicitation (Confirmed Decisions)

Confirmed by roadmap specification. Key architectural decisions:

| Decision | Outcome |
| :--- | :--- |
| **ASM-LAUNCH-001** | Use `NSWorkspace.didLaunchApplicationNotification` + `didActivateApplicationNotification` for app lifecycle detection. No private APIs. |
| **ASM-LAUNCH-002** | Register `AXObserver` for `kAXWindowCreatedNotification` on newly launched processes to detect window creation with zero polling. Timeout fallback of 10s. |
| **ASM-LAUNCH-003** | Default policy `.currentSpace`: position new window on current display using `DisplayManager` visible frame. No Space switching triggered. |
| **ASM-LAUNCH-004** | `WorkspaceObserver` → `EventBus` → `WindowPolicyManager` flow. Services decoupled via pub-sub, no direct coupling. |
| **ASM-LAUNCH-005** | AXObserver callback bridges to `@MainActor` via `Task { @MainActor in }`. Callback is C-function context, must be `Sendable`. |

## Stage 4 — Domain Model

Entities: `WindowPolicy` (enum, already defined — `.currentSpace`, `.currentDisplay`,
`.floating`, `.rememberPosition`, `.assignedLayout(UUID)`, `.assignedWorkspace(UUID)`),
`ApplicationObserver` (new infrastructure service, wraps AXObserver lifecycle),
`WorkspaceObserver` (existing stub, to be implemented), `WindowPolicyManager`
(existing stub, `applyPolicy` to be implemented), `EventBus` (existing, pub-sub).

New domain terms for CONTEXT.md:
- `ApplicationObserving` — protocol abstracting AXObserver window-creation detection
- `ApplicationObserver` — concrete impl managing per-pid AXObserver registration + timeout

## Stage 5 — Risk Register

| Risk | Severity | Mitigation |
| :--- | :--- | :--- |
| RISK-LAUNCH-001: AXObserver registration fails silently | Medium | Fallback to polling via `AppLauncher.waitForFirstWindow` pattern (100ms interval, 10s timeout) |
| RISK-LAUNCH-002: Window appears on wrong Space despite policy | High | Apply frame immediately on `kAXWindowCreatedNotification`, before macOS completes Space transition animation |
| RISK-LAUNCH-003: Race between didLaunch and AXObserver setup | Medium | Register AXObserver synchronously in notification handler; use pid from notification payload |
| RISK-LAUNCH-004: App launches but never creates window (headless, Gatekeeper) | Low | 10s timeout cleanup; AXObserver released on timeout to prevent leak |
| RISK-LAUNCH-005: Multiple rapid launches overwhelm observers | Low | Deduplicate by pid; ignore re-registration for same pid within 5s window |

## Stage 6 — Specification

Requirements (derived from roadmap US-WORK-013 AC):
- REQ-LAUNCH-001: `WorkspaceObserver` listens to `NSWorkspace.didLaunchApplicationNotification` and `didActivateApplicationNotification`
- REQ-LAUNCH-002: On launch detection, register AXObserver for `kAXWindowCreatedNotification` on the new process
- REQ-LAUNCH-003: On window creation, apply `WindowPolicy` — default `.currentSpace` positions on current display
- REQ-LAUNCH-004: 10s timeout for window creation; cleanup AXObserver on timeout
- REQ-LAUNCH-005: 100% public macOS APIs only

## Stage 7 — Validation

IEEE 29148 conformance: PASS. All 5 requirements are:
- Unambiguous (single interpretation per REQ)
- Verifiable (testable via mock NSWorkspace notifications + mock AXObserver)
- Traceable (each REQ derived from roadmap AC)
- Bounded (no open-ended "shall support future...")
- Implementation-independent (specify behavior, not code structure)

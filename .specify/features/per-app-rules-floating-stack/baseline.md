# Domain Decision Baseline: Per-App Window Policies & Smart Floating Stack (US-WORK-014)

**Status**: SIGNED-OFF v1.0
**Version**: 1.0
**Feature Slug**: `per-app-rules-floating-stack`
**Date**: 2026-09-03

This document is compiled incrementally by every stage of the Universal BA
Pipeline. Do not hand-edit sections owned by another skill.

## Stage 0 — Intake

See `00-intake.md`. Classified Bounded Task (Stages 1 → 2 → 4 → 5 → 6 → 7 → 8).
Depends on `US-WORK-013` (delivered & verified); blocks `(none)`.

## Stage 2 — Elicitation (Confirmed Decisions)

Confirmed through interactive interview (`01-elicitation.md`):

| Decision           | Outcome                                                                                                                                                                                                                         |
| :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **ASM-POLICY-001** | Floating Window & Smart Stack Stacking Protocol: exempt from grid tiling, preserve standard macOS window level, maintain MRU focus stack with automatic focus return to previous underlying window upon close.                  |
| **ASM-POLICY-002** | Clamped & Display-Aware Remembered Position: save last known `CGRect` per `bundleIdentifier`; clamp against `display.visibleFrame` (minimum 80% visibility, no clipping under menu bar/dock) if monitor changed.                |
| **ASM-POLICY-003** | Predefined Canonical Snap Zones for Assigned Layout: allow choosing from standard zones (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, `maximize`, `70/30`, `60/40`, four quarters) computed dynamically by `LayoutEngine`. |

## Stage 4 — Domain Model

Entities:

- `WindowPolicy` (expanded with `.assignedLayout(LayoutZone)` and updated cases)
- `AppPolicyRule` (`id`, `bundleID`, `appName`, `policy`, `iconName`)
- `RememberedFrameStore` (`clampedFrame(for:in:)`)
- `SmartFocusStack` (`push`, `popAndRestoreFocus`)
- `PreferencesStore` integration for persisting `[AppPolicyRule]` and `[String: CGRect]`

New terms added to `CONTEXT.md`:

- `AppPolicyRule`
- `RememberedFrameStore`
- `SmartFocusStack`

Architectural Record: `adr/0009-per-app-window-policies-and-floating-stack.md`.

## Stage 5 — Risk Register

| Risk                                                            | Severity | Mitigation                                                       |
| :-------------------------------------------------------------- | :------- | :--------------------------------------------------------------- |
| **RISK-POLICY-001**: Window off-screen after monitor disconnect | High     | Enforce `BR-POLICY-003`: mathematical clamping to visible bounds |
| **RISK-POLICY-002**: Window min size exceeds assigned zone      | Medium   | Respect `kAXSizeAttribute` minimum constraints                   |
| **RISK-POLICY-003**: Stale window reference on floating close   | Low      | Verify AX element liveness before activating focus               |
| **RISK-POLICY-004**: Duplicate rule entries                     | Medium   | Key rules by normalized `bundleIdentifier` in dictionary         |
| **RISK-POLICY-005**: Private API temptation                     | Critical | Zero private APIs; standard window level + focus return          |

## Stage 6 — Specification

Requirements (REQ-POLICY-001 to REQ-POLICY-006):

- `REQ-POLICY-001`: Per-app rule priority and persistence in `PreferencesStore`.
- `REQ-POLICY-002`: Floating window layout exemption from grid snaps.
- `REQ-POLICY-003`: Clamped display-aware position restoration.
- `REQ-POLICY-004`: Assigned canonical layout zone positioning.
- `REQ-POLICY-005`: Smart focus return to underlying active window upon floating app dismissal.
- `REQ-POLICY-006`: Reactive Settings > Applications UI with app selector and policy picker.

User Stories: `US-WORK-014-01` to `US-WORK-014-04` covering precedence, floating immunity, clamping, and UI management.

## Stage 7 — Validation

Validation Report: `validation-report.md` (IEEE 29148 Passed).
Traceability: `traceability-matrix.md` (100% bidirectional coverage).
Scope locks: MoSCoW boundary defined in `04-risk-register.md`.

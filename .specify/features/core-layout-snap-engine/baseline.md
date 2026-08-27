# Domain Decision Baseline: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

**Status**: SIGNED-OFF  
**Version**: 1.0  
**Feature Slug**: `core-layout-snap-engine`  
**Protocol**: Bounded Task

---

## 1. Executive Problem & Scope Summary

FlowSnap requires a pure, hardware-independent mathematical calculation engine (`LayoutEngine`) and snap coordinator (`SnapEngine`) to compute window placements for standard screen partitions (Left/Right/Top/Bottom halves, 4 corners, Maximize, and Restore). The solution must handle odd-pixel screen resolutions without leaving gaps or overflowing display boundaries, and must reliably track the user's pre-snap window position for single-step restoration.

---

## 2. Core Business Rules Summary

- **BR-LAYOUT-001 (Visible Bounds Isolation)**: Math strictly operates within the display's `visibleFrame` (excluding macOS Menu Bar and Dock).
- **BR-LAYOUT-002 (Odd-Pixel Flooring Policy)**: Odd dimensions allocate $\lfloor \text{dimension} / 2.0 \rfloor$ to the primary half, remainder to the adjacent half.
- **BR-LAYOUT-003 (Standard Zones)**: Deterministic 9-zone layout coordinates (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, 4 corners, `maximize`).
- **BR-LAYOUT-004 (Pre-Snap Preservation & Restore)**: The user-positioned frame prior to the first snap is preserved across consecutive snaps and consumed upon Restore.
- **BR-LAYOUT-005 (Min Size Anchoring)**: Applications with minimum sizes exceeding a zone clamp to `max(calculated, minSize)` and anchor to the target screen edge/corner.

---

## 3. Scope Boundaries (MoSCoW)

- **Must-Have (P0)**: 9 standard snap zones, odd-pixel flooring, pre-snap frame caching in `WindowRegistry`, Restore action, FlowSnapLab interactive controls, 100% unit test coverage across resolutions.
- **Should-Have (P1)**: Parameterized window gaps (`gap: CGFloat = 0`).
- **Won't-Have (Out of Scope)**: Multi-monitor coordinate inversion (`US-SNAP-003`), Global Carbon Hotkeys (`US-SNAP-004`), Menu Bar UI (`US-SNAP-005`), Drag-to-snap HUD (`US-SNAP-006`), Adaptive divider resizing (`US-SNAP-009`).

---

## 4. Key Artifact Links

- Intake Classification: [`00-intake.md`](00-intake.md)
- Elicitation Interview: [`01-elicitation.md`](01-elicitation.md)
- Domain Model & Rules: [`03-domain-model.md`](03-domain-model.md)
- Risk & Scope Register: [`04-risk-register.md`](04-risk-register.md)
- Software Requirements Specification: [`spec/SRS.md`](spec/SRS.md)
- User Stories (Gherkin): [`spec/user-stories.md`](spec/user-stories.md)
- Quality Audit Report: [`validation-report.md`](validation-report.md)

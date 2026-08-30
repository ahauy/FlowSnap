# Domain Baseline: US-SNAP-009 Adaptive Multi-Window Divider Resize

**Status:** SIGNED-OFF v1.0
**Date:** 2026-08-30
**Slug:** adaptive-divider-resize
**Epic:** EPIC-08 — Adaptive Multi-Window Resize & Gaps
**Sprint:** Sprint 2

---

## 1. Summary
US-SNAP-009 implements adaptive multi-window divider resizing. FlowSnap identifies shared collinear edges between adjacent windows using `CollinearEdgeDetector` and `LayoutGraph`, transforms the mouse cursor to appropriate resize cursors on hover, and allows users to drag shared dividers to simultaneously resize all collinear windows in real-time with 60fps rate-limiting and minSize boundary protection.

---

## 2. Business Rules Baseline
- **BR-ADR-001**: Windows sharing an edge within tolerance are collinear.
- **BR-ADR-002**: Composite divider union for multi-window edges (T-junctions, cross-junctions).
- **BR-ADR-003**: Cursor affordance (`NSCursor.resizeLeftRight` / `NSCursor.resizeUpDown`).
- **BR-ADR-004**: Strict minSize boundary preservation (no window collapse).
- **BR-ADR-005**: 60fps throttled dispatch pacing.
- **BR-ADR-006**: Zero floating-point gap drift.

# Domain Decision Baseline: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0  
**Feature Slug**: `drag-to-snap-preview`  
**Date**: 2026-08-29

---

## 1. Executive Summary

FlowSnap requires an intuitive mouse/trackpad drag-to-snap interaction combined with a high-fidelity visual preview overlay (HUD Snap Preview) that activates when dragging a window towards screen edges and corners.

This baseline establishes:

1. **Passive Global Mouse Tracking**: Utilizes `NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp])` throttled at 60fps (~16ms) to detect window drag gestures without heavy low-level kernel C-taps.
2. **Display-Aware Edge & Corner Detection**: Mathematical zone evaluation dividing screen borders into 8 canonical snap targets (Left Half, Right Half, Top/Maximize, Bottom Half, and 4 Quarters) with a 4px edge threshold.
3. **Multi-Monitor Boundary Intelligence**: Adaptive dwell timing (100ms for outer edges vs 250ms for internal adjacent monitor borders) to eliminate accidental snap triggers during cross-display window movement.
4. **Liquid Glass Preview Overlay**: A non-activating, floating `NSPanel` (`SnapPreviewPanel`) rendering a translucent glassmorphic preview (`NSVisualEffectView` / SwiftUI) with 10px corner radius and system accent highlight stroke.
5. **Release-to-Snap Execution**: Automatically applies the snap transformation to the dragged window upon mouse release (`leftMouseUp`) and smoothly dismisses the HUD overlay.

---

## 2. Settled Elicitation Decisions

| Item                                | Decision                                    | Rationale                                                                                                                       |
| :---------------------------------- | :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------ |
| **Q1: Edge Detection Mechanism**    | **Option A (NSEvent Global Monitor)**       | Lightweight, safe AppKit event monitoring with 60fps throttling, zero risk of C callback timeouts.                              |
| **Q2: Multi-Monitor Boundary Drag** | **Option A (Dwell Differentiation)**        | Outer boundaries trigger at 100ms; internal adjacent borders require 250ms dwell to permit effortless cross-screen dragging.    |
| **Q3: HUD Preview Appearance**      | **Option A (Liquid Glass + Accent Stroke)** | Translucent glassmorphism with 10px corner radius, macOS accent stroke, and 150ms fade animation for native premium aesthetics. |

---

## 3. Core Business Rules

- **BR-DRAG-001 (Edge Detection & Dwell Threshold)**:
  - Cursor within $\le 4\text{px}$ of screen boundary initiates edge evaluation.
  - Outer screen boundary: Triggers preview after 100ms dwell.
  - Internal adjacent monitor boundary: Triggers preview after 250ms dwell.
- **BR-DRAG-002 (Canonical Snap Target Mapping)**:
  - Left Edge (central 60%): `SnapTarget.leftHalf`
  - Right Edge (central 60%): `SnapTarget.rightHalf`
  - Top Edge (central 60%): `SnapTarget.maximize`
  - Bottom Edge (central 60%): `SnapTarget.bottomHalf`
  - 4 Corners (outer 20%): `SnapTarget.topLeft`, `topRight`, `bottomLeft`, `bottomRight`.
- **BR-DRAG-003 (HUD Snap Preview Overlay)**:
  - `SnapPreviewPanel` is non-activating, `.floating` level, ignores mouse clicks, and never steals key window focus.
  - Visuals conform to Liquid Glass aesthetic (10px corner radius, 1.5px accent stroke, 150ms fade transitions).
- **BR-DRAG-004 (Release-to-Snap Execution)**:
  - `leftMouseUp` while preview is active triggers `SnapEngine.snap` on the frontmost managed window and dismisses overlay immediately.
- **BR-DRAG-005 (Cancel / Move-Away Dismissal)**:
  - Moving cursor $> 20\text{px}$ away from edge cancels dwell timer and smoothly hides preview.

---

## 4. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - Global mouse drag & release tracking via `NSEvent` monitor.
  - Detection of 8 canonical snap zones on active display.
  - HUD overlay preview panel with Liquid Glass appearance.
  - Snap execution on mouse release and smooth dismissal.
  - Dwell timeout differentiation for multi-monitor adjacent edges.
- **Won't-Have (US-SNAP-006 Scope)**:
  - Windows 11 Top-Edge Layout Picker (Epic 7 / `US-SNAP-007`).
  - Custom drag ratios like 60/40, 70/30 (Epic 8 / `US-SNAP-008`).
  - Collinear shared divider dragging (Epic 8 / `US-SNAP-009`).

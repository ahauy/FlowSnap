# Technical Specification: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

## 1. Scope & Objective

This specification details the architecture and implementation for `US-SNAP-006`: providing an interactive Drag-to-Snap mechanism where dragging windows to screen edges or corners triggers a translucent Liquid Glass HUD Snap Preview overlay, snapping the window upon mouse release.

---

## 2. Functional Requirements

- **REQ-DRAG-001 (Global Mouse Drag Tracking)**:
  - The application must install global event monitors (`NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp])`) when accessibility permissions are granted.
  - Event processing during active mouse dragging must be throttled to 60fps (~16ms cadence) to prevent CPU spikes.
- **REQ-DRAG-002 (Snap Zone Geometry & Edge Detection)**:
  - The detection engine must evaluate cursor position against the active display's `visibleFrame`.
  - An edge threshold of $\le 4\text{px}$ from the display bounds triggers zone detection:
    - **Left Edge (middle 60%)**: `SnapTarget.leftHalf`
    - **Right Edge (middle 60%)**: `SnapTarget.rightHalf`
    - **Top Edge (middle 60%)**: `SnapTarget.maximize`
    - **Bottom Edge (middle 60%)**: `SnapTarget.bottomHalf`
    - **Top-Left Corner (top 20% / left 20%)**: `SnapTarget.topLeft`
    - **Top-Right Corner (top 20% / right 20%)**: `SnapTarget.topRight`
    - **Bottom-Left Corner (bottom 20% / left 20%)**: `SnapTarget.bottomLeft`
    - **Bottom-Right Corner (bottom 20% / right 20%)**: `SnapTarget.bottomRight`
- **REQ-DRAG-003 (Multi-Monitor Boundary Intelligence)**:
  - Detect whether an edge is adjacent to another display (Internal Adjacent Border) or touches empty space (Outer Boundary).
  - Outer screen boundaries trigger after a **100ms** dwell timeout.
  - Internal adjacent display borders trigger after a **250ms** dwell timeout, enabling smooth cross-display window transit without unintended snapping.
- **REQ-DRAG-004 (Liquid Glass HUD Preview Overlay)**:
  - The preview overlay (`SnapPreviewPanel`) must be an `NSPanel` configured with `.borderless`, `.nonactivatingPanel`, `level = .floating`, `ignoresMouseEvents = true`, and `isOpaque = false`.
  - Visual styling uses a translucent Liquid Glass appearance (`NSVisualEffectView` or SwiftUI glassmorphic card) with 10px corner radius and a 1.5px accent stroke (`Color.accentColor`).
  - Overlay smoothly fades in (150ms) and animates frame changes when moving between zones.
- **REQ-DRAG-005 (Release-to-Snap Execution)**:
  - Upon receiving `leftMouseUp` while a preview zone is active, the system immediately queries the frontmost `ManagedWindow`, dispatches the snap command to `SnapEngine`, and smoothly dismisses the preview overlay.
- **REQ-DRAG-006 (Cancel / Move-Away Dismissal)**:
  - Moving the cursor $> 20\text{px}$ away from the edge cancels active dwell timers and dismisses the overlay with a 150ms fade-out animation.

---

## 3. Non-Functional Requirements

- **NFR-DRAG-001 (Latency & Responsiveness)**: Edge detection and preview trigger latency $< 16\text{ms}$ after dwell threshold is reached.
- **NFR-DRAG-002 (Thread Safety & Concurrency)**: All AppKit UI interactions (`SnapPreviewPanel`, `NSAnimationContext`) must execute on `@MainActor`. Geometric calculations (`SnapDetector`) must be pure and `Sendable`.
- **NFR-DRAG-003 (Design System & Anti-AI-Slop)**: No unrequested rainbow gradients or heavy opaque cards; pure macOS native Liquid Glass blur with subtle system accent outline.

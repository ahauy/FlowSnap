# Feature Specification: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Feature**: `core-layout-snap-engine`
- **Slug**: `core-layout-snap-engine`
- **Epic**: `EPIC 02: Core Layout Calculation & Basic Snap Engine`
- **Target Sprint**: Sprint 1
- **Status**: Ready for Planning
- **Derived from**: [baseline.md](baseline.md) (SIGNED-OFF v1.0)

---

## 1. Feature Overview

FlowSnap requires a robust, hardware-independent geometric calculation engine (`LayoutEngine`) and snap coordinator (`SnapEngine`). While `US-SNAP-001` provided window discovery and metadata inspection, `US-SNAP-002` implements the mathematical brain that calculates target window frames for standard screen partitions (Halves, Quarters, Maximize) and tracks pre-snap frames for reliable window restoration.

Key objectives:

1. Pure mathematical calculation for 9 standard zones (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, 4 corner quarters, and `maximize`) relative to any display's visible bounds.
2. Exact odd-pixel distribution using flooring policy (`BR-LAYOUT-002`) to guarantee 0px gap and 0px screen boundary overflow on any resolution.
3. Thread-safe pre-snap frame caching in `WindowRegistry` (`BR-LAYOUT-004`) to support single-step restoration back to the original user-dragged position, even after multiple consecutive snap operations.
4. Graceful handling of application minimum window sizes (`BR-LAYOUT-005`) by anchoring to the zone boundary and expanding inward toward screen center.
5. Interactive verification controls in `FlowSnapLab` (`[Snap Left]`, `[Snap Right]`, `[Maximize]`, `[Restore]`).

---

## 2. Functional Requirements

### **REQ-LAYOUT-001: Standard Halves & Quarters Layout Computation**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-LAYOUT-001`, `BR-LAYOUT-003`, `ASM-LAYOUT-001`
- The system must provide pure functions in `LayoutEngine` computing concrete `CGRect` frames for:
  - `leftHalf` (left 50%, full visible height)
  - `rightHalf` (right 50%, full visible height)
  - `topHalf` (top 50%, full visible width)
  - `bottomHalf` (bottom 50%, full visible width)
  - `topLeft`, `topRight`, `bottomLeft`, `bottomRight` (each 25% of visible area: 50% width by 50% height)
  - `maximize` (100% of visible area)

### **REQ-LAYOUT-002: Odd-Pixel Dimension Flooring Policy**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-LAYOUT-002`, `ASM-LAYOUT-002`
- When screen dimensions (width or height) contain an odd number of pixels:
  - The primary partition (left or top) must receive $\lfloor \text{dimension} / 2.0 \rfloor$.
  - The adjacent partition (right or bottom) must receive $\text{dimension} - \lfloor \text{dimension} / 2.0 \rfloor$.
  - Invariant: Primary width/height + Adjacent width/height must exactly equal the available dimension.

### **REQ-LAYOUT-003: Visible Bounds Boundary Isolation**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-LAYOUT-001`, `ASM-LAYOUT-001`
- All target frames must be calculated within the provided `visibleFrame` (display bounds minus macOS Menu Bar and Dock).
- Target frame origins must be offset by `visibleFrame.origin.x` and `visibleFrame.origin.y`.

### **REQ-LAYOUT-004: Pre-Snap Frame Preservation & Single-Step Restore**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-LAYOUT-004`, `ASM-LAYOUT-003`
- Before applying the first snap to a window, `SnapEngine` must record the current frame in `WindowRegistry`.
- If the window undergoes additional consecutive snaps (e.g. Left -> Right -> Maximize), the initial pre-snap frame must remain unmodified.
- When `restore` is triggered, `SnapEngine` must retrieve the initial frame and clear the stored entry.
- If no pre-snap frame is recorded, `restore` must safely return `nil` (no-op).

### **REQ-LAYOUT-005: Minimum Window Size Clamping & Anchoring**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-LAYOUT-005`, `ASM-LAYOUT-004`
- If an application window has a minimum width or height larger than the computed zone size:
  - Width and height must be clamped to `max(calculated, minSize)`.
  - The window origin must anchor to the requested screen edge/corner so the window never extends off-screen.

---

## 3. User Scenarios & Acceptance Criteria

### Scenario 1: Halves and Quarters on Even Resolution (1920x1080)

- **Given** visible bounds `(0, 0, 1920, 1080)`
- **When** `LayoutEngine.frame(for: .leftHalf, in: bounds)` is evaluated
- **Then** the frame is `(0, 0, 960, 1080)`
- **When** `LayoutEngine.frame(for: .bottomRight, in: bounds)` is evaluated
- **Then** the frame is `(960, 540, 960, 540)`

### Scenario 2: Odd-Pixel Dimension (1441x901)

- **Given** visible bounds `(0, 0, 1441, 901)`
- **When** `leftHalf` and `rightHalf` are evaluated
- **Then** `leftHalf` is `(0, 0, 720, 901)` and `rightHalf` is `(720, 0, 721, 901)`
- **And** the sum of widths is `1441` with zero gap

### Scenario 3: Maximize with Offset Menu Bar & Dock

- **Given** visible bounds `(0, 25, 1440, 875)`
- **When** `maximize` is evaluated
- **Then** the frame matches `(0, 25, 1440, 875)` exactly

### Scenario 4: Consecutive Snaps and Restore

- **Given** a window at `(100, 100, 600, 400)`
- **When** the user snaps to Left Half, then to Maximize
- **Then** the pre-snap frame stored in `WindowRegistry` remains `(100, 100, 600, 400)`
- **When** the user executes Restore
- **Then** the target frame returned is `(100, 100, 600, 400)` and the registry entry is cleared

---

## 4. Success Criteria

1. **Performance**: Layout calculation execution time < 0.1ms per frame (pure in-memory math).
2. **Precision**: 100% pixel-perfect accuracy on all tested resolutions (no sub-pixel gaps or off-screen overflows).
3. **Purity**: Zero dependencies on AppKit or AXUIElement inside `LayoutEngine`.
4. **Test Coverage**: 100% test coverage across 5 display profiles and edge cases.

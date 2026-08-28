# Feature Specification: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature**: `display-aware-manipulation`
- **Slug**: `display-aware-manipulation`
- **Epic**: `EPIC 03: Display-Aware Coordinate System & Multi-Monitor Support`
- **Target Sprint**: Sprint 1
- **Status**: Ready for Planning
- **Derived from**: [baseline.md](baseline.md) (SIGNED-OFF v1.0)

---

## 1. Feature Overview

In a multi-monitor macOS environment, applications and windows reside in a global display topology that can span multiple screens arranged horizontally, vertically, diagonally, or in mirrored configurations with varying Retina scale factors (1x vs 2x).

The central technical challenge is bridging the two opposing global coordinate systems on macOS:

1. **AppKit (`NSScreen`)**: Origin `(0, 0)` is at the **bottom-left** of the Primary Screen; Y coordinates increase **upward**.
2. **Accessibility API (`AXUIElement`)**: Origin `(0, 0)` is at the **top-left** of the Primary Screen; Y coordinates increase **downward**.

`US-SNAP-003` delivers a robust display management architecture:

- **`Display`**: An immutable, Sendable domain model capturing display geometry, ID, and primary status.
- **`CoordinateTransformer`**: A pure, stateless mathematical involution performing bidirectional AppKit $\leftrightarrow$ AX coordinate mapping.
- **`DisplayManaging` / `DisplayManager`**: A mockable protocol and AppKit adapter tracking connected screens, handling screen changes, coalescing mirrors, and providing spatial lookups.
- **Display-Aware `SnapEngine`**: Coordinates target display resolution and coordinate inversion so snap operations place windows cleanly on the correct monitor.

---

## 2. Functional Requirements

### **REQ-DISP-001: Enhanced `Display` Domain Model**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-001`, `ASM-DISP-001`
- The `Display` struct must expose:
  - `id: CGDirectDisplayID`
  - `frame: CGRect` (AppKit global points)
  - `visibleFrame: CGRect` (Usable points excluding Dock and Menu Bar)
  - `scaleFactor: CGFloat` (Retina scaling)
  - `isPrimary: Bool` (True when `frame.origin == .zero`)

### **REQ-DISP-002: Pure Coordinate Inversion Involution**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-001`, `BR-DISP-003`, `BR-DISP-007`
- `CoordinateTransformer` must provide pure, static functions:
  - `toAX(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect`
  - `toAppKit(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect`
  - `toAX(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint`
  - `toAppKit(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint`
- Mathematical Invariant:
  $$Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$$
  $$Y_{AppKit} = H_{Primary} - (Y_{AX} + Height)$$
- Double application must reproduce original inputs exactly (`toAppKit(toAX(R, H), H) == R`) with sub-pixel floating point precision.

### **REQ-DISP-003: Target Display Resolution (Maximum Overlap)**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-002`, `ASM-DISP-003`, `ASM-DISP-004`
- For a given window frame `W`:
  1. Calculate intersection area with each connected display: $A_i = \text{area}(\text{CGRectIntersection}(W, D_i.\text{frame}))$.
  2. Select display with $\max(A_i)$ where $A_i > 0$.
  3. If all $A_i = 0$ (window off-screen): fallback to the display containing current mouse cursor location.
  4. If cursor is also outside known displays: fallback to `primaryDisplay`.

### **REQ-DISP-004: Reactive Screen Parameter Reconfiguration**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-004`, `ASM-DISP-005`
- `DisplayManager` must observe `NSApplication.didChangeScreenParametersNotification`.
- When triggered, it re-queries `NSScreen.screens` and updates cached displays asynchronously without moving windows automatically.

### **REQ-DISP-005: Mirrored Display Coalescing**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-005`, `ASM-DISP-006`
- When displays are mirrored (`CGDisplayIsInMirrorSet`), secondary mirrored screens must be filtered out, leaving only the primary active mirror master in the `displays` list.

### **REQ-DISP-006: Cyclic Display Navigation**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-DISP-006`, `ASM-DISP-007`
- `nextDisplay(after: Display)` must return the subsequent display in index order, wrapping around ($0 \to 1 \to \dots \to 0$).
- If only 1 display is connected, return `nil`.

---

## 3. Non-Functional Requirements (NFRs)

- **Performance**: Coordinate transformations must execute in $< 0.01\text{ms}$ (pure CPU arithmetic, zero heap allocation).
- **Concurrency**: Strict Swift 6 compliance. `DisplayManaging` methods are `async` and thread-safe.
- **Zero Private APIs**: Only standard public APIs (`NSScreen`, `CGDirectDisplayID`, `CGDisplayMirrorsDisplay`, CoreGraphics).

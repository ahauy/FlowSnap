# User Stories: Core Layout Calculation & Basic Snap Engine

- **Feature Slug**: `core-layout-snap-engine`
- **Parent Epic**: `EPIC 02: Core Layout Calculation & Basic Snap Engine`

---

### US-SNAP-002: Pure Layout Calculation & Snap Engine

**As a** macOS user  
**I want to** snap windows to halves, quarters, and full screen, and restore them to their pre-snap positions  
**So that** I can organize my desktop instantly with deterministic, pixel-perfect accuracy

**Traces to**: `REQ-LAYOUT-001`, `REQ-LAYOUT-002`, `REQ-LAYOUT-003`, `REQ-LAYOUT-004`, `REQ-LAYOUT-005`

---

#### Scenario 1 (Happy Path: Halves and Quarters on Even Resolution)

- **Given** a display with visible bounds of width 1920 and height 1080
- **When** `LayoutEngine.frame(for: .leftHalf, in: bounds, gap: 0)` is invoked
- **Then** the returned frame has origin `(0, 0)`, width `960`, and height `1080`
- **And** `LayoutEngine.frame(for: .topRight, in: bounds, gap: 0)` has origin `(960, 0)`, width `960`, and height `540`

#### Scenario 2 (Happy Path: Odd-Pixel Screen Dimension Distribution)

- **Given** a display with visible bounds of width 1441 and height 901
- **When** `LayoutEngine.frame(for: .leftHalf, in: bounds, gap: 0)` and `LayoutEngine.frame(for: .rightHalf, in: bounds, gap: 0)` are computed
- **Then** the left frame has width `720` (`floor(1441 / 2)`)
- **And** the right frame has origin x `720` and width `721` (`1441 - 720`)
- **And** the sum of left width and right width equals `1441` with zero pixel gap or overflow

#### Scenario 3 (Happy Path: Maximize to Full Visible Area)

- **Given** a display with visible frame origin `(0, 25)` (accounting for Menu Bar) and size `(1440, 875)` (accounting for Dock)
- **When** `LayoutEngine.frame(for: .maximize, in: bounds, gap: 0)` is computed
- **Then** the returned frame matches `(0, 25, 1440, 875)` exactly

#### Scenario 4 (Stateful Flow: Consecutive Snapping and Single-Step Restore)

- **Given** a managed window currently positioned at `(200, 150, 800, 600)`
- **When** the user snaps the window to Left Half, then Right Half, then Maximize
- **Then** `WindowRegistry` records `(200, 150, 800, 600)` upon the first snap and does NOT overwrite it during subsequent snaps
- **When** the user triggers the Restore action
- **Then** the window returns to `(200, 150, 800, 600)` and the stored pre-snap frame is cleared from `WindowRegistry`

#### Scenario 5 (Edge Case: Restore on Window Without Prior Snap)

- **Given** a managed window that has never been snapped
- **When** the user triggers Restore
- **Then** the system recognizes no pre-snap frame exists, performs no resizing, and returns nil without error

#### Scenario 6 (Edge Case: Minimum App Size Exceeds Quarter Zone)

- **Given** an application window with a minimum size of `500 x 400`
- **When** the window is snapped to the Bottom-Right quarter on a `1440 x 900` display (where zone is `720 x 450`)
- **Then** the width is `720` and height is `450` (since `720 >= 500` and `450 >= 400`)
- **When** the window is snapped on a smaller `800 x 600` display (quarter zone is `400 x 300`)
- **Then** the window dimensions clamp to `500 x 400` and its origin anchors to the bottom-right corner `(300, 200)`

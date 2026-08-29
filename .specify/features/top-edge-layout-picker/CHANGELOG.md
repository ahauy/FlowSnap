# Changelog: Top-Edge Snap Layout Picker (US-SNAP-007)

All notable changes to the `top-edge-layout-picker` feature will be documented in this file.

## [1.0.0] - 2026-08-29

### Added

- **Domain Models & Enums**:
  - Added 5 new `SnapTarget` / `LayoutZone` partition cases: `.leftTwoThirds` (70%), `.rightOneThird` (30%), `.leftThird` (33.3%), `.centerThird` (33.4%), `.rightThird` (33.3%).
  - Created `LayoutTemplate` and `LayoutSlot` domain entities with standard Windows 11 presets (2-Column Equal, 2-Column 70/30, 3-Column 1/3, 4-Quarters).
  - Defined `SnapLayoutPickerManaging` protocol for non-activating panel presentation and hit-testing.
- **Core Layout & Detection**:
  - Implemented exact pixel arithmetic for asymmetric 70/30 and 3-column splits in `LayoutEngine`.
  - Added `isTopCenterZone` detection in `SnapDetector` (middle 40% screen width, top 24px threshold).
- **UI & Presentation**:
  - Built `SnapLayoutPickerView` (SwiftUI) rendering 4 glassmorphic layout cards with interactive hover effects.
  - Implemented `SnapLayoutPickerPanel` (NSPanel non-activating, Liquid Glass material, floating level).
  - Implemented `SnapLayoutPickerManager` for presentation animations and coordinate hit-testing.
- **Coordinator & DI Integration**:
  - Integrated `SnapLayoutPickerManaging` into `DragToSnapCoordinator` and wired in `AppDependencies`.
  - Synchronized slot hover with full-screen `SnapPreviewPanel` HUD overlay.
- **Testing & Tooling**:
  - Added unit test suites for `LayoutEngine`, `SnapDetector`, `SnapLayoutPickerManager`, and `DragToSnapCoordinator`.
  - Added visual test controls in `FlowSnapLabApp`.
  - Created `SnapLayoutPickerSnapshotRenderer` producing verified PNG screenshots.

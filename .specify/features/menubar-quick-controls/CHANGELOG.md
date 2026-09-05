# Changelog: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

## [1.1.0] - 2026-09-04

### Added

- **Visual Snap Grid**: Interactive visual canvas preview for instant 1-touch window snapping in Menu Bar (`REQ-MENU-007`).
- **Compact Sections**: Limited Presets & Workspaces to ≤ 3-4 items with direct Settings navigation (`REQ-MENU-008`).
- **Modern Settings NavigationSplitView**: Revamped Settings window with sidebar navigation, grouped cards, scrollable view, and zero layout clipping (`REQ-MENU-009`).

## [1.0.0] - 2026-08-28

### Added

- **Domain**: Created `MenuBarAction` enum with 10 canonical snap actions, icon names, shortcut badges, and `SnapTarget` mappings.
- **UI & State**: Implemented `MenuBarViewModel` with `@Observable` and `@MainActor` isolation managing Accessibility trust, target window tracking, and command dispatch with auto-dismiss.
- **UI Component**: Built `MenuBarView` with native macOS aesthetics, permission warning banner with direct deep-link, and 2-column snap action grid.
- **App Lifecycle**: Configured `FlowSnapApp` with `MenuBarExtra("FlowSnap", ...).menuBarExtraStyle(.window)` and wired `menuBarViewModel` in `AppDependencies`.
- **Tests**: Created `MenuBarViewModelTests` testing permission state reactions, snap dispatch routing, direct settings delegation, and action badge mappings (`5/5` tests passing).

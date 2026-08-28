# Changelog: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

## [1.0.0] - 2026-08-28

### Added

- **Domain**: Created `MenuBarAction` enum with 10 canonical snap actions, icon names, shortcut badges, and `SnapTarget` mappings.
- **UI & State**: Implemented `MenuBarViewModel` with `@Observable` and `@MainActor` isolation managing Accessibility trust, target window tracking, and command dispatch with auto-dismiss.
- **UI Component**: Built `MenuBarView` with native macOS aesthetics, permission warning banner with direct deep-link, and 2-column snap action grid.
- **App Lifecycle**: Configured `FlowSnapApp` with `MenuBarExtra("FlowSnap", ...).menuBarExtraStyle(.window)` and wired `menuBarViewModel` in `AppDependencies`.
- **Tests**: Created `MenuBarViewModelTests` testing permission state reactions, snap dispatch routing, direct settings delegation, and action badge mappings (`5/5` tests passing).

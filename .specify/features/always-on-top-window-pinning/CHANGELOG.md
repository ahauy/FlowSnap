# Changelog: US-SNAP-021 Universal Always-On-Top Window Pinning & Stage Manager Launch Co-existence

## [1.0.0] - 2026-09-04

### Added

- **Domain Protocols & Value Types**:
  - `PinnedWindowRecord.swift`: Model for tracked pinned windows (`id`, `pid`, `bundleIdentifier`, `title`, `pinnedAt`).
  - `WindowPinningCoordinating.swift`: Contract protocol for always-on-top pinning and focus re-assertion.
  - `StageManagerLaunchCoordinating.swift`: Contract protocol for Stage Manager launch co-existence.
- **Core & Infrastructure Implementation**:
  - `WindowPinningCoordinator.swift`: Public AX-based coordinator managing dynamic LIFO Z-stacking, workspace activation notifications via `TokenBox`, `kAXRaiseAction` re-assertion, and system modal safety exemption (`SecurityAgent`, `CoreAuthUI`).
  - `StageManagerLaunchCoordinator.swift`: Launch observation coordinator using `ApplicationObserver` to preserve Stage Manager multi-window cohesion without sidebar ejection.
  - `PreferencesStore.swift`: Added `isStageManagerLaunchCoexistenceEnabled` preference.
- **Command Dispatcher & UI Controls**:
  - `WindowCommand.swift`: Added `.togglePinFocusedWindow`.
  - `ShortcutAction.swift`: Added `.togglePinFocusedWindow` (`⌃⌥P` default).
  - `CommandDispatcher.swift`: Wired `.togglePinFocusedWindow` execution.
  - `MenuBarViewModel.swift` & `MenuBarView.swift`: Added pinned windows list and unpin controls to the Menu Bar dropdown.
  - `GeneralSettingsView.swift`: Added toggle for Stage Manager launch co-existence.
  - `AppDependencies.swift`: Wired coordinators into DI container.
- **Test Double & Unit Test Suites**:
  - `MockWindowPinningCoordinator.swift` & `MockStageManagerLaunchCoordinator.swift`.
  - `WindowPinningCoordinatorTests.swift`: 8 test cases covering `TC-PIN-001` through `TC-PIN-008`.
  - `StageManagerLaunchCoordinatorTests.swift`: Test case covering `TC-PIN-009`.
- **Architectural & Technical Documentation**:
  - `adr/0015-always-on-top-window-pinning.md`.
  - `docs/features/always-on-top-window-pinning/README.md`.
  - `docs/user-guides/always-on-top-window-pinning.md`.

### Fixed

- Concurrency race condition in `MockApplicationLaunching` resolved using thread-safe `NSLock` synchronization.
- Swift 6 strict concurrency nonisolated deinit warnings resolved using thread-safe `TokenBox` pattern in `WindowPinningCoordinator` and `StageManagerLaunchCoordinator`.

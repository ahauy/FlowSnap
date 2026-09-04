# Changelog: US-SNAP-022 Quake-Style Quick Scratchpad & Instant Window Toggle

## [1.0.0] - 2026-09-04

### Added

- **Domain Protocols & Value Types**:
  - `ScratchpadRecord.swift`: Model for tracked scratchpad window (`windowID`, `pid`, `bundleID`, `appName`, `windowTitle`, `assignedAt`).
  - `ScratchpadState.swift`: State enum representing `.unassigned`, `.visible(record:)`, `.hidden(record:)`.
  - `PreSummonFocus.swift`: Model snapshotting the frontmost process and window before summoning.
  - `ScratchpadCoordinating.swift`: Contract protocol for quick scratchpad assignment, summon, dismiss, and detach.
- **Core & Infrastructure Implementation**:
  - `ScratchpadCoordinator.swift`: Public AX-based coordinator managing overlay lifecycle, sub-50ms instant summon, hybrid dismiss (process hide for single-window, de-activate/layer lower for multi-window), focus restoration to `PreSummonFocus`, ESC/blur event monitoring, and automatic lifecycle detach on app termination.
  - `PreferencesStore.swift`: Added `isScratchpadDismissOnBlurEnabled` and `isScratchpadDismissOnEscEnabled` preferences with setters.
- **Command Dispatcher & UI Controls**:
  - `WindowCommand.swift`: Added `.toggleScratchpad` and `.assignScratchpad`.
  - `ShortcutAction.swift`: Added `.toggleScratchpad` (`⌥Space` default) and `.assignScratchpad` (`⌃⌥Space` default), plus `.scratchpad` category.
  - `CommandDispatcher.swift`: Wired `.toggleScratchpad` and `.assignScratchpad` execution.
  - `MenuBarViewModel.swift` & `MenuBarView.swift`: Added Quick Scratchpad section with active status, Toggle (`⌥Space`), Assign (`⌃⌥Space`), and Detach controls.
  - `GeneralSettingsView.swift`: Added toggles for "Dismiss on ESC key" and "Dismiss when clicking outside".
  - `AppDependencies.swift`: Wired `ScratchpadCoordinator` into DI container.
- **Test Double & Unit Test Suites**:
  - `MockScratchpadCoordinator.swift`: Mock double implementing `ScratchpadCoordinating`.
  - `ScratchpadCoordinatorTests.swift`: 12 comprehensive unit tests covering `TC-SCRATCH-001` through `TC-SCRATCH-012`.
  - `MenuBarViewModelTests.swift`: Added unit test asserting detach action updates state and coordinator.
- **Architectural & Technical Documentation**:
  - `adr/0016-quake-scratchpad-instant-toggle.md`.
  - `docs/features/quake-scratchpad-instant-toggle/README.md`.
  - `docs/user-guides/quake-scratchpad-instant-toggle.md`.

# Changelog: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-018)

## [1.0.0] - 2026-09-03

### Added

- **3-Tier Fullscreen Escape Architecture**:
  - `Tier 0` (`.attributeWrite`): Fast path via `AXFullscreen`/`AXFullScreen` attribute write (≤5ms).
  - `Tier 1` (`.axButtonPress`): Interactively executes `kAXPressAction` on `kAXFullScreenButtonAttribute` for Electron and Chromium apps without focus stealing.
  - `Tier 2` (`.cgEventShortcut`): Target PID activation with synthesized `Control + Command + F` via `CGEventPosting`.
- **Domain & Protocol Seams**:
  - `FullScreenEscapeTier`: Enum representing escape tier strategy.
  - `FullScreenEscapeResult`: Telemetry model tracking exit status, tier used, duration in milliseconds, and error messages.
  - `FullScreenEscapeCoordinating`: Concurrency-safe protocol for escape coordination.
  - `CGEventPosting`: System & Mock abstractions for CoreGraphics keystroke synthesis.
- **Adaptive Polling Space Waiting**:
  - Replaces static 700ms sleep with a 100ms interval polling loop up to an 800ms ceiling.
  - Early exit as soon as window frame / state leaves full screen space.
- **Unit & Integration Tests**:
  - Complete coverage across all 3 tiers, early polling exit, ceiling timeout, and `WindowManager.move` integration (392/392 tests pass).

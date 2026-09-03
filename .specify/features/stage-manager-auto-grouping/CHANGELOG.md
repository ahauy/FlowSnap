# Changelog: stage-manager-auto-grouping (US-WORK-018)

## [1.0.0] - 2026-09-03

### Added

- `StageManagerDetecting` protocol and `StageManagerDetector` infrastructure querying `com.apple.WindowManager GloballyEnabled`.
- `AccessibilityServing.raise(window:)` and `raise(element:)` via `kAXRaiseAction`.
- `ApplicationLaunching.unhide(bundleID:)` for graceful hidden app unhiding without full activation.
- Smart Stage Coordination in `WorkspaceManager+Restore.swift`: Anchor App reveal, secondary app raise, and final primary keyboard focus lock (`BR-SMA-001` through `BR-SMA-005`).
- Comprehensive unit tests in `StageManagerDetectorTests.swift` and `WorkspaceManagerStageManagerTests.swift` covering `TC-SMA-001` to `TC-SMA-006`.
- Architectural decision record `adr/0013-stage-manager-auto-grouping.md`.
- Technical documentation `docs/features/stage-manager-auto-grouping/README.md`.
- End-user visual guide `docs/user-guides/stage-manager-auto-grouping.md` with retina `@2x` screenshots.

## [1.0.0-draft] - 2026-09-03

### Added

- Initial intake and tech context (`00-intake.md`, `00-tech-context.md`).
- Elicitation interview decisions (`01-elicitation.md`): `ASM-SMA-001`, `ASM-SMA-002`, `ASM-SMA-003`.
- Domain model and architecture specifications (`03-domain-model.md`): `BR-SMA-001` through `BR-SMA-005`.
- Risk register and MoSCoW scope lock (`04-risk-register.md`).
- User stories and acceptance scenarios (`05-user-stories.md`).
- Domain baseline draft (`baseline.md`).

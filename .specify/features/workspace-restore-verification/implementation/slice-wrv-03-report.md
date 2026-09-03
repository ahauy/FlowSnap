# SLICE-WRV-03 Report

## Scope

Updated restore-summary presentation and its UI consumers. The restore core and
Accessibility infrastructure were intentionally left untouched.

## Changes

- `RestoreSummaryBanner` now presents the placed count and separate
  failed/unverifiable/skipped groups with per-issue plain-language reasons.
- Compact Menu Bar mode keeps the existing concise headline; expanded Settings
  mode exposes the counters and issue groups.
- Added accessibility labeling for the dismiss action, hidden the decorative
  status icon from VoiceOver, marked group headings as headers, and added a
  stable banner identifier for UI inspection.
- `WorkspaceSettingsView` now uses the shared banner, preventing the Settings
  surface from rendering the legacy flat `details` list.
- `PresetResolver` now consumes the canonical `RestoreIssue` type and passes
  explicit empty failed/unverifiable collections while preserving its existing
  preset skip behavior.
- `WorkspaceViewModel` documentation now records that it mirrors all typed
  summary groups without introducing presentation logic.
- Added a UI contract regression test covering all typed outcome collections.

## Behavior preserved

- Banner remains non-modal and uses the existing caller-provided dismiss
  callback. Existing auto-dismiss/lifecycle wiring is unchanged.
- Existing localization strings and compact/expanded surface choices are
  retained; new static group/count labels use SwiftUI `LocalizedStringKey`
  literals, with no new notification system or cancel flow introduced.
- Restore diagnostics and window-placement behavior are out of scope for this
  slice.

## Verification

`xcodebuild ... -derivedDataPath /tmp/flowsnap-derived-data build
CODE_SIGNING_ALLOWED=NO` reached Swift compilation, including the changed
banner, Settings, ViewModel, PresetResolver, and test sources. The build could
not complete because the environment's Swift macro plugin server returned a
malformed `ObservationMacros.ObservableMacro` response (and CoreSimulator log
permissions were unavailable); no changed-file compiler error was reported.

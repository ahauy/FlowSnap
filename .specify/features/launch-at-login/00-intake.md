# Intake: Launch FlowSnap at Login Integration (SMAppService)

- **Date**: 2026-09-05
- **Story ID**: `US-SNAP-024`
- **Slug**: `launch-at-login`
- **Requested by**: PO / Backlog Roadmap (Sprint 7)
- **Classification**: Bounded Task (Effort: S, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 1 (`LaunchAtLoginStatus`, `LaunchAtLoginManaging` protocol)
  - Existing DB schema change: No (pure UserDefaults + SMAppService integration)
  - Screens/flows touched: 1 (`GeneralSettingsView` Launch Policy section)
  - User roles affected: 1 (Standard macOS desktop user)
  - Cross-cutting impact: Minimal (Lifecycle & Settings synchronization)
  - Estimated code lines: ~100–180 lines
  - Reversible: Yes
- **Protocol selected**: Bounded Task (Stage 1 Intake → Stage 2 Interactive Customer Interview Gate → Stage 4 Domain Modeling → Stage 5 Risk Scan → Stage 6 User Stories → Stage 7 Spec Validation → Stage 8 Handover)
- **Override**: None (matches Roadmap Effort: S)

## One-line problem statement

Users must currently launch FlowSnap manually after every reboot or login, and the existing `launchAtLogin` preference toggle is an inert `UserDefaults` boolean disconnected from Apple's modern `SMAppService.mainApp` system registration and two-way status synchronization.

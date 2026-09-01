# ADR-0007: Window Groups and Workspace Presets Architecture

- **Status**: Accepted
- **Date**: 2026-09-01
- **Feature**: `window-groups-presets` (US-WORK-012)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

Users require out-of-the-box workflow presets (Coding, Research, Writing, Design) that adapt gracefully to different installed software stacks and multi-monitor setups. Furthermore, power users need multiple windows to behave as a synchronized unit ("Window Group") during minimize, focus, and move operations, without introducing recursive feedback loops, dangling window handles, or violating macOS privacy and security policies.

## Decision

1. **Domain Template vs Live Instance Separation**:
   - `WorkspacePreset` represents an immutable template containing categorized slots (`PresetAppSlot`) with fallback chains (`preferredBundleIDs`), split ratios, and relative zone alignments.
   - Presets are decoupled from raw pixel coordinates and are dynamically resolved against the active display's `visibleBounds`.
2. **Smart App Fallback Engine (`PresetResolver`)**:
   - Evaluates slot candidates in prioritized order: (1) Running candidate app, (2) Installed candidate app via `NSWorkspace.urlForApplication(withBundleIdentifier:)` with asynchronous launch and ≤ 10.0s window polling, (3) Graceful skip with typed `SkipReason`.
3. **Synchronized Window Groups Coordinator (`WindowGroupManager`)**:
   - An isolated `@MainActor ObservableObject` managing ephemeral `WindowGroup` instances keyed by `Set<CGWindowID>`.
   - Enforces a minimum cardinality of 2 members; automatically auto-prunes destroyed windows via `kAXUIElementDestroyedNotification` and dissolves groups with < 2 members.
4. **Re-Entrancy Locking & Generation Token**:
   - `WindowGroupManager` employs an internal execution lock (`isSynchronizing` flag and `syncGeneration` counter) during group dispatch to ignore inbound AX echo notifications and prevent infinite cascade loops.
5. **Deterministic Z-Order on Group Focus**:
   - When focusing a group, background group members are raised first and the anchor/clicked window is raised last, guaranteeing the target window stays frontmost while all group windows rise together.
6. **Global Preset Hotkey Routing & Collision Prevention**:
   - `WindowCommand.restorePreset(String)` payload routed via `GlobalHotkeyManager` → `CommandDispatcher`.
   - `PreferencesStore` pre-validates proposed shortcuts against `ShortcutAction.allCases` and existing preset bindings, rejecting collisions with clear inline warnings.
7. **Zero Private API Policy**:
   - All window discoveries and frame mutations use strictly public `AXUIElement`, `NSWorkspace`, and AppKit APIs.

## Consequences

- **Positive**:
  - Out-of-the-box utility with zero manual configuration.
  - Resilient to varying developer tooling (VS Code, Xcode, JetBrains, Chrome, Safari).
  - Clean concurrency and zero data races under Swift 6 strict concurrency.
  - Safe, loop-free window grouping with automatic resource cleanup.
- **Negative / Constraints**:
  - Bounded 10s timeout on cold app launches.
  - Cross-Space window movements are restricted by macOS public API boundaries.

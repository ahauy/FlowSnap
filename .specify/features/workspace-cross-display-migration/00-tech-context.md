# Tech Context: FlowSnap (US-DISP-017)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1).
> This file is the single source of truth for tech-stack facts. Every subagent
> reads this file first; do not re-paste this blob into dispatch `task` arguments.

## Stack

- **language**: Swift 6.0 (strict concurrency: actors, `@MainActor`, `Sendable`)
- **frameworks**: SwiftUI + AppKit (macOS Native)
- **target platform**: macOS 14.0+ (Sonoma / Sequoia), Hardened Runtime enabled
- **architecture**: Domain-Driven Design (DDD) & Deep Modules
- **project generator**: XcodeGen (`project.yml`); targets: `FlowSnap`, `FlowSnapTests`, `FlowSnapLab`
- **storage**: `UserDefaults` (`PreferencesStore` with `@AppStorage` / Combine) + local JSON in `~/Library/Application Support/FlowSnap/`
- **test**: Swift Testing (`@Test`) + XCTest; protocol-based DI; mock doubles under `FlowSnapTests/Mocks/`
- **lint**: SwiftLint (`.swiftlint.yml`) — zero force unwrap / try / cast, file < 800 LOC, function < 50 LOC
- **code intelligence**: `code-review-graph` (uvx) — local Tree-sitter AST + SQLite graph

## Relevant Subsystems for US-DISP-017

- `Domain/`: `Workspace`, `WindowPlacement`, `ManagedWindow`, `Display`, `DisplayManaging`, `DisplayNavigator`, `RelativeFrameScaler`
- `Core/`: `WorkspaceManager` (`WorkspaceManager+Migration.swift`), `RelativeFrameScaler`, `AdaptiveDividerCoordinator`, `DisplayNavigator`
- `Infrastructure/`: `GlobalHotkeyManager`, `AXAccessibilityService`, `CursorWarping` / `CursorWarpService`
- `UI/`: `MenuBarView` / `MenuBarViewModel` (Quick Controls menu items for cross-display migration), `PreferencesStore` / Settings Shortcuts
- `Tests/`: `FlowSnapTests/Core/Workspace/WorkspaceMigrationTests.swift`, `FlowSnapTests/Core/Display/`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs**: Only public Accessibility API (`AXUIElementSetAttributeValue`, `kAXRaiseAction`, `AXUIElementPerformAction`) and public AppKit (`NSScreen`).
- **Proportional Scaling**: Preserve relative multi-window geometry and layout split ratios (e.g. 50/50, 70/30) via `RelativeFrameScaler`.
- **Atomic Multi-Window Ordering**: Apply 2-phase move ordering (shrink before expand) + staggered IPC to prevent window collision, viewport overflow, and Stage Manager auto-grouping detachment.
- **Adaptive Divider & Focus Handoff**: When a workspace moves from `sourceDisplay` to `targetDisplay`, the active divider (`AdaptiveDividerCoordinator`) and mouse cursor must seamlessly follow to the target display.
- **Single-Display Graceful No-op**: If `displays.count <= 1` or no active workspace is running on the focused display, migration must fail-soft / no-op with zero screen flicker.

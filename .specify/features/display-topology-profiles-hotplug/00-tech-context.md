# Tech Context: FlowSnap (US-DISP-016)

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

## Relevant Subsystems for US-DISP-016

- `Domain/`: `Display`, `DisplayTopology`, `TopologyFingerprint`, `ManagedWindow`, `WindowPlacement`, `Workspace`
- `Core/`: `DisplayManaging` / `DisplayManager`, `DisplayNavigator`, `RelativeFrameScaler`, `TopologyProfileManager`, `FrameClampingHelper`, `WorkspaceManager`
- `Infrastructure/`: `DisplayHotPlugObserver` (`NSApplication.didChangeScreenParametersNotification`), `AXAccessibilityService`, `WorkspaceStore`
- `UI/`: `SettingsView` (Display Topology tab / profiles section), `MenuBarView`
- `Tests/`: `FlowSnapTests/Core/Display/...`, `FlowSnapTests/Mocks/MockDisplayManager.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no undocumented CGS / SLS APIs. Public `NSScreen`, `CGDisplayCreateUUIDFromDisplayID`, `AXUIElement`, and CoreGraphics APIs only.
- **Zero Polling & Debounced Reactivity** — React to `NSApplication.didChangeScreenParametersNotification` with a debounce window (500ms - 1000ms) to coalesce transient display negotiation events during sleep/wake or cable plug.
- **Safe Frame Clamping** — When an external display is disconnected, windows must be clamped inside the primary display `visibleFrame` with minimum margins so title bars are never pushed off-screen or under the Menu Bar/Dock.
- **Strict Coordinate Inversion** — AppKit bottom-left origin vs AX top-left origin conversion must use `CoordinateTransformer`.
- **Swift 6 Strict Concurrency** — 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

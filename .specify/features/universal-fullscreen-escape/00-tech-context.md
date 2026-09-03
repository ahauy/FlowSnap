# Tech Context: FlowSnap (US-WORK-018)

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

## Relevant Subsystems for US-WORK-018

- `Domain/`: `ManagedWindow`, `WindowKind` (.fullscreen), `WindowPlacement`, `Workspace`
- `Core/`: `WindowManaging` / `WindowManager`, `WorkspaceManager` (`WorkspaceManager+Restore`), `CoordinateTransformer`
- `Infrastructure/`: `AccessibilityServing` / `AXAccessibilityService` (`exitFullScreen`), `CGEvent` keyboard dispatch, `WorkspaceStore`
- `Tests/`: `FlowSnapTests/Infrastructure/AXAccessibilityServiceTests.swift`, `FlowSnapTests/Core/Window/WindowManagerTests.swift`, `FlowSnapTests/Mocks/MockAccessibilityService.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no undocumented CGS / SLS APIs. Public `AXUIElement`, `kAXFullScreenButtonAttribute`, `kAXPressAction`, and `CGEvent` APIs only.
- **Two-Tier Resilient Fullscreen Escape**:
  - Tier 1: Interactive AX Zoom/FullScreen Button press (`kAXFullScreenButtonAttribute` + `kAXPressAction`).
  - Tier 2: Synthesized standard macOS Fullscreen toggle shortcut (`⌃ + ⌘ + F`) directed to target process PID via `CGEvent`.
- **Zero Race Conditions on Space Transition**: Wait for macOS fullscreen exit animation and Space transition (debounce / notification / animation duration budget 700ms) before executing subsequent `setFrame` calls.
- **Swift 6 Strict Concurrency**: 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

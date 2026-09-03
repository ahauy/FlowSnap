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

- `Domain/`: `ManagedWindow`, `WindowPlacement`, `Workspace`, `StageManagerCoordinating` / domain contracts
- `Core/`: `WorkspaceManager` (`WorkspaceManager+Restore`), `WindowManaging`, `LayoutEngine`
- `Infrastructure/`: `StageManagerDetector` / `StageManagerCoordinating`, `AccessibilityServing` / `AXAccessibilityService` (`kAXRaiseAction`), `AppLauncher` (`reveal` / `activate`)
- `Tests/`: `FlowSnapTests/Core/Workspace/WorkspaceManagerTests.swift`, `FlowSnapTests/Infrastructure/StageManagerDetectorTests.swift`, `FlowSnapTests/Mocks/MockStageManagerDetector.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no undocumented CGS / SLS APIs (e.g. no private CGSSetWindowSpaces). Use `defaults read com.apple.WindowManager GloballyEnabled` / `CFPreferences` and public Accessibility APIs (`kAXRaiseAction`, `AXUIElementPerformAction`).
- **Smart Stage Coordination**:
  - Detect if Stage Manager is active (`GloballyEnabled == true`).
  - When Stage Manager is ON, standard sequential `app.activate(options: [.activateAllWindows])` causes macOS to eject previous apps from the current Stage into the sidebar thumbnail strip.
  - FlowSnap must coordinate multi-window placement into a single cohesive Stage using primary activation + secondary window raise (`kAXRaiseAction`) without triggering Stage switching.
- **Swift 6 Strict Concurrency**: 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

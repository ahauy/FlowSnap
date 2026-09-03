# Tech Context: FlowSnap (US-WORK-014)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1).
> This file is the single source of truth for tech-stack facts. Every subagent
> reads this file first; do not re-paste this blob into dispatch `task` arguments.

## Stack

- **language**: Swift 6.0 (strict concurrency: actors, `@MainActor`, `Sendable`)
- **frameworks**: SwiftUI + AppKit (macOS Native)
- **target platform**: macOS 14.0+ (Sonoma / Sequoia), Hardened Runtime enabled
- **architecture**: Domain-Driven Design (DDD) & Deep Modules
- **project generator**: XcodeGen (`project.yml`); targets: `FlowSnap`, `FlowSnapTests`, `FlowSnapLab`
- **storage**: `UserDefaults` (`PreferencesStore` with `@AppStorage` / Combine) + local JSON in `~/Library/Application Support/FlowSnap/` (atomic file writes)
- **test**: Swift Testing (`@Test`) + XCTest; protocol-based DI; mock doubles under `FlowSnapTests/Mocks/`
- **lint**: SwiftLint (`.swiftlint.yml`) — zero force unwrap / try / cast, file < 800 LOC, function < 50 LOC
- **code intelligence**: `code-review-graph` (uvx) — local Tree-sitter AST + SQLite graph

## Relevant Subsystems for US-WORK-014

- `Domain/`: `WindowPolicy` enum (expand with full cases & parameters), `WindowKind`, `ManagedWindow`, `LayoutZone`
- `Core/`: `WindowPolicyManager` (implement `.floating`, `.rememberPosition`, `.assignedLayout`, priority precedence, persistent policy mapping), `EventBus` (window event dispatching), `WindowManager`, `SnapEngine`
- `Infrastructure/`: `PreferencesStore` (persisting user per-app rules and remembered window frames), `AccessibilityService`, `DisplayManager`, `ApplicationObserver`, `WorkspaceObserver`
- `UI/`: `ApplicationRulesView.swift` (replace static mock with live binding to `WindowPolicyManager` / `PreferencesStore`, app picker from `/Applications` / running apps, policy picker), `SettingsView.swift`
- `App/`: `AppDependencies` (inject store/manager to UI), `AppDelegate`
- `Tests`: `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`, `FlowSnapTests/Mocks/`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no CGS / SLS undocumented symbols. Public `NSWorkspace` + `AXUIElement` only.
- **Zero Polling** — `CPU Idle: 0.0%` mandate; event-driven 100% via `EventBus` + `AXObserver` callbacks.
- **Async Observation Pattern** — AXObserver callbacks bridge to `@MainActor` via `Task { @MainActor in }`.
- **Atomic Persistence** — rules saved cleanly via `PreferencesStore` or atomic JSON, resilient against corrupt files.
- **Swift 6 Strict Concurrency** — zero warnings on `Sendable`, `actor isolation`, data races.
- **Public API Surface Stability** — keep deep modules clean; minimal public interfaces.

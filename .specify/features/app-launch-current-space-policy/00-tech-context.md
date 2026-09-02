# Tech Context: FlowSnap (US-WORK-013)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1).
> This file is the single source of truth for tech-stack facts. Every subagent
> reads this file first; do not re-paste this blob into dispatch `task` arguments.

## Stack

- **language**: Swift 6.0 (strict concurrency: actors, `@MainActor`, `Sendable`)
- **frameworks**: SwiftUI + AppKit (macOS Native)
- **target platform**: macOS 14.0+ (Sonoma / Sequoia), Hardened Runtime enabled
- **architecture**: Domain-Driven Design (DDD) & Deep Modules
- **project generator**: XcodeGen (`project.yml`); targets: `FlowSnap`, `FlowSnapTests`, `FlowSnapLab`
- **storage**: `UserDefaults` (`PreferencesStore` with `@AppStorage`) + local JSON in `~/Library/Application Support/FlowSnap/` (atomic file writes)
- **test**: Swift Testing (`@Test`) + XCTest; protocol-based DI; mock doubles under `FlowSnapTests/Mocks/`
- **lint**: SwiftLint (`.swiftlint.yml`) — zero force unwrap / try / cast, file < 800 LOC, function < 50 LOC
- **code intelligence**: `code-review-graph` (uvx) — local Tree-sitter AST + SQLite graph

## Relevant Subsystems for US-WORK-013

- `Domain/`: `WindowPolicy` enum (existing), `WindowKind`, `ManagedWindow`
- `Core/`: `WindowPolicyManager` (stub to be implemented), `EventBus` (existing pub-sub), `WorkspaceManager` (existing)
- `Infrastructure/`: `ApplicationObserver` (NEW), `WorkspaceObserver` (existing stub), `AccessibilityService`, `DisplayManager`
- `App/`: `AppDependencies` (DI root), `AppDelegate` (observer wiring)
- Tests: `FlowSnapTests/Core/WindowPolicy/`, `FlowSnapTests/Mocks/MockApplicationObserver.swift` (NEW)

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no CGS / SLS undocumented symbols. Public `NSWorkspace` + `AXObserver` only.
- **Zero Polling** — `CPU Idle: 0.0%` mandate; event-driven 100% via `EventBus` + `AXObserver` callbacks.
- **Async Observation Pattern** — AXObserver C-callback must bridge to `@MainActor` via `Task { @MainActor in }`. The callback context is `Sendable`.
- **Atomic File Writes** — `WorkspaceStore` pattern: temp file + `rename(2)`; never partial JSON.
- **Swift 6 Strict Concurrency** — zero warnings on `Sendable`, `actor isolation`, data races.
- **Public API Surface Stability** — changes ripple to `AccessibilityServing`, `DisplayManaging`, `EventBus` protocols.

## Out of Scope for US-WORK-013

- `PreferencesStore` integration for policies (reserved for US-WORK-014 — Per-App Rules).
- UI for the Application Rules tab (mockup already exists; wiring deferred to US-WORK-014).
- Cross-Space intent workspace restoration (deferred to US-WORK-014).

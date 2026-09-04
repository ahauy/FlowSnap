# Tech Context: FlowSnap (US-SNAP-021)

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

## Relevant Subsystems for US-SNAP-021

- `Domain/`: `ManagedWindow`, `WindowPlacement`, `StageManagerCoordinating`, `WindowPinningCoordinating`
- `Core/`: `WindowPinningCoordinator`, `WindowPolicyManager`, `SmartFocusStack`, `WorkspaceManager`
- `Infrastructure/`: `StageManagerLaunchCoordinator`, `StageManagerDetector`, `AccessibilityServing` / `AXAccessibilityService` (`kAXRaiseAction`, `kAXFocusedWindowChangedNotification`), `ApplicationObserver`
- `Hotkeys/`: `GlobalHotkeyManager`, `KeyboardShortcut`, `ShortcutAction`
- `UI/`: `MenuBarViewModel`, `MenuBarView`, `SettingsView`, `PreferencesStore`
- `Tests/`: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`, `FlowSnapTests/Infrastructure/StageManagerLaunchCoordinatorTests.swift`, `FlowSnapTests/Mocks/MockWindowPinningCoordinator.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no undocumented CGS / SLS APIs (e.g. no private `CGSSetWindowLevel` or `SLSSetWindowProperty`). Use public Accessibility APIs (`kAXRaiseAction`, `AXUIElementPerformAction`), `NSWorkspace` notifications, and standard window server coordination.
- **Dynamic LIFO Z-Stacking**:
  - Support pinning unlimited windows concurrently.
  - Pinned windows must remain visibly above non-pinned windows.
  - The most recently focused pinned window takes topmost priority among pinned windows (LIFO).
- **Stage Manager Launch Co-existence**:
  - Prevent macOS from ejecting existing active Stage windows into the side strip when launching a new application.
  - Coordinate newly launched app windows with existing Stage members using `kAXRaiseAction` coordination.
- **Space Scoping & System Modal Safety**:
  - Pinned windows belong strictly to their local Desktop Space.
  - System security modals (Touch ID, Keychain, permission prompts) must never be obscured.
- **Swift 6 Strict Concurrency**: 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

# Tech Context — FlowSnap (from docs/PRODUCT_BACKLOG_ROADMAP.md YAML frontmatter)

> Every subagent dispatched in this session MUST read this file first. Do not re-derive the stack.

## Stack

- **Language:** Swift 6.0 (strict concurrency)
- **Frameworks:** SwiftUI + AppKit (macOS Native)
- **Architecture:** Domain-Driven Design (DDD) & Deep Modules
- **Concurrency:** Strict Concurrency (Actors, @MainActor, Sendable)
- **Storage:** UserDefaults + Local JSON (Application Support)
- **Build:** XcodeGen (project.yml) + Xcode 16.0+
- **Test:** Swift Testing (@Test) + XCTest
- **Target:** macOS 14.0+, Hardened Runtime, LSUIElement agent app

## Project Layout (Deep Modules)

- `Domain/` — pure models (ManagedWindow, LayoutZone, Display, Workspace, WindowPlacement, WindowGroup...)
- `Core/` — engines & coordinators (LayoutEngine, SnapEngine, CommandDispatcher, WindowRegistry actor, WorkspaceManager, WindowGroupManager)
- `Infrastructure/` — system integration (AXAccessibilityService, DisplayManager, GlobalHotkeyManager, MenuBarController, WorkspaceStore, WindowGroupStore)
- `UI/` — SwiftUI views + AppKit panels (SettingsView, SnapPreviewPanel, MenuBarView, WorkspacePresetsView)
- `App/` — composition root (FlowSnapApp, AppDelegate, AppDependencies)

## Hard Rules (from DoD, Section 6 of roadmap)

- Swift 6 strict concurrency: zero data-race/Sendable warnings
- No force unwrap `!`, no `try!`, no `as!`
- File < 800 LOC, function < 50 LOC
- `swiftlint lint --strict` must pass
- Tests: Swift Testing `@Test`; run via `xcodebuild test -scheme FlowSnapTests` (or swift test)
- Zero Private API policy (no CGS / undocumented frameworks)
- Persistence for this feature: Local JSON + UserDefaults for Presets & Groups

## Established Modules This Feature Depends On

- `Workspace` / `WindowPlacement` / `WorkspaceStore` (US-WORK-011)
- `WorkspaceManager` — intent matching and layout restoration
- `AccessibilityServing` / `AXAccessibilityService` — window discovery & frame manipulation
- `WindowRegistry` (actor) — tracked windows, pre-snap frames
- `LayoutEngine` — zone math incl. custom ratios & gaps
- `DisplayManager` + `CoordinateTransformer` — multi-monitor AX coordinate conversion
- `CommandDispatcher` — hotkey command routing
- `PreferencesStore` — UserDefaults-backed config
- `MenuBarController` — popover UI entry point

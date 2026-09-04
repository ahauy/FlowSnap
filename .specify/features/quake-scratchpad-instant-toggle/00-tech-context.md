# Tech Context: FlowSnap (US-SNAP-022)

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

## Relevant Subsystems for US-SNAP-022

- `Domain/`: `ManagedWindow`, `WindowPlacement`, `ScratchpadCoordinating`, `ScratchpadState`, `ScratchpadRecord`
- `Core/`: `ScratchpadCoordinator`, `WindowPinningCoordinator`, `SmartFocusStack`, `WorkspaceManager`
- `Infrastructure/`: `AccessibilityServing` / `AXAccessibilityService` (`kAXRaiseAction`, `kAXHiddenAttribute`, window activation), `GlobalEventMonitor` / `NSEvent.addGlobalMonitorForEvents` (blur / outside click / ESC tracking), `NSWorkspace`
- `Hotkeys/`: `GlobalHotkeyManager`, `KeyboardShortcut`, `ShortcutAction.toggleScratchpad`, `ShortcutAction.assignScratchpad`
- `UI/`: `MenuBarViewModel`, `MenuBarView`, `SettingsView`, `PreferencesStore`
- `Tests/`: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`, `FlowSnapTests/Mocks/MockScratchpadCoordinator.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs**: No undocumented CGS/SLS calls. Rely strictly on Public Accessibility APIs (`AXUIElement`), `NSWorkspace`, `NSRunningApplication`, and public window coordination.
- **Zero-Shrink / Zero-Displacement of Base App**: The underlying focused app (e.g. Brave full screen / tiled) must NEVER be resized or shifted by even 1 pixel during summon or dismiss.
- **Sub-50ms Latency Budget**: Instant summon and instant dismiss must execute within `< 50ms` from hotkey press.
- **Pre-Summon Focus Restoration**: On dismiss (via hotkey toggle, `ESC`, or click-outside blur), focus must return seamlessly to the exact application/window that held focus prior to summon.
- **Stage Manager & Space Scoping**: Summoning the Scratchpad must not trigger macOS space switching animations or break Stage Manager grouping.
- **Swift 6 Strict Concurrency**: 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

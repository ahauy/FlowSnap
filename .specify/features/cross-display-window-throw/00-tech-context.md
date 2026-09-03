# Tech Context: FlowSnap (US-DISP-015)

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

## Relevant Subsystems for US-DISP-015

- `Domain/`: `WindowCommand` (`.moveToNextDisplay`, `.moveToPreviousDisplay`), `ShortcutAction` (`.nextDisplay`, `.previousDisplay`), `Display` model, `CoordinateTransformer`
- `Core/`: `DisplayManaging` / `DisplayManager` (extend with horizontal topology navigation `nextDisplay`, `previousDisplay`), `RelativeFrameScaler` (scale window relative to source vs target display `visibleFrame`), `CommandDispatcher`, `SnapEngine`, `WindowManager`
- `Infrastructure/`: `AccessibilityService` (`setFrame`, `focusWindow`), `CursorManager` / `CGWarpMouseCursorPosition` (cursor relocation to center of window)
- `Hotkeys/`: `GlobalHotkeyManager` registering `⌃⌥⇧→` (keyCode: 124) and `⌃⌥⇧←` (keyCode: 123)
- `UI/`: `ShortcutSettingsView` (configured in Settings UI under Display Navigation), `PreferencesStore`
- `Tests`: `FlowSnapTests/Core/Display/DisplayNavigatorTests.swift`, `FlowSnapTests/Core/Display/RelativeFrameScalerTests.swift`

## Hard Constraints (from roadmap §7 + prior ADRs)

- **Zero Private APIs** — no undocumented CGS / SLS APIs. Public `NSScreen`, `AXUIElement`, and CoreGraphics APIs only (`CGWarpMouseCursorPosition`).
- **Zero Polling** — hotkey event-driven via Carbon Event Hotkeys and CommandDispatcher.
- **Strict Coordinate Inversion** — AppKit bottom-left origin vs AX / CG top-left origin conversion must use `CoordinateTransformer`.
- **Display Topology Ordering** — Multiple displays arranged in arbitrary desktop layouts (side-by-side, stacked) must be sorted deterministically (e.g. by screen X origin, then Y origin).
- **Single-Display Graceful Degradation** — If only 1 display is connected, hotkey action is a safe no-op with zero flicker or error.
- **Swift 6 Strict Concurrency** — 100% Sendable compliance, actor isolation on `@MainActor` coordinators.

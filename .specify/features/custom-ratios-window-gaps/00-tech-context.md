# Tech Context (from docs/PRODUCT_BACKLOG_ROADMAP.md YAML frontmatter)

- language: Swift 6.0
- frameworks: SwiftUI + AppKit (macOS Native)
- architecture: Domain-Driven Design (DDD) & Deep Modules
- concurrency: Strict Concurrency (Actors, @MainActor, Sendable)
- storage: UserDefaults + Local JSON (Application Support)
- build: XcodeGen (project.yml) + Xcode 16.0+
- test: Swift Testing (@Test) + XCTest
- git-mode: hybrid
- target: macOS 14.0+

## Layer map (existing)

- Domain:      FlowSnap/Domain/**        (pure models: LayoutZone, Layout, SnapTarget, ManagedWindow, Display)
- Core:        FlowSnap/Core/**          (LayoutEngine, SnapEngine, CommandDispatcher, SnapDetector, DragToSnapCoordinator)
- Infra:       FlowSnap/Infrastructure/**(AXAccessibilityService, DisplayManager, GlobalHotkeyManager, PreferencesStore)
- UI:          FlowSnap/UI/**            (MenuBar, SnapPreview, LayoutPicker, Settings)
- App:         FlowSnap/App/**           (FlowSnapApp, AppDelegate, AppDependencies @MainActor DI container)

## Hard constraints (DoD, roadmap section 6)

- Swift 6 strict concurrency, zero warnings.
- No force unwrap / try! / as!.
- File < 800 LOC, function < 50 LOC.
- `swiftlint lint --strict` must pass.
- 100% mathematical coverage on LayoutEngine via Swift Testing.
- Ubiquitous language must match CONTEXT.md.

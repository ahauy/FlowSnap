# ADR-0005: Shortcut Customization and Unified Settings Architecture

- **Status**: Accepted
- **Date**: 2026-08-30
- **Feature**: `settings-shortcut-customization` (US-SNAP-010)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement
Users need the ability to configure shortcuts according to their personal muscle memory (such as matching Rectangle or Magnet shortcuts) and tweak system behaviors like window gaps, split ratios, and drag-to-snap toggles.
The existing hotkey system had hardcoded shortcuts in `GlobalHotkeyManager` and basic gap settings in `PreferencesStore`. We need an extensible, conflict-resilient shortcut management system and a native 4-tab SwiftUI Settings interface.

## Decision
1. **ShortcutAction Domain Enum**: Define `ShortcutAction` as the single canonical identifier for all customizable actions, encapsulating default shortcuts, categories, and command mappings.
2. **Unified PreferencesStore**: Store user-customized shortcuts as a Codable dictionary `[String: KeyboardShortcut]` within `UserDefaults`, accompanied by `@Published` properties for SwiftUI reactivity.
3. **ShortcutRecorderField FSM**: Implement a dedicated macOS SwiftUI `ShortcutRecorderField` that captures local keydown events, enforces at least one modifier key, provides clear (Delete) and cancel (Escape) ergonomics, and displays real-time collision warnings.
4. **Dynamic Carbon Hotkey Re-Registration**: `GlobalHotkeyManager` dynamically unregisters and re-registers active bindings when `PreferencesStore` emits updates, ensuring immediate effect without application restart.
5. **4-Tab Native Settings**: Structure the settings window into 4 coherent tabs: `General`, `Shortcuts`, `Application Rules`, and `About`.

## Consequences
- **Positive**: Complete user flexibility; zero restart required; reliable conflict detection; clean decoupling between UI, domain actions, and system hotkey registrations.
- **Negative / Constraints**: Must filter out reserved OS keys and ensure modifier keys are present to avoid key interception bugs.

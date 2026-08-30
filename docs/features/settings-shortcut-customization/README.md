# Feature: Settings UI & Shortcut Customization (US-SNAP-010)

- **Feature Slug**: `settings-shortcut-customization`
- **Epic**: `EPIC 09: SwiftUI Settings UI & Custom Shortcut Management`
- **Status**: Completed & Verified (`132/132` tests passing)
- **Specifications**: [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/settings-shortcut-customization/baseline.md) | [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/settings-shortcut-customization/spec.md) | [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/settings-shortcut-customization/plan.md) | [data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/settings-shortcut-customization/data-model.md)
- **Architectural Decision Record**: [ADR-0005: Shortcut Customization and Unified Settings Architecture](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0005-shortcut-customization-and-settings-architecture.md)

---

## 1. Overview & Business Value

While standard default shortcuts (e.g. `⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`) provide out-of-the-box window tiling, macOS power users frequently have muscle memory built around custom shortcut conventions from tools like Rectangle, Magnet, Raycast, or Spectacle. Additionally, users demand fine-grained control over window gap sizes, asymmetric split ratios, drag-to-snap sensitivity, and application exclusion rules.

`US-SNAP-010` delivers a macOS-native SwiftUI Settings window and a dynamic keyboard shortcut management engine:

1. **Four-Tab SwiftUI Settings Architecture (`SettingsView`)**: Polished tabs for `General`, `Shortcuts`, `Application Rules`, and `About`.
2. **Interactive Shortcut Recorder (`ShortcutRecorderField`)**: Live keydown capture supporting modifier combinations (`⌃`, `⌥`, `⌘`, `⇧`), collision detection warnings, Escape to cancel, and Backspace/Delete to clear.
3. **Domain Shortcut Taxonomy (`ShortcutAction`, `ShortcutCategory`)**: Strongly typed enum encompassing 14+ snap and window commands categorized by functional intent.
4. **Reactive Persistence (`PreferencesStore`)**: `@MainActor` observable store persisting custom shortcut bindings, drag-to-snap toggles, preview dwell delay, and launch-at-login via `UserDefaults`.
5. **Dynamic Carbon Hotkey Re-Registration (`GlobalHotkeyManager`)**: Seamless hotkey listener updates on preference changes without requiring application restart.

---

## 2. Diataxis Architecture & Guides

### Tutorial: Customizing a Window Snap Shortcut

1. Open FlowSnap Settings via the Menu Bar Extra (`⌘,` or clicking "Settings...").
2. Switch to the **Shortcuts** tab.
3. Find the action you wish to customize (e.g., **Left Half**).
4. Click the shortcut button (currently showing `⌃⌥←`). The button enters recording mode with a pulsing accent indicator ("Type keys...").
5. Press your desired key combination (e.g., `⌥⌘←`).
6. FlowSnap validates that modifiers are present, checks for conflicts, saves the new combination to `PreferencesStore`, and updates the Carbon hotkey listener immediately.

### How-To Guide: Programmatic Shortcut Registration & Conflict Checks

```swift
import FlowSnap

@MainActor
func configureCustomShortcuts(store: PreferencesStore) {
    let newShortcut = KeyboardShortcut(keyCode: 123, carbonModifiers: 0x1800) // ⌃⌥←

    // 1. Check for conflicts
    if let conflictingAction = store.hasConflict(newShortcut, excluding: .leftHalf) {
        print("Warning: conflicts with \(conflictingAction.displayName)")
    }

    // 2. Assign shortcut
    store.setShortcut(newShortcut, for: .leftHalf)

    // 3. Reset all shortcuts back to default presets if needed
    store.resetShortcutsToDefault()
}
```

### Reference: ShortcutAction Taxonomy

| Action ID | Display Label | Category | Default Key Binding | Default Window Command |
| :--- | :--- | :--- | :--- | :--- |
| `leftHalf` | Left Half | Halves & Maximize | `⌃⌥←` | `.snap(.zone(.leftHalf))` |
| `rightHalf` | Right Half | Halves & Maximize | `⌃⌥→` | `.snap(.zone(.rightHalf))` |
| `topHalf` | Top Half | Halves & Maximize | `⌃⌥⇧↑` | `.snap(.zone(.topHalf))` |
| `bottomHalf` | Bottom Half | Halves & Maximize | `⌃⌥⇧↓` | `.snap(.zone(.bottomHalf))` |
| `maximize` | Maximize | Halves & Maximize | `⌃⌥↑` | `.maximize` |
| `restore` | Restore / Center | Halves & Maximize | `⌃⌥↓` | `.restore` |
| `topLeft` | Top Left | Quarter Screens | `⌃⌥1` | `.snap(.zone(.topLeft))` |
| `topRight` | Top Right | Quarter Screens | `⌃⌥2` | `.snap(.zone(.topRight))` |
| `bottomLeft` | Bottom Left | Quarter Screens | `⌃⌥3` | `.snap(.zone(.bottomLeft))` |
| `bottomRight` | Bottom Right | Quarter Screens | `⌃⌥4` | `.snap(.zone(.bottomRight))` |
| `left70_30` | Left 70% / 2/3 | Asymmetric & Thirds | `⌃⌥⇧1` | `.snap(.zone(.left70_30))` |
| `rightOneThird` | Right 30% / 1/3 | Asymmetric & Thirds | `⌃⌥⇧2` | `.snap(.zone(.rightOneThird))` |
| `leftThird` | Left 1/3 | Asymmetric & Thirds | `⌃⌥⇧3` | `.snap(.zone(.leftThird))` |
| `centerThird` | Center 1/3 | Asymmetric & Thirds | `⌃⌥⇧4` | `.snap(.zone(.centerThird))` |
| `rightThird` | Right 1/3 | Asymmetric & Thirds | `⌃⌥⇧5` | `.snap(.zone(.rightThird))` |

---

## 3. Verification & Test Evidence

- **Unit Test Suite**: `FlowSnapTests/Domain/ShortcutActionTests.swift`, `FlowSnapTests/Domain/KeyboardShortcutTests.swift`, `FlowSnapTests/Infrastructure/PreferencesStoreTests.swift`.
- **UI Snapshots**: Rendered via `FlowSnapTests/UI/SettingsSnapshotRenderer.swift` into `docs/user-guides/images/settings-shortcut-customization/`.
- **Test Result**: `132 passed, 0 failed` across 24 suites in `xcodebuild test`.

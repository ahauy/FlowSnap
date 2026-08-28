# Data Model: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Feature**: `global-hotkeys-dispatcher`
- **Architect**: `system-architect`

---

## 1. Domain Entities & Value Objects

### `KeyboardShortcut` (Value Object)

Path: `FlowSnap/Domain/Hotkeys/KeyboardShortcut.swift`

```swift
import Carbon
import Foundation

/// Value object representing a physical key code and Carbon modifier mask.
public struct KeyboardShortcut: Hashable, Codable, Sendable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    /// Canonical display glyphs for macOS (e.g. "⌃⌥←", "⌃⌥↑", "⌃⌥1").
    public var displayString: String {
        var glyphs = ""
        if carbonModifiers & UInt32(controlKey) != 0 { glyphs += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { glyphs += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { glyphs += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { glyphs += "⌘" }

        switch keyCode {
        case 123: glyphs += "←"
        case 124: glyphs += "→"
        case 125: glyphs += "↓"
        case 126: glyphs += "↑"
        case 18: glyphs += "1"
        case 19: glyphs += "2"
        case 20: glyphs += "3"
        case 21: glyphs += "4"
        default: glyphs += "[\(keyCode)]"
        }
        return glyphs
    }
}
```

### `HotkeyBinding` (Entity)

Path: `FlowSnap/Domain/Hotkeys/HotkeyBinding.swift`

```swift
import Foundation

/// Associates a specific KeyboardShortcut with an executable WindowCommand.
public struct HotkeyBinding: Identifiable, Hashable, Sendable {
    public let id: UInt32
    public let shortcut: KeyboardShortcut
    public let command: WindowCommand
    public let isRegistered: Bool

    public init(
        id: UInt32,
        shortcut: KeyboardShortcut,
        command: WindowCommand,
        isRegistered: Bool = false
    ) {
        self.id = id
        self.shortcut = shortcut
        self.command = command
        self.isRegistered = isRegistered
    }
}
```

---

## 2. Service Protocols & Implementations

### `GlobalHotkeyManaging` (Protocol)

Path: `FlowSnap/Core/Hotkeys/GlobalHotkeyManaging.swift`

```swift
import Foundation

/// Abstraction for global system-wide keyboard shortcut registration.
public protocol GlobalHotkeyManaging: AnyObject, Sendable {
    func register(_ binding: HotkeyBinding, action: @escaping @Sendable (WindowCommand) -> Void) -> Bool
    func registerDefaultHotkeys(action: @escaping @Sendable (WindowCommand) -> Void) -> [HotkeyBinding]
    func unregisterAll()
    var activeBindings: [HotkeyBinding] { get }
}
```

### `GlobalHotkeyManager` (Infrastructure Service)

Path: `FlowSnap/Infrastructure/Hotkeys/GlobalHotkeyManager.swift`

- Uses `RegisterEventHotKey` and `InstallEventHandler` on `GetApplicationEventTarget()`.
- Keeps a mapping of `EventHotKeyID` $\rightarrow$ handler callback.
- Cleans up via `UnregisterEventHotKey` in `unregisterAll()` and `deinit`.
- Handles `eventHotKeyExistsErr` gracefully (`BR-HOTKEY-002`).

### `CommandDispatcher` (Core Service)

Path: `FlowSnap/Core/Commands/CommandDispatcher.swift`

- Coordinates:
  1. `WindowManaging.focusedWindow()`
  2. `DisplayManaging.display(for: window.frame, cursorPoint: nil)`
  3. `SnapEngine.calculateAXFrame(for:window:on:primaryScreenHeight:gap:)`
  4. `WindowManaging.move(window, to: targetFrame)`
- Concurrency:
  - Actor-isolated or `@MainActor` task coalescing (`BR-HOTKEY-005`) with 50ms latest-wins debounce.

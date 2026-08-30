# Data Model: Settings UI & Shortcut Customization (US-SNAP-010)

## Schema & Types

### 1. `ShortcutAction`
```swift
public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case maximize
    case restore
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case left70_30
    case rightOneThird
    case nextDisplay
    case previousDisplay

    public var id: String { rawValue }
    public var displayName: String { ... }
    public var defaultShortcut: KeyboardShortcut? { ... }
    public var defaultCommand: WindowCommand { ... }
    public var category: ShortcutCategory { ... }
}
```

### 2. `ShortcutCategory`
```swift
public enum ShortcutCategory: String, CaseIterable, Identifiable, Sendable {
    case halvesAndMaximize = "Halves & Maximize"
    case quarters = "Quarter Screens"
    case asymmetric = "Asymmetric & Thirds"
    case displays = "Display Navigation"

    public var id: String { rawValue }
}
```

### 3. `KeyboardShortcut`
```swift
public struct KeyboardShortcut: Hashable, Codable, Sendable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32
    public var displayString: String
    
    public init(keyCode: UInt32, carbonModifiers: UInt32)
    public init(keyCode: Int, carbonModifiers: Int)
}
```

### 4. `PreferencesStore`
```swift
@MainActor
public final class PreferencesStore: ObservableObject {
    @Published public private(set) var windowGap: CGFloat
    @Published public private(set) var defaultRatio: LayoutRatio
    @Published public private(set) var customShortcuts: [ShortcutAction: KeyboardShortcut]
    @Published public private(set) var isDragToSnapEnabled: Bool
    @Published public private(set) var dragPreviewDwellDelay: Double
    @Published public private(set) var launchAtLogin: Bool

    public func shortcut(for action: ShortcutAction) -> KeyboardShortcut?
    public func setShortcut(_ shortcut: KeyboardShortcut?, for action: ShortcutAction)
    public func resetShortcutsToDefault()
    public func hasConflict(_ shortcut: KeyboardShortcut, excluding action: ShortcutAction?) -> ShortcutAction?
    public func setDragToSnapEnabled(_ enabled: Bool)
    public func setDragPreviewDwellDelay(_ delay: Double)
    public func setLaunchAtLogin(_ enabled: Bool)
}
```

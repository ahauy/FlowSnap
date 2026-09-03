# Data Model & Interface Contracts: US-WORK-017

## 1. Domain Protocols

### `StageManagerDetecting`

```swift
/// Detects whether macOS Stage Manager (WindowManager) is currently active.
public protocol StageManagerDetecting: Sendable {
    /// Returns `true` if Stage Manager is enabled system-wide.
    var isStageManagerEnabled: Bool { get }
}
```

### `AccessibilityServing` (Extended)

```swift
public protocol AccessibilityServing: Sendable {
    // Existing members...

    /// Raises a window AXUIElement to the foreground / top of the visual layer via `kAXRaiseAction`.
    @discardableResult
    func raise(element: AXUIElement) -> Bool

    /// Raises a ManagedWindow by looking up or referencing its AXUIElement.
    @discardableResult
    func raise(window: ManagedWindow) -> Bool
}
```

---

## 2. Infrastructure Layer

### `StageManagerDetector`

```swift
public final class StageManagerDetector: StageManagerDetecting {
    private let suiteName: String
    private let key: String
    private let userDefaults: UserDefaults?

    public init(
        suiteName: String = "com.apple.WindowManager",
        key: String = "GloballyEnabled",
        userDefaults: UserDefaults? = nil
    ) {
        self.suiteName = suiteName
        self.key = key
        self.userDefaults = userDefaults ?? UserDefaults(suiteName: suiteName)
    }

    public var isStageManagerEnabled: Bool {
        // Read directly from CFPreferences to bypass cached daemon values
        if let val = CFPreferencesCopyAppValue(key as CFString, suiteName as CFString) {
            if let boolVal = val as? Bool {
                return boolVal
            }
            if let numVal = val as? NSNumber {
                return numVal.boolValue
            }
        }
        return userDefaults?.bool(forKey: key) ?? false
    }
}
```

---

## 3. Core Layer Integration

### `WorkspaceManager`

- Injected with `stageManagerDetector: StageManagerDetecting`.
- `WorkspaceManager+Restore.swift`:
  - Before iterating placements, check:
    ```swift
    let stageManagerActive = stageManagerDetector.isStageManagerEnabled
    ```
  - During loop:
    - If `stageManagerActive == true`:
      - First placement (Anchor): calls `launcher.reveal(bundleID:)` after `place()`.
      - Subsequent placements:
        - If `app.isHidden`, calls `app.unhide()`.
        - Calls `place()`.
        - For each placed window element: calls `accessibilityService.raise(element: resolved.element)` (or `raise(window:)`).
        - Does NOT call `launcher.reveal()`.
    - If `stageManagerActive == false`:
      - Standard behavior: calls `launcher.reveal(bundleID:)` for each placed app.
  - After loop:
    - If `stageManagerActive == true`, re-raise the first placement's primary window:
      ```swift
      if let firstPlacement = placements.first,
         let anchorWindow = matchingWindows(for: firstPlacement).first {
          if let el = anchorWindow.element {
              accessibilityService.raise(element: el)
          } else {
              accessibilityService.raise(window: anchorWindow.window)
          }
      }
      ```

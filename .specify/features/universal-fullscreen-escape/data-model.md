# Data Model & Protocol Contracts: US-WORK-018

## 1. Domain Entities

### `FullScreenEscapeTier` (`FlowSnap/Domain/Window/FullScreenEscapeTier.swift`)

```swift
import Foundation

/// Defines the execution tier used to trigger a macOS Native Full Screen exit.
public enum FullScreenEscapeTier: String, Sendable, CaseIterable, Codable {
    /// Tier 0: Direct attribute write (AXFullscreen / AXFullScreen = false). Fastest for Cocoa apps.
    case attributeWrite
    /// Tier 1: Accessibility button action (kAXFullScreenButtonAttribute + kAXPressAction). Primary for Electron/Chromium.
    case axButtonPress
    /// Tier 2: Synthesized macOS keyboard shortcut (Control + Command + F) posted via CGEvent to target PID.
    case cgEventShortcut
}
```

### `FullScreenEscapeResult` (`FlowSnap/Domain/Window/FullScreenEscapeResult.swift`)

```swift
import Foundation

/// Telemetry and execution outcome of a full-screen escape request.
public struct FullScreenEscapeResult: Sendable, Equatable, Codable {
    public let succeeded: Bool
    public let tierUsed: FullScreenEscapeTier?
    public let durationMs: Int
    public let error: String?

    public static func success(tier: FullScreenEscapeTier, durationMs: Int) -> FullScreenEscapeResult {
        FullScreenEscapeResult(succeeded: true, tierUsed: tier, durationMs: durationMs, error: nil)
    }

    public static func failure(durationMs: Int, error: String) -> FullScreenEscapeResult {
        FullScreenEscapeResult(succeeded: false, tierUsed: nil, durationMs: durationMs, error: error)
    }
}
```

---

## 2. Service Protocol Contracts

### `CGEventPosting` (`FlowSnap/Infrastructure/Accessibility/CGEventPosting.swift`)

```swift
import CoreGraphics
import Foundation

/// Testable abstraction for posting synthesized CGEvents to target process PIDs.
public protocol CGEventPosting: Sendable {
    /// Posts a keystroke (keyDown and keyUp) with specified flags to the given process identifier.
    func postKeystroke(keyCode: CGKeyCode, flags: CGEventFlags, to pid: pid_t) throws
}
```

### `FullScreenEscapeCoordinating` (`FlowSnap/Core/Window/FullScreenEscapeCoordinating.swift`)

```swift
import ApplicationServices
import Foundation

/// Protocol coordinating multi-tier escape from macOS full screen mode with adaptive transition waiting.
public protocol FullScreenEscapeCoordinating: Sendable {
    /// Requests the window element to exit full screen mode, escalating through Tiers 0 -> 1 -> 2 as needed,
    /// and waits adaptively (every 100ms, max 800ms) until `isFullScreenChecker` reports false.
    func exitFullScreen(
        for element: AXUIElement,
        pid: pid_t?,
        isFullScreenChecker: @Sendable () async -> Bool
    ) async throws -> FullScreenEscapeResult
}
```

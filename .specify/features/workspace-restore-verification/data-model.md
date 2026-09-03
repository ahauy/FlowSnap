# Data Model: Verified Workspace Restoration

**Feature Slug:** `workspace-restore-verification`  
**Status:** Ready for task decomposition

## 1. Ephemeral value objects

### RestorePlacementResult

```swift
struct RestorePlacementResult: Sendable, Equatable {
    let bundleIdentifier: String
    let orderIndex: Int
    let category: Category
    let reason: SkipReason?

    enum Category: String, Sendable, Equatable {
        case placed
        case failed
        case unverifiable
        case skipped
    }
}
```

`reason` is nil only for `placed`. Failed/unverifiable/skipped results carry
the matching typed reason.

### SkipReason (extended)

Existing `SkipReason` gains:

- `moveFailed`
- `unverifiablePlacement`
- `fullscreenTransitionTimeout`
- `notInstalled`
- `launchTimeout`
- `noWindow`

The type remains Codable/Hashable/Sendable. Existing discovery cases remain
source-compatible for callers that switch exhaustively after updates.

### RestoreSummary

```swift
struct RestoreSummary: Sendable, Equatable, Hashable {
    let placedCount: Int
    let failedCount: Int
    let unverifiableCount: Int
    let skippedCount: Int
    let totalPlacements: Int
    let failed: [RestoreIssue]
    let unverifiable: [RestoreIssue]
    let skipped: [RestoreIssue]
}
```

`RestoreIssue` contains bundle ID, order index, and reason. Counts satisfy
`placed + failed + unverifiable + skipped == total`. Compatibility computed
views may be retained if existing consumers require `SkippedApp`.

### WindowVerificationResult

```swift
struct WindowVerificationResult: Sendable, Equatable {
    let frameMatches: Bool
    let isMinimized: Bool
    let isFullscreen: Bool
    var isPlacementVerified: Bool {
        frameMatches && !isMinimized && !isFullscreen
    }
}
```

## 2. Policy values

`RestoreVerificationPolicy` is a pure namespace of constants: tolerance 30;
attempts 3; retry backoff 100ms/200ms; fullscreen timeout 2s; fullscreen poll
100ms. Values are not persisted or user-configurable in P0.

## 3. Lifecycle

`Resolving → Preparing → FullscreenGate (optional) → Attempting → Verifying →
Placed | Failed | Unverifiable | Skipped`. Fullscreen throw/timeout and missing
AX element terminate before `Attempting`. Restore pass aggregates all terminal
results and then optionally performs one final focus.

## 4. Persistence and deletion

No new durable entities or fields. Existing `Workspace` and `WindowPlacement`
JSON are untouched. Restore results are ephemeral; no deletion, retention, or
migration applies.

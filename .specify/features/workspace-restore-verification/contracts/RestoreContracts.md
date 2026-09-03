# Internal Contracts: Verified Workspace Restoration

## 1. AccessibilityService seam

```swift
public protocol AccessibilityService: Sendable {
    func isFullScreen(_ window: AXUIElement) -> Bool
    func frame(of window: AXUIElement) -> CGRect?
    func setFrame(_ frame: CGRect, for window: AXUIElement) throws
    func exitFullScreen(_ window: AXUIElement) throws
    // existing methods unchanged
}
```

`isFullScreen` reuses `AXAccessibilityService`'s existing classification. No
private API or current-Space claim is exposed.

## 2. Restore result contract

`WorkspaceManager.restore(workspace:options:)` remains the single async entry
point and throws only pass-level `RestoreError`. Per-placement failures return
inside `RestoreSummary` as typed issue collections and counters. The operation
is sequential and bounded by policy values.

## 3. Placement internal seam

The manager's internal placement module accepts a `ResolvedWindow` with a
non-optional AX element at the operation boundary, target frame, and policy. It
returns `MoveOutcome` without exposing retry mechanics to UI or future callers.

## 4. Summary banner contract

`RestoreSummaryBanner` consumes `RestoreSummary`, displays placed/failed/
unverifiable/skipped groups and reasons, preserves compact/expanded modes and
the existing auto-dismiss timeout, and remains non-modal.

## 5. Diagnostics contract

The existing logging abstraction is used when present. Allowed fields are
bundle ID, phase, reason, attempt, and technical error/code. Titles, contents,
UI text, screenshots, and user data are prohibited.

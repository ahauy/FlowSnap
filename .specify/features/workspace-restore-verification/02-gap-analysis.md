# Gap Analysis: Verified Workspace Restoration Enhancement (US-WORK-011)

## AS-IS

- `WorkspaceManager+Restore` resolves windows and processes placements in workspace order, but `move` returns `true` after `WindowManaging.move` without reading the actual AX frame afterward.
- A successful AX write is therefore counted as `placed` even when macOS silently ignores it, the frame cannot be read, or the window remains minimized/fullscreen.
- `WindowManager` attempts fullscreen exit and then uses a fixed 700ms sleep. Exit errors are logged and placement can continue, so fullscreen state is not a verified gate.
- `AccessibilityService` exposes `exitFullScreen` but not a public `isFullScreen` query; fullscreen classification is private inside `AXAccessibilityService`.
- `ResolvedWindow.element` is optional. The WindowServer fallback produces `nil`, and the current `WindowManager` can resolve another element by window/frame, which permits unsafe guessing.
- Per-placement outcomes are reduced to `.placed` or `.skipped(reason)`. `RestoreSummary` only exposes `placedCount`, `totalPlacements`, and `skipped`, and existing move failures are mapped to `.noWindow`.
- Restore reveals each app after its placement, allowing focus/activation churn. There is no single final-focus selection based on verified results.
- `RestoreSummaryBanner` already provides a non-blocking, auto-dismiss-capable surface, but its headline/details model only understands the current placed/skipped shape.
- US-WORK-013 Space/observer infrastructure is incomplete for this path: `WorkspaceObserver` and `WindowPolicyManager` contain TODOs, while `SpaceManaging` only provides a minimal capability shell. No current-Space proof is available from AX geometry.

## TO-BE

For manual restore from Menu Bar/Settings, reusable core orchestration processes placements sequentially by `orderIndex`: resolve an exact AX element, prepare minimized/fullscreen state, attempt `setFrame`, verify actual frame and state, retry recoverable errors/mismatches up to three total attempts with 100ms/200ms backoff, and emit a typed outcome. Missing AX elements are unverifiable and are never moved through frame guessing. Fullscreen exit is synchronous and must be confirmed by 100ms polling within 2 seconds before placement starts. After all placements, one best-effort reveal/focus targets the lowest-order verified placement only. `RestoreSummary` exposes typed counters and reasons; `RestoreSummaryBanner` renders them without blocking and preserves its existing auto-dismiss behavior. Cross-Space remains exploratory and does not gate P0. Picker app names and cancellation remain follow-up work.

## Functional gaps

- Add a reusable verification policy and result model for frame tolerance, minimized state, fullscreen state, retry count, and backoff.
- Add `AccessibilityService.isFullScreen(_:)` and reuse existing AX fullscreen classification.
- Move fullscreen polling out of the fixed-delay `WindowManager` path and make transition failure stop placement.
- Require non-optional AX target handling at the restore operation boundary; `nil` resolves to `.unverifiablePlacement` without a move attempt.
- Verify post-conditions after every move attempt; retry both thrown move errors and mismatches, while stopping on non-recoverable conditions.
- Add explicit `.moveFailed`, `.unverifiablePlacement`, and `.fullscreenTransitionTimeout` reason categories alongside discovery/launch reasons.
- Expand `RestoreSummary` counters and details while preserving pass-level `RestoreError` semantics.
- Separate placement from reveal/focus and select one final verified target deterministically.
- Update the existing summary banner to render grouped counts/reasons, retaining compact and expanded surfaces.
- Add P0 unit tests for silent-ignore, unreadable frame, minimized/fullscreen state, retry/backoff, missing element, fullscreen timeout, ordering, and final focus.

## Data gaps

- No new persisted workspace JSON fields are required. Existing `Workspace`, `WindowPlacement`, and stored placements remain compatible.
- `RestoreSummary` is an in-memory result, so new counters/reasons are a source/API contract change rather than a persistence migration. Preserve compatible initializers or update all in-repo consumers, including `PresetResolver` and test fixtures.
- `SkipReason` is Codable/Hashable; adding cases is additive for writers but decoding unknown future values must not be silently invented. Existing persisted workspaces do not contain summary reasons.
- Diagnostics must use the existing logging abstraction if available and may include bundle ID, phase, reason, attempt, and technical error/code only. Window titles/content/screenshots/user data are excluded.

## User impact

- Existing manual restore entry points remain unchanged and still use the current Menu Bar/Settings controls.
- Some restores previously reported as successful will now appear as failed or unverifiable; this is an intentional accuracy correction, not a regression in reporting.
- Partial restore continues processing remaining placements. The existing non-blocking banner remains the notification surface and keeps its current auto-dismiss timeout.
- Users are not asked to migrate saved workspaces, re-onboard, or respond to a new modal. Picker app-name presentation is deferred.

## Transition requirements

- Preserve the signed-off `workspace-snapshot-restoration` baseline; record this as a versioned enhancement with its own spec/validation artifacts.
- Update mocks and existing consumers of `RestoreSummary`, `AccessibilityService`, and `WindowManaging` in one compatibility pass; regenerate the Xcode project if source lists require it.
- Run old restore regression tests alongside new P0 tests. No dual-run behavior or feature flag is required because the new verification is the only supported manual-restore path after rollout.
- Cross-Space work is a separate spike: inspect/reuse US-WORK-013 observers and policy infrastructure without introducing a second Space-management mechanism. Its outcome must not block P0 completion.
- No database/file migration or rollback script is needed. If a build rollback is required, reverting the enhancement commit restores the previous in-memory summary behavior while existing workspace JSON remains readable.

# Research Notes: Verified Workspace Restoration

## Decision 1 — Keep orchestration in `WorkspaceManager`

- **Finding:** `WorkspaceManager+Restore.swift` already owns placement ordering,
  target resolution, display geometry, launch fallback, and summary publication.
- **Decision:** Deepen this seam with preparation, verification, retry, and final
  focus rather than introducing a parallel restore coordinator.
- **Rationale:** One caller-facing restore operation gives manual, future hotkey,
  preset, and group callers the same correctness behavior.
- **Alternative rejected:** Put verification in each UI action; this duplicates
  business rules and cannot protect future callers.

## Decision 2 — Expose fullscreen read through `AccessibilityService`

- **Finding:** `AXAccessibilityService` already has private multi-strategy
  fullscreen classification (`AXFullscreen`, `AXFullScreen`, geometry
  corroboration); the public protocol exposes only `exitFullScreen`.
- **Decision:** Add the minimal `isFullScreen(_:) -> Bool` interface and reuse the
  existing classifier. Keep AX implementation details in the adapter.
- **Rationale:** Tests can script state transitions and callers need no private
  AX knowledge.
- **Alternative rejected:** Duplicate fullscreen heuristics in WorkspaceManager
  or introduce a second service.

## Decision 3 — Exact-element-only placement in P0

- **Finding:** `ResolvedWindow.element` is optional because the WindowServer
  fallback cannot pair a snapshot with an AX element. `WindowManager` currently
  guesses another target when the element is absent.
- **Decision:** Restore treats nil as unverifiable and performs no move. The
  existing frame fallback is deferred until a separate safety spike.
- **Rationale:** Correctness and target identity outweigh best-effort guessing.

## Decision 4 — Typed in-memory summary, no persistence migration

- **Finding:** `RestoreSummary` is consumed by WorkspaceManager, WorkspaceViewModel,
  RestoreSummaryBanner, PresetResolver, and tests; workspace JSON contains no
  restore outcomes.
- **Decision:** Extend the in-memory contract with typed counters and issue groups;
  update consumers atomically while preserving workspace JSON.
- **Rationale:** Users need category-specific feedback without changing durable
  workspace intent data.
- **Alternative rejected:** Encode summary outcomes into workspace JSON; this
  would couple transient operation state to durable data and require migration.

## Decision 5 — State polling, not elapsed-time sleep

- **Finding:** `WindowManager` sleeps 700ms after fullscreen exit and then writes
  the frame even if the transition failed.
- **Decision:** Poll `isFullScreen` every 100ms up to 2 seconds; timeout/throw is a
  pre-placement failure.
- **Rationale:** A state observation is portable across app animation timings and
  testable without wall-clock guesses.

## Decision 6 — Cross-Space remains a bounded spike

- **Finding:** `WorkspaceObserver`, `WindowPolicyManager`, and `SpaceManaging`
  are incomplete/TODO-backed, and AX frame does not prove current Space.
- **Decision:** Do not add a new Space manager in P0. Document a non-blocking
  capability spike and reuse US-WORK-013 only if public APIs prove adequate.
- **Rationale:** Avoid speculative private API and scope expansion.

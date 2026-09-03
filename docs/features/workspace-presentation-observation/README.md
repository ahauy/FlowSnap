# Workspace Presentation Observation (P0.5)

> **Status:** Implemented · **Baseline:** ADR-0008 · **Spec:** `.specify/features/workspace-presentation-observation/P0_5_IMPLEMENTATION_SPEC_v4.md` (approved, all 16 open questions ticked in `OPEN_QUESTIONS_CHECKLIST_v3.md`)

## 1. Overview

ADR-0008's verified restore proves **geometry + AX state** (`WindowVerificationResult`), but a window can be moved "successfully" while living on another Space — the user sees nothing while the banner claims success. P0.5 adds an independent **presentation observation** axis:

> After a move is verified, observe once whether the window appears in the WindowServer's on-screen list, and report the outcome honestly.

It is **observation only**: no Space migration, no activation/reveal attempts in the loop, no private API.

## 2. Outcome semantics (two independent axes)

| `MoveOutcome` | Presentation | Category | Reason |
|---|---|---|---|
| `.failed` | n/a | `.failed` | `.moveFailed` |
| `.unverifiable` | n/a | `.unverifiable` | `.unverifiablePlacement` |
| `.moved` | `.presented` | `.placed` | — |
| `.moved` | `.notPresented` | `.movedButNotPresented` | `.notPresentedOnCurrentScreen` |
| `.moved` | `.unverifiable` | `.unverifiable` | `.presentationUnverifiable` |
| *(skipped pre-move)* | n/a | `.skipped` | `.notInstalled` / `.launchTimeout` / `.noWindow` |

Conservation rule: `placed + failed + unverifiable + skipped + movedButNotPresented == totalPlacements`. `isFullSuccess` is strict — any `.movedButNotPresented` keeps the banner orange.

## 3. Architecture

- **`CurrentScreenVisibilityChecking`** (`Infrastructure/macOS/CurrentScreenVisibilityChecker.swift`) — protocol + production `CGWindowListCurrentScreenVisibilityChecker` built on public `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements])`:
  - `isOnCurrentScreen(windowID:)` → `.presented` / `.notPresented` / `.unverifiable(reason:)` (layer-0 filter, own-PID guard, zero-id guard).
  - `reResolveWindowID(pid:frame:)` → `CGWindowID?` (5pt origin tolerance, **no hash fallback**) — used after a successful fullscreen exit (§4.5): Chromium/Electron apps may recreate the window, invalidating the captured id. Re-resolve failure ⇒ unverifiable, **no move, no observation**.
- **`PresentationOutcome`** (`Core/Workspace/RestoreVerification.swift`) — domain-side enum (`MoveOutcome` untouched, per Option A of the approved checklist).
- **Orchestration** (`WorkspaceManager+Restore.swift`) — observation runs exactly once, for the primary window only, after verify; never retried, never activates/raises; final reveal/focus unchanged (lowest-order verified placement only).
- **Injection seam** — the spec forbids touching `WorkspaceManager.swift`, so `injectPresentationChecker(_:)` provides a per-instance, MainActor-isolated override keyed by `ObjectIdentifier`; production instances use the real checker.

## 4. UI

`RestoreSummaryBanner` gains one counter chip ("Not presented", orange) and one issue group in expanded mode. Compact mode keeps the single-line headline, which now includes `"<App> was positioned but is not on the current screen"`.

## 5. Files

| Change | File |
|---|---|
| New | `FlowSnap/Infrastructure/macOS/CurrentScreenVisibilityChecker.swift` |
| New | `FlowSnapTests/Mocks/MockCurrentScreenVisibilityChecker.swift` |
| New | `FlowSnapTests/Core/Workspace/WorkspacePresentationObservationTests.swift` (T1–T14) |
| Modified | `FlowSnap/Core/Workspace/RestoreVerification.swift`, `FlowSnap/Domain/Workspace/RestoreSummary.swift`, `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`, `FlowSnap/UI/Components/RestoreSummaryBanner.swift` |
| Docs | `CONTEXT.md` (glossary), `docs/RESTORE_CROSSSPACE_ANALYSIS.md` (Appendix K) |

## 6. Tests

17 tests in `WorkspacePresentationObservationTests` cover the spec matrix: T1 placed, T2 moved-but-not-presented (core), T3 move-failure skips observation, T4 element-less fallback, T5 unverifiable observation, T6 own-PID (unit + 3 production integration probes), T7 primary-only counting, T8 minimized, T9 fullscreen, T10 one-shot (no retry), T11 reveal still placed-only, T12 banner five buckets, T13 strict `isFullSuccess`, T14 re-resolve after fullscreen exit (success + failure variants).

## 7. Limitations

- Absence from the on-screen list is reported `.notPresented`; a window destroyed *without* a fullscreen transition in the milliseconds between move and observation is indistinguishable and would be reported orange (acknowledged risk, spec §11 — mitigation is the fullscreen re-resolve path).
- Cross-Space **migration** (fixing the problem) is explicitly out of scope (T6 spike).
- `docs/features/README.md` index row intentionally not added — that file is outside the spec's §12 change list.

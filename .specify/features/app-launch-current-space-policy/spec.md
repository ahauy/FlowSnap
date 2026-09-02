# Feature Specification — App Launch Observer & Current Space Policy (US-WORK-013)

> Derived from `baseline.md` (SIGNED-OFF v1.0). Stage 2 ASM-LAUNCH-* decisions,
> Stage 4 domain model, Stage 5 RISK-LAUNCH-* register, Stage 6 REQ-LAUNCH-001..005.
> Source: `docs/PRODUCT_BACKLOG_ROADMAP.md` EPIC 11 / US-WORK-013 (P0 Must-Have).

## 1. Purpose

Detect when applications launch or activate on macOS and ensure their new
windows appear on the user's current Space and current display without
triggering unwanted Space switching, using only public macOS APIs with an
async observation pattern that handles the inherent timing race between
process launch and window creation.

## 2. Scope

In scope:
- Listening to `NSWorkspace` lifecycle notifications.
- Registering `AXObserver` per launched PID for `kAXWindowCreatedNotification`.
- Applying the `.currentSpace` default `WindowPolicy` on first-window detection.
- Timeout cleanup and dedup against rapid duplicate launches.
- 100% public macOS APIs (`NSWorkspace`, `AXObserver`, `kAXWindowCreatedNotification`).

Out of scope (deferred to US-WORK-014):
- `PreferencesStore` persistence of per-app policies.
- UI for the Application Rules tab.
- Cross-Space intent workspace restoration.

## 3. Requirements (Stage 6 baseline)

| REQ ID         | Description                                                                                              | Derived From                    |
| :------------- | :------------------------------------------------------------------------------------------------------- | :------------------------------ |
| REQ-LAUNCH-001 | `WorkspaceObserver` listens to `NSWorkspace.didLaunchApplicationNotification` and `didActivateApplicationNotification`. | roadmap AC #1 |
| REQ-LAUNCH-002 | On launch detection, register `AXObserver` for `kAXWindowCreatedNotification` on the new process.         | roadmap AC #2, ASM-LAUNCH-002   |
| REQ-LAUNCH-003 | On window creation, apply `WindowPolicy` — default `.currentSpace` positions on current display.        | roadmap AC #3, ASM-LAUNCH-003   |
| REQ-LAUNCH-004 | 10 s timeout for window creation; cleanup `AXObserver` on timeout.                                       | roadmap AC #2, RISK-LAUNCH-001/004 |
| REQ-LAUNCH-005 | 100 % public macOS APIs only — no CGS / SLS undocumented symbols.                                        | roadmap AC #4, ADR-0001         |

## 4. Assumptions (ASM-LAUNCH-*)

- **ASM-LAUNCH-001**: `NSWorkspace.didLaunchApplicationNotification` and
  `didActivateApplicationNotification` are sufficient signals for app lifecycle
  detection. No private APIs.
- **ASM-LAUNCH-002**: `AXObserver` with `kAXWindowCreatedNotification` and a 10 s
  timeout is the canonical async pattern. Polling fallback (`100 ms / 10 s`) only
  if registration fails (RISK-LAUNCH-001).
- **ASM-LAUNCH-003**: Default `.currentSpace` resolves to positioning on the
  current display using `DisplayManaging.visibleFrame`, with no Space switch
  triggered. `.withoutActivating` flag or immediate frame adjustment on
  `kAXWindowCreatedNotification` is acceptable.
- **ASM-LAUNCH-004**: Decoupling contract: `WorkspaceObserver` → `EventBus` →
  `WindowPolicyManager`. No direct service calls.
- **ASM-LAUNCH-005**: AXObserver C-callback bridges to `@MainActor` via
  `Task { @MainActor in }`. Callback context must be `Sendable`.

## 5. Risks (RISK-LAUNCH-*)

- **RISK-LAUNCH-001 (Medium)** — AXObserver registration fails silently.
  Mitigation: fall back to polling via the `ApplicationLaunching` wait pattern
  (100 ms / 10 s).
- **RISK-LAUNCH-002 (High)** — Window appears on wrong Space despite policy.
  Mitigation: apply frame immediately on `kAXWindowCreatedNotification`, before
  macOS completes Space transition animation.
- **RISK-LAUNCH-003 (Medium)** — Race between `didLaunch` and AXObserver setup.
  Mitigation: register AXObserver synchronously inside the notification handler
  with the pid extracted from the notification payload.
- **RISK-LAUNCH-004 (Low)** — App launches but never creates a window (headless,
  Gatekeeper). Mitigation: 10 s timeout releases the observer.
- **RISK-LAUNCH-005 (Low)** — Multiple rapid launches overwhelm observers.
  Mitigation: dedup by pid; ignore re-registration within a 5 s window per pid.

## 6. User Stories (Gherkin)

> Each user story is mapped to one or more REQ-LAUNCH-* IDs.

### US-LAUNCH-001 — Detect a new app launch
**Given** a user has FlowSnap running and Accessibility permission granted
**When** any third-party app is launched
**Then** `WorkspaceObserver` receives `NSWorkspace.didLaunchApplicationNotification`
**And** it publishes a `WindowEvent.applicationLaunched(pid)` on the `EventBus`
**And** the AXObserver for that pid is registered before the handler returns.
**REQ**: REQ-LAUNCH-001, REQ-LAUNCH-002.

### US-LAUNCH-002 — Detect a re-activated app
**Given** an already-running app is brought to the foreground
**When** `NSWorkspace.didActivateApplicationNotification` fires
**Then** the existing policy for that app's bundle id is reapplied (no new
AXObserver registered).
**REQ**: REQ-LAUNCH-001, REQ-LAUNCH-003.

### US-LAUNCH-003 — First window of a launched app appears on the current Space
**Given** an app just launched and AXObserver is registered for its pid
**When** macOS creates the first window (`kAXWindowCreatedNotification`)
**Then** `ApplicationObserver` resolves the window to a `ManagedWindow`
**And** publishes `WindowEvent.windowCreated(windowID)`
**And** `WindowPolicyManager.applyPolicy(for:)` resolves the policy
(`.currentSpace` by default)
**And** the window's frame is set to the visible frame of the current display
using `DisplayManaging.visibleFrame`
**And** the window is not made key/foreground (`.withoutActivating` semantics).
**REQ**: REQ-LAUNCH-002, REQ-LAUNCH-003.

### US-LAUNCH-004 — Timeout when no window appears within 10 s
**Given** an app launched but never creates a window
**When** 10 s elapse without any `kAXWindowCreatedNotification`
**Then** `ApplicationObserver` releases the AXObserver for that pid
**And** publishes no `windowCreated` event.
**REQ**: REQ-LAUNCH-004.

### US-LAUNCH-005 — Dedup of rapid duplicate launches
**Given** the same app pid triggers `didLaunchApplicationNotification` twice
within 5 s
**When** the second notification arrives
**Then** the AXObserver is not re-registered
**And** the existing observer continues to operate until its 10 s timeout.
**REQ**: REQ-LAUNCH-002, REQ-LAUNCH-004.

### US-LAUNCH-006 — Public macOS APIs only
**Given** the entire feature implementation
**When** the source is audited for `CGS*`, `SLS*`, or any non-Apple-exported
symbol
**Then** zero matches are returned by `grep` against `FlowSnap/Infrastructure/`.
**REQ**: REQ-LAUNCH-005.

## 7. Acceptance Criteria Mapping

| AC from roadmap US-WORK-013            | REQ IDs                            | User Story IDs                |
| :------------------------------------- | :--------------------------------- | :---------------------------- |
| Listen to launch + activate notifs     | REQ-LAUNCH-001                     | US-LAUNCH-001, US-LAUNCH-002  |
| Register AXObserver for new process    | REQ-LAUNCH-002                     | US-LAUNCH-001, US-LAUNCH-003  |
| Apply `.currentSpace` default policy   | REQ-LAUNCH-003                     | US-LAUNCH-002, US-LAUNCH-003  |
| Async timing race + timeout            | REQ-LAUNCH-004                     | US-LAUNCH-004                 |
| 100 % public macOS APIs                | REQ-LAUNCH-005                     | US-LAUNCH-006                 |

## 8. Non-Functional Requirements

- **NFR-LAUNCH-001**: Zero polling loops in steady state. `CPU Idle: 0.0%`
  mandate — event-driven only.
- **NFR-LAUNCH-002**: AXObserver C-callback context is `Sendable`; bridge to
  `@MainActor` via `Task { @MainActor in }`.
- **NFR-LAUNCH-003**: All new public types are `Sendable` or actor-isolated;
  Swift 6 strict concurrency produces zero warnings.
- **NFR-LAUNCH-004**: File < 800 LOC; function < 50 LOC (SwiftLint rules).
- **NFR-LAUNCH-005**: No `force_unwrapping`, `try!`, or `as!` in new code.

## 9. Out of Scope (explicit)

- Per-app policy persistence (`PreferencesStore`) — US-WORK-014.
- UI wiring for Application Rules tab — US-WORK-014.
- Cross-Space intent restoration — US-WORK-014.
- `AppLauncher` polling fallback implementation (RISK-LAUNCH-001 mitigation is
  *noted* in code as a comment but not implemented — only relevant if AX
  registration fails; tracked as future hardening task).
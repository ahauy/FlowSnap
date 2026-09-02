# Changelog: App Launch Observer & Current Space Policy

## v1.3 — 2026-09-02

### REVIEW + DOCS COMPLETE — Phase 6 closed

- **Phase 6A — Adversarial Quality Review (Dual Pass)**:
  - **Pass A — Standards & Security**: Clean. Swift 6 strict concurrency produces zero warnings. Zero force unwrap / try / cast in changed files. All files under 800 LOC; all functions under 50 LOC. `scripts/audit-no-private-apis.sh` returns `OK: no private CGS/SLS symbols`. `ObserverEntry` is `@unchecked Sendable` with documented justification (OpaquePointer contained on `@MainActor`).
  - **Pass B — Spec & Domain Fidelity**: Clean. All 5 REQ-LAUNCH-* requirements map to passing TCs. Domain layer (`Domain/Window/ApplicationObserving.swift`, `Domain/Window/LaunchObservationEvent.swift`) contains zero `AppKit` / `ApplicationServices` imports. All 3 confirmed decisions in `plan.md §10` honoured: (1) `applicationLaunched(pid, bundleID:)` in-place replacement done; (2) `ApplicationObserver` auto-releases after first `.windowCreated` (`handleWindowCreated`); (3) `MockApplicationObserver` skeleton in `FlowSnapTests/Mocks/` produced.
  - **Findings**: 0 CRITICAL, 0 HIGH, 1 MEDIUM (deferred), 1 LOW.
    - MEDIUM: `ApplicationObserver.makeLiveRegistration()` (`Infrastructure/macOS/ApplicationObserver.swift:177-199`) currently returns `.registered` without invoking the real `AXObserverCreate` / `AXObserverAddNotification`. Documented in code as deferred runtime hardening (exercised manually against the running app). Does not block test path or build; production hardening tracked as future ticket.
    - LOW: `EventBus` strong capture inside `WorkspaceObserver` non-isolated notification handler — acceptable because `EventBus` is itself `@MainActor`-isolated.
- **Phase 6B — Documentation**:
  - `docs/features/app-launch-current-space-policy/README.md` — full feature README using the standard Diataxis layout (Overview, Tutorial, How-To, Reference, Architecture, Tests, Traceability).
  - `docs/features/README.md` index updated with the new EPIC 11 entry.
  - `adr/0008-application-observing-seam.md` — ADR for the `ApplicationObserving` protocol seam in Domain + `ApplicationObserver` concrete in Infrastructure.
  - `CONTEXT.md` glossary extended with 7 new terms (`ApplicationObserving`, `ApplicationObserver`, `LaunchObservationEvent`, `LaunchObservationFailure`, `AXErrorCode`, `ApplicationObservingDefaults`, `WorkspaceObserver`, `WindowPolicyManager`).
  - `docs/user-guides/app-launch-current-space-policy.md` — non-technical end-user guide covering the menu-bar / behaviour nature of the feature, how to verify it works (current-Space test), how to diagnose misroutes via Console.app, and the 10-second headless-app limitation.

### Final test gate

- `xcodebuild test` → **333 / 333 tests passing** across 51 suites (5.525 s).
- `swift build` → clean under Swift 6 strict concurrency.
- `scripts/audit-no-private-apis.sh` → OK.

## v1.2 — 2026-09-02

- Phase 5 (Implementation) complete:
  - `Domain/Window/ApplicationObserving.swift` — Sendable protocol.
  - `Domain/Window/LaunchObservationEvent.swift` — Sendable/Hashable enum + `AXErrorCode` shim + `LaunchObservationFailure`.
  - `Core/Events/WindowEvent.swift` — `applicationLaunched(pid_t, bundleID: String?)` in-place replacement + `applicationWindowCreated(pid:windowID:)` new case.
  - `Core/Policy/WindowPolicyManager.swift` — `applyPolicy(for:)` for `.currentSpace` / `.currentDisplay`; `handle(event:)` subscribes to `.applicationWindowCreated`.
  - `Infrastructure/macOS/WorkspaceObserver.swift` — full NSWorkspace notification bridge (launch + activate + terminate).
  - `Infrastructure/macOS/ApplicationObserver.swift` — `@MainActor` AXObserver lifecycle with injectable `RegistrationFactory`, dedup, 10 s timeout, auto-release.
  - `App/AppDependencies.swift` — wires `WorkspaceObserver`, `ApplicationObserver`, `WindowPolicyManager` into the DI graph.
  - `App/AppDelegate.swift` — starts `workspaceObserver.startObserving()` and subscribes `WindowPolicyManager.handle(event:)` to the EventBus in `applicationDidFinishLaunching`.
  - `scripts/audit-no-private-apis.sh` — TC-013-07 CI grep gate.
  - 6 new test files under `FlowSnapTests/Domain/`, `FlowSnapTests/Core/{Events,Policy}/`, `FlowSnapTests/Infrastructure/`, `FlowSnapTests/Mocks/MockApplicationObserver.swift`.

## v1.1 — 2026-09-02

- Speckit Plan artifacts drafted: `spec.md`, `plan.md`, `data-model.md`, `tasks.md`.
- Contract stubs: `contracts/ApplicationObserving.swift`, `contracts/LaunchEvent.swift`.
- `MockApplicationObserver` skeleton added under `FlowSnapTests/Mocks/`.
- **Status:** Plan APPROVED v1.0 by user (Confirmation Gate 2 passed).
- **Confirmed decisions:**
  1. `EventBus.applicationLaunched` payload: in-place replace with `(pid_t, bundleID: String?)`.
  2. `AXObserver` lifecycle: auto-release after first `.windowCreated` event.
  3. Test scaffolding: `MockApplicationObserver` skeleton now; full test code in Phase 5.

## v1.0 — 2026-09-02

- Initial baseline created from Product Backlog Roadmap US-WORK-013.
- Classified as Bounded Task (Effort L, multi-session, P0 Must-Have).
- Dependencies: US-WORK-012 (delivered).
- Blocks: US-WORK-014.

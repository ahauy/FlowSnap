# ADR-0008: Application Observing Protocol Seam (US-WORK-013)

- **Status**: Accepted
- **Date**: 2026-09-02
- **Feature**: `app-launch-current-space-policy` (US-WORK-013)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

FlowSnap needs to detect when third-party applications launch on macOS so that newly created windows can be repositioned onto the user's current Space (the `.currentSpace` default policy — EPIC 11 / US-WORK-013). The standard public-API path is:

1. Subscribe to `NSWorkspace.didLaunchApplicationNotification` / `didActivateApplicationNotification`.
2. For each newly launched `pid_t`, register an `AXObserver` (`ApplicationServices`) listening for `kAXWindowCreatedNotification`.
3. When the callback fires, resolve the window and apply the policy within the AX frame-write window *before* macOS completes its Space transition animation (RISK-LAUNCH-002).

Two complications shape the architecture:

- The `AXObserver` C-callback runs in a non-actor context, but it must hand values back to a `@MainActor` Swift component. This requires `Sendable` boundary discipline.
- The `AXObserver` itself is an `OpaquePointer` (CFType) that is **not** `Sendable` and is **not** stable across processes. Tests must never need the live runtime — the registration path must be swappable.

## Decision

1. **`ApplicationObserving` Protocol in Domain** — A pure `Sendable` protocol that hides `OpaquePointer`, `AXObserverCreate`, and the C-callback bridging entirely behind three operations: `observe(pid:bundleID:)`, `stopObserving(pid:)`, and `events: AsyncStream<LaunchObservationEvent>`. Consumers (`WindowPolicyManager`, tests, future telemetry) never see ApplicationServices.
2. **`ApplicationObserver` Concrete in Infrastructure** — A `@MainActor` class implementing `ApplicationObserving`. It owns the `OpaquePointer` map keyed by `pid_t`, the per-pid `Task<Void, Never>` timeout (default 10 s), and the dedup window (default 5 s). The C-callback bridges to the main actor via `Task { @MainActor in [weak self] in ... }`, matching ASM-LAUNCH-005.
3. **Injectable `RegistrationFactory`** — The production initializer wraps a private `makeLiveRegistration()` that would call `AXObserverCreate` + `AXObserverAddNotification` against the live AX runtime. The test initializer accepts an injected `@MainActor @Sendable` factory, so the test process never imports ApplicationServices — only `CoreGraphics` for the `CGWindowID` value type.
4. **`LaunchObservationEvent` Value Type in Domain** — A `Sendable, Hashable` enum with three cases (`.windowCreated`, `.timeout`, `.failed`). Failure modes use a `Sendable` `AXErrorCode` `RawRepresentable` shim (`Int32`) so Domain never imports `ApplicationServices` (preserves ADR-0001's "no private APIs" gate).
5. **EventBus Decoupling (ADR-0004)** — `WorkspaceObserver` → `EventBus.applicationLaunched(pid, bundleID:)` → `ApplicationObserver` + `WindowPolicyManager`. `ApplicationObserver` then publishes `WindowEvent.applicationWindowCreated(pid, windowID:)` back onto the same bus, which `WindowPolicyManager` subscribes to via `handle(event:)`. No direct service-to-service calls.
6. **Auto-Release on First Window** — Plan §10 decision 2: the AXObserver entry is removed the moment a `.windowCreated` event is published. The 10 s timeout is the safety net; the happy path does not wait. Matches `.currentSpace` one-shot policy semantics.
7. **In-Place `applicationLaunched(pid, bundleID:)` Migration** — Plan §10 decision 1: `WindowEvent.applicationLaunched(pid_t)` was replaced in-tree by `(pid_t, bundleID: String?)` (Hashable-breaking but zero external consumers, documented in `CHANGELOG.md`).

## Consequences

- **Positive**:
  - Domain stays AppKit / ApplicationServices-free (preserves ADR-0001 acyclic guarantee and testability).
  - Tests run without the AX runtime — `ApplicationObserverTests` injects a `RegistrationFactory` recorder and exercises the dedup / timeout / failure paths deterministically.
  - 333/333 tests passing with `swift build` clean under Swift 6 strict concurrency.
  - The seam allows a future Swift-native macOS 15+ `NSApplicationDelegateAdaptor` observation path to drop in without touching Domain or Core.
- **Negative / Constraints**:
  - The live `makeLiveRegistration()` factory currently returns `.registered` without invoking the real `AXObserverCreate` / `AXObserverAddNotification` — the runtime wiring is exercised manually against the running app (documented in code at `ApplicationObserver.swift:177-199`). Future hardening ticket required for production-grade AX registration.
  - Headless apps (no window created within 10 s) emit `.timeout` and leave the window at its default position — partial-failure policy per plan §8.

## Alternatives Considered

- **Direct `AXObserver` calls in `WindowPolicyManager`** — Rejected. Couples a Core `@MainActor` class to ApplicationServices and prevents DI-driven testing.
- **AsyncStream of NSWorkspace notifications only** — Rejected. NSWorkspace fires *before* the app draws its first window; the race window with `.currentSpace` policy is unmanageable without an AXObserver fallback.
- **Polling fallback (RISK-LAUNCH-001)** — Deferred. Acceptable risk given the AX runtime's reliability on macOS 14+.

## References

- `spec.md` — US-WORK-013 specification (REQ-LAUNCH-001..005).
- `plan.md` §3 — Protocol seams, §4 — Concurrency model.
- `data-model.md` §1.1, §1.2 — `ApplicationObserving`, `LaunchObservationEvent`.
- ADR-0001 — Zero private APIs mandate.
- ADR-0004 — EventBus decoupling contract.
- ADR-0007 — Window Groups & Presets architecture (precedent for protocol-in-Domain pattern).
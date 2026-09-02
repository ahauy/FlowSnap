// contracts/ApplicationObserving.swift
// Standalone stub for the Domain-layer protocol seam.
// This file is a CONTRACT only — do not add implementation.
// It is intentionally free of AppKit / ApplicationServices imports so Domain
// stays portable and the protocol can be mocked under FlowSnapTests/Mocks/.
//
// US-WORK-013 / spec.md §6 US-LAUNCH-001..006.

import Foundation

/// Abstraction over the per-pid AXObserver window-creation detector.
///
/// Why this is a protocol in Domain:
/// - Hides the AppKit / ApplicationServices details of `AXObserver` (an
///   `OpaquePointer`) behind a Sendable value-type interface (Deep Module,
///   Ousterhout). Consumers (WindowPolicyManager, tests) never see
///   `OpaquePointer` or C-callbacks.
/// - Lets the implementation be swapped for a deterministic mock in tests
///   without bringing the AX runtime into the test process.
///
/// Isolation contract:
/// - The protocol is `Sendable`.
/// - `events` is an `AsyncStream` so consumers can `for await` without
///   crossing actor boundaries by hand.
public protocol ApplicationObserving: Sendable {

    /// Begin observing window-creation events for `pid`.
    ///
    /// Idempotent within `dedupWindow` (default 5s) per `pid_t`. Returns once
    /// the observer has either been registered or its registration was
    /// determined to have failed.
    ///
    /// - Parameters:
    ///   - pid: The pid of the launched application (from
    ///     `NSWorkspace.didLaunchApplicationNotification`).
    ///   - bundleID: Optional bundle identifier, used by policy resolution.
    func observe(pid: pid_t, bundleID: String?) async

    /// Force-release any observer registered for `pid`. Called on
    /// `kAXWindowCreatedNotification` success or `didTerminateApplicationNotification`.
    func stopObserving(pid: pid_t)

    /// Hot stream of observation outcomes.
    ///
    /// Emits `.windowCreated`, `.timeout`, or `.failed` exactly once per
    /// successful observation. Finishes only on `stopObservingAll`.
    var events: AsyncStream<LaunchObservationEvent> { get }
}

/// Placeholder for the default concrete registration timeout (10s) and the
/// dedup window (5s). The concrete `ApplicationObserver` in Infrastructure
/// surfaces these as constructor overrides; Domain stays numeric-free.
public enum ApplicationObservingDefaults {
    public static let windowCreationTimeout: TimeInterval = 10.0
    public static let launchDedupWindow: TimeInterval = 5.0
}
import CoreGraphics
import Foundation

/// Protocol orchestrating display topology profiles, auto-snapshotting, and auto-restoration.
///
/// Traces to: US-DISP-016, REQ-DISP-004, REQ-DISP-005, REQ-DISP-006, REQ-DISP-007.
@MainActor
public protocol TopologyProfileManaging: AnyObject, Sendable {

    /// Current active topology fingerprint.
    var currentFingerprint: TopologyFingerprint? { get }

    /// All saved topology profiles keyed by fingerprint raw value.
    var profiles: [String: DisplayTopologyProfile] { get }

    /// Evaluates a topology change event and executes either clamping or auto-restoration.
    func handleTopologyChange(_ event: DisplayTopologyChangeEvent) async

    /// Captures a snapshot of current window arrangements for a given fingerprint.
    func captureProfile(for fingerprint: TopologyFingerprint, name: String?) async -> DisplayTopologyProfile

    /// Restores a topology profile to the current displays.
    func restoreProfile(_ profile: DisplayTopologyProfile) async -> Bool

    /// Explicitly persists a profile into local storage.
    func saveProfile(_ profile: DisplayTopologyProfile)
}

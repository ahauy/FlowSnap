import CoreGraphics
import Foundation

// MARK: - Domain Models

/// Unique, deterministic fingerprint of a display setup.
///
/// Traces to US-DISP-016, REQ-DISP-003, BR-DISP-007, ASM-DISP-006.
public struct TopologyFingerprint: RawRepresentable, Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public let displayCount: Int
    public let displayDescriptions: [String]

    public init(rawValue: String, displayCount: Int, displayDescriptions: [String]) {
        self.rawValue = rawValue
        self.displayCount = displayCount
        self.displayDescriptions = displayDescriptions
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
        self.displayCount = 0
        self.displayDescriptions = []
    }

    public var description: String {
        "\(rawValue.prefix(12))... (\(displayCount) displays)"
    }
}

/// Saved workspace profile mapped directly to a display topology.
///
/// Traces to US-DISP-016, REQ-DISP-004, REQ-DISP-006.
public struct DisplayTopologyProfile: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let fingerprint: TopologyFingerprint
    public var name: String
    public let capturedAt: Date
    public var windowPlacements: [String: WindowPlacement]
    public var displayIndexMap: [String: Int]

    public init(
        id: UUID = UUID(),
        fingerprint: TopologyFingerprint,
        name: String? = nil,
        capturedAt: Date = Date(),
        windowPlacements: [String: WindowPlacement] = [:],
        displayIndexMap: [String: Int] = [:]
    ) {
        self.id = id
        self.fingerprint = fingerprint
        self.name = name ?? "Setup (\(fingerprint.displayCount) displays)"
        self.capturedAt = capturedAt
        self.windowPlacements = windowPlacements
        self.displayIndexMap = displayIndexMap
    }
}

// MARK: - Observer Contracts

/// Event emitted when display parameters change and settle.
public enum DisplayTopologyChangeEvent: Sendable, Equatable {
    case hotPlugConnected(newFingerprint: TopologyFingerprint, addedCount: Int)
    case hotUnplugDisconnected(newFingerprint: TopologyFingerprint, departingFingerprint: TopologyFingerprint)
    case geometryChanged(newFingerprint: TopologyFingerprint)
}

/// Protocol for observing system display hot-plug events with debouncing.
///
/// Traces to US-DISP-016, REQ-DISP-001, REQ-DISP-002, BR-DISP-008.
@MainActor
public protocol DisplayHotPlugObserving: AnyObject, Sendable {
    /// Handler invoked when a debounced display change is confirmed.
    var onTopologyChanged: (@MainActor @Sendable (DisplayTopologyChangeEvent) -> Void)? { get set }

    /// Starts observing system display parameter notifications.
    func startObserving()

    /// Stops observing notifications.
    func stopObserving()
}

// MARK: - Manager Contracts

/// Protocol orchestrating display topology profiles, auto-snapshotting, and auto-restoration.
///
/// Traces to US-DISP-016, REQ-DISP-004, REQ-DISP-005, REQ-DISP-006, REQ-DISP-007.
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
}

import Foundation

/// Saved workspace profile associated with a specific hardware display topology.
///
/// Traces to: US-DISP-016, REQ-DISP-004, REQ-DISP-006.
public struct DisplayTopologyProfile: Identifiable, Codable, Sendable, Equatable {

    public let id: UUID
    public let fingerprint: TopologyFingerprint
    public var name: String
    public let capturedAt: Date
    public var windowPlacements: [String: WindowPlacement] // bundleID -> WindowPlacement
    public var displayIndexMap: [String: Int]              // bundleID -> displayIndex

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

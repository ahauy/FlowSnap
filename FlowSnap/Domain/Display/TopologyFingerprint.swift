import CoreGraphics
import CryptoKit
import Foundation

/// Unique, deterministic fingerprint representing a physical display topology.
///
/// Traces to: US-DISP-016, REQ-DISP-003, BR-DISP-007, ASM-DISP-006.
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

    /// Generates a deterministic `TopologyFingerprint` from a collection of active displays.
    ///
    /// Displays are sorted spatially by `(minX, minY)` so the output is identical regardless
    /// of the order in which macOS or AppKit returns `NSScreen.screens`.
    ///
    /// - Parameter displays: Array of connected `Display` domain entities.
    /// - Returns: A unique, deterministic `TopologyFingerprint`.
    public static func generate(from displays: [Display]) -> TopologyFingerprint {
        guard !displays.isEmpty else {
            return TopologyFingerprint(rawValue: "empty", displayCount: 0, displayDescriptions: [])
        }

        // BR-DISP-007: Sort displays deterministically by horizontal origin, then vertical origin
        let sorted = displays.sorted { d1, d2 in
            if d1.frame.minX != d2.frame.minX {
                return d1.frame.minX < d2.frame.minX
            }
            return d1.frame.minY < d2.frame.minY
        }

        var canonicalPieces: [String] = ["count:\(sorted.count)"]
        var descriptions: [String] = []

        for (index, display) in sorted.enumerated() {
            let width = Int(display.frame.width)
            let height = Int(display.frame.height)
            let visX = Int(display.visibleFrame.origin.x)
            let visY = Int(display.visibleFrame.origin.y)
            let visW = Int(display.visibleFrame.width)
            let visH = Int(display.visibleFrame.height)
            let scale = String(format: "%.1f", display.scaleFactor)

            let piece = "disp[\(index)]:id=\(display.id):geom=\(width)x\(height):vis=\(visX),\(visY),\(visW),\(visH):scale=\(scale)"
            canonicalPieces.append(piece)

            let name = display.isPrimary ? "Primary Display (\(width)x\(height))" : "Display \(index + 1) (\(width)x\(height))"
            descriptions.append(name)
        }

        let canonicalString = canonicalPieces.joined(separator: "|")
        let digest = SHA256.hash(data: Data(canonicalString.utf8))
        let hexHash = digest.map { String(format: "%02x", $0) }.joined()

        return TopologyFingerprint(
            rawValue: hexHash,
            displayCount: sorted.count,
            displayDescriptions: descriptions
        )
    }
}

import CoreGraphics
import Foundation

/// A single window's placement within a workspace, stored as a **layout intent**
/// rather than hard pixel coordinates (BR-WORK-001).
///
/// Why intent instead of geometry: pixel coordinates are meaningless across
/// display changes — a snapshot taken on a 1920×1080 panel and restored on a
/// 1440×900 laptop would drop windows off-screen. Storing a `LayoutZone` lets
/// restoration recompute geometry against the *current* display's visible frame,
/// which is what makes "works after a monitor change" true by construction
/// (BR-WORK-007, RISK-WORK-001).
///
/// Traces to: data-model.md §1 (WindowPlacement), spec §3 FR-1.
public struct WindowPlacement: Codable, Equatable, Hashable, Sendable {

    /// The app to place, e.g. `"com.microsoft.VSCode"`. This is the intent key:
    /// it survives app restarts and machine changes, unlike a window id.
    public var bundleIdentifier: String

    /// The zone to restore into, recomputed against the current display.
    public var zone: LayoutZone

    /// How many windows of this app were visible at capture time (ASM-WORK-002).
    /// Drives count-aware mapping: the primary window gets the zone, extras
    /// cascade inside it.
    public var expectedWindowCount: Int

    /// Deterministic restore order (left-to-right / largest-area first).
    /// Normalised to `0..<n` on save so hand-edited files cannot produce gaps
    /// or duplicates (data-model.md §3).
    public var orderIndex: Int

    /// Proportional normalized bounds (0...1 coordinates, top-left origin) preserving
    /// custom divider ratios (e.g. 80/20, 70/30) across restores.
    public var normalizedRect: CGRect?

    public init(
        bundleIdentifier: String,
        zone: LayoutZone,
        expectedWindowCount: Int = 1,
        orderIndex: Int = 0,
        normalizedRect: CGRect? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.zone = zone
        self.expectedWindowCount = max(1, expectedWindowCount)
        self.orderIndex = orderIndex
        self.normalizedRect = normalizedRect
    }

    /// Explicit decoder so the `>= 1` clamp in the memberwise init also applies
    /// to values coming off disk (data-model.md §3: "Decoded values clamped to ≥ 1").
    ///
    /// A `zone` whose raw value is not a known `LayoutZone` still fails to decode,
    /// which routes the file down the corrupt-file path (E7) rather than silently
    /// substituting a default layout the user never asked for.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.zone = try container.decode(LayoutZone.self, forKey: .zone)
        self.expectedWindowCount = try container.decodeIfPresent(Int.self, forKey: .expectedWindowCount) ?? 1
        self.orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex) ?? 0
        self.normalizedRect = try container.decodeIfPresent(CGRect.self, forKey: .normalizedRect)
    }

    private enum CodingKeys: String, CodingKey {
        case bundleIdentifier, zone, expectedWindowCount, orderIndex, normalizedRect
    }
}

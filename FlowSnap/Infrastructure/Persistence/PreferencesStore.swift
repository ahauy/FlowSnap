import Combine
import Foundation

/// Persists user preferences (general settings, hotkeys, app policies).
///
/// MVP uses UserDefaults. See spec §45.
///
/// ASM-CRW-003: MainActor-isolated observable store with Combine `@Published`
/// surfaces for SwiftUI bindings. Gap is clamped to the allowed set
/// {0, 4, 8, 12, 16} (BR-CRW-002).
@MainActor
public final class PreferencesStore: ObservableObject {

    /// Allowed window gap values (BR-CRW-002).
    public static let allowedGaps: [CGFloat] = [0, 4, 8, 12, 16]
    public static let defaultGap: CGFloat = 4
    public static let defaultRatio: LayoutRatio = .equal

    private let defaults: UserDefaults

    @Published public private(set) var windowGap: CGFloat
    @Published public private(set) var defaultRatio: LayoutRatio

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedGap = defaults.object(forKey: "windowGap") != nil
            ? CGFloat(defaults.double(forKey: "windowGap"))
            : Self.defaultGap
        let storedRatio = LayoutRatio(rawValue: defaults.string(forKey: "defaultRatio") ?? "")
        self.windowGap = Self.clampGap(storedGap)
        self.defaultRatio = storedRatio ?? .equal
    }

    // MARK: - Window Gap (BR-CRW-002)

    /// Set the window gap, clamped to {0, 4, 8, 12, 16}.
    public func setWindowGap(_ newValue: CGFloat) {
        let clamped = Self.clampGap(newValue)
        defaults.set(Double(clamped), forKey: "windowGap")
        windowGap = clamped
    }

    // MARK: - Default Ratio

    /// Set the default layout ratio.
    public func setDefaultRatio(_ newValue: LayoutRatio) {
        defaults.set(newValue.rawValue, forKey: "defaultRatio")
        defaultRatio = newValue
    }

    // MARK: - Clamping (contracts.md §4.2)

    /// Round down to the nearest allowed gap value; 0 for negative input.
    public static func clampGap(_ value: CGFloat) -> CGFloat {
        allowedGaps.last(where: { $0 <= value }) ?? 0
    }
}

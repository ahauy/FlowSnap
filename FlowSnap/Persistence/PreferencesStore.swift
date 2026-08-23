import Foundation

/// Persists user preferences (general settings, hotkeys, app policies).
///
/// MVP uses UserDefaults. See spec §45.
final class PreferencesStore {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Window Gap (spec §18)

    var windowGap: CGFloat {
        get { CGFloat(defaults.double(forKey: "windowGap")) }
        set { defaults.set(Double(newValue), forKey: "windowGap") }
    }

    // TODO: Launch at login
    // TODO: Per-app policies
    // TODO: Custom shortcuts
}

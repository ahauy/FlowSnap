import Combine
import Foundation

/// Persists user preferences (general settings, hotkeys, drag-to-snap toggles, app policies).
///
/// MVP uses UserDefaults. See spec §45, US-SNAP-008, US-SNAP-010, ADR-0004, ADR-0005.
///
/// MainActor-isolated observable store with Combine `@Published`
/// surfaces for SwiftUI bindings.
@MainActor
public final class PreferencesStore: ObservableObject {

    // MARK: - Constants & Defaults

    public static let allowedGaps: [CGFloat] = [0, 4, 8, 12, 16]
    public static let defaultGap: CGFloat = 4
    public static let defaultRatio: LayoutRatio = .equal
    public static let defaultDragToSnapEnabled: Bool = true
    public static let defaultDragPreviewDwellDelay: Double = 0.05
    public static let defaultLaunchAtLogin: Bool = false

    private let defaults: UserDefaults

    // MARK: - Published Properties

    @Published public private(set) var windowGap: CGFloat
    @Published public private(set) var defaultRatio: LayoutRatio
    @Published public private(set) var customShortcuts: [ShortcutAction: KeyboardShortcut]
    @Published public private(set) var isDragToSnapEnabled: Bool
    @Published public private(set) var dragPreviewDwellDelay: Double
    @Published public private(set) var launchAtLogin: Bool

    // MARK: - Initialization

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Window Gap
        let storedGap = defaults.object(forKey: "windowGap") != nil
            ? CGFloat(defaults.double(forKey: "windowGap"))
            : Self.defaultGap
        self.windowGap = Self.clampGap(storedGap)

        // Default Ratio
        let storedRatio = LayoutRatio(rawValue: defaults.string(forKey: "defaultRatio") ?? "")
        self.defaultRatio = storedRatio ?? Self.defaultRatio

        // Drag to Snap Enabled
        if defaults.object(forKey: "isDragToSnapEnabled") != nil {
            self.isDragToSnapEnabled = defaults.bool(forKey: "isDragToSnapEnabled")
        } else {
            self.isDragToSnapEnabled = Self.defaultDragToSnapEnabled
        }

        // Drag Preview Dwell Delay
        if defaults.object(forKey: "dragPreviewDwellDelay") != nil {
            self.dragPreviewDwellDelay = defaults.double(forKey: "dragPreviewDwellDelay")
        } else {
            self.dragPreviewDwellDelay = Self.defaultDragPreviewDwellDelay
        }

        // Launch at Login
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        // Custom Shortcuts
        var loadedShortcuts: [ShortcutAction: KeyboardShortcut] = [:]
        if let data = defaults.data(forKey: "customShortcuts"),
           let dict = try? JSONDecoder().decode([String: KeyboardShortcut].self, from: data) {
            for (key, shortcut) in dict {
                if let action = ShortcutAction(rawValue: key) {
                    loadedShortcuts[action] = shortcut
                }
            }
        }
        self.customShortcuts = loadedShortcuts
    }

    // MARK: - Window Gap (BR-CRW-002)

    /// Set the window gap, clamped to {0, 4, 8, 12, 16}.
    public func setWindowGap(_ newValue: CGFloat) {
        let clamped = Self.clampGap(newValue)
        defaults.set(Double(clamped), forKey: "windowGap")
        windowGap = clamped
    }

    // MARK: - Default Ratio (BR-CRW-006)

    /// Set the default layout ratio.
    public func setDefaultRatio(_ newValue: LayoutRatio) {
        defaults.set(newValue.rawValue, forKey: "defaultRatio")
        defaultRatio = newValue
    }

    // MARK: - Drag to Snap Options (US-SNAP-010)

    /// Enable or disable drag-to-snap edge detection.
    public func setDragToSnapEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: "isDragToSnapEnabled")
        isDragToSnapEnabled = enabled
    }

    /// Set preview dwell delay (in seconds).
    public func setDragPreviewDwellDelay(_ delay: Double) {
        let clamped = max(0.0, min(delay, 1.0))
        defaults.set(clamped, forKey: "dragPreviewDwellDelay")
        dragPreviewDwellDelay = clamped
    }

    /// Set launch at login preference.
    public func setLaunchAtLogin(_ enabled: Bool) {
        defaults.set(enabled, forKey: "launchAtLogin")
        launchAtLogin = enabled
    }

    // MARK: - Shortcuts Customization (US-SNAP-010, BR-SET-001..005)

    /// Returns the effective shortcut for a given action (customized or fallback default).
    public func shortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        if let custom = customShortcuts[action] {
            return custom
        }
        return action.defaultShortcut
    }

    /// Assigns or unassigns a shortcut for a given action.
    public func setShortcut(_ shortcut: KeyboardShortcut?, for action: ShortcutAction) {
        if let shortcut = shortcut {
            customShortcuts[action] = shortcut
        } else {
            customShortcuts.removeValue(forKey: action)
        }
        saveCustomShortcuts()
    }

    /// Checks if a proposed shortcut conflicts with any existing action.
    public func hasConflict(_ shortcut: KeyboardShortcut, excluding action: ShortcutAction? = nil) -> ShortcutAction? {
        for candidate in ShortcutAction.allCases {
            if let excluding = action, candidate == excluding {
                continue
            }
            if let bound = self.shortcut(for: candidate), bound == shortcut {
                return candidate
            }
        }
        return nil
    }

    /// Resets all shortcuts to the default preset bindings (BR-SET-004).
    public func resetShortcutsToDefault() {
        customShortcuts.removeAll()
        defaults.removeObject(forKey: "customShortcuts")
    }

    private func saveCustomShortcuts() {
        var serializable: [String: KeyboardShortcut] = [:]
        for (action, shortcut) in customShortcuts {
            serializable[action.rawValue] = shortcut
        }
        if let data = try? JSONEncoder().encode(serializable) {
            defaults.set(data, forKey: "customShortcuts")
        }
    }

    // MARK: - Clamping (contracts.md §4.2)

    /// Round down to the nearest allowed gap value; 0 for negative input.
    public static func clampGap(_ value: CGFloat) -> CGFloat {
        allowedGaps.last(where: { $0 <= value }) ?? 0
    }
}

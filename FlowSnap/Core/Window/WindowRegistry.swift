import CoreGraphics
import Foundation

/// Thread-safe registry of all windows FlowSnap is currently tracking.
///
/// Uses Swift `actor` for safe concurrent access across threads.
public actor WindowRegistry {

    private var windows: [CGWindowID: ManagedWindow] = [:]

    public init() {}

    /// Add or update a tracked window.
    public func update(_ window: ManagedWindow) {
        windows[window.id] = window
    }

    /// Stop tracking a window.
    public func remove(_ id: CGWindowID) {
        windows.removeValue(forKey: id)
    }

    /// Get a tracked window by ID.
    public func window(for id: CGWindowID) -> ManagedWindow? {
        windows[id]
    }

    /// Get all windows belonging to a given PID.
    public func windows(for pid: pid_t) -> [ManagedWindow] {
        windows.values.filter { $0.pid == pid }
    }

    /// All currently tracked windows.
    public var allWindows: [ManagedWindow] {
        Array(windows.values)
    }

    /// Remove all tracked windows.
    public func clear() {
        windows.removeAll()
    }
}

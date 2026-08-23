import CoreGraphics

/// Thread-safe registry of all windows FlowSnap is currently tracking.
///
/// Uses Swift `actor` for safe concurrent access. See spec §39.
actor WindowRegistry {

    private var windows: [CGWindowID: ManagedWindow] = [:]

    /// Add or update a tracked window.
    func update(_ window: ManagedWindow) {
        windows[window.id] = window
    }

    /// Stop tracking a window.
    func remove(_ id: CGWindowID) {
        windows.removeValue(forKey: id)
    }

    /// Get a tracked window by ID.
    func window(for id: CGWindowID) -> ManagedWindow? {
        windows[id]
    }

    /// All currently tracked windows.
    var allWindows: [ManagedWindow] {
        Array(windows.values)
    }
}

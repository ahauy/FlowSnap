import CoreGraphics
import Foundation

/// Thread-safe registry of all windows FlowSnap is currently tracking.
///
/// Uses Swift `actor` for safe concurrent access across threads.
/// Tracks window states and pre-snap frames for restore operations (BR-LAYOUT-004).
public actor WindowRegistry {

    private var windows: [CGWindowID: ManagedWindow] = [:]
    private var preSnapFrames: [CGWindowID: CGRect] = [:]

    public init() {}

    // MARK: - Window Management

    /// Add or update a tracked window.
    public func update(_ window: ManagedWindow) {
        windows[window.id] = window
    }

    /// Stop tracking a window and discard any cached pre-snap frames.
    public func remove(_ id: CGWindowID) {
        windows.removeValue(forKey: id)
        preSnapFrames.removeValue(forKey: id)
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

    /// Remove all tracked windows and pre-snap states.
    public func clear() {
        windows.removeAll()
        preSnapFrames.removeAll()
    }

    // MARK: - Pre-Snap Frame Preservation (BR-LAYOUT-004)

    /// Store a pre-snap frame for a window if one is not already recorded.
    /// Consecutive snaps preserve the initial user-positioned frame.
    public func storePreSnapFrameIfNeeded(_ frame: CGRect, for id: CGWindowID) {
        if preSnapFrames[id] == nil {
            preSnapFrames[id] = frame
        }
    }

    /// Read the cached pre-snap frame without clearing it.
    public func preSnapFrame(for id: CGWindowID) -> CGRect? {
        preSnapFrames[id]
    }

    /// Retrieve and remove the pre-snap frame for a window (consumed on Restore).
    public func consumePreSnapFrame(for id: CGWindowID) -> CGRect? {
        preSnapFrames.removeValue(forKey: id)
    }

    /// Explicitly clear the stored pre-snap frame for a window.
    public func clearPreSnapFrame(for id: CGWindowID) {
        preSnapFrames.removeValue(forKey: id)
    }
}

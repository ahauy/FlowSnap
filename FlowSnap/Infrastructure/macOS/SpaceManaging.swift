import Foundation

/// Abstraction for macOS Spaces/Desktops observation.
///
/// macOS does not provide a full public API for managing Spaces,
/// so this protocol only exposes what can be done safely.
/// See spec §50.
protocol SpaceManaging {
    /// Information about the current Space context.
    func currentContext() -> SpaceContext

    /// Start observing Space changes.
    func observeSpaceChanges()
}

/// Minimal information about the current Space.
struct SpaceContext {
    /// Whether the current space changed since last check.
    let didChange: Bool

    // TODO: Add observable properties as macOS APIs allow
}

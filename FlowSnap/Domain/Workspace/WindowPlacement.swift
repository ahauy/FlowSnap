import Foundation

/// Maps an application to a layout zone within a workspace.
///
/// Uses bundle identifier (not window ID) so placements survive
/// app restarts. See spec §38.
struct WindowPlacement: Codable, Hashable {
    /// The app's bundle identifier (e.g. "com.apple.Safari").
    var bundleIdentifier: String

    /// The layout zone this app should occupy.
    var zoneID: UUID
}

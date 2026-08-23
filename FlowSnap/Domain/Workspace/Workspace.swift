import Foundation

/// A saved workspace configuration that can be restored.
///
/// Stores the *intent* of window arrangement (which app goes where),
/// not pixel-exact positions. This makes workspaces portable across
/// display configurations. See spec §38.
struct Workspace: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var placements: [WindowPlacement]

    init(id: UUID = UUID(), name: String, icon: String = "desktopcomputer", placements: [WindowPlacement] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.placements = placements
    }
}

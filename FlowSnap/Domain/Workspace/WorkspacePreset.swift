import Foundation

/// An immutable workflow template defining multi-window layout intents and application archetypes (spec §1.1).
public struct WorkspacePreset: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var description: String
    public var iconSymbolName: String
    public var defaultShortcut: KeyboardShortcut?
    public var defaultRatio: LayoutRatio
    public var slots: [PresetAppSlot]
    public var autoGroupWindows: Bool

    public init(
        id: String,
        name: String,
        description: String,
        iconSymbolName: String,
        defaultShortcut: KeyboardShortcut? = nil,
        defaultRatio: LayoutRatio = .seventyThirty,
        slots: [PresetAppSlot],
        autoGroupWindows: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconSymbolName = iconSymbolName
        self.defaultShortcut = defaultShortcut
        self.defaultRatio = defaultRatio
        self.slots = slots
        self.autoGroupWindows = autoGroupWindows
    }
}

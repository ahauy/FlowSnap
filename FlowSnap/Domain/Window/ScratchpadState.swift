import Foundation

/// Finite state enum representing the visibility and registration lifecycle of the Scratchpad.
public enum ScratchpadState: Sendable, Equatable {
    case unassigned
    case visible(record: ScratchpadRecord)
    case hidden(record: ScratchpadRecord)

    public var isAssigned: Bool {
        switch self {
        case .unassigned: return false
        case .visible, .hidden: return true
        }
    }

    public var isVisible: Bool {
        switch self {
        case .visible: return true
        case .unassigned, .hidden: return false
        }
    }

    public var record: ScratchpadRecord? {
        switch self {
        case .unassigned: return nil
        case .visible(let record), .hidden(let record): return record
        }
    }
}

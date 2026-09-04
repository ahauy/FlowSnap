import CoreGraphics
import Foundation
@testable import FlowSnap

@MainActor
public final class MockScratchpadCoordinator: ScratchpadCoordinating {
    public var state: ScratchpadState = .unassigned

    public var currentRecord: ScratchpadRecord? {
        state.record
    }

    public var isVisible: Bool {
        state.isVisible
    }

    public var assignFocusedWindowCallsCount: Int = 0
    public var toggleScratchpadCallsCount: Int = 0
    public var summonScratchpadCallsCount: Int = 0
    public var dismissScratchpadCallsCount: Int = 0
    public var detachScratchpadCallsCount: Int = 0

    public var assignFocusedWindowResult: Bool = true
    public var toggleScratchpadResult: Bool = true
    public var summonScratchpadResult: Bool = true
    public var dismissScratchpadResult: Bool = true

    public init(initialState: ScratchpadState = .unassigned) {
        self.state = initialState
    }

    public func assignFocusedWindow() async -> Bool {
        assignFocusedWindowCallsCount += 1
        return assignFocusedWindowResult
    }

    public func toggleScratchpad() async -> Bool {
        toggleScratchpadCallsCount += 1
        if state.isVisible {
            return await dismissScratchpad()
        } else {
            return await summonScratchpad()
        }
    }

    public func summonScratchpad() async -> Bool {
        summonScratchpadCallsCount += 1
        if let record = currentRecord {
            state = .visible(record: record)
        }
        return summonScratchpadResult
    }

    public func dismissScratchpad() async -> Bool {
        dismissScratchpadCallsCount += 1
        if let record = currentRecord {
            state = .hidden(record: record)
        }
        return dismissScratchpadResult
    }

    public func detachScratchpad() {
        detachScratchpadCallsCount += 1
        state = .unassigned
    }
}

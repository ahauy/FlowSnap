import CoreGraphics
import Foundation
@testable import FlowSnap

@MainActor
public final class MockWindowPinningCoordinator: WindowPinningCoordinating {
    public var pinnedWindows: [PinnedWindowRecord] = []
    public var isPinningActive: Bool { !pinnedWindows.isEmpty }

    public var togglePinCalls: [ManagedWindow] = []
    public var unpinCalls: [CGWindowID] = []
    public var unpinAllCallsCount: Int = 0
    public var handleFocusChangeCalls: [(activeWindowID: CGWindowID?, activePID: pid_t?)] = []

    public var togglePinResult: Bool?

    public init() {}

    public func isPinned(windowID: CGWindowID) -> Bool {
        pinnedWindows.contains { $0.id == windowID }
    }

    public func togglePin(window: ManagedWindow) async -> Bool {
        togglePinCalls.append(window)
        if let explicit = togglePinResult {
            return explicit
        }
        if let idx = pinnedWindows.firstIndex(where: { $0.id == window.id }) {
            pinnedWindows.remove(at: idx)
            return false
        } else {
            let record = PinnedWindowRecord(
                id: window.id,
                pid: window.pid,
                bundleIdentifier: window.bundleIdentifier,
                title: window.title
            )
            pinnedWindows.insert(record, at: 0)
            return true
        }
    }

    public func unpin(windowID: CGWindowID) {
        unpinCalls.append(windowID)
        pinnedWindows.removeAll { $0.id == windowID }
    }

    public func unpinAll() {
        unpinAllCallsCount += 1
        pinnedWindows.removeAll()
    }

    public func handleFocusChange(activeWindowID: CGWindowID?, activePID: pid_t?) async {
        handleFocusChangeCalls.append((activeWindowID, activePID))
    }
}

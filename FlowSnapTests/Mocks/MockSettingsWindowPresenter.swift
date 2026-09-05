import Foundation
@testable import FlowSnap

@MainActor
public final class MockSettingsWindowPresenter: SettingsWindowPresenting {

    public var showSettingsWindowCallCount: Int = 0
    public var lastRequestedTab: SettingsTab?

    public init() {}

    public func showSettingsWindow() {
        showSettingsWindowCallCount += 1
    }

    public func showSettingsWindow(tab: SettingsTab) {
        showSettingsWindowCallCount += 1
        lastRequestedTab = tab
    }
}


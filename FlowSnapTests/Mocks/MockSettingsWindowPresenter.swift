import Foundation
@testable import FlowSnap

@MainActor
public final class MockSettingsWindowPresenter: SettingsWindowPresenting {

    public var showSettingsWindowCallCount: Int = 0

    public init() {}

    public func showSettingsWindow() {
        showSettingsWindowCallCount += 1
    }
}

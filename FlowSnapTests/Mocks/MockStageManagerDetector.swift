import Foundation
@testable import FlowSnap

/// Test double for `StageManagerDetecting` allowing tests to simulate Stage Manager states.
public final class MockStageManagerDetector: StageManagerDetecting, @unchecked Sendable {
    public var isStageManagerEnabled: Bool

    public init(isStageManagerEnabled: Bool = false) {
        self.isStageManagerEnabled = isStageManagerEnabled
    }
}

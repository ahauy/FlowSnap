import Foundation
@testable import FlowSnap

@MainActor
public final class MockStageManagerLaunchCoordinator: StageManagerLaunchCoordinating {
    public var isCoexistenceEnabled: Bool = true
    public var handleApplicationLaunchedCalls: [(pid: pid_t, bundleID: String?)] = []

    public init() {}

    public func handleApplicationLaunched(processIdentifier: pid_t, bundleIdentifier: String?) async {
        handleApplicationLaunchedCalls.append((processIdentifier, bundleIdentifier))
    }
}

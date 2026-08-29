import Foundation
@testable import FlowSnap

public final class MockCommandDispatcher: CommandDispatching, @unchecked Sendable {

    public var dispatchedCommands: [WindowCommand] = []
    public var dispatchCallCount: Int = 0

    public init() {}

    public func dispatch(_ command: WindowCommand) async throws {
        dispatchCallCount += 1
        dispatchedCommands.append(command)
    }
}

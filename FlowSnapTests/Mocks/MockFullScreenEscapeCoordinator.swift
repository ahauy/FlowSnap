import ApplicationServices
import Foundation
@testable import FlowSnap

public final class MockFullScreenEscapeCoordinator: FullScreenEscapeCoordinating, @unchecked Sendable {
    public var callCount = 0
    public var lastElement: AXUIElement?
    public var lastPid: pid_t?
    public var stubbedResult: FullScreenEscapeResult = .success(tier: .attributeWrite, durationMs: 5)
    public var shouldThrow: Error?

    public init() {}

    public func exitFullScreen(
        for element: AXUIElement,
        pid: pid_t?,
        isFullScreenChecker: (@Sendable () async -> Bool)? = nil
    ) async throws -> FullScreenEscapeResult {
        callCount += 1
        lastElement = element
        lastPid = pid
        if let shouldThrow {
            throw shouldThrow
        }
        return stubbedResult
    }
}

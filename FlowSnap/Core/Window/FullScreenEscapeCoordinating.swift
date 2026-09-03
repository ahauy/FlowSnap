import ApplicationServices
import Foundation

/// Protocol coordinating multi-tier escape from macOS full screen mode with adaptive transition waiting.
public protocol FullScreenEscapeCoordinating: Sendable {
    /// Requests the window element to exit full screen mode, escalating through Tiers 0 -> 1 -> 2 as needed,
    /// and waits adaptively (every 100ms, max 800ms) until `isFullScreenChecker` reports false.
    func exitFullScreen(
        for element: AXUIElement,
        pid: pid_t?,
        isFullScreenChecker: (@Sendable () async -> Bool)?
    ) async throws -> FullScreenEscapeResult
}

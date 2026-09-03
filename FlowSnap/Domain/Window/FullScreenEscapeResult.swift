import Foundation

/// Telemetry and execution outcome of a full-screen escape request.
public struct FullScreenEscapeResult: Sendable, Equatable, Codable {
    public let succeeded: Bool
    public let tierUsed: FullScreenEscapeTier?
    public let durationMs: Int
    public let error: String?

    public init(succeeded: Bool, tierUsed: FullScreenEscapeTier?, durationMs: Int, error: String? = nil) {
        self.succeeded = succeeded
        self.tierUsed = tierUsed
        self.durationMs = durationMs
        self.error = error
    }

    public static func success(tier: FullScreenEscapeTier, durationMs: Int) -> FullScreenEscapeResult {
        FullScreenEscapeResult(succeeded: true, tierUsed: tier, durationMs: durationMs, error: nil)
    }

    public static func failure(durationMs: Int, error: String) -> FullScreenEscapeResult {
        FullScreenEscapeResult(succeeded: false, tierUsed: nil, durationMs: durationMs, error: error)
    }
}

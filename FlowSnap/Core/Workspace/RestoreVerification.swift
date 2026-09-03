import CoreGraphics
import Foundation

/// Fixed P0 timing and geometry values for a verified restore.
///
/// Keeping these values behind a named policy gives the restore coordinator one
/// source of truth and keeps timing decisions out of orchestration code. They
/// are intentionally not persisted or user-configurable in P0.
public enum RestoreVerificationPolicy {

    /// Maximum difference allowed for each frame component, in points.
    public static let frameTolerance: CGFloat = 30

    /// Total move attempts per placement, including the first attempt.
    public static let maxAttempts = 3

    /// Delay after attempts one and two, respectively.
    public static let retryBackoff: [Duration] = [
        .milliseconds(100),
        .milliseconds(200)
    ]

    /// Maximum time allowed for a full-screen transition to become observable.
    public static let fullscreenTimeout: Duration = .seconds(2)

    /// Poll interval used while waiting for full-screen exit.
    public static let fullscreenPollInterval: Duration = .milliseconds(100)

    /// Returns the delay before the next attempt, if another attempt is allowed.
    /// `attempt` is one-based and denotes the attempt that just failed.
    public static func retryDelay(afterAttempt attempt: Int) -> Duration? {
        guard attempt > 0 else { return nil }
        let index = attempt - 1
        guard retryBackoff.indices.contains(index) else { return nil }
        return retryBackoff[index]
    }
}

/// Post-condition evidence collected after a frame write.
///
/// This proves only geometry and exposed AX state. It deliberately makes no
/// claim about whether the window is visible on the current macOS Space.
public struct WindowVerificationResult: Equatable, Hashable, Sendable {

    public let frameMatches: Bool
    public let isMinimized: Bool
    public let isFullscreen: Bool

    public var isPlacementVerified: Bool {
        frameMatches && !isMinimized && !isFullscreen
    }

    public init(frameMatches: Bool, isMinimized: Bool, isFullscreen: Bool) {
        self.frameMatches = frameMatches
        self.isMinimized = isMinimized
        self.isFullscreen = isFullscreen
    }

    /// Builds evidence from an optional read-back frame. A missing frame is
    /// represented as a mismatch and can never be treated as placement success.
    public init(
        targetFrame: CGRect,
        actualFrame: CGRect?,
        isMinimized: Bool,
        isFullscreen: Bool,
        tolerance: CGFloat = RestoreVerificationPolicy.frameTolerance
    ) {
        self.init(
            frameMatches: Self.framesMatch(targetFrame, actualFrame, tolerance: tolerance),
            isMinimized: isMinimized,
            isFullscreen: isFullscreen
        )
    }

    /// Compares each origin and size component independently, as required by
    /// BR-WRV-002. This avoids area-based comparisons that can hide a shifted
    /// or differently sized window.
    public static func framesMatch(
        _ target: CGRect,
        _ actual: CGRect?,
        tolerance: CGFloat = RestoreVerificationPolicy.frameTolerance
    ) -> Bool {
        guard let actual else { return false }
        return abs(target.origin.x - actual.origin.x) <= tolerance
            && abs(target.origin.y - actual.origin.y) <= tolerance
            && abs(target.size.width - actual.size.width) <= tolerance
            && abs(target.size.height - actual.size.height) <= tolerance
    }
}

/// Internal outcome of one placement operation sequence before summary mapping.
///
/// The restore coordinator uses this small result to distinguish an operation
/// error from a placement that could not be proven. It does not expose retry
/// mechanics to callers.
public enum MoveOutcome {
    case moved
    case failed(any Error)
    case unverifiable
}

/// Observation-only outcome of whether a moved window is actually presented on
/// the user's current screen (P0.5 — workspace presentation observation).
///
/// This is the domain-side view of `OnScreenObservationResult`: it carries the
/// three semantic states without the infrastructure reason payload. It never
/// mixes with `MoveOutcome` — geometry/state proof (ADR-0008) and current-screen
/// presentation are two independent axes, mapped together only in the summary.
public enum PresentationOutcome: Equatable, Sendable {
    /// The window appears on the current screen.
    case presented

    /// The window does not appear on the current screen.
    case notPresented

    /// The presentation could not be observed; presence is unknown.
    case unverifiable
}

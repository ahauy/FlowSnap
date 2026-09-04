import Foundation

/// Defines the contract for Stage Manager multi-window cohesion when applications launch.
@MainActor
public protocol StageManagerLaunchCoordinating: AnyObject, Sendable {
    /// Whether launch co-existence is enabled.
    var isCoexistenceEnabled: Bool { get set }

    /// Handles an application launch event, snapshotting and preserving the active Stage.
    func handleApplicationLaunched(processIdentifier: pid_t, bundleIdentifier: String?) async
}

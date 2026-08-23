import Foundation

/// Manages per-app window placement policies.
///
/// Determines how a newly opened or activated window should
/// behave: stay on current space, float, remember position, etc.
/// See spec §37.
@MainActor
final class WindowPolicyManager {

    private var policies: [String: WindowPolicy] = [:]

    /// The default policy for apps without a specific rule.
    var defaultPolicy: WindowPolicy = .currentSpace

    /// Set the policy for a specific app.
    func setPolicy(_ policy: WindowPolicy, forBundleID bundleID: String) {
        policies[bundleID] = policy
    }

    /// Get the policy for a specific app (falls back to default).
    func policy(forBundleID bundleID: String) -> WindowPolicy {
        policies[bundleID] ?? defaultPolicy
    }

    /// Apply the appropriate policy when a window appears.
    func applyPolicy(for window: ManagedWindow) async throws {
        // TODO: Look up policy, execute appropriate action
    }
}

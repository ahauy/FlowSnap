import Foundation

/// Per-app behavior rule mapping an application to its window placement policy.
///
/// See spec §37, US-WORK-014.
public struct AppPolicyRule: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let bundleID: String
    public var appName: String
    public var policy: WindowPolicy
    public var iconName: String

    public init(
        id: UUID = UUID(),
        bundleID: String,
        appName: String,
        policy: WindowPolicy,
        iconName: String = "app.dashed"
    ) {
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.policy = policy
        self.iconName = iconName
    }
}

//
//  WindowPolicyContracts.swift
//  FlowSnap
//
//  Contract DTOs and Interfaces for Per-App Window Policies & Floating Stack
//

import CoreGraphics
import Foundation

// MARK: - App Policy Rule DTO

public struct AppPolicyRuleDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let bundleID: String
    public let appName: String
    public let policy: WindowPolicy
    public let iconName: String

    public init(id: UUID = UUID(), bundleID: String, appName: String, policy: WindowPolicy, iconName: String = "app.dashed") {
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.policy = policy
        self.iconName = iconName
    }
}

// MARK: - Frame Clamping Contract

public protocol FrameClamping: Sendable {
    static func clamp(frame: CGRect, to visibleBounds: CGRect, minimumVisibleRatio: CGFloat) -> CGRect
}

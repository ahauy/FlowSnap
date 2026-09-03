import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite
struct WindowPolicyModelTests {

    @Test func appPolicyRuleEncodesAndDecodesCleanly() throws {
        let original = AppPolicyRule(
            id: UUID(),
            bundleID: "com.microsoft.VSCode",
            appName: "Visual Studio Code",
            policy: .assignedLayout(.left70_30),
            iconName: "chevron.left.forwardslash.chevron.right"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppPolicyRule.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.bundleID == original.bundleID)
        #expect(decoded.appName == original.appName)
        #expect(decoded.policy == original.policy)
        #expect(decoded.iconName == original.iconName)
    }

    @Test func rememberedFrameEncodesAndDecodesCleanly() throws {
        let frame = CGRect(x: 150, y: 250, width: 900, height: 700)
        let original = RememberedFrame(
            bundleID: "com.spotify.client",
            frame: frame,
            displayID: 12345
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RememberedFrame.self, from: data)

        #expect(decoded.bundleID == original.bundleID)
        #expect(decoded.frame == original.frame)
        #expect(decoded.displayID == original.displayID)
    }
}

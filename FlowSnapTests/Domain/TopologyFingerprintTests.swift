import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for TopologyFingerprint and DisplayTopologyProfile.
///
/// Traces to: US-DISP-016, REQ-DISP-003, BR-DISP-007, TC-016-01, TC-016-02.
struct TopologyFingerprintTests {

    private func makeDisplay(
        id: CGDirectDisplayID,
        originX: CGFloat,
        originY: CGFloat = 0,
        width: CGFloat,
        height: CGFloat,
        isPrimary: Bool = false
    ) -> Display {
        Display(
            id: id,
            frame: CGRect(x: originX, y: originY, width: width, height: height),
            visibleFrame: CGRect(x: originX, y: originY + 25, width: width, height: height - 25),
            scaleFactor: 2.0,
            isPrimary: isPrimary
        )
    }

    @Test func deterministicFingerprintAcrossDisplayOrder() {
        let displayA = makeDisplay(id: 1, originX: 0, width: 1512, height: 982, isPrimary: true)
        let displayB = makeDisplay(id: 2, originX: 1512, width: 1920, height: 1080)

        let fp1 = TopologyFingerprint.generate(from: [displayA, displayB])
        let fp2 = TopologyFingerprint.generate(from: [displayB, displayA])

        #expect(fp1.rawValue == fp2.rawValue)
        #expect(fp1.displayCount == 2)
        #expect(fp1.displayDescriptions.count == 2)
        #expect(!fp1.rawValue.isEmpty)
    }

    @Test func distinctFingerprintsForDifferentResolutions() {
        let displayA = makeDisplay(id: 1, originX: 0, width: 1512, height: 982, isPrimary: true)
        let displayFHD = makeDisplay(id: 2, originX: 1512, width: 1920, height: 1080)
        let display4K = makeDisplay(id: 2, originX: 1512, width: 3840, height: 2160)

        let fpFHD = TopologyFingerprint.generate(from: [displayA, displayFHD])
        let fp4K = TopologyFingerprint.generate(from: [displayA, display4K])

        #expect(fpFHD.rawValue != fp4K.rawValue)
    }

    @Test func singleDisplayFingerprint() {
        let single = makeDisplay(id: 1, originX: 0, width: 1512, height: 982, isPrimary: true)
        let fp = TopologyFingerprint.generate(from: [single])

        #expect(fp.displayCount == 1)
        #expect(fp.displayDescriptions.count == 1)
        #expect(fp.description.contains("1 displays"))
    }

    @Test func emptyDisplaysFallback() {
        let fp = TopologyFingerprint.generate(from: [])
        #expect(fp.displayCount == 0)
        #expect(fp.displayDescriptions.isEmpty)
        #expect(fp.rawValue == "empty")
    }

    @Test func displayTopologyProfileEncodingAndDecoding() throws {
        let display = makeDisplay(id: 1, originX: 0, width: 1512, height: 982, isPrimary: true)
        let fp = TopologyFingerprint.generate(from: [display])

        let placement = WindowPlacement(
            bundleIdentifier: "com.apple.Safari",
            zone: .leftHalf,
            expectedWindowCount: 1,
            orderIndex: 0
        )

        let profile = DisplayTopologyProfile(
            fingerprint: fp,
            name: "Test Desk Profile",
            windowPlacements: ["com.apple.Safari": placement],
            displayIndexMap: ["com.apple.Safari": 0]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DisplayTopologyProfile.self, from: data)

        #expect(decoded.id == profile.id)
        #expect(decoded.fingerprint == fp)
        #expect(decoded.name == "Test Desk Profile")
        #expect(decoded.windowPlacements["com.apple.Safari"]?.bundleIdentifier == "com.apple.Safari")
        #expect(decoded.displayIndexMap["com.apple.Safari"] == 0)
    }
}

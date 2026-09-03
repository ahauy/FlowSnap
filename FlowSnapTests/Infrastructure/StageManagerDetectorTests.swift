import Testing
import Foundation
@testable import FlowSnap

@Suite("StageManagerDetectorTests")
struct StageManagerDetectorTests {

    @Test("StageManagerDetector returns false when key is not present")
    func testMissingKeyDefaultsToFalse() {
        let suiteName = "com.flowsnap.test.windowmanager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let detector = StageManagerDetector(suiteName: suiteName, key: "GloballyEnabled", userDefaults: defaults)
        #expect(!detector.isStageManagerEnabled)
    }

    @Test("StageManagerDetector returns true when GloballyEnabled is true")
    func testGloballyEnabledTrue() {
        let suiteName = "com.flowsnap.test.windowmanager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(true, forKey: "GloballyEnabled")
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let detector = StageManagerDetector(suiteName: suiteName, key: "GloballyEnabled", userDefaults: defaults)
        #expect(detector.isStageManagerEnabled)
    }

    @Test("StageManagerDetector returns false when GloballyEnabled is false")
    func testGloballyEnabledFalse() {
        let suiteName = "com.flowsnap.test.windowmanager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(false, forKey: "GloballyEnabled")
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let detector = StageManagerDetector(suiteName: suiteName, key: "GloballyEnabled", userDefaults: defaults)
        #expect(!detector.isStageManagerEnabled)
    }

    @Test("StageManagerDetector handles integer 1 as true")
    func testGloballyEnabledIntOne() {
        let suiteName = "com.flowsnap.test.windowmanager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(1, forKey: "GloballyEnabled")
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let detector = StageManagerDetector(suiteName: suiteName, key: "GloballyEnabled", userDefaults: defaults)
        #expect(detector.isStageManagerEnabled)
    }
}

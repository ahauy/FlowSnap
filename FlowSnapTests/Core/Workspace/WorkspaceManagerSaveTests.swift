import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// T009 — capture/save orchestration (US-WORK-011 spec §2 J1, BR-WORK-001/002).
///
/// Covers the two halves of "save": `capture(from:)` turning live windows into
/// zone intents, and `saveWorkspace(named:placements:)` persisting them with the
/// validation rules (E1 duplicate name, E2 empty name, E3 nothing eligible).
@MainActor
@Suite("WorkspaceManager Save")
struct WorkspaceManagerSaveTests {

    private func makeManager(
        windows: [ManagedWindow],
        displays: [Display] = WorkspaceTestFixtures.singleDisplay,
        trusted: Bool = true,
        gap: CGFloat = 0
    ) -> WorkspaceManager {
        let accessibility = MockAccessibilityService(isTrusted: trusted)
        accessibility.mockVisibleWindows = windows
        let store = WorkspaceStore(directoryURL: tempDir())
        return WorkspaceManager(
            store: store,
            accessibilityService: accessibility,
            displayManager: MockDisplayManager(displays: displays),
            preferences: WorkspaceTestFixtures.preferences(gap: gap),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
    }

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapSaveTests-\(UUID().uuidString)", isDirectory: true)
        return dir
    }

    private func snapshot(_ window: ManagedWindow) -> WindowGroupSnapshot {
        // swiftlint:disable:next force_unwrapping
        WindowGroupSnapshot(window: window)!
    }

    // MARK: - Zone inference (BR-WORK-002)

    @Test("A window on the left half captures as .leftHalf")
    func leftHalfCaptures() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let manager = makeManager(windows: [win])
        let placements = try await manager.capture(from: [snapshot(win)])

        #expect(placements.count == 1)
        #expect(placements.first?.zone == .leftHalf)
        #expect(placements.first?.bundleIdentifier == "com.editor")
    }

    @Test("A window on the top-right quadrant captures as .topRight")
    func topRightCaptures() async throws {
        // AppKit y-up: the top-right quadrant is x in [720,1440], y in [450,900].
        let win = WorkspaceTestFixtures.window(
            id: 2, bundle: "com.chat", appKitFrame: CGRect(x: 720, y: 450, width: 720, height: 450)
        )
        let manager = makeManager(windows: [win])
        let placements = try await manager.capture(from: [snapshot(win)])
        #expect(placements.first?.zone == .topRight)
    }

    @Test("A full-screen window captures as .maximize")
    func maximizeCaptures() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 3, bundle: "com.browser", appKitFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )
        let manager = makeManager(windows: [win])
        let placements = try await manager.capture(from: [snapshot(win)])
        #expect(placements.first?.zone == .maximize)
    }

    @Test("An oversized window clamps to a valid zone instead of crashing")
    func oversizedClamps() async throws {
        // Larger than the display — normalization clamps to 0...1, so this must
        // still yield a deterministic zone (maximize is the IoU winner).
        let win = WorkspaceTestFixtures.window(
            id: 4, bundle: "com.big", appKitFrame: CGRect(x: -100, y: -100, width: 2000, height: 1200)
        )
        let manager = makeManager(windows: [win])
        let placements = try await manager.capture(from: [snapshot(win)])
        #expect(placements.first?.zone == .maximize)
    }

    // MARK: - Grouping & count (ASM-WORK-002)

    @Test("Two windows of the same app collapse to one placement with count 2")
    func groupsByApp() async throws {
        let first = WorkspaceTestFixtures.window(
            id: 10, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let second = WorkspaceTestFixtures.window(
            id: 11, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 700, height: 880)
        )
        let manager = makeManager(windows: [first, second])
        let placements = try await manager.capture(from: [snapshot(first), snapshot(second)])

        #expect(placements.count == 1)
        #expect(placements.first?.expectedWindowCount == 2)
    }

    @Test("orderIndex is a dense 0..<n run in left-to-right order")
    func orderIndexDense() async throws {
        let left = WorkspaceTestFixtures.window(
            id: 20, bundle: "com.left", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let right = WorkspaceTestFixtures.window(
            id: 21, bundle: "com.right", appKitFrame: CGRect(x: 720, y: 0, width: 720, height: 900)
        )
        let manager = makeManager(windows: [right, left])
        let placements = try await manager.capture(from: [snapshot(right), snapshot(left)])

        #expect(placements.map(\.orderIndex) == [0, 1])
        #expect(placements.first?.bundleIdentifier == "com.left")
    }

    // MARK: - Eligibility (BR-WORK-001)

    @Test("FlowSnap's own windows are never captured")
    func excludesOwnPanels() async throws {
        let own = WorkspaceTestFixtures.window(
            id: 30, bundle: "com.flowsnap.app", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let manager = makeManager(windows: [own])
        await #expect(throws: WindowCaptureError.noEligibleWindows(
            .init(seen: 1, ownPanels: 1, nonNormal: 0, zeroArea: 0)
        )) {
            _ = try await manager.capture(from: [snapshot(own)])
        }
    }

    @Test("Non-normal windows are excluded")
    func excludesNonNormal() async throws {
        let panel = WorkspaceTestFixtures.window(
            id: 31, bundle: "com.util", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900),
            kind: .utility
        )
        let manager = makeManager(windows: [panel])
        await #expect(throws: WindowCaptureError.self) {
            _ = try await manager.capture(from: [snapshot(panel)])
        }
    }

    // MARK: - Permission (E11)

    @Test("Capture throws accessibilityDenied when untrusted")
    func deniedThrows() async {
        let win = WorkspaceTestFixtures.window(
            id: 40, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let manager = makeManager(windows: [win], trusted: false)
        await #expect(throws: WindowCaptureError.accessibilityDenied) {
            _ = try await manager.capture(from: [snapshot(win)])
        }
    }

    // MARK: - Save validation (E1/E2/E3)

    @Test("Saving persists a workspace and refreshes the published list")
    func savePersists() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let scoped = WorkspaceManager(
            store: WorkspaceStore(directoryURL: dir),
            accessibilityService: MockAccessibilityService(isTrusted: true),
            preferences: WorkspaceTestFixtures.preferences(),
            loadAtInit: false
        )
        let placements = [WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]
        let saved = try await scoped.saveWorkspace(named: "Coding", placements: placements)

        #expect(saved.name == "Coding")
        #expect(scoped.workspaces.count == 1)

        // And it survives a fresh manager reading the same directory — the point
        // of persisting at all.
        let reopened = WorkspaceManager(
            store: WorkspaceStore(directoryURL: dir),
            accessibilityService: MockAccessibilityService(isTrusted: true),
            preferences: WorkspaceTestFixtures.preferences(),
            loadAtInit: false
        )
        await reopened.reload()
        #expect(reopened.workspaces.map(\.name) == ["Coding"])
        #expect(reopened.workspaces.first?.placements.first?.zone == .leftHalf)
    }

    @Test("Empty name is rejected (E2)")
    func emptyNameRejected() async throws {
        let scoped = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: MockAccessibilityService(),
            preferences: WorkspaceTestFixtures.preferences(),
            loadAtInit: false
        )
        await #expect(throws: WorkspaceError.invalidName) {
            _ = try await scoped.saveWorkspace(named: "   ", placements: [
                WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)
            ])
        }
    }

    @Test("Duplicate name (case-insensitive) is rejected (E1/BR-WORK-008)")
    func duplicateNameRejected() async throws {
        let scoped = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: MockAccessibilityService(),
            preferences: WorkspaceTestFixtures.preferences(),
            loadAtInit: false
        )
        _ = try await scoped.saveWorkspace(named: "Coding", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)
        ])
        await #expect(throws: WorkspaceError.duplicateName("coding")) {
            _ = try await scoped.saveWorkspace(named: "coding", placements: [
                WindowPlacement(bundleIdentifier: "com.other", zone: .rightHalf)
            ])
        }
    }

    @Test("No placements is rejected (E3)")
    func emptyPlacementsRejected() async throws {
        let scoped = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: MockAccessibilityService(),
            preferences: WorkspaceTestFixtures.preferences(),
            loadAtInit: false
        )
        await #expect(throws: WorkspaceError.noEligibleWindows) {
            _ = try await scoped.saveWorkspace(named: "Empty", placements: [])
        }
    }
}

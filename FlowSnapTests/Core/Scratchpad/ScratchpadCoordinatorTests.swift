import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite @MainActor
struct ScratchpadCoordinatorTests {

    private func makePreferencesStore() -> PreferencesStore {
        let defaults = UserDefaults(suiteName: "test_scratchpad_\(UUID().uuidString)") ?? .standard
        return PreferencesStore(defaults: defaults)
    }

    private func makeWindow(
        id: CGWindowID,
        pid: pid_t,
        title: String,
        bundleID: String = "com.test.app",
        frame: CGRect = CGRect(x: 100, y: 100, width: 600, height: 400)
    ) -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid,
            bundleIdentifier: bundleID,
            title: title,
            frame: frame,
            kind: .normal
        )
    }

    // MARK: - TC-SCRATCH-001: Assign Focused Window as Scratchpad
    @Test func assignFocusedWindowWhenActiveWindowExists() async {
        let mockAX = MockAccessibilityService()
        let window = makeWindow(id: 201, pid: 500, title: "iTerm2 Terminal", bundleID: "com.googlecode.iterm2")
        mockAX.mockFocusedManagedWindow = window

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore()
        )

        let success = await coordinator.assignFocusedWindow()
        #expect(success == true)
        #expect(coordinator.state.isAssigned == true)
        #expect(coordinator.currentRecord?.windowID == 201)
        #expect(coordinator.currentRecord?.pid == 500)
        #expect(coordinator.currentRecord?.appName == "iTerm2 Terminal")
    }

    // MARK: - TC-SCRATCH-002: Re-assigning Replaces Prior Scratchpad
    @Test func reassigningScratchpadReplacesPrevious() async {
        let mockAX = MockAccessibilityService()
        let window1 = makeWindow(id: 201, pid: 500, title: "iTerm2")
        let window2 = makeWindow(id: 202, pid: 600, title: "Calculator")
        mockAX.mockFocusedManagedWindow = window1

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore()
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.currentRecord?.windowID == 201)

        mockAX.mockFocusedManagedWindow = window2
        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.currentRecord?.windowID == 202)
        #expect(coordinator.currentRecord?.appName == "Calculator")
    }

    // MARK: - TC-SCRATCH-003: Detach Scratchpad
    @Test func detachScratchpadTransitionsToUnassigned() async {
        let mockAX = MockAccessibilityService()
        let window = makeWindow(id: 201, pid: 500, title: "iTerm2")
        mockAX.mockFocusedManagedWindow = window

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore()
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.state.isAssigned == true)

        coordinator.detachScratchpad()
        #expect(coordinator.state == .unassigned)
        #expect(coordinator.currentRecord == nil)
    }

    // MARK: - TC-SCRATCH-004: Instant Summon (< 50ms) Caches PreSummonFocus and Activates
    @Test func summonScratchpadCachesPreSummonFocusAndRaises() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        let braveWindow = makeWindow(id: 101, pid: 700, title: "Brave Browser", bundleID: "com.brave.Browser")

        mockAX.mockFocusedManagedWindow = scratchpadWindow
        var activatedPIDs: [pid_t] = []

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationActivator: { pid in
                activatedPIDs.append(pid)
                return true
            }
        )

        _ = await coordinator.assignFocusedWindow()
        _ = await coordinator.dismissScratchpad()
        #expect(coordinator.state.isVisible == false)

        // Now user is working in Brave
        mockAX.mockFocusedManagedWindow = braveWindow

        let summonSuccess = await coordinator.summonScratchpad()
        #expect(summonSuccess == true)
        #expect(coordinator.state.isVisible == true)
        #expect(coordinator.preSummonFocus?.pid == 700)
        #expect(coordinator.preSummonFocus?.windowID == 101)
        #expect(activatedPIDs.contains(500))
    }

    // MARK: - TC-SCRATCH-005: Hybrid Dismiss for Single-Window Application
    @Test func hybridDismissForSingleWindowHidesProcess() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        var hiddenPIDs: [pid_t] = []
        var activatedPIDs: [pid_t] = []

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationHider: { pid in
                hiddenPIDs.append(pid)
                return true
            },
            applicationActivator: { pid in
                activatedPIDs.append(pid)
                return true
            },
            windowCountProvider: { _ in 1 } // exactly 1 window
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.state.isVisible == true)

        let dismissSuccess = await coordinator.dismissScratchpad()
        #expect(dismissSuccess == true)
        #expect(coordinator.state.isVisible == false)
        #expect(hiddenPIDs.contains(500))
    }

    // MARK: - TC-SCRATCH-006: Hybrid Dismiss for Multi-Window Application
    @Test func hybridDismissForMultiWindowDoesNotHideProcess() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "Chrome")
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        var hiddenPIDs: [pid_t] = []
        var activatedPIDs: [pid_t] = []

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationHider: { pid in
                hiddenPIDs.append(pid)
                return true
            },
            applicationActivator: { pid in
                activatedPIDs.append(pid)
                return true
            },
            windowCountProvider: { _ in 3 } // multiple windows
        )

        _ = await coordinator.assignFocusedWindow()
        let dismissSuccess = await coordinator.dismissScratchpad()

        #expect(dismissSuccess == true)
        #expect(coordinator.state.isVisible == false)
        #expect(hiddenPIDs.isEmpty) // must NOT call hide() for multi-window app
    }

    // MARK: - TC-SCRATCH-007: Pre-Summon Focus Restoration
    @Test func preSummonFocusRestorationReactivatesPreviousApp() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        let braveWindow = makeWindow(id: 101, pid: 700, title: "Brave")

        var activatedPIDs: [pid_t] = []

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationHider: { _ in true },
            applicationActivator: { pid in
                activatedPIDs.append(pid)
                return true
            },
            windowCountProvider: { _ in 1 }
        )

        mockAX.mockFocusedManagedWindow = scratchpadWindow
        _ = await coordinator.assignFocusedWindow()
        _ = await coordinator.dismissScratchpad()

        // Focus Brave and summon
        mockAX.mockFocusedManagedWindow = braveWindow
        _ = await coordinator.summonScratchpad()
        #expect(coordinator.preSummonFocus?.pid == 700)

        // Dismiss and verify Brave is reactivated
        activatedPIDs.removeAll()
        _ = await coordinator.dismissScratchpad()
        #expect(activatedPIDs.contains(700))
    }

    // MARK: - TC-SCRATCH-008: Safe Fallback when Pre-Summon Process Terminated
    @Test func safeFallbackWhenPreSummonAppTerminated() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationHider: { _ in true },
            applicationActivator: { _ in false }, // simulated failure / dead process
            windowCountProvider: { _ in 1 }
        )

        mockAX.mockFocusedManagedWindow = scratchpadWindow
        _ = await coordinator.assignFocusedWindow()

        let dismissSuccess = await coordinator.dismissScratchpad()
        #expect(dismissSuccess == true)
        #expect(coordinator.state.isVisible == false)
    }

    // MARK: - TC-SCRATCH-009: ESC Key Dismiss
    @Test func escKeyDismissWhenActive() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        let prefs = makePreferencesStore()
        prefs.setScratchpadDismissOnEscEnabled(true)

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: prefs,
            applicationHider: { _ in true },
            windowCountProvider: { _ in 1 }
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.state.isVisible == true)

        let handled = await coordinator.handleEscKey()
        #expect(handled == true)
        #expect(coordinator.state.isVisible == false)
    }

    // MARK: - TC-SCRATCH-010: Dismiss on Blur (Outside Click)
    @Test func dismissOnBlurWhenOutsideClickOccurs() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(
            id: 201,
            pid: 500,
            title: "iTerm2",
            frame: CGRect(x: 200, y: 200, width: 500, height: 400)
        )
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        let prefs = makePreferencesStore()
        prefs.setScratchpadDismissOnBlurEnabled(true)

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: prefs,
            applicationHider: { _ in true },
            windowCountProvider: { _ in 1 }
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.state.isVisible == true)

        // Click outside frame: (50, 50)
        let handled = await coordinator.handleClickOutside(clickLocation: CGPoint(x: 50, y: 50))
        #expect(handled == true)
        #expect(coordinator.state.isVisible == false)
    }

    // MARK: - TC-SCRATCH-011: Safe Lifecycle Detach on App Termination
    @Test func appTerminationAutoDetachesScratchpad() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore()
        )

        _ = await coordinator.assignFocusedWindow()
        #expect(coordinator.state.isAssigned == true)

        coordinator.handleApplicationTerminated(processIdentifier: 500)
        #expect(coordinator.state == .unassigned)
        #expect(coordinator.currentRecord == nil)
    }

    // MARK: - TC-SCRATCH-012: Dead Window UIElement Auto-Purge
    @Test func deadWindowAutoPurgesOnSummonFailure() async {
        let mockAX = MockAccessibilityService()
        let scratchpadWindow = makeWindow(id: 201, pid: 500, title: "iTerm2")
        mockAX.mockFocusedManagedWindow = scratchpadWindow

        let coordinator = ScratchpadCoordinator(
            accessibilityService: mockAX,
            preferencesStore: makePreferencesStore(),
            applicationActivator: { _ in false } // dead process / failure
        )

        _ = await coordinator.assignFocusedWindow()
        _ = await coordinator.dismissScratchpad()

        // Configure mock AX to fail raise
        mockAX.isTrusted = false
        _ = await coordinator.summonScratchpad()

        #expect(coordinator.state == .unassigned)
    }
}

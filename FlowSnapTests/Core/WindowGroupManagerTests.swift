import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("WindowGroupManager Lifecycle & Invariant Tests")
struct WindowGroupManagerTests {

    @MainActor
    @Test("createGroup requires at least 2 windows")
    func testCreateGroupMinimumCardinality() {
        let mockAX = MockAccessibilityService()
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        let emptyGroup = manager.createGroup(name: "Empty", windowIDs: [])
        #expect(emptyGroup == nil)
        #expect(manager.activeGroups.isEmpty)

        let singleGroup = manager.createGroup(name: "Single", windowIDs: [101])
        #expect(singleGroup == nil)
        #expect(manager.activeGroups.isEmpty)

        let validGroup = manager.createGroup(name: "Pair", windowIDs: [101, 102])
        #expect(validGroup != nil)
        #expect(manager.activeGroups.count == 1)
        #expect(manager.activeGroups.first?.name == "Pair")
        #expect(manager.activeGroups.first?.memberCount == 2)
    }

    @MainActor
    @Test("removeWindow dissolves group when member count drops below 2")
    func testRemoveWindowAutoDissolution() {
        let mockAX = MockAccessibilityService()
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        guard let group = manager.createGroup(name: "Pair", windowIDs: [101, 102]) else {
            Issue.record("Failed to create group")
            return
        }

        #expect(manager.activeGroups.count == 1)
        manager.removeWindow(101, fromGroup: group.id)

        #expect(manager.activeGroups.isEmpty)
        #expect(manager.group(for: 102) == nil)
    }

    @MainActor
    @Test("handleWindowDestroyed prunes member and dissolves if < 2")
    func testHandleWindowDestroyed() {
        let mockAX = MockAccessibilityService()
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        let group3 = manager.createGroup(name: "Trio", windowIDs: [101, 102, 103])
        #expect(group3 != nil)
        #expect(manager.activeGroups.count == 1)

        // Destroy 1 window: group remains with 2 windows
        manager.handleWindowDestroyed(windowID: 101)
        #expect(manager.activeGroups.count == 1)
        #expect(manager.activeGroups.first?.memberCount == 2)
        #expect(manager.group(for: 101) == nil)
        #expect(manager.group(for: 102) != nil)

        // Destroy another window: group dissolves (< 2 windows)
        manager.handleWindowDestroyed(windowID: 102)
        #expect(manager.activeGroups.isEmpty)
    }

    @MainActor
    @Test("Windows cannot belong to multiple groups simultaneously")
    func testSingleGroupMembershipInvariant() {
        let mockAX = MockAccessibilityService()
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        let groupA = manager.createGroup(name: "Group A", windowIDs: [101, 102, 103])
        #expect(groupA != nil)
        #expect(manager.activeGroups.count == 1)

        // Creating group B stealing 102 and 103 leaves group A with 1 window -> group A dissolves
        let groupB = manager.createGroup(name: "Group B", windowIDs: [102, 103, 104])
        #expect(groupB != nil)
        #expect(manager.activeGroups.count == 1)
        #expect(manager.activeGroups.first?.name == "Group B")
        #expect(manager.group(for: 101) == nil)
        #expect(manager.group(for: 102)?.name == "Group B")
    }

    @MainActor
    @Test("addWindow and dissolveGroup behave correctly")
    func testAddWindowAndDissolveGroup() {
        let mockAX = MockAccessibilityService()
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        guard let group = manager.createGroup(name: "Trio", windowIDs: [101, 102]) else {
            Issue.record("Failed to create group")
            return
        }

        manager.addWindow(103, toGroup: group.id)
        #expect(manager.group(for: 103)?.id == group.id)
        #expect(manager.activeGroups.first?.memberCount == 3)

        manager.dissolveGroup(id: group.id)
        #expect(manager.activeGroups.isEmpty)
        #expect(manager.group(for: 101) == nil)
    }
}

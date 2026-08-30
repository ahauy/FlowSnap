import Carbon
import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for ShortcutAction enum and taxonomy.
///
/// Traces to: US-SNAP-010, BR-SET-001, TC-SET-001.
struct ShortcutActionTests {

    @Test func allCasesHaveValidDisplayNamesAndCategories() {
        #expect(ShortcutAction.allCases.count >= 14)

        for action in ShortcutAction.allCases {
            #expect(!action.displayName.isEmpty)
            #expect(!action.rawValue.isEmpty)
            #expect(action.id == action.rawValue)
        }
    }

    @Test func defaultShortcutsIntegrity() {
        let left = ShortcutAction.leftHalf.defaultShortcut
        #expect(left != nil)
        #expect(left?.keyCode == 123) // Arrow left
        #expect(left?.displayString == "⌃⌥←")

        let max = ShortcutAction.maximize.defaultShortcut
        #expect(max != nil)
        #expect(max?.keyCode == 126) // Arrow up
        #expect(max?.displayString == "⌃⌥↑")

        let q1 = ShortcutAction.topLeft.defaultShortcut
        #expect(q1 != nil)
        #expect(q1?.keyCode == 18) // 1
        #expect(q1?.displayString == "⌃⌥1")

        let topHalf = ShortcutAction.topHalf.defaultShortcut
        #expect(topHalf != nil)
        #expect(topHalf?.displayString == "⌃⌥⇧↑")
    }

    @Test func defaultCommandsIntegrity() {
        #expect(ShortcutAction.leftHalf.defaultCommand == .snap(.zone(.leftHalf)))
        #expect(ShortcutAction.rightHalf.defaultCommand == .snap(.zone(.rightHalf)))
        #expect(ShortcutAction.maximize.defaultCommand == .maximize)
        #expect(ShortcutAction.restore.defaultCommand == .restore)
        #expect(ShortcutAction.topLeft.defaultCommand == .snap(.zone(.topLeft)))
    }
}

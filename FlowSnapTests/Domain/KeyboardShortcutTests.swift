import AppKit
import Carbon
import Foundation
import Testing
@testable import FlowSnap

/// Tests for KeyboardShortcut and HotkeyBinding domain models.
///
/// Traces to: US-SNAP-004.3, US-SNAP-010, TC-HOTKEY-001..004, TC-SET-002.
struct KeyboardShortcutTests {

    @Test func arrowKeyGlyphs() {
        let left = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))
        let right = KeyboardShortcut(keyCode: 124, carbonModifiers: UInt32(controlKey | optionKey))
        let down = KeyboardShortcut(keyCode: 125, carbonModifiers: UInt32(controlKey | optionKey))
        let up = KeyboardShortcut(keyCode: 126, carbonModifiers: UInt32(controlKey | optionKey))

        #expect(left.displayString == "⌃⌥←")
        #expect(right.displayString == "⌃⌥→")
        #expect(down.displayString == "⌃⌥↓")
        #expect(up.displayString == "⌃⌥↑")
    }

    @Test func quarterKeyGlyphs() {
        let q1 = KeyboardShortcut(keyCode: 18, carbonModifiers: UInt32(controlKey | optionKey))
        let q2 = KeyboardShortcut(keyCode: 19, carbonModifiers: UInt32(controlKey | optionKey))
        let q3 = KeyboardShortcut(keyCode: 20, carbonModifiers: UInt32(controlKey | optionKey))
        let q4 = KeyboardShortcut(keyCode: 21, carbonModifiers: UInt32(controlKey | optionKey))

        #expect(q1.displayString == "⌃⌥1")
        #expect(q2.displayString == "⌃⌥2")
        #expect(q3.displayString == "⌃⌥3")
        #expect(q4.displayString == "⌃⌥4")
    }

    @Test func letterAndSpecialKeys() {
        let cmdShiftP = KeyboardShortcut(keyCode: 35, carbonModifiers: UInt32(cmdKey | shiftKey))
        #expect(cmdShiftP.displayString == "⇧⌘P")

        let ctrlReturn = KeyboardShortcut(keyCode: 36, carbonModifiers: UInt32(controlKey))
        #expect(ctrlReturn.displayString == "⌃↩")

        let optSpace = KeyboardShortcut(keyCode: 49, carbonModifiers: UInt32(optionKey))
        #expect(optSpace.displayString == "⌥Space")
    }

    @Test func multipleModifiersOrder() {
        let allMods = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey | shiftKey | cmdKey))
        #expect(allMods.displayString == "⌃⌥⇧⌘←")
    }

    @Test func carbonModifiersFromNSEventFlags() {
        let flags: NSEvent.ModifierFlags = [.control, .option]
        let carbon = KeyboardShortcut.carbonModifiers(from: flags)
        #expect(carbon & UInt32(controlKey) != 0)
        #expect(carbon & UInt32(optionKey) != 0)
        #expect(carbon & UInt32(shiftKey) == 0)
    }

    @Test func codableAndEquality() throws {
        let original = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self, from: data)

        #expect(decoded == original)
        #expect(decoded.hashValue == original.hashValue)
    }

    @Test func hotkeyBindingEntityLifecycle() {
        let shortcut = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))
        let binding = HotkeyBinding(id: 1, shortcut: shortcut, command: .snap(.zone(.leftHalf)), isRegistered: false)

        #expect(binding.id == 1)
        #expect(binding.isRegistered == false)

        let registered = binding.withRegistrationStatus(true)
        #expect(registered.isRegistered == true)
        #expect(registered.id == 1)
        #expect(registered.command == .snap(.zone(.leftHalf)))
    }
}

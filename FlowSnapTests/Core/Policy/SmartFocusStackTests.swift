import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite @MainActor
struct SmartFocusStackTests {

    @Test func focusRestorationReturnsPreviousNonFloatingWindow() {
        let stack = SmartFocusStack()

        // 1. Focus a tiled window (ID 10)
        stack.recordFocus(windowID: 10, isFloating: false)

        // 2. Focus another tiled window (ID 20)
        stack.recordFocus(windowID: 20, isFloating: false)

        // 3. Focus a floating chat window (ID 99)
        stack.recordFocus(windowID: 99, isFloating: true)

        // 4. Dismiss/close floating window 99
        let restoreTarget = stack.removeFloatingWindow(windowID: 99)

        // Should return 20 (the last non-floating window)
        #expect(restoreTarget == 20)
    }

    @Test func multipleFloatingWindowsDismissInLIFOOrder() {
        let stack = SmartFocusStack()

        stack.recordFocus(windowID: 10, isFloating: false)
        stack.recordFocus(windowID: 101, isFloating: true)
        stack.recordFocus(windowID: 102, isFloating: true)

        let target1 = stack.removeFloatingWindow(windowID: 102)
        #expect(target1 == 10)

        let target2 = stack.removeFloatingWindow(windowID: 101)
        #expect(target2 == 10)
    }

    @Test func removingNonFloatingWindowUpdatesHistory() {
        let stack = SmartFocusStack()

        stack.recordFocus(windowID: 10, isFloating: false)
        stack.recordFocus(windowID: 20, isFloating: false)

        stack.removeWindow(windowID: 20)
        #expect(stack.currentHistory == [10])
    }
}

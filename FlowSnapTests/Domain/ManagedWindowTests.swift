import Testing
import CoreGraphics
@testable import FlowSnap

struct ManagedWindowTests {

    @Test func standardWindowIsSnappable() {
        let window = ManagedWindow(
            id: 101,
            pid: 1234,
            bundleIdentifier: "com.apple.Safari",
            title: "Safari",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            isMinimized: false,
            isResizable: true,
            kind: .normal
        )

        #expect(window.kind == .normal)
        #expect(window.kind.isSnappable == true)
        #expect(window.isResizable == true)
        #expect(window.title == "Safari")
    }

    @Test func nonNormalWindowsAreNotSnappable() {
        let kinds: [WindowKind] = [.dialog, .sheet, .system, .unsupported]

        for kind in kinds {
            #expect(kind.isSnappable == false)
            let window = ManagedWindow(
                id: 102,
                pid: 1234,
                title: "Test",
                frame: CGRect(x: 0, y: 0, width: 400, height: 300),
                kind: kind
            )
            #expect(window.kind.isSnappable == false)
        }
    }

    @Test func managedWindowEquatabilityAndHashing() {
        let frame = CGRect(x: 10, y: 20, width: 500, height: 400)
        let window1 = ManagedWindow(id: 42, pid: 100, title: "App", frame: frame)
        let window2 = ManagedWindow(id: 42, pid: 100, title: "App", frame: frame)
        let window3 = ManagedWindow(id: 99, pid: 100, title: "App", frame: frame)

        #expect(window1 == window2)
        #expect(window1 != window3)
        #expect(window1.hashValue == window2.hashValue)
    }
}

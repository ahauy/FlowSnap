import Testing
import CoreGraphics
@testable import FlowSnap

struct WindowRegistryTests {

    @Test func registerAndLookupWindow() async {
        let registry = WindowRegistry()
        let window = ManagedWindow(
            id: 201,
            pid: 1001,
            title: "Browser",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        await registry.update(window)

        let retrieved = await registry.window(for: 201)
        #expect(retrieved != nil)
        #expect(retrieved?.id == 201)
        #expect(retrieved?.title == "Browser")
    }

    @Test func filterWindowsByPID() async {
        let registry = WindowRegistry()
        let win1 = ManagedWindow(id: 1, pid: 777, title: "Tab 1", frame: .zero)
        let win2 = ManagedWindow(id: 2, pid: 777, title: "Tab 2", frame: .zero)
        let win3 = ManagedWindow(id: 3, pid: 888, title: "Other App", frame: .zero)

        await registry.update(win1)
        await registry.update(win2)
        await registry.update(win3)

        let pid777Windows = await registry.windows(for: 777)
        #expect(pid777Windows.count == 2)

        let pid888Windows = await registry.windows(for: 888)
        #expect(pid888Windows.count == 1)
    }

    @Test func removeAndClearWindows() async {
        let registry = WindowRegistry()
        let win = ManagedWindow(id: 50, pid: 100, title: "Window", frame: .zero)

        await registry.update(win)
        #expect(await registry.allWindows.count == 1)

        await registry.remove(50)
        #expect(await registry.window(for: 50) == nil)
        #expect(await registry.allWindows.isEmpty)
    }
}

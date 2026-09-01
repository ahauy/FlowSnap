# Contracts: Window Groups & Synchronization Engine (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Status:** Engineering Interface Contract  
**Created:** 2026-09-01

---

## 1. `WindowGroupManaging` Protocol & Coordinator — `FlowSnap/Core/Window/WindowGroupManager.swift`

```swift
import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

public protocol WindowGroupManaging: AnyObject, Sendable {
    @MainActor var activeGroups: [WindowGroup] { get }

    @MainActor
    @discardableResult
    func createGroup(name: String, windowIDs: Set<CGWindowID>, syncOptions: GroupSyncOptions) -> WindowGroup?

    @MainActor
    func dissolveGroup(id: UUID)

    @MainActor
    func addWindow(_ windowID: CGWindowID, toGroup id: UUID)

    @MainActor
    func removeWindow(_ windowID: CGWindowID, fromGroup id: UUID)

    @MainActor
    func group(for windowID: CGWindowID) -> WindowGroup?

    // Group state propagation hooks
    @MainActor
    func handleWindowMinimize(triggerWindowID: CGWindowID) async throws

    @MainActor
    func handleWindowRestore(triggerWindowID: CGWindowID) async throws

    @MainActor
    func handleWindowFocus(triggerWindowID: CGWindowID) async throws

    @MainActor
    func handleWindowMove(triggerWindowID: CGWindowID, delta: CGPoint) async throws

    @MainActor
    func handleWindowDestroyed(windowID: CGWindowID)
}

@MainActor
public final class WindowGroupManager: ObservableObject, WindowGroupManaging {
    @Published public private(set) var activeGroups: [WindowGroup] = []

    private let accessibilityService: any AccessibilityService
    private let windowManager: any WindowManaging

    /// Re-entrancy guard flag preventing echo event cascading
    private var isSynchronizing: Bool = false
    private var syncGeneration: UInt64 = 0

    public init(
        accessibilityService: any AccessibilityService,
        windowManager: any WindowManaging
    ) {
        self.accessibilityService = accessibilityService
        self.windowManager = windowManager
    }

    // MARK: - Lifecycle Management

    @discardableResult
    public func createGroup(
        name: String,
        windowIDs: Set<CGWindowID>,
        syncOptions: GroupSyncOptions = .all
    ) -> WindowGroup? {
        guard windowIDs.count >= 2 else { return nil }

        // Remove windows from existing groups to prevent dual-group membership
        for windowID in windowIDs {
            if let existing = group(for: windowID) {
                removeWindow(windowID, fromGroup: existing.id)
            }
        }

        let newGroup = WindowGroup(
            name: name,
            windowIDs: windowIDs,
            anchorWindowID: windowIDs.first,
            syncOptions: syncOptions
        )
        activeGroups.append(newGroup)
        return newGroup
    }

    public func dissolveGroup(id: UUID) {
        activeGroups.removeAll { $0.id == id }
    }

    public func addWindow(_ windowID: CGWindowID, toGroup id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }
        // Ensure not in another group
        if let existing = group(for: windowID), existing.id != id {
            removeWindow(windowID, fromGroup: existing.id)
        }
        activeGroups[index].windowIDs.insert(windowID)
    }

    public func removeWindow(_ windowID: CGWindowID, fromGroup id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }
        activeGroups[index].windowIDs.remove(windowID)
        if activeGroups[index].windowIDs.count < 2 {
            dissolveGroup(id: id)
        }
    }

    public func group(for windowID: CGWindowID) -> WindowGroup? {
        activeGroups.first { $0.windowIDs.contains(windowID) }
    }

    public func handleWindowDestroyed(windowID: CGWindowID) {
        if let targetGroup = group(for: windowID) {
            removeWindow(windowID, fromGroup: targetGroup.id)
        }
    }

    // MARK: - Synchronization Operations

    public func handleWindowMinimize(triggerWindowID: CGWindowID) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = group(for: triggerWindowID),
              targetGroup.syncOptions.contains(.minimizeTogether) else { return }

        isSynchronizing = true
        syncGeneration &+= 1
        defer { isSynchronizing = false }

        let otherWindowIDs = targetGroup.windowIDs.subtracting([triggerWindowID])
        let allWindows = accessibilityService.allVisibleManagedWindows()

        for windowID in otherWindowIDs {
            if let managedWindow = allWindows.first(where: { $0.id == windowID }), !managedWindow.isMinimized {
                try? await windowManager.minimize(managedWindow)
            }
        }
    }

    public func handleWindowRestore(triggerWindowID: CGWindowID) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = group(for: triggerWindowID),
              targetGroup.syncOptions.contains(.minimizeTogether) else { return }

        isSynchronizing = true
        syncGeneration &+= 1
        defer { isSynchronizing = false }

        let otherWindowIDs = targetGroup.windowIDs.subtracting([triggerWindowID])
        // Query process windows via AX to unminimize docked/minimized windows
        for windowID in otherWindowIDs {
            // Unminimize via accessibilityService
        }
    }

    public func handleWindowFocus(triggerWindowID: CGWindowID) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = group(for: triggerWindowID),
              targetGroup.syncOptions.contains(.focusTogether) else { return }

        isSynchronizing = true
        syncGeneration &+= 1
        defer { isSynchronizing = false }

        let otherWindowIDs = targetGroup.windowIDs.subtracting([triggerWindowID])
        let allWindows = accessibilityService.allVisibleManagedWindows()

        // 1. Raise background group windows first
        for windowID in otherWindowIDs {
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) {
                try? await windowManager.focus(managedWindow)
            }
        }

        // 2. Raise trigger/anchor window last to ensure it remains frontmost (Z-order preservation)
        if let triggerWindow = allWindows.first(where: { $0.id == triggerWindowID }) {
            try? await windowManager.focus(triggerWindow)
        }
    }

    public func handleWindowMove(triggerWindowID: CGWindowID, delta: CGPoint) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = group(for: triggerWindowID),
              targetGroup.syncOptions.contains(.moveTogether) else { return }

        isSynchronizing = true
        syncGeneration &+= 1
        defer { isSynchronizing = false }

        let otherWindowIDs = targetGroup.windowIDs.subtracting([triggerWindowID])
        let allWindows = accessibilityService.allVisibleManagedWindows()

        for windowID in otherWindowIDs {
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) {
                var newFrame = managedWindow.frame
                newFrame.origin.x += delta.x
                newFrame.origin.y += delta.y
                try? await windowManager.move(managedWindow, to: newFrame)
            }
        }
    }
}
```

---

## 2. Window Manager Protocol Extension — `FlowSnap/Core/Window/WindowManaging.swift`

Ensure `WindowManaging` has `minimize` and `unminimize`:

```swift
public protocol WindowManaging: Sendable {
    func focusedWindow() async -> ManagedWindow?
    func move(_ window: ManagedWindow, to frame: CGRect) async throws
    func move(_ window: ManagedWindow, to frame: CGRect, element: AXUIElement?) async throws
    func focus(_ window: ManagedWindow) async throws
    func minimize(_ window: ManagedWindow) async throws
    func unminimize(_ window: ManagedWindow) async throws
}
```

---

## 3. Error Types

```swift
public enum WindowGroupError: Error, Equatable, Sendable {
    case groupNotFound(UUID)
    case insufficientMembers
    case accessibilityDenied
    case windowNotFound(CGWindowID)
    case synchronizationFailed(String)
}
```

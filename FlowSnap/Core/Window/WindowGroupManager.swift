import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

private let groupLogger = Logger(subsystem: "com.flowsnap", category: "WindowGroupManager")

/// Errors that can occur during window group management and synchronization (spec §1.4).
public enum WindowGroupError: Error, Equatable, Sendable {
    case groupNotFound(UUID)
    case insufficientMembers
    case accessibilityDenied
    case windowNotFound(CGWindowID)
    case synchronizationFailed(String)
}

/// Protocol defining window group coordination operations (contracts §1).
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
    func updateSyncOptions(_ options: GroupSyncOptions, for id: UUID)

    @MainActor
    func group(for windowID: CGWindowID) -> WindowGroup?

    // MARK: - State Synchronization

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

/// Coordinator managing linked window groups and cross-window state propagation (spec §1.4).
@MainActor
public final class WindowGroupManager: ObservableObject, WindowGroupManaging {
    @Published public private(set) var activeGroups: [WindowGroup] = []

    private let accessibilityService: any AccessibilityService
    private let windowManager: any WindowManaging

    /// Re-entrancy guard flag preventing echo event cascading (spec §1.4, FR-GROUP-005)
    public private(set) var isSynchronizing: Bool = false
    public private(set) var syncGeneration: UInt64 = 0

    public init(
        accessibilityService: any AccessibilityService,
        windowManager: any WindowManaging
    ) {
        self.accessibilityService = accessibilityService
        self.windowManager = windowManager
    }

    // MARK: - Group Lifecycle Management

    @discardableResult
    public func createGroup(
        name: String,
        windowIDs: Set<CGWindowID>,
        syncOptions: GroupSyncOptions = .all
    ) -> WindowGroup? {
        guard windowIDs.count >= 2 else {
            groupLogger.warning("Cannot create group with fewer than 2 windows.")
            return nil
        }

        // Prevent dual-group membership by removing from existing groups
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
        groupLogger.info("Created WindowGroup '\(name)' with \(windowIDs.count) windows.")
        return newGroup
    }

    public func dissolveGroup(id: UUID) {
        activeGroups.removeAll { $0.id == id }
        groupLogger.info("Dissolved WindowGroup \(id).")
    }

    public func addWindow(_ windowID: CGWindowID, toGroup id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }

        // Remove from any existing group first
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

    public func updateSyncOptions(_ options: GroupSyncOptions, for id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }
        activeGroups[index].syncOptions = options
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
        let allWindows = accessibilityService.allVisibleManagedWindows()

        for windowID in otherWindowIDs {
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) {
                try? await windowManager.unminimize(managedWindow)
            }
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

        // 2. Raise trigger/anchor window last to preserve relative z-order (anchor on top)
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

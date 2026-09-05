import AppKit
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
    func handleGroupMoveToDisplay(groupID: UUID, targetDisplayID: CGDirectDisplayID) async throws

    @MainActor
    func handleGroupCrossDisplayThrow(triggerWindowID: CGWindowID, isNext: Bool) async throws

    @MainActor
    func handleWindowDestroyed(windowID: CGWindowID)
}

/// Coordinator managing linked window groups and cross-window state propagation (spec §1.4).
@MainActor
public final class WindowGroupManager: ObservableObject, WindowGroupManaging {
    @Published public private(set) var activeGroups: [WindowGroup] = []

    public let accessibilityService: any AccessibilityService
    public let windowManager: any WindowManaging
    public let displayManager: (any DisplayManaging)?
    public let displayNavigator: any DisplayNavigating
    public let layoutEngine: any LayoutCalculating

    /// Cached metadata of managed windows to allow resolving windows even when minimized
    public private(set) var cachedWindows: [CGWindowID: ManagedWindow] = [:]

    /// Re-entrancy guard flag preventing echo event cascading (spec §1.4, FR-GROUP-005)
    public private(set) var isSynchronizing: Bool = false
    public private(set) var syncGeneration: UInt64 = 0

    private var syncMonitorTask: Task<Void, Never>?
    private var lastKnownMinimizedStates: [UUID: Set<CGWindowID>] = [:]
    nonisolated(unsafe) private var appActivateObserver: (any NSObjectProtocol)?

    public init(
        accessibilityService: any AccessibilityService,
        windowManager: any WindowManaging,
        displayManager: (any DisplayManaging)? = nil,
        displayNavigator: any DisplayNavigating = DisplayNavigator(),
        layoutEngine: any LayoutCalculating = LayoutEngine()
    ) {
        self.accessibilityService = accessibilityService
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.displayNavigator = displayNavigator
        self.layoutEngine = layoutEngine
        setupWorkspaceNotifications()
    }

    deinit {
        syncMonitorTask?.cancel()
        if let observer = appActivateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    public func cacheWindows(_ windows: [ManagedWindow]) {
        for win in windows {
            cachedWindows[win.id] = win
        }
    }

    public func window(for id: CGWindowID) -> ManagedWindow? {
        cachedWindows[id]
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
        updateMonitoring()
        groupLogger.info("Created WindowGroup '\(name)' with \(windowIDs.count) windows.")
        return newGroup
    }

    @discardableResult
    public func createGroup(
        name: String,
        windows: [ManagedWindow],
        syncOptions: GroupSyncOptions = .all
    ) -> WindowGroup? {
        cacheWindows(windows)
        let ids = Set(windows.map { $0.id })
        return createGroup(name: name, windowIDs: ids, syncOptions: syncOptions)
    }

    @discardableResult
    public func createGroupFromVisibleWindows(name: String? = nil) -> WindowGroup? {
        let windows = accessibilityService.allVisibleManagedWindows()
            .filter { $0.frame.width > 200 && $0.frame.height > 200 }
            .prefix(4)
        cacheWindows(Array(windows))
        let ids = Set(windows.map { $0.id })
        guard ids.count >= 2 else {
            groupLogger.warning("Need at least 2 visible windows to form a group.")
            return nil
        }
        let resolvedName: String
        if let name, !name.isEmpty {
            resolvedName = name
        } else {
            let names = windows.map { win -> String in
                let app = win.displayAppName
                let detail = win.displayDetailTitle
                if detail != "(Untitled Window)" && detail.caseInsensitiveCompare(app) != .orderedSame {
                    return "\(app) (\(detail.prefix(16)))"
                }
                return app
            }
            resolvedName = names.isEmpty ? "Linked Workspace" : names.joined(separator: " + ")
        }
        return createGroup(name: resolvedName, windowIDs: ids, syncOptions: .all)
    }

    public func dissolveGroup(id: UUID) {
        activeGroups.removeAll { $0.id == id }
        lastKnownMinimizedStates.removeValue(forKey: id)
        updateMonitoring()
        groupLogger.info("Dissolved WindowGroup \(id).")
    }

    public func addWindow(_ windowID: CGWindowID, toGroup id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }

        // Remove from any existing group first
        if let existing = group(for: windowID), existing.id != id {
            removeWindow(windowID, fromGroup: existing.id)
        }

        activeGroups[index].windowIDs.insert(windowID)
        updateMonitoring()
    }

    public func removeWindow(_ windowID: CGWindowID, fromGroup id: UUID) {
        guard let index = activeGroups.firstIndex(where: { $0.id == id }) else { return }
        activeGroups[index].windowIDs.remove(windowID)

        if activeGroups[index].windowIDs.count < 2 {
            dissolveGroup(id: id)
        } else {
            updateMonitoring()
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

    // MARK: - Live Observation & State Monitoring

    private func setupWorkspaceNotifications() {
        appActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, !self.isSynchronizing else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            let pid = app.processIdentifier
            guard pid != ProcessInfo.processInfo.processIdentifier else { return }

            for group in self.activeGroups where group.syncOptions.contains(.focusTogether) {
                for wid in group.windowIDs {
                    if let win = self.cachedWindows[wid], win.pid == pid {
                        Task { @MainActor [weak self] in
                            try? await self?.handleWindowFocus(triggerWindowID: wid)
                        }
                        return
                    }
                }
            }
        }
    }

    private func updateMonitoring() {
        if activeGroups.isEmpty {
            syncMonitorTask?.cancel()
            syncMonitorTask = nil
            lastKnownMinimizedStates.removeAll()
            return
        }

        guard syncMonitorTask == nil else { return }

        syncMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard let self, !self.isSynchronizing else { continue }
                await self.checkLiveGroupStates()
            }
        }
    }

    private func checkLiveGroupStates() async {
        guard !isSynchronizing else { return }

        for group in activeGroups {
            guard group.syncOptions.contains(.minimizeTogether) else { continue }

            var currentMinimized = Set<CGWindowID>()
            var currentVisible = Set<CGWindowID>()

            for wid in group.windowIDs {
                guard let win = cachedWindows[wid] ?? accessibilityService.allVisibleManagedWindows().first(where: { $0.id == wid }) else {
                    continue
                }
                cachedWindows[wid] = win
                if let element = accessibilityService.windowElement(for: win) {
                    var val: AnyObject?
                    if AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &val) == .success,
                       let isMin = val as? Bool, isMin {
                        currentMinimized.insert(wid)
                    } else {
                        currentVisible.insert(wid)
                    }
                }
            }

            let previousMinimized = lastKnownMinimizedStates[group.id] ?? []

            // Window newly minimized by user
            let newlyMinimized = currentMinimized.subtracting(previousMinimized)
            if let trigger = newlyMinimized.first, !currentVisible.isEmpty {
                lastKnownMinimizedStates[group.id] = group.windowIDs
                try? await handleWindowMinimize(triggerWindowID: trigger)
                continue
            }

            // Window newly restored (unminimized) by user
            let newlyRestored = previousMinimized.subtracting(currentMinimized)
            if let trigger = newlyRestored.first, !currentMinimized.isEmpty {
                lastKnownMinimizedStates[group.id] = []
                try? await handleWindowRestore(triggerWindowID: trigger)
                continue
            }

            lastKnownMinimizedStates[group.id] = currentMinimized
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
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) ?? cachedWindows[windowID], !managedWindow.isMinimized {
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
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) ?? cachedWindows[windowID] {
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
            if let managedWindow = allWindows.first(where: { $0.id == windowID }) ?? cachedWindows[windowID] {
                try? await windowManager.focus(managedWindow)
            }
        }

        // 2. Raise trigger/anchor window last to preserve relative z-order (anchor on top)
        if let triggerWindow = allWindows.first(where: { $0.id == triggerWindowID }) ?? cachedWindows[triggerWindowID] {
            try? await windowManager.focus(triggerWindow)
        }
    }

    /// Shifts the other members of a group by `delta` when one member is dragged.
    ///
    /// - Parameter delta: Displacement in **Accessibility** coordinates (y grows
    ///   downward), matching the space `WindowManaging.move` writes in.
    ///
    /// Every move in the codebase addresses `WindowManaging.move` in AX space —
    /// `CommandDispatcher`, `AdaptiveDividerCoordinator` and the restore path all
    /// convert with `CoordinateTransformer.toAX` first. `ManagedWindow.frame` is
    /// AppKit (y grows upward), so applying an AppKit delta to it and handing the
    /// result straight to `move` mirrors each window vertically: the members land
    /// the wrong distance from the trigger, and off-screen once the primary display
    /// is tall enough to push them past its bottom edge.
    ///
    /// Rather than convert, this reads each member's *current* AX position and
    /// offsets that. Two things follow, both desirable: the group stays rigid
    /// however far the trigger has already travelled, and a member whose snapshot
    /// is stale (moved by hand since the list was built) moves from where it really
    /// is instead of snapping back to where it used to be.
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
            guard let managedWindow = allWindows.first(where: { $0.id == windowID }),
                  let element = accessibilityService.windowElement(for: managedWindow) else { continue }

            // The member's *current* AX position. Without it there is no origin to
            // offset, and guessing from the AppKit snapshot would teleport the window
            // back to wherever it was when the list was built — worse than leaving it.
            guard let moved = accessibilityService.frame(of: element) else {
                groupLogger.warning("Skip group move for window \(windowID): no live AX frame.")
                continue
            }
            var target = moved
            target.origin.x += delta.x
            target.origin.y += delta.y
            try? await windowManager.move(managedWindow, to: target, element: element)
        }
    }

    // MARK: - Cross-Display Group Migration (US-GROUP-010)

    public func handleGroupCrossDisplayThrow(triggerWindowID: CGWindowID, isNext: Bool) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = group(for: triggerWindowID),
              targetGroup.syncOptions.contains(.crossDisplayTogether) else { return }
        guard let displayManager else {
            groupLogger.warning("Cannot migrate group: displayManager not configured.")
            return
        }

        let displays = await displayManager.displays
        guard displays.count > 1 else {
            groupLogger.debug("Single display connected. Cross-display group throw is no-op.")
            return
        }

        let allWindows = accessibilityService.allVisibleManagedWindows()
        let memberWindows = targetGroup.windowIDs.compactMap { wid in
            allWindows.first(where: { $0.id == wid }) ?? cachedWindows[wid]
        }
        guard !memberWindows.isEmpty else { return }

        let triggerWindow = memberWindows.first(where: { $0.id == triggerWindowID }) ?? memberWindows[0]
        guard let sourceDisplay = await displayManager.display(for: triggerWindow.frame, cursorPoint: nil) else { return }

        let targetDisplay: Display?
        if isNext {
            targetDisplay = displayNavigator.nextDisplay(after: sourceDisplay, in: displays)
        } else {
            targetDisplay = displayNavigator.previousDisplay(before: sourceDisplay, in: displays)
        }

        guard let destination = targetDisplay else { return }
        try await migrateGroup(
            targetGroup,
            memberWindows: memberWindows,
            from: sourceDisplay,
            to: destination,
            triggerWindowID: triggerWindowID
        )
    }

    public func handleGroupMoveToDisplay(groupID: UUID, targetDisplayID: CGDirectDisplayID) async throws {
        guard !isSynchronizing else { return }
        guard let targetGroup = activeGroups.first(where: { $0.id == groupID }) else { return }
        guard let displayManager else {
            groupLogger.warning("Cannot migrate group: displayManager not configured.")
            return
        }

        let displays = await displayManager.displays
        guard let destination = displays.first(where: { $0.id == targetDisplayID }) else { return }

        let allWindows = accessibilityService.allVisibleManagedWindows()
        let memberWindows = targetGroup.windowIDs.compactMap { wid in
            allWindows.first(where: { $0.id == wid }) ?? cachedWindows[wid]
        }
        guard let firstWin = memberWindows.first else { return }

        guard let sourceDisplay = await displayManager.display(for: firstWin.frame, cursorPoint: nil) else { return }
        guard sourceDisplay.id != destination.id else { return }

        let triggerID = targetGroup.anchorWindowID ?? firstWin.id
        try await migrateGroup(
            targetGroup,
            memberWindows: memberWindows,
            from: sourceDisplay,
            to: destination,
            triggerWindowID: triggerID
        )
    }

    private func migrateGroup(
        _ group: WindowGroup,
        memberWindows: [ManagedWindow],
        from sourceDisplay: Display,
        to targetDisplay: Display,
        triggerWindowID: CGWindowID
    ) async throws {
        isSynchronizing = true
        syncGeneration &+= 1
        defer { isSynchronizing = false }

        groupLogger.info("Migrating group '\(group.name)' with \(memberWindows.count) windows from display \(sourceDisplay.id) to \(targetDisplay.id).")

        let primaryHeight = await (displayManager?.primaryScreenHeight ?? 1080)
        let sourceVisible = sourceDisplay.visibleFrame
        let targetVisible = targetDisplay.visibleFrame

        // 1. Calculate target AX frames for all member windows
        var targetFrames: [(window: ManagedWindow, axFrame: CGRect, appKitFrame: CGRect)] = []

        for window in memberWindows {
            let norm = ZoneInference.normalizedRect(of: window.frame, within: sourceVisible)
            let inferred = ZoneInference.inferZone(forNormalized: norm)
            let iou = ZoneInference.intersectionOverUnion(norm, inferred.normalizedRect)

            let targetAppKit: CGRect
            if iou >= 0.75 {
                targetAppKit = layoutEngine.frame(for: inferred, in: targetVisible, gap: 0, uniform: false)
            } else {
                targetAppKit = RelativeFrameScaler.scale(
                    frame: window.frame,
                    from: sourceVisible,
                    to: targetVisible
                )
            }
            let targetAX = CoordinateTransformer.toAX(rect: targetAppKit, primaryScreenHeight: primaryHeight)
            targetFrames.append((window, targetAX, targetAppKit))
        }

        // 2. Concurrently move all windows
        for item in targetFrames {
            if let element = accessibilityService.windowElement(for: item.window) {
                try? await windowManager.move(item.window, to: item.axFrame, element: element)
            } else {
                try? await windowManager.move(item.window, to: item.axFrame)
            }
            var updated = item.window
            updated.frame = item.appKitFrame
            cachedWindows[updated.id] = updated
        }

        // 3. Preserve relative z-order: raise background members, then trigger window last
        let otherWindows = memberWindows.filter { $0.id != triggerWindowID }
        for other in otherWindows {
            try? await windowManager.focus(other)
        }
        if let trigger = memberWindows.first(where: { $0.id == triggerWindowID }) {
            try? await windowManager.focus(trigger)
        }
    }
}

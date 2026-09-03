import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Concrete implementation of AccessibilityService using public macOS AXUIElement APIs.
///
/// This is the only class in the codebase that interacts directly with
/// CoreFoundation AXUIElement APIs.
public final class AXAccessibilityService: AccessibilityService, @unchecked Sendable {

    private let settingsRouter: SystemSettingsRouter

    public init(settingsRouter: SystemSettingsRouter = SystemSettingsRouter()) {
        self.settingsRouter = settingsRouter
    }

    // MARK: - Permission Verification

    public var isTrusted: Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    public func openSystemSettings() {
        Task { @MainActor in
            settingsRouter.openAccessibilitySettings()
        }
    }

    // MARK: - Focused Window Discovery

    public func focusedWindow() -> AXUIElement? {
        guard isTrusted else { return nil }

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return focusedWindowViaSystemWide()
        }

        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        )

        if result == .success, let element = windowValue {
            // swiftlint:disable:next force_cast
            return (element as! AXUIElement)
        }

        return focusedWindowViaSystemWide()
    }

    private func focusedWindowViaSystemWide() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var appValue: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &appValue
        )
        guard appResult == .success, let appElement = appValue else { return nil }

        var windowValue: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            // swiftlint:disable:next force_cast
            appElement as! AXUIElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        )
        guard windowResult == .success, let windowElement = windowValue else { return nil }
        // swiftlint:disable:next force_cast
        return (windowElement as! AXUIElement)
    }

    public func focusedManagedWindow() -> ManagedWindow? {
        guard isTrusted, let windowElement = focusedWindow() else { return nil }

        var pid: pid_t = 0
        guard AXUIElementGetPid(windowElement, &pid) == .success else { return nil }

        // FlowSnap must never snap its own windows (Lab, Settings, MenuBar)
        if pid == ProcessInfo.processInfo.processIdentifier {
            return nil
        }

        return managedWindow(from: windowElement, pid: pid)
    }

    /// Builds the domain snapshot of one AX window. Shared by the focused-window and
    /// per-process lookups so both report identical fields.
    private func managedWindow(from windowElement: AXUIElement, pid: pid_t) -> ManagedWindow? {
        guard let windowFrame = frame(of: windowElement) else { return nil }

        let runningApp = NSRunningApplication(processIdentifier: pid)
        let title = resolveTitle(for: windowElement, runningApp: runningApp)
        let isResizable = checkResizable(windowElement)
        let isMinimized = checkMinimized(windowElement)
        let kind = classifyKind(windowElement, isResizable: isResizable)
        let windowId = resolveWindowID(for: pid, frame: windowFrame)

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let appKitFrame = CoordinateTransformer.toAppKit(rect: windowFrame, primaryScreenHeight: primaryHeight)

        return ManagedWindow(
            id: windowId,
            pid: pid,
            bundleIdentifier: runningApp?.bundleIdentifier,
            title: title,
            frame: appKitFrame,
            isMinimized: isMinimized,
            isResizable: isResizable,
            kind: kind
        )
    }

    // MARK: - Windows of Process

    public func windows(of pid: pid_t) -> [AXUIElement] {
        guard isTrusted else { return [] }
        let appElement = AXUIElementCreateApplication(pid)
        var windowsValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        )
        guard result == .success, let raw = windowsValue as? [AXUIElement] else {
            return fallbackWindowElements(of: appElement)
        }
        let list = raw.filter { isWindowElement($0) }
        guard !list.isEmpty else {
            return fallbackWindowElements(of: appElement)
        }
        return list
    }

    /// Whether an element reported by `kAXWindowsAttribute` really is a window.
    ///
    /// Apps are not obliged to keep that list to windows, and some do not. Finder
    /// answers it with a single `AXScrollArea` at `(0,0,1440,900)` - the desktop
    /// behind the icons. Left in, it is snapshotted as a window, and because it is
    /// neither resizable nor movable it was classified `.fullscreen` and offered for
    /// restore, where every write against it is meaningless.
    ///
    /// Fails open when the role cannot be read: an app that will not say what the
    /// element is gets the benefit of the doubt, matching the behaviour before this
    /// check existed, rather than losing a window that may have been real.
    private func isWindowElement(_ element: AXUIElement) -> Bool {
        var roleValue: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
              let role = roleValue as? String else { return true }
        return role == (kAXWindowRole as String)
    }

    /// Windows recovered from `AXMainWindow` / `AXFocusedWindow`.
    ///
    /// Some apps answer `kAXWindowsAttribute` with *success and an empty list*
    /// while their window is on screen and fully addressable — Zalo returns
    /// `err=0, count=0`. `kAXChildrenAttribute` is no help either: it lists only
    /// the menu bar. The single-window attributes still resolve, and the element
    /// they return really is writable (`SET Position`/`SET Size` return `err=0`
    /// and read back unchanged), so an app that reports no windows at all is
    /// still restorable through them.
    ///
    /// The alternatives were measured, and do not work — recorded here so nobody
    /// re-derives them:
    /// - Hit-testing the centre of the window's own frame finds an `AXWindow`
    ///   ancestor, but it is a *different element* from `AXMainWindow` and
    ///   reports `AXPosition` as non-settable.
    /// - `kAXMinimizedWindowsAttribute` does not exist. The symbol appears
    ///   nowhere in the macOS SDK, so as a string literal it always resolves to
    ///   `kAXErrorAttributeUnsupported` (-25205).
    ///
    /// Only consulted when the primary query comes back empty, so apps that
    /// expose their windows normally never get these elements appended.
    private func fallbackWindowElements(of appElement: AXUIElement) -> [AXUIElement] {
        let keys: [String] = [kAXMainWindowAttribute, kAXFocusedWindowAttribute]
        var found: [AXUIElement] = []
        for key in keys {
            var value: AnyObject?
            guard AXUIElementCopyAttributeValue(appElement, key as CFString, &value) == .success,
                  // swiftlint:disable:next force_cast
                  let element = (value as! AXUIElement?)
            else { continue }
            // Nothing stops an app from answering these with a non-window
            // element; refuse anything that is not actually a window.
            var roleValue: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
            guard (roleValue as? String) == (kAXWindowRole as String) else { continue }
            guard !found.contains(where: { CFEqual($0, element) }) else { continue }
            found.append(element)
        }
        return found
    }

    public func managedWindows(of pid: pid_t) -> [ManagedWindow] {
        guard isTrusted else { return [] }
        // Never operate on FlowSnap's own windows.
        guard pid != ProcessInfo.processInfo.processIdentifier else { return [] }

        return resolvedWindows(of: pid).map(\.window)
    }

    public func resolvedWindows(of pid: pid_t) -> [ResolvedWindow] {
        guard isTrusted else { return [] }
        // Never operate on FlowSnap's own windows.
        guard pid != ProcessInfo.processInfo.processIdentifier else { return [] }

        // Deliberately NOT routed through `allVisibleManagedWindows()`: that list is
        // built with `.optionOnScreenOnly` and therefore drops minimized windows and
        // windows parked on another Space. Restoration must find those too.
        //
        // Uses `isRestorable` (not `isSnappable`) so full-screen windows are included:
        // restore exits full-screen before repositioning, but it needs to find the
        // window first. The capture path still uses `isSnappable` and correctly
        // excludes full-screen windows from the picker.
        return windows(of: pid).compactMap { element in
            guard let snapshot = managedWindow(from: element, pid: pid),
                  snapshot.kind.isRestorable
            else { return nil }
            return ResolvedWindow(window: snapshot, element: element)
        }
    }

    // MARK: - Frame Operations

    public func frame(of window: AXUIElement) -> CGRect? {
        var origin = CGPoint.zero
        var size = CGSize.zero

        var posValue: AnyObject?
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue)
        guard posResult == .success, let pos = posValue else { return nil }
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(pos as! AXValue, .cgPoint, &origin) else { return nil }

        var sizeValue: AnyObject?
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        guard sizeResult == .success, let sizeObj = sizeValue else { return nil }
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(sizeObj as! AXValue, .cgSize, &size) else { return nil }

        guard !origin.x.isNaN, !origin.y.isNaN, !size.width.isNaN, !size.height.isNaN else {
            return nil
        }

        return CGRect(origin: origin, size: size)
    }

    public func setFrame(_ frame: CGRect, for window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }

        var origin = frame.origin
        var size = frame.size
        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw AccessibilityError.invalidGeometry
        }

        var currentSize = CGSize.zero
        var currentSizeVal: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &currentSizeVal) == .success,
           let val = currentSizeVal {
            // swiftlint:disable:next force_cast
            _ = AXValueGetValue(val as! AXValue, .cgSize, &currentSize)
        }

        // 2-phase setFrame ordering for Shrink vs Expand:
        // Shrink (new size <= current size): set size first to release space, then position.
        // Expand (new size > current size): set position first into available space, then size.
        let isShrinking = currentSize != .zero && (frame.size.width * frame.size.height) <= (currentSize.width * currentSize.height)
        if isShrinking {
            _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            guard posResult == .success else { throw AccessibilityError.cannotComplete }
        } else {
            _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            guard sizeResult == .success else { throw AccessibilityError.cannotComplete }
        }
    }

    public func raise(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        guard result == .success else { throw AccessibilityError.cannotComplete }
    }

    @discardableResult
    public func raise(window: ManagedWindow) -> Bool {
        guard let element = windowElement(for: window) else { return false }
        do {
            try raise(element)
            return true
        } catch {
            return false
        }
    }

    public func minimize(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        guard result == .success else { throw AccessibilityError.cannotComplete }
    }

    public func unminimize(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        let result = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        guard result == .success else { throw AccessibilityError.cannotComplete }
    }

    public func exitFullScreen(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        // Setting AXFullscreen to false triggers the macOS full-screen exit animation.
        // Try both known spellings; the first successful write is all we need.
        // The caller must sleep after this returns to let the animation complete before
        // reading or writing the window's frame.
        for key in AXAccessibilityService.fullscreenAttributeKeys {
            let result = AXUIElementSetAttributeValue(window, key as CFString, kCFBooleanFalse)
            if result == .success {
                diagPrint("[AXAccessibilityService] exitFullScreen succeeded via attribute '\(key)'")
                return
            }
        }

        // Tier 1 fallback: Interactively trigger the window's full screen button via AX (for Electron/Chromium)
        var buttonValue: AnyObject?
        let buttonResult = AXUIElementCopyAttributeValue(window, kAXFullScreenButtonAttribute as CFString, &buttonValue)
        if buttonResult == .success, let button = buttonValue, CFGetTypeID(button) == AXUIElementGetTypeID() {
            // swiftlint:disable:next force_cast
            let pressResult = AXUIElementPerformAction((button as! AXUIElement), kAXPressAction as CFString)
            if pressResult == .success {
                diagPrint("[AXAccessibilityService] exitFullScreen succeeded via full screen button press")
                return
            }
        }

        diagPrint("[AXAccessibilityService] exitFullScreen: all attribute writes and button press failed")
        throw AccessibilityError.cannotComplete
    }

    // MARK: - Private Classification & Extraction Helpers

    private func resolveTitle(for window: AXUIElement, runningApp: NSRunningApplication?) -> String {
        var titleValue: AnyObject?
        _ = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)

        if let raw = titleValue as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        if let localizedName = runningApp?.localizedName, !localizedName.isEmpty {
            return localizedName
        }

        return "Unknown Window"
    }

    private func checkResizable(_ window: AXUIElement) -> Bool {
        var isSettable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &isSettable)
        return result == .success && isSettable.boolValue
    }

    // macOS does NOT expose a public SDK constant for the window full-screen state.
    // Different internal versions of the attribute have appeared under both spellings.
    private static let fullscreenAttributeKeys: [String] = ["AXFullscreen", "AXFullScreen"]

    /// Returns `true` if the window is currently in macOS full-screen mode.
    ///
    /// Requires the full-screen attribute AND the geometry to agree, because
    /// measured live, neither signal is trustworthy on its own.
    ///
    /// The attribute lies. Chromium answers `AXFullScreen = true` for an ordinary
    /// window: Brave reported `true` while its menu bar was still on screen
    /// (WindowServer layers 24/25/26 at y=0..30). Trusting it classifies such a
    /// window as `.fullscreen`, so restore calls `exitFullScreen` on it first; that
    /// write fails, and the window is retried and then skipped.
    ///
    /// Geometry alone lies the other way - a window dragged to fill the desktop is
    /// not in full-screen mode, and treating it as such costs a doomed
    /// `exitFullScreen` write before every move.
    ///
    /// A real full-screen window satisfies both. Measured on a window this process
    /// owns and toggled with `toggleFullScreen`: attribute `true`, frame
    /// `(0,30,1440,870)` on a 1440x900 display with a 30pt menu bar. Note the
    /// height is 870, not 900 - so the previous heuristic, which compared against
    /// `screen.frame`, could never match a full-screen window and the attribute
    /// branch had nothing corroborating it. See `fillsDisplay` for why the
    /// comparison is a band rather than an exact match.
    ///
    /// `isResizable` is deliberately not consulted. It comes from the settability of
    /// `kAXSizeAttribute`, and a real full-screen window reports that as *settable*
    /// (measured on the probe window and on iTerm2), so gating on it hides genuine
    /// full-screen windows.
    private func checkFullScreen(_ window: AXUIElement) -> Bool {
        guard let windowFrame = frame(of: window) else { return false }
        guard fillsDisplay(windowFrame) else { return false }

        var claimsFullScreen = false
        var attributeReadable = false
        for key in Self.fullscreenAttributeKeys {
            var val: AnyObject?
            guard AXUIElementCopyAttributeValue(window, key as CFString, &val) == .success,
                  let boolVal = val as? Bool else { continue }
            attributeReadable = true
            if boolVal {
                diagPrint("[AXAccessibilityService] Full-screen confirmed via attribute '\(key)' + geometry")
                claimsFullScreen = true
                break
            }
        }

        // An app that does not expose the attribute at all - as opposed to exposing
        // it as false - leaves nothing to corroborate the geometry, so fall back to
        // the other signal macOS withholds in full-screen: it refuses to let the
        // window be moved. A stretched-but-normal window stays movable, so this
        // still excludes it.
        if !attributeReadable {
            var settable = DarwinBoolean(false)
            let readable = AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable) == .success
            claimsFullScreen = readable && !settable.boolValue
            if claimsFullScreen {
                diagPrint("[AXAccessibilityService] Full-screen inferred from geometry + immovable position")
            }
        }
        return claimsFullScreen
    }

    /// Whether `windowFrame` (raw Accessibility coordinates) fills a display apart
    /// from the menu bar.
    ///
    /// Deliberately a band rather than an exact match against `visibleFrame`:
    /// `visibleFrame` also subtracts the Dock, so it changes shape with the Dock's
    /// position and auto-hide setting. Measured on one display: with the Dock on the
    /// left, `visibleFrame` is `(64,0,1376,870)` while a genuinely full-screen
    /// window still reports `(0,30,1440,870)` - full display width, top edge just
    /// below the menu bar. Requiring an exact match rejected that window.
    ///
    /// The band is still tight enough to reject the case that motivated this check:
    /// Brave's `AXMainWindow` reported `AXFullScreen = true` from a frame of
    /// `(0,111,1440,789)`, because Chromium hands out the *web content* rectangle as
    /// the window frame - 30pt menu bar plus a 40pt tab strip and a 41pt bookmarks
    /// bar are already subtracted. Its top edge sits 111pt down, far outside the
    /// menu-bar allowance.
    private func fillsDisplay(_ windowFrame: CGRect) -> Bool {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let displays = NSScreen.screens.map { screen in
            DisplayGeometry(
                frame: CoordinateTransformer.toAX(
                    rect: screen.frame,
                    primaryScreenHeight: primaryHeight
                ),
                menuBarHeight: DisplayGeometry.menuBarHeight(
                    frame: screen.frame,
                    visibleFrame: screen.visibleFrame
                )
            )
        }
        return Self.fillsDisplay(windowFrame, in: displays)
    }

    /// A display and the strip along its top edge that macOS reserves for the menu
    /// bar. Pure value type so the full-screen geometry rule can be tested without
    /// a screen, a window server, or accessibility permission.
    struct DisplayGeometry: Sendable {
        /// The display's bounds in raw Accessibility coordinates (top-left origin).
        var frame: CGRect
        /// Height of the menu bar, in points.
        var menuBarHeight: CGFloat

        /// Height of the menu bar, in points, from a display's two AppKit rects.
        ///
        /// Must be read off the top edge. `frame.height - visibleFrame.height` looks
        /// equivalent and is not: `visibleFrame` excludes the Dock too, so with the
        /// Dock at the bottom that difference is menu bar plus Dock, and demanding a
        /// window's top edge sit that far down rejects every genuine full-screen
        /// window. Measured with the Dock on the left, where both formulas give 30 -
        /// which is exactly why the mistake survives local testing.
        ///
        /// The top edge is Dock-proof: macOS places the Dock on the left, right or
        /// bottom, never the top, so nothing but the menu bar reduces `maxY`.
        static func menuBarHeight(frame screenFrame: CGRect, visibleFrame: CGRect) -> CGFloat {
            max(0, screenFrame.maxY - visibleFrame.maxY)
        }
    }

    /// Pure form of `fillsDisplay`: whether `windowFrame` covers a display apart
    /// from its menu bar. See `fillsDisplay` for why this is a band.
    ///
    /// The top edge is pinned to the menu bar line rather than merely required to be
    /// below it. A window that also covers the menu bar is not in full-screen mode -
    /// measured, a real full-screen window reports its top edge at the menu bar line
    /// (y=30 on this display), never above it.
    static func fillsDisplay(_ windowFrame: CGRect, in displays: [DisplayGeometry]) -> Bool {
        displays.contains { display in
            let bounds = display.frame
            let menuBarLine = bounds.minY + display.menuBarHeight
            let spansWidth = abs(windowFrame.width - bounds.width) <= fullScreenTolerance
            let topAtMenuBarLine = abs(windowFrame.minY - menuBarLine) <= fullScreenTolerance
            let reachesBottom = windowFrame.maxY >= bounds.maxY - fullScreenTolerance
            return spansWidth && topAtMenuBarLine && reachesBottom
        }
    }

    /// Slack, in points, allowed when matching a window frame against a display.
    /// Covers rounding in Accessibility coordinates and the 1pt shadow inset some
    /// apps leave at the screen edge.
    static let fullScreenTolerance: CGFloat = 20

    private func checkMinimized(_ window: AXUIElement) -> Bool {
        var minVal: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minVal)
        guard result == .success, let isMin = minVal as? Bool else { return false }
        return isMin
    }

    private func classifyKind(_ window: AXUIElement, isResizable: Bool) -> WindowKind {
        // We MUST NOT rely on !isResizable to gate fullscreen checks.
        // Chromium/Electron apps (like Zalo, Brave) report isResizable=true even in Fullscreen mode.
        // checkFullScreen corroborates the attribute against the window's geometry instead,
        // so resizable Chromium fullscreen windows are still classified correctly.
        if checkFullScreen(window) {
            return .fullscreen
        }

        var roleVal: AnyObject?
        var subroleVal: AnyObject?
        _ = AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleVal)
        _ = AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleVal)

        let role = (roleVal as? String) ?? ""
        let subrole = (subroleVal as? String) ?? ""

        if role == kAXWindowRole {
            if subrole == kAXStandardWindowSubrole {
                return isResizable ? .normal : .unsupported
            } else if subrole == kAXDialogSubrole || subrole == kAXSystemDialogSubrole {
                return .dialog
            } else {
                return isResizable ? .normal : .dialog
            }
        } else if role == kAXSheetRole {
            return .sheet
        }

        return .system
    }

    private func resolveWindowID(for pid: pid_t, frame: CGRect) -> CGWindowID {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

        for info in windowList {
            guard let windowPID = info[kCGWindowOwnerPID as String] as? pid_t, windowPID == pid else {
                continue
            }
            if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
               let windowBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                // Check if bounds roughly match
                let deltaX = abs(windowBounds.origin.x - frame.origin.x)
                let deltaY = abs(windowBounds.origin.y - frame.origin.y)
                if deltaX < 5 && deltaY < 5 {
                    if let windowNumber = info[kCGWindowNumber as String] as? CGWindowID {
                        return windowNumber
                    }
                }
            }
        }

        // Fallback deterministic ID from pid and frame coordinates
        let hash = UInt32(bitPattern: Int32(pid)) ^ UInt32(max(0, Int(frame.origin.x)))
        return CGWindowID(hash)
    }

    // MARK: - Specific Window Resolution

    public func windowElement(for window: ManagedWindow) -> AXUIElement? {
        guard isTrusted else { return nil }
        let axWindows = windows(of: window.pid)
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let targetAXFrame = CoordinateTransformer.toAX(rect: window.frame, primaryScreenHeight: primaryHeight)
        return matchWindowElement(in: axWindows, targetAXFrame: targetAXFrame)
    }

    public func allVisibleManagedWindows() -> [ManagedWindow] {
        guard isTrusted else { return [] }
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        var results: [ManagedWindow] = []
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        var axWindowsCache: [pid_t: [AXUIElement]] = [:]

        for info in windowList {
            if let managed = makeManagedWindow(
                from: info,
                currentPID: currentPID,
                primaryHeight: primaryHeight,
                axWindowsCache: &axWindowsCache
            ) {
                results.append(managed)
            }
        }
        return results
    }

    private func makeManagedWindow(
        from info: [String: Any],
        currentPID: pid_t,
        primaryHeight: CGFloat,
        axWindowsCache: inout [pid_t: [AXUIElement]]
    ) -> ManagedWindow? {
        guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { return nil }
        guard let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != currentPID else { return nil }
        guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
              let windowBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { return nil }

        if windowBounds.width < 100 || windowBounds.height < 100 { return nil }

        let runningApp = NSRunningApplication(processIdentifier: pid)
        let bundleIdentifier = runningApp?.bundleIdentifier

        let windowNumber = info[kCGWindowNumber as String] as? CGWindowID ?? 0
        var title = (info[kCGWindowName as String] as? String) ?? ""
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            title = (info[kCGWindowOwnerName as String] as? String) ?? runningApp?.localizedName ?? "Window"
        }
        let appKitFrame = CoordinateTransformer.toAppKit(rect: windowBounds, primaryScreenHeight: primaryHeight)

        let axWindows = axWindowsCache[pid] ?? {
            let list = windows(of: pid)
            axWindowsCache[pid] = list
            return list
        }()

        var isResizable = true
        var kind: WindowKind = .normal

        if let matchedElement = matchWindowElement(in: axWindows, targetAXFrame: windowBounds) {
            isResizable = checkResizable(matchedElement)
            kind = classifyKind(matchedElement, isResizable: isResizable)
            let resolvedTitle = resolveTitle(for: matchedElement, runningApp: runningApp)
            if !resolvedTitle.isEmpty && resolvedTitle != "Unknown Window" {
                title = resolvedTitle
            }
        }

        return ManagedWindow(
            id: windowNumber,
            pid: pid,
            bundleIdentifier: bundleIdentifier,
            title: title,
            frame: appKitFrame,
            isMinimized: false,
            isResizable: isResizable,
            kind: kind
        )
    }

    /// The element that best represents a window snapshot's frame.
    ///
    /// Resolution order:
    /// 1. an element whose frame matches within tolerance;
    /// 2. otherwise the largest element.
    ///
    /// Step 2 used to be `axWindows.first`, which is not a rule at all: `kAXWindowsAttribute`
    /// carries no ordering guarantee, and Chromium-family apps list small hidden helper
    /// surfaces (tab search, extension popups, picture-in-picture) ahead of the document
    /// window. Picking "first" therefore moved an invisible window and reported success.
    /// The document window is reliably the largest thing an app owns, so area is both a
    /// better and a deterministic guess.
    private func matchWindowElement(in axWindows: [AXUIElement], targetAXFrame: CGRect) -> AXUIElement? {
        guard !axWindows.isEmpty else { return nil }
        if axWindows.count == 1 {
            return axWindows.first
        }
        var best: (element: AXUIElement, area: CGFloat)?
        for element in axWindows {
            guard let windowFrame = frame(of: element) else { continue }
            let deltaX = abs(windowFrame.origin.x - targetAXFrame.origin.x)
            let deltaY = abs(windowFrame.origin.y - targetAXFrame.origin.y)
            let deltaW = abs(windowFrame.size.width - targetAXFrame.size.width)
            let deltaH = abs(windowFrame.size.height - targetAXFrame.size.height)
            if deltaX < 30 && deltaY < 30 && deltaW < 30 && deltaH < 30 {
                return element
            }
            let area = windowFrame.width * windowFrame.height
            if area > (best?.area ?? 0) {
                best = (element, area)
            }
        }
        return best?.element
    }
}

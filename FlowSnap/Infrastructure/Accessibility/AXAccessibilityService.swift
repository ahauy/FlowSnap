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
        guard result == .success, let list = windowsValue as? [AXUIElement] else {
            return []
        }
        return list
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
                NSLog("[AXAccessibilityService] exitFullScreen succeeded via attribute '%@'", key)
                return
            }
        }
        NSLog("[AXAccessibilityService] exitFullScreen: all attribute writes failed")
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
    /// Detection uses three independent strategies in priority order so that the
    /// check works even when the attribute name differs across macOS versions:
    ///
    /// 1. `"AXFullscreen"` — the spelling used by most modern window managers
    ///    (Yabai, Amethyst, etc.) and consistent with the AX naming convention.
    /// 2. `"AXFullScreen"` — an alternate capitalisation seen in some Apple samples.
    /// 3. Frame-size heuristic — if the window's size matches a screen exactly
    ///    AND the caller already confirmed it is non-resizable, the window is almost
    ///    certainly in macOS full-screen mode (maximised windows remain resizable).
    private func checkFullScreen(_ window: AXUIElement) -> Bool {
        for key in Self.fullscreenAttributeKeys {
            var val: AnyObject?
            if AXUIElementCopyAttributeValue(window, key as CFString, &val) == .success,
               let boolVal = val as? Bool, boolVal {
                NSLog("[AXAccessibilityService] Full-screen detected via attribute '%@'", key)
                return true
            }
        }

        // Fallback: compare window size to every connected screen.
        // AX and NSScreen both operate in points, so no scale conversion is needed.
        var sizeVal: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeVal) == .success,
              let axVal = sizeVal else { return false }
        var size = CGSize.zero
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(axVal as! AXValue, .cgSize, &size) else { return false }
        let coveredByScreen = NSScreen.screens.contains { screen in
            abs(size.width  - screen.frame.width)  < 5 &&
            abs(size.height - screen.frame.height) < 5
        }
        if coveredByScreen {
            NSLog("[AXAccessibilityService] Full-screen detected via frame heuristic (%.0f × %.0f)",
                  size.width, size.height)
        }
        return coveredByScreen
    }

    private func checkMinimized(_ window: AXUIElement) -> Bool {
        var minVal: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minVal)
        guard result == .success, let isMin = minVal as? Bool else { return false }
        return isMin
    }

    private func classifyKind(_ window: AXUIElement, isResizable: Bool) -> WindowKind {
        // Check full-screen BEFORE the standard role/subrole branch.
        //
        // A full-screen window reports kAXSizeAttribute as non-settable (macOS forbids
        // AX resizing while in full-screen). Without this early return it would fall
        // through to `isResizable ? .normal : .unsupported` and be misclassified as
        // .unsupported, which silently skips the window during workspace restore and
        // causes waitForFirstWindow to time out when the app restores to full-screen.
        //
        // We only call the (slightly more expensive) checkFullScreen when the attribute
        // settability check has already confirmed the window is non-resizable, keeping
        // the hot path for ordinary windows fast.
        if !isResizable, checkFullScreen(window) {
            return .fullscreen
        }

        var roleVal: AnyObject?
        var subroleVal: AnyObject?
        _ = AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleVal)
        _ = AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleVal)

        let role = roleVal as? String
        let subrole = subroleVal as? String

        if role == (kAXWindowRole as String) {
            if subrole == (kAXStandardWindowSubrole as String) {
                return isResizable ? .normal : .unsupported
            } else if subrole == (kAXDialogSubrole as String) || subrole == (kAXSystemDialogSubrole as String) {
                return .dialog
            } else {
                return isResizable ? .normal : .dialog
            }
        } else if role == (kAXSheetRole as String) {
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

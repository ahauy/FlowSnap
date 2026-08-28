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

        guard let windowFrame = frame(of: windowElement) else { return nil }

        let runningApp = NSRunningApplication(processIdentifier: pid)
        let title = resolveTitle(for: windowElement, runningApp: runningApp)
        let isResizable = checkResizable(windowElement)
        let isMinimized = checkMinimized(windowElement)
        let kind = classifyKind(windowElement, isResizable: isResizable)
        let windowId = resolveWindowID(for: pid, frame: windowFrame)

        return ManagedWindow(
            id: windowId,
            pid: pid,
            bundleIdentifier: runningApp?.bundleIdentifier,
            title: title,
            frame: windowFrame,
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
        guard sizeResult == .success, let sz = sizeValue else { return nil }
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(sz as! AXValue, .cgSize, &size) else { return nil }

        guard !origin.x.isNaN, !origin.y.isNaN, !size.width.isNaN, !size.height.isNaN else {
            return nil
        }

        return CGRect(origin: origin, size: size)
    }

    public func setFrame(_ frame: CGRect, for window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }

        var currentPos = CGPoint.zero
        var currentPosVal: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &currentPosVal) == .success,
           let val = currentPosVal {
            // swiftlint:disable:next force_cast
            _ = AXValueGetValue(val as! AXValue, .cgPoint, &currentPos)
        }

        var origin = frame.origin
        var size = frame.size

        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw AccessibilityError.invalidGeometry
        }

        // Smart ordering to prevent visual overflow:
        // Moving right: set position first, then size.
        // Moving left: set size first, then position.
        if frame.origin.x >= currentPos.x {
            _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            guard sizeResult == .success else { throw AccessibilityError.cannotComplete }
        } else {
            _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            guard posResult == .success else { throw AccessibilityError.cannotComplete }
        }
    }

    public func raise(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        guard result == .success else { throw AccessibilityError.cannotComplete }
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

    private func checkMinimized(_ window: AXUIElement) -> Bool {
        var minVal: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minVal)
        guard result == .success, let isMin = minVal as? Bool else { return false }
        return isMin
    }

    private func classifyKind(_ window: AXUIElement, isResizable: Bool) -> WindowKind {
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
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

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
}

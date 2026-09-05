@preconcurrency import ApplicationServices
import CoreGraphics
import Foundation

/// Concrete implementation of WindowManaging.
///
/// Delegates actual window control to AccessibilityService on the MainActor.
/// See spec §27.
@MainActor
public final class WindowManager: WindowManaging {

    private let accessibilityService: AccessibilityService
    private let fullScreenEscapeCoordinator: FullScreenEscapeCoordinating
    public var onWindowMoved: ((CGWindowID) -> Void)?

    public init(
        accessibilityService: AccessibilityService,
        fullScreenEscapeCoordinator: FullScreenEscapeCoordinating = FullScreenEscapeCoordinator.shared
    ) {
        self.accessibilityService = accessibilityService
        self.fullScreenEscapeCoordinator = fullScreenEscapeCoordinator
    }

    public func focusedWindow() async -> ManagedWindow? {
        accessibilityService.focusedManagedWindow()
    }

    public func move(_ window: ManagedWindow, to frame: CGRect) async throws {
        try await move(window, to: frame, element: nil)
    }

    public func move(_ window: ManagedWindow, to frame: CGRect, element: AXUIElement?) async throws {
        // Prevent snapping FlowSnap's own windows
        if window.pid == ProcessInfo.processInfo.processIdentifier {
            return
        }
        let targetElement: AXUIElement
        if let element {
            targetElement = element
        } else if let resolved = accessibilityService.windowElement(for: window) {
            targetElement = resolved
        } else if let focused = accessibilityService.focusedWindow() {
            targetElement = focused
        } else {
            throw AccessibilityError.cannotComplete
        }

        // A minimized window accepts AX position/size writes but stays in the Dock,
        // so the user sees nothing. Clear the flag first (best-effort: some apps
        // reject the write, and a partially restored window still beats none).
        if window.isMinimized {
            do {
                try accessibilityService.unminimize(targetElement)
            } catch {
                diagPrint("[WindowManager] Unminimize failed for \(window.title): \(error.localizedDescription)")
            }
        }

        // A full-screen window cannot be repositioned while in full-screen mode;
        // macOS returns success but silently ignores the AX frame writes. Exit
        // full-screen first via the multi-tier escape coordinator with adaptive
        // space transition waiting before calling setFrame.
        if window.kind == .fullscreen {
            do {
                _ = try await fullScreenEscapeCoordinator.exitFullScreen(
                    for: targetElement,
                    pid: window.pid,
                    isFullScreenChecker: { [weak self] in
                        guard let self else { return false }
                        guard let currentFrame = self.accessibilityService.frame(of: targetElement) else { return false }
                        return currentFrame == window.frame
                    }
                )
            } catch {
                diagPrint("[WindowManager] ExitFullScreen failed for \(window.title): \(error.localizedDescription)")
            }
        }

        // Tiered Backoff Retry (Bug 1 Fix)
        let maxRetries = 3
        diagPrint("[DIAG-MOVE] calling setFrame (\(frame.minX), \(frame.minY), \(frame.width), \(frame.height)) for '\(window.title)' kind=\(window.kind)")
        for attempt in 1...maxRetries {
            do {
                try accessibilityService.setFrame(frame, for: targetElement)
                diagPrint("[DIAG-MOVE] setFrame OK for '\(window.title)' attempt=\(attempt)")
                onWindowMoved?(window.id)
                break // Success
            } catch AccessibilityError.cannotComplete {
                diagPrint("[DIAG-MOVE] setFrame THREW cannotComplete for '\(window.title)' attempt=\(attempt)")
                if attempt == maxRetries {
                    diagPrint("[WindowManager] Move failed for \(window.title) after \(maxRetries) attempts (cannotComplete)")
                    throw AccessibilityError.cannotComplete
                }

                if attempt == 1 {
                    // Tier 1: Wait for AX tree to initialize or Space to switch
                    try await Task.sleep(nanoseconds: 200_000_000)
                } else if attempt == 2 {
                    // Tier 2: Wake up the AX tree explicitly without stealing workspace focus
                    do {
                        try accessibilityService.raise(targetElement)
                    } catch { /* ignore raise error, wait anyway */ }
                    try await Task.sleep(nanoseconds: 300_000_000)
                }
            } catch {
                // If it is not cannotComplete (e.g. notTrusted), fail immediately.
                diagPrint("[DIAG-MOVE] setFrame THREW \(error) for '\(window.title)' — no retry")
                throw error
            }
        }

    }

    public func focus(_ window: ManagedWindow) async throws {
        // Prevent focusing FlowSnap's own windows
        if window.pid == ProcessInfo.processInfo.processIdentifier {
            return
        }
        let element: AXUIElement
        if let targetElement = accessibilityService.windowElement(for: window) {
            element = targetElement
        } else if let focused = accessibilityService.focusedWindow() {
            element = focused
        } else {
            throw AccessibilityError.cannotComplete
        }
        try accessibilityService.raise(element)
    }

    public func minimize(_ window: ManagedWindow) async throws {
        if window.pid == ProcessInfo.processInfo.processIdentifier { return }
        let element: AXUIElement
        if let targetElement = accessibilityService.windowElement(for: window) {
            element = targetElement
        } else if let focused = accessibilityService.focusedWindow() {
            element = focused
        } else {
            throw AccessibilityError.cannotComplete
        }
        try accessibilityService.minimize(element)
    }

    public func unminimize(_ window: ManagedWindow) async throws {
        if window.pid == ProcessInfo.processInfo.processIdentifier { return }
        let element: AXUIElement
        if let targetElement = accessibilityService.windowElement(for: window) {
            element = targetElement
        } else {
            let appWindows = accessibilityService.windows(of: window.pid)
            if let first = appWindows.first {
                element = first
            } else {
                throw AccessibilityError.cannotComplete
            }
        }
        try accessibilityService.unminimize(element)
    }
}

extension WindowManager {}

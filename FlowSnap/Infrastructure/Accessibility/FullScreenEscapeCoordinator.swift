import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Coordinator executing multi-tier escape from macOS full screen mode with adaptive transition waiting.
public final class FullScreenEscapeCoordinator: FullScreenEscapeCoordinating, @unchecked Sendable {
    public static let shared = FullScreenEscapeCoordinator()

    public static let fullscreenAttributeKeys: [String] = ["AXFullscreen", "AXFullScreen"]
    public static let fKeyCode: CGKeyCode = 0x03

    private let eventPoster: CGEventPosting
    private let appActivator: @Sendable (pid_t) -> Bool
    private let attributeWriter: @Sendable (AXUIElement, String, CFBoolean) -> AXError
    private let buttonFinder: @Sendable (AXUIElement) -> AXUIElement?
    private let buttonPresser: @Sendable (AXUIElement) -> AXError
    private let sleepFunction: @Sendable (UInt64) async throws -> Void

    public init(
        eventPoster: CGEventPosting = SystemCGEventPoster(),
        appActivator: (@Sendable (pid_t) -> Bool)? = nil,
        attributeWriter: (@Sendable (AXUIElement, String, CFBoolean) -> AXError)? = nil,
        buttonFinder: (@Sendable (AXUIElement) -> AXUIElement?)? = nil,
        buttonPresser: (@Sendable (AXUIElement) -> AXError)? = nil,
        sleepFunction: (@Sendable (UInt64) async throws -> Void)? = nil
    ) {
        self.eventPoster = eventPoster
        self.appActivator = appActivator ?? { pid in
            NSRunningApplication(processIdentifier: pid)?.activate(options: [.activateIgnoringOtherApps]) ?? false
        }
        self.attributeWriter = attributeWriter ?? { element, key, value in
            AXUIElementSetAttributeValue(element, key as CFString, value)
        }
        self.buttonFinder = buttonFinder ?? { element in
            var buttonValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, kAXFullScreenButtonAttribute as CFString, &buttonValue)
            if result == .success, let val = buttonValue, CFGetTypeID(val) == AXUIElementGetTypeID() {
                // swiftlint:disable:next force_cast
                return (val as! AXUIElement)
            }
            return nil
        }
        self.buttonPresser = buttonPresser ?? { button in
            AXUIElementPerformAction(button, kAXPressAction as CFString)
        }
        self.sleepFunction = sleepFunction ?? { nanoseconds in
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    public func exitFullScreen(
        for element: AXUIElement,
        pid: pid_t?,
        isFullScreenChecker: (@Sendable () async -> Bool)? = nil
    ) async throws -> FullScreenEscapeResult {
        let startTime = DispatchTime.now()

        // 1. Tier 0: Direct Attribute Write (AXFullscreen / AXFullScreen = false)
        var tierUsed: FullScreenEscapeTier?
        for key in Self.fullscreenAttributeKeys {
            let result = attributeWriter(element, key, kCFBooleanFalse)
            if result == .success {
                diagPrint("[FullScreenEscapeCoordinator] Tier 0 (.attributeWrite) succeeded via '\(key)'")
                tierUsed = .attributeWrite
                break
            }
        }

        // 2. Tier 1: AX FullScreen Button Press (kAXFullScreenButtonAttribute + kAXPressAction)
        if tierUsed == nil {
            if let button = buttonFinder(element) {
                let pressResult = buttonPresser(button)
                if pressResult == .success {
                    diagPrint("[FullScreenEscapeCoordinator] Tier 1 (.axButtonPress) succeeded")
                    tierUsed = .axButtonPress
                } else {
                    diagPrint("[FullScreenEscapeCoordinator] Tier 1 button press failed: \(pressResult.rawValue)")
                }
            } else {
                diagPrint("[FullScreenEscapeCoordinator] Tier 1 button not found")
            }
        }

        // 3. Tier 2: Synthesized ⌃⌘F keystroke via CGEvent to target PID
        if tierUsed == nil {
            if let pid {
                diagPrint("[FullScreenEscapeCoordinator] Tier 2 (.cgEventShortcut) activating PID \(pid)...")
                _ = appActivator(pid)
                try? await sleepFunction(50_000_000) // 50ms for focus stabilization

                do {
                    try eventPoster.postKeystroke(
                        keyCode: Self.fKeyCode,
                        flags: [.maskControl, .maskCommand],
                        to: pid
                    )
                    diagPrint("[FullScreenEscapeCoordinator] Tier 2 (.cgEventShortcut) posted ⌃⌘F to PID \(pid)")
                    tierUsed = .cgEventShortcut
                } catch {
                    diagPrint("[FullScreenEscapeCoordinator] Tier 2 postKeystroke failed: \(error.localizedDescription)")
                }
            } else {
                diagPrint("[FullScreenEscapeCoordinator] Tier 2 skipped: PID is nil")
            }
        }

        guard let confirmedTier = tierUsed else {
            let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000)
            return .failure(durationMs: elapsedMs, error: "All escape tiers failed")
        }

        // 4. Adaptive Polling Loop (100ms interval, up to 800ms ceiling)
        let maxIntervals = 8
        var pollCount = 0
        while pollCount < maxIntervals {
            try? await sleepFunction(100_000_000) // 100ms
            pollCount += 1

            if let isFullScreenChecker, !(await isFullScreenChecker()) {
                let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000)
                diagPrint("[FullScreenEscapeCoordinator] Adaptive exit detected at attempt \(pollCount) (\(elapsedMs)ms)")
                return .success(tier: confirmedTier, durationMs: elapsedMs)
            }
        }

        let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000)
        diagPrint("[FullScreenEscapeCoordinator] Polling ceiling reached (\(elapsedMs)ms), returning best-effort")
        return .success(tier: confirmedTier, durationMs: elapsedMs)
    }
}

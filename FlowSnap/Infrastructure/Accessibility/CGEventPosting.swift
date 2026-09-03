import CoreGraphics
import Foundation

/// Testable abstraction for posting synthesized CGEvents to target process PIDs.
public protocol CGEventPosting: Sendable {
    /// Posts a keystroke (keyDown and keyUp) with specified flags to the given process identifier.
    func postKeystroke(keyCode: CGKeyCode, flags: CGEventFlags, to pid: pid_t) throws
}

/// System implementation dispatching standard CoreGraphics keyboard events to target process PIDs.
public struct SystemCGEventPoster: CGEventPosting {
    public init() {}

    public func postKeystroke(keyCode: CGKeyCode, flags: CGEventFlags, to pid: pid_t) throws {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            throw AccessibilityError.cannotComplete
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
}

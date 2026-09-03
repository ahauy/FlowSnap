import CoreGraphics
import Foundation
@testable import FlowSnap

public final class MockCGEventPoster: CGEventPosting, @unchecked Sendable {
    public struct KeystrokeRecord: Equatable {
        public let keyCode: CGKeyCode
        public let flags: CGEventFlags
        public let pid: pid_t

        public init(keyCode: CGKeyCode, flags: CGEventFlags, pid: pid_t) {
            self.keyCode = keyCode
            self.flags = flags
            self.pid = pid
        }
    }

    public private(set) var postedKeystrokes: [KeystrokeRecord] = []
    public var shouldThrow: Error?

    public init() {}

    public func postKeystroke(keyCode: CGKeyCode, flags: CGEventFlags, to pid: pid_t) throws {
        if let shouldThrow {
            throw shouldThrow
        }
        postedKeystrokes.append(KeystrokeRecord(keyCode: keyCode, flags: flags, pid: pid))
    }

    public func reset() {
        postedKeystrokes.removeAll()
        shouldThrow = nil
    }
}

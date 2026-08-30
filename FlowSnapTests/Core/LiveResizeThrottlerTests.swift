import Foundation
import Testing
@testable import FlowSnap

@Suite("LiveResizeThrottler Tests")
struct LiveResizeThrottlerTests {

    @Test("Allows first event immediately")
    func allowsFirstEventImmediately() {
        let throttler = LiveResizeThrottler(fps: 60.0)
        #expect(throttler.shouldProcess(timestamp: 100.0) == true)
    }

    @Test("Drops events that occur within the 16.6ms window")
    func dropsRapidEvents() {
        let throttler = LiveResizeThrottler(fps: 60.0)
        #expect(throttler.shouldProcess(timestamp: 100.0) == true)
        // 5ms later -> drop
        #expect(throttler.shouldProcess(timestamp: 100.005) == false)
        // 10ms later -> drop
        #expect(throttler.shouldProcess(timestamp: 100.010) == false)
    }

    @Test("Allows event after minimum interval elapses")
    func allowsEventAfterInterval() {
        let throttler = LiveResizeThrottler(fps: 60.0)
        #expect(throttler.shouldProcess(timestamp: 100.0) == true)
        // 17ms later -> pass
        #expect(throttler.shouldProcess(timestamp: 100.017) == true)
    }

    @Test("Reset allows immediate execution")
    func resetAllowsImmediate() {
        let throttler = LiveResizeThrottler(fps: 60.0)
        #expect(throttler.shouldProcess(timestamp: 100.0) == true)
        #expect(throttler.shouldProcess(timestamp: 100.005) == false)

        throttler.reset()
        #expect(throttler.shouldProcess(timestamp: 100.006) == true)
    }
}

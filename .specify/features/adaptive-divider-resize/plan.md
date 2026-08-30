# Implementation Plan: US-SNAP-009 Adaptive Multi-Window Divider Resize

## 1. Architecture Plan
1. **Domain Models**: Add `DividerOrientation.swift`, `CollinearEdge.swift`, `LayoutNode.swift`, `LayoutGraph.swift`.
2. **Core Algorithms**: Implement `CollinearEdgeDetector.swift` handling 2-window, 3-window (T-junction), 4-window cross splits, tolerance hit-testing, and delta calculations.
3. **Throttler & Coordinator**: Implement `LiveResizeThrottler.swift` and `AdaptiveDividerCoordinator.swift` managing `@MainActor` event flow, cursor swapping, and throttled window resizing.
4. **Unit Testing**: Create full test coverage in `LayoutGraphTests.swift`, `CollinearEdgeDetectorTests.swift`, `LiveResizeThrottlerTests.swift`, and `AdaptiveDividerCoordinatorTests.swift`.
5. **Verification**: Run `xcodebuild test` and verify clean build and all test passes.
6. **Documentation**: Create feature README, update main docs, roadmap, and user guides.

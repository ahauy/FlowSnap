import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("LayoutGraph & LayoutNode Tests")
struct LayoutGraphTests {

    @Test("Leaf node frame evaluation")
    func leafNodeFrameEvaluation() {
        let frame = CGRect(x: 100, y: 100, width: 400, height: 300)
        let leaf = LayoutNode.leaf(windowID: 101, frame: frame, minSize: CGSize(width: 200, height: 150))

        #expect(leaf.allWindowIDs() == [101])
        #expect(leaf.allFrames() == [101: frame])

        let computed = leaf.computeFrames(in: frame)
        #expect(computed[101] == frame)
    }

    @Test("Vertical split node partition computation")
    func verticalSplitNodePartitionComputation() {
        let leaf1 = LayoutNode.leaf(windowID: 1, frame: .zero, minSize: nil)
        let leaf2 = LayoutNode.leaf(windowID: 2, frame: .zero, minSize: nil)

        let split = LayoutNode.split(
            axis: .vertical,
            ratio: 0.5,
            gap: 0,
            first: leaf1,
            second: leaf2
        )

        let container = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let frames = split.computeFrames(in: container)

        #expect(frames[1] == CGRect(x: 0, y: 0, width: 500, height: 800))
        #expect(frames[2] == CGRect(x: 500, y: 0, width: 500, height: 800))
    }

    @Test("Horizontal split node partition computation with gap")
    func horizontalSplitNodePartitionComputationWithGap() {
        let leaf1 = LayoutNode.leaf(windowID: 10, frame: .zero, minSize: nil)
        let leaf2 = LayoutNode.leaf(windowID: 20, frame: .zero, minSize: nil)

        let split = LayoutNode.split(
            axis: .horizontal,
            ratio: 0.5,
            gap: 10,
            first: leaf1,
            second: leaf2
        )

        let container = CGRect(x: 0, y: 0, width: 1000, height: 810)
        let frames = split.computeFrames(in: container)

        #expect(frames[10] == CGRect(x: 0, y: 0, width: 1000, height: 400))
        #expect(frames[20] == CGRect(x: 0, y: 410, width: 1000, height: 400))
    }

    @Test("LayoutGraph frames extraction and divider query")
    func layoutGraphFramesExtractionAndDividerQuery() {
        let w1 = ManagedWindow(id: 1, pid: 10, title: "W1", frame: CGRect(x: 0, y: 0, width: 500, height: 1000))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "W2", frame: CGRect(x: 500, y: 0, width: 500, height: 1000))

        let graph = LayoutGraph(
            windows: [w1, w2],
            containerFrame: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            gap: 0
        )

        let frames = graph.frames()
        #expect(frames.count == 2)
        #expect(frames[1] == w1.frame)
        #expect(frames[2] == w2.frame)

        let dividers = graph.detectDividers()
        #expect(dividers.count == 1)
        #expect(dividers.first?.orientation == .vertical)
        #expect(dividers.first?.coordinate == 500)

        let hit = graph.divider(at: CGPoint(x: 502, y: 500))
        #expect(hit != nil)
        #expect(hit?.coordinate == 500)

        // Applying resize
        let resizedGraph = graph.applyingResize(divider: hit!, targetCoordinate: 600)
        let updatedFrames = resizedGraph.frames()
        #expect(updatedFrames[1]?.width == 600)
        #expect(updatedFrames[2]?.origin.x == 600)
        #expect(updatedFrames[2]?.width == 400)
    }
}

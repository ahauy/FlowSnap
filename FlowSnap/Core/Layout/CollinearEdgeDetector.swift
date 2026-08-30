import CoreGraphics
import Foundation

/// Detects shared collinear edges (dividers) between adjacent windows and computes
/// live resized frames while enforcing minimum size constraints and gap spacing.
public struct CollinearEdgeDetector: CollinearEdgeDetecting, Sendable {

    public let defaultMinWidth: CGFloat
    public let defaultMinHeight: CGFloat

    public init(defaultMinWidth: CGFloat = 380.0, defaultMinHeight: CGFloat = 260.0) {
        self.defaultMinWidth = defaultMinWidth
        self.defaultMinHeight = defaultMinHeight
    }

    // MARK: - Divider Detection

    public func detectDividers(
        in windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat = 0,
        tolerance: CGFloat = 6.0
    ) -> [CollinearEdge] {
        guard windows.count >= 2 else { return [] }

        var dividers: [CollinearEdge] = []
        let minOverlap: CGFloat = 5.0

        // 1. Detect Vertical Dividers (Separating Left and Right windows)
        // Group pairs by divider X position
        struct VPair {
            let left: ManagedWindow
            let right: ManagedWindow
            let dividerX: CGFloat
            let overlapRange: ClosedRange<CGFloat>
        }

        var vPairs: [VPair] = []
        for i in 0..<windows.count {
            for j in 0..<windows.count where i != j {
                let w1 = windows[i]
                let w2 = windows[j]

                // Check if w1 is to the left of w2
                let distance = w2.frame.minX - w1.frame.maxX
                if abs(distance - gap) <= tolerance || abs(distance) <= tolerance {
                    let overlapMin = max(w1.frame.minY, w2.frame.minY)
                    let overlapMax = min(w1.frame.maxY, w2.frame.maxY)
                    if overlapMax - overlapMin >= minOverlap {
                        let dividerX = (w1.frame.maxX + w2.frame.minX) / 2.0
                        vPairs.append(VPair(
                            left: w1,
                            right: w2,
                            dividerX: dividerX,
                            overlapRange: overlapMin...overlapMax
                        ))
                    }
                }
            }
        }

        // Group collinear vertical pairs that share the same X (within tolerance)
        var visitedVPairs = Set<Int>()
        for i in 0..<vPairs.count {
            guard !visitedVPairs.contains(i) else { continue }
            visitedVPairs.insert(i)

            var groupPairs = [vPairs[i]]
            for j in (i + 1)..<vPairs.count {
                guard !visitedVPairs.contains(j) else { continue }
                if abs(vPairs[i].dividerX - vPairs[j].dividerX) <= tolerance {
                    visitedVPairs.insert(j)
                    groupPairs.append(vPairs[j])
                }
            }

            let avgX = groupPairs.map(\.dividerX).reduce(0, +) / CGFloat(groupPairs.count)
            let allMinY = groupPairs.map { min($0.left.frame.minY, $0.right.frame.minY) }.min() ?? 0
            let allMaxY = groupPairs.map { max($0.left.frame.maxY, $0.right.frame.maxY) }.max() ?? 0

            var leadingIDs = Set<CGWindowID>()
            var trailingIDs = Set<CGWindowID>()
            var leadingWindows: [ManagedWindow] = []
            var trailingWindows: [ManagedWindow] = []

            for p in groupPairs {
                if !leadingIDs.contains(p.left.id) {
                    leadingIDs.insert(p.left.id)
                    leadingWindows.append(p.left)
                }
                if !trailingIDs.contains(p.right.id) {
                    trailingIDs.insert(p.right.id)
                    trailingWindows.append(p.right)
                }
            }

            // Min and Max X boundary constraints based on minSize
            var minCoord: CGFloat = containerFrame.minX + defaultMinWidth + (gap / 2.0)
            for w in leadingWindows {
                let minW = max(defaultMinWidth, w.minSize?.width ?? defaultMinWidth)
                minCoord = max(minCoord, w.frame.minX + minW + gap / 2.0)
            }

            var maxCoord: CGFloat = containerFrame.maxX - defaultMinWidth - (gap / 2.0)
            for w in trailingWindows {
                let minW = max(defaultMinWidth, w.minSize?.width ?? defaultMinWidth)
                maxCoord = min(maxCoord, w.frame.maxX - minW - gap / 2.0)
            }

            if maxCoord >= minCoord {
                let span = allMinY...allMaxY
                let hitRect = CGRect(
                    x: avgX - tolerance,
                    y: span.lowerBound,
                    width: tolerance * 2.0,
                    height: max(1.0, span.upperBound - span.lowerBound)
                )

                dividers.append(CollinearEdge(
                    orientation: .vertical,
                    coordinate: avgX,
                    span: span,
                    hitRect: hitRect,
                    leadingWindowIDs: Array(leadingIDs),
                    trailingWindowIDs: Array(trailingIDs),
                    minCoordinate: minCoord,
                    maxCoordinate: maxCoord
                ))
            }
        }

        // 2. Detect Horizontal Dividers (Separating Bottom and Top windows)
        struct HPair {
            let bottom: ManagedWindow
            let top: ManagedWindow
            let dividerY: CGFloat
            let overlapRange: ClosedRange<CGFloat>
        }

        var hPairs: [HPair] = []
        for i in 0..<windows.count {
            for j in 0..<windows.count where i != j {
                let w1 = windows[i]
                let w2 = windows[j]

                // In AppKit coordinates, bottom window maxY meets top window minY
                let distance = w2.frame.minY - w1.frame.maxY
                if abs(distance - gap) <= tolerance || abs(distance) <= tolerance {
                    let overlapMin = max(w1.frame.minX, w2.frame.minX)
                    let overlapMax = min(w1.frame.maxX, w2.frame.maxX)
                    if overlapMax - overlapMin >= minOverlap {
                        let dividerY = (w1.frame.maxY + w2.frame.minY) / 2.0
                        hPairs.append(HPair(
                            bottom: w1,
                            top: w2,
                            dividerY: dividerY,
                            overlapRange: overlapMin...overlapMax
                        ))
                    }
                }
            }
        }

        var visitedHPairs = Set<Int>()
        for i in 0..<hPairs.count {
            guard !visitedHPairs.contains(i) else { continue }
            visitedHPairs.insert(i)

            var groupPairs = [hPairs[i]]
            for j in (i + 1)..<hPairs.count {
                guard !visitedHPairs.contains(j) else { continue }
                if abs(hPairs[i].dividerY - hPairs[j].dividerY) <= tolerance {
                    visitedHPairs.insert(j)
                    groupPairs.append(hPairs[j])
                }
            }

            let avgY = groupPairs.map(\.dividerY).reduce(0, +) / CGFloat(groupPairs.count)
            let allMinX = groupPairs.map { min($0.bottom.frame.minX, $0.top.frame.minX) }.min() ?? 0
            let allMaxX = groupPairs.map { max($0.bottom.frame.maxX, $0.top.frame.maxX) }.max() ?? 0

            var leadingIDs = Set<CGWindowID>()
            var trailingIDs = Set<CGWindowID>()
            var leadingWindows: [ManagedWindow] = []
            var trailingWindows: [ManagedWindow] = []

            for p in groupPairs {
                if !leadingIDs.contains(p.bottom.id) {
                    leadingIDs.insert(p.bottom.id)
                    leadingWindows.append(p.bottom)
                }
                if !trailingIDs.contains(p.top.id) {
                    trailingIDs.insert(p.top.id)
                    trailingWindows.append(p.top)
                }
            }

            // Min and Max Y boundary constraints based on minSize
            var minCoord: CGFloat = containerFrame.minY + defaultMinHeight + (gap / 2.0)
            for w in leadingWindows {
                let minH = max(defaultMinHeight, w.minSize?.height ?? defaultMinHeight)
                minCoord = max(minCoord, w.frame.minY + minH + gap / 2.0)
            }

            var maxCoord: CGFloat = containerFrame.maxY - defaultMinHeight - (gap / 2.0)
            for w in trailingWindows {
                let minH = max(defaultMinHeight, w.minSize?.height ?? defaultMinHeight)
                maxCoord = min(maxCoord, w.frame.maxY - minH - gap / 2.0)
            }

            if maxCoord >= minCoord {
                let span = allMinX...allMaxX
                let hitRect = CGRect(
                    x: span.lowerBound,
                    y: avgY - tolerance,
                    width: max(1.0, span.upperBound - span.lowerBound),
                    height: tolerance * 2.0
                )

                dividers.append(CollinearEdge(
                    orientation: .horizontal,
                    coordinate: avgY,
                    span: span,
                    hitRect: hitRect,
                    leadingWindowIDs: Array(leadingIDs),
                    trailingWindowIDs: Array(trailingIDs),
                    minCoordinate: minCoord,
                    maxCoordinate: maxCoord
                ))
            }
        }

        return dividers
    }

    // MARK: - Hit Testing

    public func hitTestDivider(
        at point: CGPoint,
        in dividers: [CollinearEdge]
    ) -> CollinearEdge? {
        dividers.first { $0.contains(point) }
    }

    // MARK: - Resizing Frame Computation

    public func computeResizedFrames(
        for divider: CollinearEdge,
        targetCoordinate: CGFloat,
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat = 0
    ) -> [CGWindowID: CGRect] {
        var windowDict: [CGWindowID: ManagedWindow] = [:]
        for w in windows {
            windowDict[w.id] = w
        }

        var result: [CGWindowID: CGRect] = [:]

        switch divider.orientation {
        case .vertical:
            let containerMinCoord = containerFrame.minX + defaultMinWidth + (gap / 2.0)
            let containerMaxCoord = containerFrame.maxX - defaultMinWidth - (gap / 2.0)

            var effectiveMin: CGFloat = max(divider.minCoordinate, containerMinCoord)
            for id in divider.leadingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let minW = max(defaultMinWidth, window.minSize?.width ?? defaultMinWidth)
                effectiveMin = max(effectiveMin, window.frame.minX + minW + (gap / 2.0))
            }

            var effectiveMax: CGFloat = min(divider.maxCoordinate, containerMaxCoord)
            for id in divider.trailingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let minW = max(defaultMinWidth, window.minSize?.width ?? defaultMinWidth)
                effectiveMax = min(effectiveMax, window.frame.maxX - minW - (gap / 2.0))
            }

            if effectiveMax < effectiveMin {
                effectiveMax = effectiveMin
            }

            let safeCoordinate = max(effectiveMin, min(effectiveMax, targetCoordinate))
            let leadingEdge = safeCoordinate - (gap / 2.0)
            let trailingEdge = safeCoordinate + (gap / 2.0)

            for id in divider.leadingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let initialMinX = max(containerFrame.minX, window.frame.minX)
                let newWidth = max(0, leadingEdge - initialMinX)
                result[id] = CGRect(
                    x: initialMinX,
                    y: window.frame.minY,
                    width: newWidth,
                    height: window.frame.height
                )
            }

            for id in divider.trailingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let initialMaxX = min(containerFrame.maxX, window.frame.maxX)
                let newWidth = max(0, initialMaxX - trailingEdge)
                result[id] = CGRect(
                    x: trailingEdge,
                    y: window.frame.minY,
                    width: newWidth,
                    height: window.frame.height
                )
            }

        case .horizontal:
            let containerMinCoord = containerFrame.minY + defaultMinHeight + (gap / 2.0)
            let containerMaxCoord = containerFrame.maxY - defaultMinHeight - (gap / 2.0)

            var effectiveMin: CGFloat = max(divider.minCoordinate, containerMinCoord)
            for id in divider.leadingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let minH = max(defaultMinHeight, window.minSize?.height ?? defaultMinHeight)
                effectiveMin = max(effectiveMin, window.frame.minY + minH + (gap / 2.0))
            }

            var effectiveMax: CGFloat = min(divider.maxCoordinate, containerMaxCoord)
            for id in divider.trailingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let minH = max(defaultMinHeight, window.minSize?.height ?? defaultMinHeight)
                effectiveMax = min(effectiveMax, window.frame.maxY - minH - (gap / 2.0))
            }

            if effectiveMax < effectiveMin {
                effectiveMax = effectiveMin
            }

            let safeCoordinate = max(effectiveMin, min(effectiveMax, targetCoordinate))
            let leadingEdge = safeCoordinate - (gap / 2.0)
            let trailingEdge = safeCoordinate + (gap / 2.0)

            for id in divider.leadingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let initialMinY = max(containerFrame.minY, window.frame.minY)
                let newHeight = max(0, leadingEdge - initialMinY)
                result[id] = CGRect(
                    x: window.frame.minX,
                    y: initialMinY,
                    width: window.frame.width,
                    height: newHeight
                )
            }

            for id in divider.trailingWindowIDs {
                guard let window = windowDict[id] else { continue }
                let initialMaxY = min(containerFrame.maxY, window.frame.maxY)
                let newHeight = max(0, initialMaxY - trailingEdge)
                result[id] = CGRect(
                    x: window.frame.minX,
                    y: trailingEdge,
                    width: window.frame.width,
                    height: newHeight
                )
            }
        }

        return result
    }
}

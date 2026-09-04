import CoreGraphics
import Foundation

/// Detects collinear shared edges between adjacent windows and computes
/// synchronized resize frames for adaptive divider dragging.
///
/// The detector is a pure geometric service: it takes window frames and
/// returns dividers plus resized frames. It performs no AX calls and holds
/// no state, which keeps it trivially unit-testable.
///
/// Coordinate space: AppKit global (bottom-left origin), matching
/// `ManagedWindow.frame`.
public struct CollinearEdgeDetector: CollinearEdgeDetecting {

    /// Fallback minimum width used when a window does not report one.
    public let defaultMinWidth: CGFloat

    /// Fallback minimum height used when a window does not report one.
    public let defaultMinHeight: CGFloat

    /// A seam shorter than this many points is not a usable divider.
    static let minimumSpanLength: CGFloat = 12.0

    public init(defaultMinWidth: CGFloat = 380.0, defaultMinHeight: CGFloat = 260.0) {
        self.defaultMinWidth = defaultMinWidth
        self.defaultMinHeight = defaultMinHeight
    }

    // MARK: - Pair model

    /// One candidate seam found between two facing windows.
    struct SeamPair {
        let leading: ManagedWindow
        let trailing: ManagedWindow
        let coordinate: CGFloat
        /// Stretch where the two windows genuinely face each other.
        let overlap: ClosedRange<CGFloat>
    }

    // MARK: - Detection

    public func detectDividers(
        in windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat = 0,
        tolerance: CGFloat = 6.0
    ) -> [CollinearEdge] {
        // Only resizable, on-screen windows that belong to this container.
        let candidates = windows.filter { window in
            window.isResizable
                && !window.isMinimized
                && window.frame.width > 1
                && window.frame.height > 1
                && window.frame.intersects(containerFrame)
        }
        guard candidates.count >= 2 else { return [] }

        var dividers: [CollinearEdge] = []
        dividers.append(contentsOf: detect(
            .vertical, windows: candidates, containerFrame: containerFrame,
            gap: gap, tolerance: tolerance
        ))
        dividers.append(contentsOf: detect(
            .horizontal, windows: candidates, containerFrame: containerFrame,
            gap: gap, tolerance: tolerance
        ))
        return dividers
    }

    /// Orientation-agnostic seam search.
    ///
    /// `along` is the axis the divider slides on, `cross` the perpendicular
    /// axis it spans. Vertical: along = x, cross = y. Horizontal: along = y,
    /// cross = x, with leading being the lower window in AppKit space.
    private func detect(
        _ orientation: DividerOrientation,
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat,
        tolerance: CGFloat
    ) -> [CollinearEdge] {
        var pairs: [SeamPair] = []

        for i in 0..<windows.count {
            for j in (i + 1)..<windows.count {
                // Windows that appear before the seam pair in the front-to-back list are in front of the seam.
                let higherIndex = max(i, j)
                let potentialOccluders = windows[0..<higherIndex].filter { $0.id != windows[i].id && $0.id != windows[j].id }
                if let pair = seamPair(
                    between: windows[i],
                    and: windows[j],
                    orientation: orientation,
                    gap: gap,
                    tolerance: tolerance,
                    occludingWindows: potentialOccluders
                ) {
                    pairs.append(pair)
                }
            }
        }

        guard !pairs.isEmpty else { return [] }

        // Group pairs sitting on the same line. Integer rounding keeps a
        // one-pixel reporting difference from splitting one seam in two.
        let groups = Dictionary(grouping: pairs) { Int($0.coordinate.rounded()) }

        var results: [CollinearEdge] = []
        for group in groups.values {
            if let divider = buildDivider(
                from: group, orientation: orientation,
                containerFrame: containerFrame, gap: gap
            ) {
                results.append(divider)
            }
        }
        return results
    }

    /// Finds the seam between two windows, if they are neighbours.
    private func seamPair(
        between a: ManagedWindow,
        and b: ManagedWindow,
        orientation: DividerOrientation,
        gap: CGFloat,
        tolerance: CGFloat,
        occludingWindows: [ManagedWindow] = []
    ) -> SeamPair? {
        let aAlong = alongRange(of: a, orientation: orientation)
        let bAlong = alongRange(of: b, orientation: orientation)
        let aCross = crossRange(of: a, orientation: orientation)
        let bCross = crossRange(of: b, orientation: orientation)

        var overlapStart = max(aCross.lowerBound, bCross.lowerBound)
        var overlapEnd = min(aCross.upperBound, bCross.upperBound)
        guard overlapEnd - overlapStart >= Self.minimumSpanLength else { return nil }

        let effectiveTolerance = max(tolerance, gap + 6.0)
        let aBeforeB = (bAlong.lowerBound - aAlong.upperBound) >= -effectiveTolerance && (bAlong.lowerBound - aAlong.upperBound) <= gap + effectiveTolerance
        let bBeforeA = (aAlong.lowerBound - bAlong.upperBound) >= -effectiveTolerance && (aAlong.lowerBound - bAlong.upperBound) <= gap + effectiveTolerance

        guard aBeforeB != bBeforeA else { return nil }
        let (leading, trailing) = aBeforeB ? (a, b) : (b, a)
        let (lAlong, tAlong) = aBeforeB ? (aAlong, bAlong) : (bAlong, aAlong)
        let seam = (lAlong.upperBound + tAlong.lowerBound) / 2.0

        // Z-order occlusion check:
        // Any window sitting in front of both/either window in the seam pair that covers the seam coordinate
        // reduces the visible seam span or completely occludes the divider.
        for occluder in occludingWindows {
            let occAlong = alongRange(of: occluder, orientation: orientation)
            let occCross = crossRange(of: occluder, orientation: orientation)

            let coversSeam = (occAlong.lowerBound <= seam + effectiveTolerance) && (occAlong.upperBound >= seam - effectiveTolerance)
            guard coversSeam else { continue }

            let occStart = occCross.lowerBound
            let occEnd = occCross.upperBound

            // If occluder completely covers the overlap range:
            if occStart <= overlapStart && occEnd >= overlapEnd {
                return nil
            }
            // If occluder covers the lower/left portion:
            else if occStart <= overlapStart && occEnd > overlapStart {
                overlapStart = max(overlapStart, occEnd)
            }
            // If occluder covers the upper/right portion:
            else if occEnd >= overlapEnd && occStart < overlapEnd {
                overlapEnd = min(overlapEnd, occStart)
            }
            // If occluder is in the middle: take the larger visible sub-segment
            else if occStart > overlapStart && occEnd < overlapEnd {
                let lowerLength = occStart - overlapStart
                let upperLength = overlapEnd - occEnd
                if lowerLength >= upperLength {
                    overlapEnd = occStart
                } else {
                    overlapStart = occEnd
                }
            }

            guard overlapEnd - overlapStart >= Self.minimumSpanLength else { return nil }
        }

        return SeamPair(
            leading: leading,
            trailing: trailing,
            coordinate: seam,
            overlap: overlapStart...overlapEnd
        )
    }

    /// Merges every pair sharing a line into one divider.
    ///
    /// The span is the union of the pairwise overlaps — never the union of the
    /// windows themselves, which is what used to light up phantom hit areas
    /// beside T-junctions and staircased layouts.
    private func buildDivider(
        from pairs: [SeamPair],
        orientation: DividerOrientation,
        containerFrame: CGRect,
        gap: CGFloat
    ) -> CollinearEdge? {
        guard !pairs.isEmpty else { return nil }

        var spanStart = CGFloat.greatestFiniteMagnitude
        var spanEnd = -CGFloat.greatestFiniteMagnitude
        for pair in pairs {
            spanStart = min(spanStart, pair.overlap.lowerBound)
            spanEnd = max(spanEnd, pair.overlap.upperBound)
        }
        spanStart = spanStart.rounded()
        spanEnd = spanEnd.rounded()
        guard spanEnd - spanStart >= Self.minimumSpanLength else { return nil }

        let coordinate = (pairs.map(\.coordinate).reduce(0, +) / CGFloat(pairs.count)).rounded()
        let span = spanStart...spanEnd

        let (leadingWindows, trailingWindows) = uniqueParticipatingWindows(from: pairs)
        let bounds = seamBounds(
            origin: coordinate,
            leading: leadingWindows,
            trailing: trailingWindows,
            orientation: orientation,
            containerFrame: containerFrame,
            gap: gap
        )

        return CollinearEdge(
            orientation: orientation,
            coordinate: coordinate,
            span: span,
            hitRect: hitRect(coordinate: coordinate, span: span, orientation: orientation, gap: gap),
            leadingWindowIDs: leadingWindows.map(\.id),
            trailingWindowIDs: trailingWindows.map(\.id),
            minCoordinate: bounds.lowerBound,
            maxCoordinate: bounds.upperBound
        )
    }

    private func uniqueParticipatingWindows(from pairs: [SeamPair]) -> ([ManagedWindow], [ManagedWindow]) {
        var seenLeading = Set<CGWindowID>()
        var leadingWindows: [ManagedWindow] = []
        for pair in pairs where !seenLeading.contains(pair.leading.id) {
            seenLeading.insert(pair.leading.id)
            leadingWindows.append(pair.leading)
        }
        var seenTrailing = Set<CGWindowID>()
        var trailingWindows: [ManagedWindow] = []
        for pair in pairs where !seenTrailing.contains(pair.trailing.id) {
            seenTrailing.insert(pair.trailing.id)
            trailingWindows.append(pair.trailing)
        }
        return (leadingWindows, trailingWindows)
    }

    /// Range the seam may legally occupy, given every window that touches it.
    ///
    /// Shared by detection (to publish the range on the divider) and by
    /// `computeResizedFrames` (to clamp the drag), so the advertised range can
    /// never disagree with what the drag actually allows.
    ///
    /// A leading window keeps its far edge fixed and grows toward the seam, so
    /// it demands `seam >= minX + floor + halfGap`. A trailing window mirrors that.
    private func seamBounds(
        origin: CGFloat,
        leading: [ManagedWindow],
        trailing: [ManagedWindow],
        orientation: DividerOrientation,
        containerFrame: CGRect,
        gap: CGFloat
    ) -> ClosedRange<CGFloat> {
        let halfGap = gap / 2.0

        var lower: CGFloat
        var upper: CGFloat
        switch orientation {
        case .vertical:
            lower = containerFrame.minX + halfGap
            upper = containerFrame.maxX - halfGap
        case .horizontal:
            lower = containerFrame.minY + halfGap
            upper = containerFrame.maxY - halfGap
        }

        for window in leading {
            switch orientation {
            case .vertical:
                lower = max(lower, window.frame.minX + floorWidth(of: window) + halfGap)
            case .horizontal:
                lower = max(lower, window.frame.minY + floorHeight(of: window) + halfGap)
            }
        }
        for window in trailing {
            switch orientation {
            case .vertical:
                upper = min(upper, window.frame.maxX - floorWidth(of: window) - halfGap)
            case .horizontal:
                upper = min(upper, window.frame.maxY - floorHeight(of: window) - halfGap)
            }
        }

        // Space is genuinely too tight: hold the seam where it is rather than
        // advertising an inverted range the drag could never satisfy.
        if upper < lower {
            return origin...origin
        }

        return lower...upper
    }

    // MARK: - Hit Testing

    /// Returns the divider the point falls on, preferring the closest one when
    /// hit rectangles overlap (cross junctions).
    public func hitTestDivider(
        at point: CGPoint,
        in dividers: [CollinearEdge]
    ) -> CollinearEdge? {
        var best: CollinearEdge?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for divider in dividers where divider.contains(point) {
            let probe = divider.orientation == .vertical ? point.x : point.y
            let distance = abs(divider.coordinate - probe)
            if distance < bestDistance {
                bestDistance = distance
                best = divider
            }
        }
        return best
    }

    // MARK: - Junction Detection & 2D Resizing

    /// Detect intersection junctions (T-junctions and Cross junctions) where vertical and horizontal dividers intersect.
    public func detectJunctions(
        in dividers: [CollinearEdge],
        tolerance: CGFloat = 8.0
    ) -> [CrossJunction] {
        let verticalDividers = dividers.filter { $0.orientation == .vertical }
        let horizontalDividers = dividers.filter { $0.orientation == .horizontal }
        guard !verticalDividers.isEmpty, !horizontalDividers.isEmpty else { return [] }

        var junctions: [CrossJunction] = []

        for v in verticalDividers {
            for h in horizontalDividers {
                // Check if vertical seam X falls within horizontal span X, and horizontal seam Y falls within vertical span Y
                let xInHorizontalSpan = (v.coordinate >= h.span.lowerBound - tolerance) && (v.coordinate <= h.span.upperBound + tolerance)
                let yInVerticalSpan = (h.coordinate >= v.span.lowerBound - tolerance) && (h.coordinate <= v.span.upperBound + tolerance)

                guard xInHorizontalSpan && yInVerticalSpan else { continue }

                let intersectionPoint = CGPoint(x: v.coordinate, y: h.coordinate)
                let participating = Set(v.leadingWindowIDs + v.trailingWindowIDs + h.leadingWindowIDs + h.trailingWindowIDs)

                junctions.append(
                    CrossJunction(
                        point: intersectionPoint,
                        verticalDivider: v,
                        horizontalDivider: h,
                        hitRadius: 18.0,
                        participatingWindowIDs: Array(participating)
                    )
                )
            }
        }

        return junctions
    }

    /// Hit-test a point against available junctions, selecting the closest within its hit radius.
    public func hitTestJunction(
        at point: CGPoint,
        in junctions: [CrossJunction]
    ) -> CrossJunction? {
        var best: CrossJunction?
        var minDistanceSq = CGFloat.greatestFiniteMagnitude

        for junction in junctions {
            let dx = point.x - junction.point.x
            let dy = point.y - junction.point.y
            let distSq = dx * dx + dy * dy
            if distSq <= (junction.hitRadius * junction.hitRadius) && distSq < minDistanceSq {
                minDistanceSq = distSq
                best = junction
            }
        }

        return best
    }

    /// Checks whether candidate represents the same seam as reference (orientation and adjacent windows).
    private func isSameSeam(_ candidate: CollinearEdge, as reference: CollinearEdge) -> Bool {
        candidate.orientation == reference.orientation
            && Set(candidate.leadingWindowIDs) == Set(reference.leadingWindowIDs)
            && Set(candidate.trailingWindowIDs) == Set(reference.trailingWindowIDs)
    }

    /// Computes synchronized 2D resized frames across all participating windows for a moving junction.
    public func compute2DResizedFrames(
        for junction: CrossJunction,
        targetPoint: CGPoint,
        in dividers: [CollinearEdge],
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat = 0
    ) -> [CGWindowID: CGRect] {
        let vDivider = dividers.first(where: { isSameSeam($0, as: junction.verticalDivider) }) ?? junction.verticalDivider
        let hDivider = dividers.first(where: { isSameSeam($0, as: junction.horizontalDivider) }) ?? junction.horizontalDivider

        let verticalUpdated = computeResizedFrames(
            for: vDivider,
            targetCoordinate: targetPoint.x,
            windows: windows,
            containerFrame: containerFrame,
            gap: gap
        )

        let horizontalUpdated = computeResizedFrames(
            for: hDivider,
            targetCoordinate: targetPoint.y,
            windows: windows,
            containerFrame: containerFrame,
            gap: gap
        )

        var merged: [CGWindowID: CGRect] = [:]
        let allIDs = Set(verticalUpdated.keys).union(horizontalUpdated.keys)
        let windowMap = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0) })

        for id in allIDs {
            guard let baseWindow = windowMap[id] else { continue }
            let baseFrame = baseWindow.frame

            let vFrame = verticalUpdated[id]
            let hFrame = horizontalUpdated[id]

            let finalX = vFrame?.origin.x ?? baseFrame.origin.x
            let finalWidth = vFrame?.size.width ?? baseFrame.size.width

            let finalY = hFrame?.origin.y ?? baseFrame.origin.y
            let finalHeight = hFrame?.size.height ?? baseFrame.size.height

            merged[id] = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
        }

        return merged
    }

    // MARK: - Resize Computation

    public func computeResizedFrames(
        for divider: CollinearEdge,
        targetCoordinate: CGFloat,
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat = 0
    ) -> [CGWindowID: CGRect] {
        let lookup = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0) })
        let leading = divider.leadingWindowIDs.compactMap { lookup[$0] }
        let trailing = divider.trailingWindowIDs.compactMap { lookup[$0] }
        guard !leading.isEmpty, !trailing.isEmpty else { return [:] }

        let halfGap = gap / 2.0
        let origin = divider.coordinate

        let bounds = seamBounds(
            origin: origin,
            leading: leading,
            trailing: trailing,
            orientation: divider.orientation,
            containerFrame: containerFrame,
            gap: gap
        )

        let clampedSeam = min(max(targetCoordinate, bounds.lowerBound), bounds.upperBound).rounded()

        switch divider.orientation {
        case .vertical:
            return computeVerticalFrames(
                seam: clampedSeam, halfGap: halfGap, leading: leading,
                trailing: trailing, containerFrame: containerFrame
            )
        case .horizontal:
            return computeHorizontalFrames(
                seam: clampedSeam, halfGap: halfGap, leading: leading,
                trailing: trailing, containerFrame: containerFrame
            )
        }
    }

    private func computeVerticalFrames(
        seam: CGFloat,
        halfGap: CGFloat,
        leading: [ManagedWindow],
        trailing: [ManagedWindow],
        containerFrame: CGRect
    ) -> [CGWindowID: CGRect] {
        var result: [CGWindowID: CGRect] = [:]
        let leadingEdge = seam - halfGap
        let trailingEdge = seam + halfGap
        for window in leading {
            let minX = max(containerFrame.minX, window.frame.minX)
            let width = max(floorWidth(of: window), leadingEdge - minX)
            result[window.id] = CGRect(
                x: minX.rounded(), y: window.frame.minY.rounded(),
                width: width.rounded(), height: window.frame.height.rounded()
            )
        }
        for window in trailing {
            let maxX = min(containerFrame.maxX, window.frame.maxX)
            let width = max(floorWidth(of: window), maxX - trailingEdge)
            result[window.id] = CGRect(
                x: (maxX - width).rounded(), y: window.frame.minY.rounded(),
                width: width.rounded(), height: window.frame.height.rounded()
            )
        }
        return result
    }

    private func computeHorizontalFrames(
        seam: CGFloat,
        halfGap: CGFloat,
        leading: [ManagedWindow],
        trailing: [ManagedWindow],
        containerFrame: CGRect
    ) -> [CGWindowID: CGRect] {
        var result: [CGWindowID: CGRect] = [:]
        let leadingEdge = seam - halfGap
        let trailingEdge = seam + halfGap
        for window in leading {
            let minY = max(containerFrame.minY, window.frame.minY)
            let height = max(floorHeight(of: window), leadingEdge - minY)
            result[window.id] = CGRect(
                x: window.frame.minX.rounded(), y: minY.rounded(),
                width: window.frame.width.rounded(), height: height.rounded()
            )
        }
        for window in trailing {
            let maxY = min(containerFrame.maxY, window.frame.maxY)
            let height = max(floorHeight(of: window), maxY - trailingEdge)
            result[window.id] = CGRect(
                x: window.frame.minX.rounded(), y: (maxY - height).rounded(),
                width: window.frame.width.rounded(), height: height.rounded()
            )
        }
        return result
    }

    // MARK: - Minimum Size Floors

    func floorWidth(of window: ManagedWindow) -> CGFloat {
        if let minSize = window.minSize, minSize.width > 0 {
            return max(minSize.width, 1)
        }
        return min(max(defaultMinWidth, 1), max(window.frame.width, 1))
    }

    /// Height counterpart of `floorWidth(of:)`.
    func floorHeight(of window: ManagedWindow) -> CGFloat {
        if let minSize = window.minSize, minSize.height > 0 {
            return max(minSize.height, 1)
        }
        return min(max(defaultMinHeight, 1), max(window.frame.height, 1))
    }

    private func floor(of window: ManagedWindow, orientation: DividerOrientation) -> CGFloat {
        orientation == .vertical ? floorWidth(of: window) : floorHeight(of: window)
    }

    /// Travel available from the first seam position, ignoring container bounds.
    private func room(for pairs: [SeamPair], orientation: DividerOrientation, backward: Bool) -> CGFloat {
        var room = CGFloat.greatestFiniteMagnitude
        for pair in pairs {
            let window = backward ? pair.leading : pair.trailing
            let size = orientation == .vertical ? window.frame.width : window.frame.height
            room = min(room, size - floor(of: window, orientation: orientation))
        }
        return max(0, room)
    }

    // MARK: - Geometry Helpers

    /// Extent along the axis the divider slides on.
    private func alongRange(of window: ManagedWindow, orientation: DividerOrientation) -> ClosedRange<CGFloat> {
        switch orientation {
        case .vertical:   return window.frame.minX...window.frame.maxX
        case .horizontal: return window.frame.minY...window.frame.maxY
        }
    }

    /// Extent perpendicular to the divider — the direction the seam spans.
    private func crossRange(of window: ManagedWindow, orientation: DividerOrientation) -> ClosedRange<CGFloat> {
        switch orientation {
        case .vertical:   return window.frame.minY...window.frame.maxY
        case .horizontal: return window.frame.minX...window.frame.maxX
        }
    }

    /// Screen-space rectangle that captures pointer events for this seam.
    private func hitRect(
        coordinate: CGFloat,
        span: ClosedRange<CGFloat>,
        orientation: DividerOrientation,
        gap: CGFloat
    ) -> CGRect {
        let captureWidth = max(18.0, gap + 16.0)
        switch orientation {
        case .vertical:
            return CGRect(
                x: coordinate - captureWidth / 2.0,
                y: span.lowerBound,
                width: captureWidth,
                height: max(1.0, span.upperBound - span.lowerBound)
            )
        case .horizontal:
            return CGRect(
                x: span.lowerBound,
                y: coordinate - captureWidth / 2.0,
                width: max(1.0, span.upperBound - span.lowerBound),
                height: captureWidth
            )
        }
    }
}

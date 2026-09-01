import CoreGraphics
import Foundation

/// Capture half of `WorkspaceManager` (contracts §3).
///
/// The whole point of capture is that it stores an *intent*, not a screenshot of
/// geometry (BR-WORK-001): each eligible window is reduced to a bundle id plus the
/// `LayoutZone` it currently occupies, so the workspace still means something
/// after a monitor change or a resolution change (BR-WORK-007).
extension WorkspaceManager: WorkspaceCapturing {

    /// On-screen windows the user may add (spec §2 J1.2).
    ///
    /// Applies exactly the rules `capture` enforces, so the picker can never offer
    /// a window that capture would silently drop.
    public func eligibleWindows(for tracked: Set<String> = []) async throws -> [WindowGroupSnapshot] {
        guard accessibilityService.isTrusted else {
            throw WindowCaptureError.accessibilityDenied
        }
        return Self.eligibleSnapshots(
            from: accessibilityService.allVisibleManagedWindows(),
            ownBundleIdentifier: ownBundleIdentifier,
            tracked: tracked
        )
    }

    /// Builds placements from the windows the user selected (spec §2 J1.3–J1.4).
    ///
    /// Re-reads the live window list rather than trusting the snapshots, so a
    /// window that closed between opening the picker and pressing Save is dropped
    /// instead of being saved against a stale frame.
    public func capture(from selections: [WindowGroupSnapshot]) async throws -> [WindowPlacement] {
        guard accessibilityService.isTrusted else {
            throw WindowCaptureError.accessibilityDenied
        }

        let liveWindows = accessibilityService.allVisibleManagedWindows()
        let selectedIDs = Set(selections.map(\.id))
        let matched = liveWindows.filter { window in
            WindowGroupSnapshot(window: window).map { selectedIDs.contains($0.id) } ?? false
        }

        let eligible = matched.filter {
            Self.isEligible($0, ownBundleIdentifier: ownBundleIdentifier)
        }
        guard !eligible.isEmpty else {
            throw WindowCaptureError.noEligibleWindows(
                Self.detail(for: matched, ownBundleIdentifier: ownBundleIdentifier)
            )
        }

        // One read of the display topology for the whole pass: resolving zones
        // against a snapshot avoids an async round-trip per window and guarantees
        // every window in this pass is measured against the same geometry.
        let displays = await displayManager.displays

        // One placement per app, counting how many windows of that app were
        // selected (ASM-WORK-002). The first window of an app carries the zone;
        // extras only contribute to `expectedWindowCount`.
        let grouped = Self.group(eligible, displays: displays)

        guard !grouped.placementsByBundle.isEmpty else {
            throw WindowCaptureError.noEligibleWindows(
                Self.detail(for: matched, ownBundleIdentifier: ownBundleIdentifier)
            )
        }

        // Deterministic restore order: left-to-right, then top-to-bottom, then
        // largest area first (data-model.md §3 "orderIndex"). Sorting by the
        // window's own position rather than dictionary order is what makes the
        // saved workspace read as "the layout I had", not "an arbitrary order".
        let ordered = grouped.placementsByBundle.values.sorted { lhs, rhs in
            let lhsFrame = grouped.primaryFrames[lhs.bundleIdentifier] ?? .zero
            let rhsFrame = grouped.primaryFrames[rhs.bundleIdentifier] ?? .zero
            if lhsFrame.minX != rhsFrame.minX { return lhsFrame.minX < rhsFrame.minX }
            if lhsFrame.maxY != rhsFrame.maxY { return lhsFrame.maxY > rhsFrame.maxY }
            return lhsFrame.width * lhsFrame.height > rhsFrame.width * rhsFrame.height
        }

        return ordered.enumerated().map { index, placement in
            var mutable = placement
            mutable.orderIndex = index
            return mutable
        }
    }

    /// Collapses eligible windows into one placement per app, recording the
    /// primary window's frame so callers can sort deterministically.
    private static func group(
        _ windows: [ManagedWindow],
        displays: [Display]
    ) -> (placementsByBundle: [String: WindowPlacement], primaryFrames: [String: CGRect]) {
        var placementsByBundle: [String: WindowPlacement] = [:]
        var primaryFrames: [String: CGRect] = [:]
        for window in windows {
            let bundleID = window.bundleIdentifier ?? ""
            guard let frame = Self.appKitFrame(of: window, displays: displays) else { continue }
            let visibleFrame = Self.visibleFrame(of: window, displays: displays)
            let normRect = ZoneInference.normalizedRect(of: frame, within: visibleFrame)
            let zone = ZoneInference.inferZone(forNormalized: normRect)
            if var existing = placementsByBundle[bundleID] {
                existing.expectedWindowCount += 1
                placementsByBundle[bundleID] = existing
            } else {
                placementsByBundle[bundleID] = WindowPlacement(
                    bundleIdentifier: bundleID,
                    zone: zone,
                    expectedWindowCount: 1,
                    orderIndex: 0,
                    normalizedRect: normRect
                )
                primaryFrames[bundleID] = frame
            }
        }
        return (placementsByBundle, primaryFrames)
    }

    /// Adds a window to an existing workspace, overwriting that app's previous
    /// zone (spec §4.5 "Add Window" + "Edit Layout" in one gesture).
    public func capture(window snapshot: WindowGroupSnapshot) async throws -> WindowPlacement {
        let placements = try await capture(from: [snapshot])
        guard let placement = placements.first else {
            throw WindowCaptureError.noEligibleWindows(
                Self.detail(for: [], ownBundleIdentifier: ownBundleIdentifier)
            )
        }
        return placement
    }

    // MARK: - Geometry helpers

    /// The window's frame in AppKit space (y-up, primary display at the origin).
    ///
    /// `ManagedWindow.frame` is *already* AppKit: every producer converts before
    /// storing (`AXAccessibilityService.focusedManagedWindow` and
    /// `allVisibleManagedWindows` both call `CoordinateTransformer.toAppKit`).
    /// Converting again flips it a second time — harmless on a single origin-(0,0)
    /// display, but it resolves windows to the wrong monitor when displays are
    /// stacked vertically, and it silently inverts top/bottom zone inference.
    static func appKitFrame(of window: ManagedWindow, displays: [Display]) -> CGRect? {
        guard primaryScreenHeight(from: displays) != nil else { return nil }
        return window.frame
    }

    /// The visible frame of the display a window currently occupies.
    ///
    /// Resolving per-window rather than assuming the main display is what makes a
    /// multi-monitor workspace capture correctly (spec §3 FR-6). Falls back to the
    /// primary display when no screen contains the window (e.g. a window parked in
    /// the gap between two displays).
    static func visibleFrame(of window: ManagedWindow, displays: [Display]) -> CGRect {
        let frame = window.frame
        let containing = displays.first { display in
            let overlap = display.frame.intersection(frame)
            return !overlap.isNull && overlap.width > 0 && overlap.height > 0
        }
        return (containing ?? primaryDisplay(from: displays)).visibleFrame
    }

    static func primaryDisplay(from displays: [Display]) -> Display {
        displays.first { $0.isPrimary } ?? displays[0]
    }

    static func primaryScreenHeight(from displays: [Display]) -> CGFloat? {
        guard let primary = displays.first(where: { $0.isPrimary }) ?? displays.first else {
            return nil
        }
        return primary.frame.height
    }

    // MARK: - Filtering (BR-WORK-001)

    /// Applies the eligibility rules and maps to picker rows.
    ///
    /// Excluded: FlowSnap's own panels, non-normal windows (system UI, dialogs,
    /// sheets, utilities, fullscreen tiles), and windows with no area.
    static func eligibleSnapshots(
        from windows: [ManagedWindow],
        ownBundleIdentifier: String?,
        tracked: Set<String>
    ) -> [WindowGroupSnapshot] {
        windows
            .filter { isEligible($0, ownBundleIdentifier: ownBundleIdentifier) }
            .compactMap { window in
                WindowGroupSnapshot(
                    window: window,
                    isAlreadyTracked: tracked.contains(window.bundleIdentifier ?? "")
                )
            }
    }

    static func isEligible(_ window: ManagedWindow, ownBundleIdentifier: String?) -> Bool {
        guard window.kind.isSnappable else { return false }
        guard window.frame.width > 0, window.frame.height > 0 else { return false }
        guard !window.isMinimized else { return false }
        if let ownBundleIdentifier, window.bundleIdentifier == ownBundleIdentifier {
            return false
        }
        return true
    }

    /// Builds the "explain why" breakdown behind E3.
    static func detail(
        for windows: [ManagedWindow],
        ownBundleIdentifier: String?
    ) -> WindowCaptureError.NoEligibleWindowsDetail {
        var ownPanels = 0
        var nonNormal = 0
        var zeroArea = 0
        for window in windows {
            if let ownBundleIdentifier, window.bundleIdentifier == ownBundleIdentifier {
                ownPanels += 1
            } else if !window.kind.isSnappable {
                nonNormal += 1
            } else if window.frame.width <= 0 || window.frame.height <= 0 || window.isMinimized {
                zeroArea += 1
            }
        }
        return .init(
            seen: windows.count,
            ownPanels: ownPanels,
            nonNormal: nonNormal,
            zeroArea: zeroArea
        )
    }
}

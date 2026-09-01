import CoreGraphics
import Foundation

/// Restore half of `WorkspaceManager` (contracts §4).
///
/// The pass is **best-effort by design** (BR-WORK-004): a placement that cannot be
/// satisfied is recorded in the summary and the loop continues. A workspace whose
/// one missing app aborted everything would be worse than useless — the user would
/// see nothing happen at all.
///
/// Geometry is recomputed from the *current* display topology on every pass
/// (BR-WORK-007), never from stored pixels, which is what makes restoration correct
/// after a monitor change (RISK-WORK-001).
extension WorkspaceManager: WorkspaceRestoring {

    /// Cascade step for extra windows of the same app (spec §2 J2.4).
    ///
    /// 24pt is small enough that a stack of windows still reads as one group and
    /// large enough that each title bar stays clickable.
    static let cascadeOffset: CGFloat = 24

    public func restore(
        workspace: Workspace,
        options: RestoreOptions = .default
    ) async throws -> RestoreSummary {
        // E11 — nothing can be moved without the Accessibility permission, so
        // abort before touching any window.
        guard accessibilityService.isTrusted else {
            throw RestoreError.accessibilityDenied
        }

        let placements = workspace.orderedPlacements

        // E8 — an empty workspace is a no-op, not an error: the menu item is
        // disabled in the UI, so this only guards programmatic callers.
        guard !placements.isEmpty else {
            return RestoreSummary(placedCount: 0, totalPlacements: 0, skipped: [])
        }

        // One snapshot of the display topology for the whole pass, so every
        // placement is measured against the same geometry even if a monitor is
        // unplugged mid-restore.
        let displays = await displayManager.displays

        var placed = 0
        var skipped: [SkippedApp] = []

        for placement in placements {
            switch await restore(placement, displays: displays, options: options) {
            case .placed:
                placed += 1
            case .skipped(let reason):
                skipped.append(SkippedApp(bundleIdentifier: placement.bundleIdentifier, reason: reason))
            }
        }

        // J2.6 — record the restore timestamp. The moves already happened, so a
        // store failure here is deliberately not surfaced as a restore failure
        // (E14); it is logged and the next `reload()` reconciles.
        do {
            var stamped = workspace
            stamped.lastRestoredAt = Date()
            try await store.upsert(stamped)
        } catch {
            NSLog("[WorkspaceManager] Could not record lastRestoredAt: \(error.localizedDescription)")
        }
        await reload()

        return RestoreSummary(placedCount: placed, totalPlacements: placements.count, skipped: skipped)
    }

    /// Restores one placement.
    ///
    /// Kept `private` and returning a tiny enum rather than throwing: the caller
    /// needs to keep going after any single failure, so an error type would invite
    /// the wrong control flow here.
    private func restore(
        _ placement: WindowPlacement,
        displays: [Display],
        options: RestoreOptions
    ) async -> PlacementResult {
        var windows = matchingWindows(for: placement)

        // J2.2 — the app is not running. Launch it, unless the user asked for a
        // pure reposition pass.
        if windows.isEmpty, options.launchOfflineApps {
            guard await launcher.openApp(withBundleIdentifier: placement.bundleIdentifier) else {
                // E4 — not installed, or the launch was refused.
                return .skipped(.notInstalled)
            }
            let pid = launcher.runningProcessIdentifier(bundleID: placement.bundleIdentifier)
            guard let pid, await launcher.waitForFirstWindow(pid: pid, timeout: launchTimeout) else {
                // E5 — launched but never drew a window within the budget.
                return .skipped(.launchTimeout)
            }
            windows = matchingWindows(for: placement)
        }

        guard !windows.isEmpty else {
            // E5/E10 — running (or the user opted out of launching) but no window
            // to move. Fewer windows than at save time is not an error for the
            // other placements.
            return .skipped(.noWindow)
        }

        // `frame(for:)` and `cascadeFrame` both work in AppKit space (y-up), which
        // is where the "down-and-right" cascade reads correctly. `WindowManaging.move`
        // however expects AX space (y-down from the primary display's top) — every
        // other move call site converts first (CommandDispatcher,
        // AdaptiveDividerCoordinator). Converting here keeps restore consistent with
        // them; skipping it lands every window vertically mirrored.
        let moved = await place(windows, placement: placement, displays: displays, options: options)

        // Reveal last, once the windows already sit where they belong: un-hiding
        // first would flash the app at its old position. A hidden app (Cmd+H) or one
        // whose windows live on another Space otherwise stays invisible even though
        // every move succeeded — the "it restored but I can't see it" half of the
        // reported defect. Best-effort: a refused activation must not downgrade a
        // placed window to a skipped one.
        if moved {
            launcher.reveal(bundleID: placement.bundleIdentifier)
        }

        return moved ? .placed : .skipped(.noWindow)
    }

    /// Moves a placement's windows into their zone: the primary window takes the
    /// zone, extras cascade inside it (J2.3/J2.4).
    ///
    /// Returns whether the *primary* window moved. E6 makes a refused move
    /// non-fatal — the window keeps its position and the pass continues — so this
    /// reports the outcome rather than throwing, and the caller turns `false` into
    /// a skip.
    private func place(
        _ windows: [ResolvedWindow],
        placement: WindowPlacement,
        displays: [Display],
        options: RestoreOptions
    ) async -> Bool {
        let primaryHeight = WorkspaceManager.primaryScreenHeight(from: displays) ?? 0
        let zoneFrame = frame(for: placement, windows: windows.map(\.window), displays: displays)
        let extras = options.cascadeExtraWindows ? Array(windows.dropFirst()) : []

        guard await move(windows[0], to: zoneFrame, primaryHeight: primaryHeight, placement: placement) else {
            return false
        }
        for (index, extra) in extras.enumerated() {
            let cascaded = Self.cascadeFrame(base: zoneFrame, step: index + 1)
            _ = await move(extra, to: cascaded, primaryHeight: primaryHeight, placement: placement)
        }
        return true
    }

    /// One `WindowManaging.move`, converting AppKit → AX and swallowing E6 failures.
    ///
    /// Carries the AX element the snapshot was read from so the write lands on that
    /// exact window. Without it, `WindowManager` re-resolves by frame and can move a
    /// different window than the one that was measured.
    private func move(
        _ resolved: ResolvedWindow,
        to appKitFrame: CGRect,
        primaryHeight: CGFloat,
        placement: WindowPlacement
    ) async -> Bool {
        do {
            try await windowManager.move(
                resolved.window,
                to: CoordinateTransformer.toAX(rect: appKitFrame, primaryScreenHeight: primaryHeight),
                element: resolved.element
            )
            return true
        } catch {
            NSLog("[WorkspaceManager] Move failed for \(placement.bundleIdentifier): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Window matching

    /// Live windows belonging to a placement's app, primary first, each paired with
    /// the element it was read from.
    ///
    /// Ordered by area descending so the largest window gets the zone and small
    /// utility-ish windows cascade behind it — the arrangement the user almost
    /// certainly means (spec §2 J2.4 "primary window").
    ///
    /// The app's Accessibility window list is the primary source because it still
    /// contains windows that are minimized or parked on another Space. The
    /// WindowServer on-screen list (`allVisibleManagedWindows`) is only a fallback:
    /// it drops exactly those windows, which caused the "some apps restore, some
    /// don't" defect — a minimized app was reported `noWindow` and skipped even
    /// though it was running.
    ///
    /// The AX path is preferred for a second reason: it hands back the element the
    /// frame came from. The WindowServer fallback cannot, so its windows carry a
    /// `nil` element and `WindowManager` has to match one by frame — the guess that
    /// let a restore write a real frame onto an invisible helper window (a Chromium
    /// tab-search panel, an extension view, a PiP surface) and still report success.
    private func matchingWindows(for placement: WindowPlacement) -> [ResolvedWindow] {
        var candidates: [ResolvedWindow] = []
        if let pid = launcher.runningProcessIdentifier(bundleID: placement.bundleIdentifier) {
            candidates = accessibilityService.resolvedWindows(of: pid)
        }
        // Nothing addressable through AX (pid unknown, or the app exposes no AX
        // windows at all): fall back to what is currently on screen.
        if candidates.isEmpty {
            candidates = accessibilityService.allVisibleManagedWindows()
                .filter { $0.bundleIdentifier == placement.bundleIdentifier }
                .map { ResolvedWindow(window: $0, element: nil) }
        }
        return candidates
            .filter { window in
                window.window.kind.isRestorable
                    && window.window.frame.width > 0
                    && window.window.frame.height > 0
            }
            .sorted {
                ($0.window.frame.width * $0.window.frame.height)
                    > ($1.window.frame.width * $1.window.frame.height)
            }
    }

    /// Converts normalized proportional bounds (0...1 top-left) to concrete AppKit frame with window gap.
    static func frameFromNormalizedRect(
        _ normRect: CGRect,
        in visibleFrame: CGRect,
        gap: CGFloat
    ) -> CGRect {
        let totalWidth = max(0, visibleFrame.width)
        let totalHeight = max(0, visibleFrame.height)
        guard totalWidth > 0, totalHeight > 0 else { return .zero }

        let rawX = visibleFrame.minX + (normRect.minX * totalWidth)
        let rawWidth = normRect.width * totalWidth
        let rawHeight = normRect.height * totalHeight
        let rawY = visibleFrame.maxY - (normRect.maxY * totalHeight)

        let safeGap = max(0, gap)
        let insetX = normRect.minX > 0.01 ? safeGap / 2.0 : 0
        let insetTrailing = normRect.maxX < 0.99 ? safeGap / 2.0 : 0
        let insetY = normRect.minY > 0.01 ? safeGap / 2.0 : 0
        let insetBottom = normRect.maxY < 0.99 ? safeGap / 2.0 : 0

        let adjustedX = rawX + insetX
        let adjustedWidth = max(50, rawWidth - insetX - insetTrailing)
        let adjustedY = rawY + insetBottom
        let adjustedHeight = max(50, rawHeight - insetY - insetBottom)

        return CGRect(
            x: floor(adjustedX),
            y: floor(adjustedY),
            width: floor(adjustedWidth),
            height: floor(adjustedHeight)
        )
    }

    /// Resolves a placement's zone to a concrete frame on the display its window
    /// currently occupies (BR-WORK-007).
    private func frame(
        for placement: WindowPlacement,
        windows: [ManagedWindow],
        displays: [Display]
    ) -> CGRect {
        guard let window = windows.first,
              WorkspaceManager.primaryScreenHeight(from: displays) != nil else {
            return .zero
        }
        let visibleFrame = WorkspaceManager.visibleFrame(of: window, displays: displays)
        if let normRect = placement.normalizedRect {
            return Self.frameFromNormalizedRect(normRect, in: visibleFrame, gap: preferences.windowGap)
        }
        return layoutEngine.frame(for: placement.zone, in: visibleFrame, gap: preferences.windowGap)
    }

    /// The frame for a zone on the display a given window rectangle occupies.
    ///
    /// Exposed for the UI's zone preview (contracts §4).
    public func frame(for zone: LayoutZone, windowFrame: CGRect) async -> CGRect {
        let displays = await displayManager.displays
        guard WorkspaceManager.primaryScreenHeight(from: displays) != nil else { return .zero }
        let proxy = ManagedWindow(
            id: 0,
            pid: 0,
            bundleIdentifier: nil,
            title: "",
            frame: windowFrame
        )
        let visibleFrame = WorkspaceManager.visibleFrame(of: proxy, displays: displays)
        return layoutEngine.frame(for: zone, in: visibleFrame, gap: preferences.windowGap)
    }

    /// Offsets an extra window inside its zone, clamped so it never leaves it
    /// (spec §5 E9).
    ///
    /// Clamping matters more than it looks: without it, a 2-window cascade in a
    /// narrow `.rightOneThird` zone pushes the second window off-screen, which is
    /// indistinguishable from "restore lost my window".
    ///
    /// The offset is applied by *shrinking* rather than by translating and then
    /// clipping. Translating first and clamping the size afterwards leaves the
    /// origin outside the zone (the bug this formulation caused: `minY` ran past
    /// the zone's bottom edge while only `height` was corrected), and on a window
    /// that already fills its zone the two corrections cancel out, so every extra
    /// window landed exactly on top of the primary one.
    ///
    /// Works in AppKit space (y-up): the left edge moves right and the top edge
    /// drops, which is what leaves each cascaded title bar visible and clickable
    /// below the previous window.
    static func cascadeFrame(base: CGRect, step: Int) -> CGRect {
        guard step > 0, base.width > 0, base.height > 0 else { return base }
        let offset = cascadeOffset * CGFloat(step)

        // Never shrink a cascaded window below a usable size; a 24pt step on a
        // narrow zone would otherwise produce a sliver that is technically inside
        // the zone but is not something the user can interact with.
        let offsetX = min(offset, max(0, base.width - minCascadeWidth))
        let offsetY = min(offset, max(0, base.height - minCascadeHeight))

        return CGRect(
            x: base.minX + offsetX,
            y: base.minY,
            width: base.width - offsetX,
            height: base.height - offsetY
        )
    }

    /// Smallest width/height a cascaded window may be shrunk to (spec §5 E9).
    static let minCascadeWidth: CGFloat = 200
    static let minCascadeHeight: CGFloat = 140

    private enum PlacementResult {
        case placed
        case skipped(SkipReason)
    }
}

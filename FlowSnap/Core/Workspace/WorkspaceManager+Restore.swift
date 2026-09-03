import ApplicationServices
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

    // MARK: - Presentation observation (P0.5)

    /// Production checker used by every manager without an override.
    private static let defaultPresentationChecker: any CurrentScreenVisibilityChecking =
        CGWindowListCurrentScreenVisibilityChecker()

    /// Per-instance presentation checker overrides, keyed by manager identity.
    ///
    /// P0.5 test seam: the spec's §12/§13 file lists forbid touching
    /// `WorkspaceManager.swift` (where `init` lives), so constructor injection
    /// is unavailable. A test instead installs a checker on *its own* manager
    /// instance via `injectPresentationChecker(_:)` and removes it when done;
    /// every instance without an override observes through the production
    /// `CGWindowListCurrentScreenVisibilityChecker`. The registry inherits the
    /// manager's MainActor isolation and is keyed per instance, so parallel
    /// tests never observe each other's scripting.
    private static var presentationCheckerOverrides: [ObjectIdentifier: any CurrentScreenVisibilityChecking] = [:]

    /// The checker this instance observes with: an installed override, else the
    /// production `CGWindowList` implementation.
    var presentationChecker: any CurrentScreenVisibilityChecking {
        if let override = Self.presentationCheckerOverrides[ObjectIdentifier(self)] {
            return override
        }
        return Self.defaultPresentationChecker
    }

    /// Installs (or, with `nil`, removes) the presentation checker used by this
    /// manager instance only. Test-only: production code must keep the default.
    func injectPresentationChecker(_ checker: (any CurrentScreenVisibilityChecking)?) {
        if let checker {
            Self.presentationCheckerOverrides[ObjectIdentifier(self)] = checker
        } else {
            Self.presentationCheckerOverrides.removeValue(forKey: ObjectIdentifier(self))
        }
    }

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

        var outcomes: [PlacementExecution] = []
        outcomes.reserveCapacity(placements.count)
        // Keep the pass serial: orderIndex is observable, and concurrent AX
        // writes can invalidate the resolve/read-back pairing.
        for placement in placements {
            outcomes.append(await restore(placement, displays: displays, options: options))
        }

        // Placement proof is geometry/state only. Reveal and focus are a single,
        // best-effort final action for the lowest-order verified placement.
        if let focusTarget = outcomes
            .filter({ $0.result.isVerified })
            .sorted(by: { $0.result.orderIndex < $1.result.orderIndex })
            .first?.resolved {
            _ = launcher.reveal(bundleID: focusTarget.window.bundleIdentifier ?? "")
            do {
                try await windowManager.focus(focusTarget.window, element: focusTarget.element)
            } catch {
                Self.logRestore(
                    phase: "final-focus",
                    bundleID: focusTarget.window.bundleIdentifier ?? "",
                    reason: "focusFailed",
                    attempt: nil,
                    error: error
                )
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
            Self.logRestore(
                phase: "persist",
                bundleID: "-",
                reason: "storeFailure",
                attempt: nil,
                error: error
            )
        }
        await reload()

        return Self.summary(from: outcomes, totalPlacements: placements.count)
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
    ) async -> PlacementExecution {
        var windows = matchingWindows(for: placement)

        // J2.2 — the app is not running. Launch it, unless the user asked for a
        // pure reposition pass.
        if windows.isEmpty, options.launchOfflineApps {
            guard await launcher.openApp(withBundleIdentifier: placement.bundleIdentifier) else {
                // E4 — not installed, or the launch was refused.
                return .skipped(placement, reason: .notInstalled)
            }
            let pid = launcher.runningProcessIdentifier(bundleID: placement.bundleIdentifier)
            guard let pid, await launcher.waitForFirstWindow(pid: pid, timeout: launchTimeout) else {
                // E5 — launched but never drew a window within the budget.
                return .skipped(placement, reason: .launchTimeout)
            }
            windows = matchingWindows(for: placement)
        }

        guard !windows.isEmpty else {
            // E5/E10 — running (or the user opted out of launching) but no window
            // to move. Fewer windows than at save time is not an error for the
            // other placements.
            return .skipped(placement, reason: .noWindow)
        }

        // `frame(for:)` and `cascadeFrame` both work in AppKit space (y-up), which
        // is where the "down-and-right" cascade reads correctly. `WindowManaging.move`
        // however expects AX space (y-down from the primary display's top) — every
        // other move call site converts first (CommandDispatcher,
        // AdaptiveDividerCoordinator). Converting here keeps restore consistent with
        // them; skipping it lands every window vertically mirrored.
        return await place(windows, placement: placement, displays: displays, options: options)
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
    ) async -> PlacementExecution {
        let primaryHeight = WorkspaceManager.primaryScreenHeight(from: displays) ?? 0
        let zoneFrame = frame(for: placement, windows: windows.map(\.window), displays: displays)
        let extras = options.cascadeExtraWindows ? Array(windows.dropFirst()) : []

        guard let element = windows[0].element else {
            Self.logRestore(phase: "prepare", bundleID: placement.bundleIdentifier,
                            reason: SkipReason.unverifiablePlacement.rawValue,
                            attempt: nil, error: nil)
            return .unverifiable(placement)
        }

        let exitedFullScreen: Bool
        switch await prepare(element: element, placement: placement) {
        case .ready(let exited): exitedFullScreen = exited
        case .failed(let reason): return .failure(placement, reason: reason)
        }

        // P0.5 §4.5 — a successful full-screen exit can make Chromium/Electron
        // apps destroy and recreate their window, invalidating the captured
        // CGWindowID. Re-resolve identity through the presentation checker
        // (never through the private AX-side resolver) before trusting the old
        // id. Without a provable identity there is no honest observation to
        // make: the placement is reported unverifiable and nothing is moved.
        var observedWindowID = windows[0].window.id
        if exitedFullScreen {
            guard let postExitFrame = accessibilityService.frame(of: element),
                  let reResolvedID = presentationChecker.reResolveWindowID(
                      pid: windows[0].window.pid, frame: postExitFrame
                  ) else {
                Self.logRestore(phase: "presentation", bundleID: placement.bundleIdentifier,
                                reason: SkipReason.presentationUnverifiable.rawValue,
                                attempt: nil, error: nil)
                return .presentationUnverifiable(placement)
            }
            observedWindowID = reResolvedID
        }

        let targetAXFrame = CoordinateTransformer.toAX(
            rect: zoneFrame, primaryScreenHeight: primaryHeight
        )
        let primaryOutcome = await move(
            windows[0], to: targetAXFrame, targetFrame: targetAXFrame, placement: placement
        )
        guard case .moved = primaryOutcome else {
            return PlacementExecution(
                result: Self.result(for: placement, moveOutcome: primaryOutcome, presentation: .notObserved),
                resolved: nil
            )
        }

        for (index, extra) in extras.enumerated() {
            let cascaded = Self.cascadeFrame(base: zoneFrame, step: index + 1)
            guard let extraElement = extra.element else { continue }
            guard case .ready = await prepare(element: extraElement, placement: placement) else {
                // A primary placement remains valid even when an additional
                // window cannot leave minimized/full-screen state. Do not issue
                // a frame write for that extra window.
                continue
            }
            let extraAXFrame = CoordinateTransformer.toAX(
                rect: cascaded, primaryScreenHeight: primaryHeight
            )
            // `move` always performs the same post-condition proof for extras.
            // The placement result is keyed to the primary window; an extra
            // window failure is logged and does not erase a verified primary.
            _ = await move(extra, to: extraAXFrame, targetFrame: extraAXFrame, placement: placement)
        }
        // P0.5 — presentation is observed exactly once, for the primary window
        // only, after the move was verified. It is never retried and never
        // activates or raises anything: a window that is not presented is
        // reported honestly, not chased (spec §4.2/§4.4).
        let presentation = observePresentation(for: observedWindowID, checker: presentationChecker)
        return PlacementExecution(
            result: Self.result(
                for: placement, moveOutcome: primaryOutcome, presentation: .observed(presentation)
            ),
            resolved: windows[0]
        )
    }

    /// One `WindowManaging.move`, converting AppKit → AX and swallowing E6 failures.
    ///
    /// Carries the AX element the snapshot was read from so the write lands on that
    /// exact window. Without it, `WindowManager` re-resolves by frame and can move a
    /// different window than the one that was measured.
    private func move(
        _ resolved: ResolvedWindow,
        to targetAXFrame: CGRect,
        targetFrame: CGRect,
        placement: WindowPlacement
    ) async -> MoveOutcome {
        guard let element = resolved.element else { return .unverifiable }
        var lastError: Error?
        for attempt in 1...RestoreVerificationPolicy.maxAttempts {
            do {
                try await windowManager.move(resolved.window, to: targetAXFrame, element: element)
            } catch {
                lastError = error
                Self.logRestore(phase: "place", bundleID: placement.bundleIdentifier,
                                reason: SkipReason.moveFailed.rawValue,
                                attempt: attempt, error: error)
                if !Self.isRecoverable(error) { return .failed(error) }
                if attempt == RestoreVerificationPolicy.maxAttempts { break }
                if let delay = RestoreVerificationPolicy.retryDelay(afterAttempt: attempt) {
                    try? await Task.sleep(for: delay)
                }
                continue
            }

            lastError = nil
            let evidence = verify(element: element, targetFrame: targetFrame)
            if let evidence, evidence.isPlacementVerified {
                return .moved
            }
            Self.logRestore(
                phase: "verify",
                bundleID: placement.bundleIdentifier,
                reason: Self.verificationReason(evidence),
                attempt: attempt,
                error: nil
            )
            if attempt < RestoreVerificationPolicy.maxAttempts,
               let delay = RestoreVerificationPolicy.retryDelay(afterAttempt: attempt) {
                try? await Task.sleep(for: delay)
            }
        }
        if let lastError { return .failed(lastError) }
        return .unverifiable
    }

    private static func verificationReason(_ evidence: WindowVerificationResult?) -> String {
        guard let evidence else { return "unverifiablePlacement" }
        if evidence.isMinimized { return "minimized" }
        if evidence.isFullscreen { return "fullscreen" }
        return "frameMismatch"
    }

    /// Prepares exactly the resolved AX element. Fullscreen is a hard gate:
    /// callers never receive a `ready` result while the old fullscreen state is
    /// still observable, so no frame write is attempted during its transition.
    private func prepare(
        element: AXUIElement,
        placement: WindowPlacement
    ) async -> PreparationResult {
        if accessibilityService.isMinimized(element) {
            do {
                try accessibilityService.unminimize(element)
            } catch {
                Self.logRestore(phase: "prepare", bundleID: placement.bundleIdentifier,
                                reason: SkipReason.moveFailed.rawValue,
                                attempt: nil, error: error)
                return .failed(.moveFailed)
            }
        }

        let fullscreen = await waitForFullscreenExit(element, bundleID: placement.bundleIdentifier)
        guard fullscreen.completed else {
            return .failed(.fullscreenTransitionTimeout)
        }
        return .ready(exitedFullScreen: fullscreen.performedExit)
    }

    /// Waits out a full-screen exit and reports both whether the window is back
    /// in a regular state (`completed`) and whether this call performed the
    /// exit itself (`performedExit`) — P0.5 §4.5 keys the CGWindowID re-resolve
    /// off the second flag, because only a window that was actually torn down
    /// during the transition can come back with a different identity.
    private func waitForFullscreenExit(
        _ element: AXUIElement,
        bundleID: String
    ) async -> (completed: Bool, performedExit: Bool) {
        guard accessibilityService.isFullScreen(element) else { return (true, false) }
        do {
            try accessibilityService.exitFullScreen(element)
        } catch {
            Self.logRestore(phase: "prepare", bundleID: bundleID,
                            reason: SkipReason.fullscreenTransitionTimeout.rawValue,
                            attempt: nil, error: error)
            return (false, true)
        }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: RestoreVerificationPolicy.fullscreenTimeout)
        while clock.now < deadline {
            if !accessibilityService.isFullScreen(element) { return (true, true) }
            do {
                try await Task.sleep(for: RestoreVerificationPolicy.fullscreenPollInterval)
            } catch {
                return (false, true)
            }
        }
        let exited = !accessibilityService.isFullScreen(element)
        if !exited {
            Self.logRestore(phase: "prepare", bundleID: bundleID,
                            reason: SkipReason.fullscreenTransitionTimeout.rawValue,
                            attempt: nil, error: nil)
        }
        return (exited, true)
    }

    private func verify(element: AXUIElement, targetFrame: CGRect) -> WindowVerificationResult? {
        let actualFrame = accessibilityService.frame(of: element)
        return WindowVerificationResult(
            targetFrame: targetFrame,
            actualFrame: actualFrame,
            isMinimized: accessibilityService.isMinimized(element),
            isFullscreen: accessibilityService.isFullScreen(element)
        )
    }

    /// Whether the presentation axis was actually observed for a placement.
    /// `notObserved` covers the outcomes that end before the observation runs
    /// (failed move, unverifiable placement) — P0.5 spec §2.3 "n/a".
    private enum PresentationObservation {
        case observed(PresentationOutcome)
        case notObserved
    }

    /// Maps the two independent outcome axes onto the summary result
    /// (P0.5 spec §2.3). A moved window only counts `placed` when the
    /// observation found it on the current screen; a window that is certainly
    /// not presented is `movedButNotPresented`; an unobservable presentation is
    /// honestly `unverifiable` rather than a false green or a false orange.
    private static func result(
        for placement: WindowPlacement,
        moveOutcome: MoveOutcome,
        presentation: PresentationObservation
    ) -> RestorePlacementResult {
        switch (moveOutcome, presentation) {
        case (.failed, _):
            return RestorePlacementResult(
                bundleIdentifier: placement.bundleIdentifier,
                orderIndex: placement.orderIndex,
                category: .failed,
                reason: .moveFailed
            )
        case (.unverifiable, _):
            return RestorePlacementResult(
                bundleIdentifier: placement.bundleIdentifier,
                orderIndex: placement.orderIndex,
                category: .unverifiable,
                reason: .unverifiablePlacement
            )
        case (.moved, .observed(.presented)):
            return RestorePlacementResult(
                bundleIdentifier: placement.bundleIdentifier,
                orderIndex: placement.orderIndex,
                category: .placed
            )
        case (.moved, .observed(.notPresented)):
            return RestorePlacementResult(
                bundleIdentifier: placement.bundleIdentifier,
                orderIndex: placement.orderIndex,
                category: .movedButNotPresented,
                reason: .notPresentedOnCurrentScreen
            )
        case (.moved, .observed(.unverifiable)), (.moved, .notObserved):
            // Unreachable in practice (a moved primary is always observed), but
            // an unknown presentation must never be claimed as `placed`.
            return RestorePlacementResult(
                bundleIdentifier: placement.bundleIdentifier,
                orderIndex: placement.orderIndex,
                category: .unverifiable,
                reason: .presentationUnverifiable
            )
        }
    }

    /// Runs the one-shot on-screen observation for a moved window, mapping the
    /// infrastructure result onto the domain outcome. No retry, no activation:
    /// observation is side-effect-free by contract (P0.5 spec §4.2).
    private func observePresentation(
        for windowID: CGWindowID,
        checker: CurrentScreenVisibilityChecking
    ) -> PresentationOutcome {
        switch checker.isOnCurrentScreen(windowID: windowID) {
        case .presented: return .presented
        case .notPresented: return .notPresented
        case .unverifiable: return .unverifiable
        }
    }

    private static func summary(
        from executions: [PlacementExecution],
        totalPlacements: Int
    ) -> RestoreSummary {
        let results = executions.map(\.result)
        let failed = results.compactMap { result -> RestoreIssue? in
            guard result.category == .failed, let reason = result.reason else { return nil }
            return RestoreIssue(bundleIdentifier: result.bundleIdentifier,
                                orderIndex: result.orderIndex, reason: reason)
        }
        let unverifiable = results.compactMap { result -> RestoreIssue? in
            guard result.category == .unverifiable, let reason = result.reason else { return nil }
            return RestoreIssue(bundleIdentifier: result.bundleIdentifier,
                                orderIndex: result.orderIndex, reason: reason)
        }
        let skipped = results.compactMap { result -> RestoreIssue? in
            guard result.category == .skipped, let reason = result.reason else { return nil }
            return RestoreIssue(bundleIdentifier: result.bundleIdentifier,
                                orderIndex: result.orderIndex, reason: reason)
        }
        let movedButNotPresented = results.compactMap { result -> RestoreIssue? in
            guard result.category == .movedButNotPresented, let reason = result.reason else { return nil }
            return RestoreIssue(bundleIdentifier: result.bundleIdentifier,
                                orderIndex: result.orderIndex, reason: reason)
        }
        return RestoreSummary(
            placedCount: results.filter { $0.category == .placed }.count,
            failedCount: failed.count,
            unverifiableCount: unverifiable.count,
            skippedCount: skipped.count,
            movedButNotPresentedCount: movedButNotPresented.count,
            totalPlacements: totalPlacements,
            failed: failed,
            unverifiable: unverifiable,
            skipped: skipped,
            movedButNotPresented: movedButNotPresented
        )
    }

    private static func isRecoverable(_ error: Error) -> Bool {
        guard let error = error as? AccessibilityError else { return true }
        switch error {
        case .windowNotFound, .applicationNotFound, .attributeUnsupported, .invalidGeometry, .notTrusted:
            return false
        default:
            return true
        }
    }

    private static func logRestore(
        phase: String,
        bundleID: String,
        reason: String,
        attempt: Int?,
        error: Error?
    ) {
        let attemptText = attempt.map(String.init) ?? "-"
        let errorText = error.map { " error=\($0.localizedDescription)" } ?? ""
        NSLog("[WorkspaceManager] restore phase=\(phase) bundle=\(bundleID) attempt=\(attemptText) reason=\(reason)\(errorText)")
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

    private struct PlacementExecution {
        let result: RestorePlacementResult
        let resolved: ResolvedWindow?

        static func skipped(_ placement: WindowPlacement, reason: SkipReason) -> Self {
            Self(
                result: RestorePlacementResult(
                    bundleIdentifier: placement.bundleIdentifier,
                    orderIndex: placement.orderIndex,
                    category: .skipped,
                    reason: reason
                ),
                resolved: nil
            )
        }

        static func failure(_ placement: WindowPlacement, reason: SkipReason) -> Self {
            let category: RestorePlacementResult.Category = reason == .unverifiablePlacement
                ? .unverifiable : .failed
            return Self(
                result: RestorePlacementResult(
                    bundleIdentifier: placement.bundleIdentifier,
                    orderIndex: placement.orderIndex,
                    category: category,
                    reason: reason
                ),
                resolved: nil
            )
        }

        static func unverifiable(_ placement: WindowPlacement) -> Self {
            failure(placement, reason: .unverifiablePlacement)
        }

        /// P0.5 §4.5 — the presentation identity could not be established after
        /// a full-screen exit, so nothing was moved and nothing was observed.
        /// The presentation is unverifiable — never "not presented", since
        /// absence was not actually observed.
        static func presentationUnverifiable(_ placement: WindowPlacement) -> Self {
            Self(
                result: RestorePlacementResult(
                    bundleIdentifier: placement.bundleIdentifier,
                    orderIndex: placement.orderIndex,
                    category: .unverifiable,
                    reason: .presentationUnverifiable
                ),
                resolved: nil
            )
        }
    }

    /// Whether the primary element is ready for a frame write, and — P0.5 §4.5 —
    /// whether getting there performed a full-screen exit, the one transition
    /// that can invalidate the window's CGWindowID.
    private enum PreparationResult {
        case ready(exitedFullScreen: Bool)
        case failed(SkipReason)
    }
}

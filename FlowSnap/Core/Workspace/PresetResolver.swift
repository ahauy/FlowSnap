import CoreGraphics
import Foundation
import OSLog

private let presetLogger = Logger(subsystem: "com.flowsnap", category: "PresetResolver")

/// Error conditions arising during preset resolution and execution (spec §4).
public enum PresetError: Error, Equatable, Sendable {
    case presetNotFound(String)
    case accessibilityDenied
    case noEligibleWindows
    case executionFailed(String)
}

/// Protocol for resolving and applying workspace presets to live applications (contracts §1).
public protocol PresetResolving: Sendable {
    /// Restores a workflow preset onto the target display.
    @MainActor
    func restore(preset: WorkspacePreset, on targetDisplay: Display?) async throws -> RestoreSummary
}

/// Engine that resolves application candidates, calculates frames, and places windows for presets (spec §1).
@MainActor
public final class PresetResolver: PresetResolving {
    private let accessibilityService: any AccessibilityService
    private let windowManager: any WindowManaging
    private let displayManager: any DisplayManaging
    private let layoutEngine: any LayoutCalculating
    private let launcher: any ApplicationLaunching
    private let preferencesStore: PreferencesStore
    private let windowGroupManager: (any WindowGroupManaging)?
    private let launchTimeout: TimeInterval

    public init(
        accessibilityService: any AccessibilityService,
        windowManager: any WindowManaging,
        displayManager: any DisplayManaging,
        layoutEngine: any LayoutCalculating,
        launcher: any ApplicationLaunching,
        preferencesStore: PreferencesStore,
        windowGroupManager: (any WindowGroupManaging)? = nil,
        launchTimeout: TimeInterval = 10.0
    ) {
        self.accessibilityService = accessibilityService
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.layoutEngine = layoutEngine
        self.launcher = launcher
        self.preferencesStore = preferencesStore
        self.windowGroupManager = windowGroupManager
        self.launchTimeout = launchTimeout
    }

    public func restore(preset: WorkspacePreset, on targetDisplay: Display? = nil) async throws -> RestoreSummary {
        guard accessibilityService.isTrusted else {
            throw PresetError.accessibilityDenied
        }

        guard !preset.slots.isEmpty else {
            return RestoreSummary(placedCount: 0, totalPlacements: 0, skipped: [])
        }

        let target = await resolveTargetDisplay(targetDisplay)
        let visibleFrame = target.visibleFrame
        let primaryHeight = await displayManager.primaryScreenHeight

        var placedWindowIDs: Set<CGWindowID> = []
        var skipped: [SkippedApp] = []
        var usedWindowIDs: Set<CGWindowID> = []

        for slot in preset.slots {
            let outcome = await resolveSlot(
                slot,
                visibleFrame: visibleFrame,
                primaryHeight: primaryHeight,
                usedWindowIDs: &usedWindowIDs
            )
            switch outcome {
            case .placed(let windowID):
                placedWindowIDs.insert(windowID)
            case .skipped(let bundleID, let reason):
                skipped.append(SkippedApp(bundleIdentifier: bundleID, reason: reason))
            }
        }

        linkWindowGroupIfNeeded(preset: preset, placedWindowIDs: placedWindowIDs)

        return RestoreSummary(
            placedCount: placedWindowIDs.count,
            totalPlacements: preset.slots.count,
            skipped: skipped
        )
    }

    // MARK: - Display Resolution

    private func resolveTargetDisplay(_ targetDisplay: Display?) async -> Display {
        if let targetDisplay {
            return targetDisplay
        }
        if let focused = await windowManager.focusedWindow(),
           let display = await displayManager.display(for: focused.frame, cursorPoint: nil) {
            return display
        }
        if let first = await displayManager.displays.first {
            return first
        }
        return Display(
            id: 0,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
    }

    // MARK: - Slot Resolution Chain

    private enum SlotOutcome {
        case placed(CGWindowID)
        case skipped(bundleID: String, reason: SkipReason)
    }

    private struct ResolvedCandidate {
        let bundleID: String
        let resolved: ResolvedWindow
    }

    private func resolveSlot(
        _ slot: PresetAppSlot,
        visibleFrame: CGRect,
        primaryHeight: CGFloat,
        usedWindowIDs: inout Set<CGWindowID>
    ) async -> SlotOutcome {
        // Step 1: Check running candidates first
        for bundleID in slot.preferredBundleIDs {
            if let window = findRestorableWindow(for: bundleID, usedWindowIDs: usedWindowIDs) {
                usedWindowIDs.insert(window.window.id)
                let candidate = ResolvedCandidate(bundleID: bundleID, resolved: window)
                let placed = await placeCandidate(
                    candidate,
                    slot: slot,
                    visibleFrame: visibleFrame,
                    primaryHeight: primaryHeight
                )
                return placed ? .placed(window.window.id) : .skipped(bundleID: bundleID, reason: .noWindow)
            }
        }

        // Step 2: Check installed candidates and launch if needed
        var lastFailureReason: SkipReason = .notInstalled
        var lastFailureBundleID: String = slot.preferredBundleIDs.first ?? "unknown"

        for bundleID in slot.preferredBundleIDs {
            if launcher.runningProcessIdentifier(bundleID: bundleID) != nil {
                lastFailureReason = .noWindow
                lastFailureBundleID = bundleID
                continue
            }

            if let outcome = await launchCandidate(
                bundleID: bundleID,
                slot: slot,
                visibleFrame: visibleFrame,
                primaryHeight: primaryHeight,
                usedWindowIDs: &usedWindowIDs
            ) {
                switch outcome {
                case .placed:
                    return outcome
                case .skipped(_, let reason):
                    lastFailureReason = reason
                    lastFailureBundleID = bundleID
                }
            }
        }

        return .skipped(bundleID: lastFailureBundleID, reason: lastFailureReason)
    }

    private func launchCandidate(
        bundleID: String,
        slot: PresetAppSlot,
        visibleFrame: CGRect,
        primaryHeight: CGFloat,
        usedWindowIDs: inout Set<CGWindowID>
    ) async -> SlotOutcome? {
        guard await launcher.openApp(withBundleIdentifier: bundleID) else { return nil }
        guard let pid = launcher.runningProcessIdentifier(bundleID: bundleID) else {
            return .skipped(bundleID: bundleID, reason: .launchTimeout)
        }
        guard await launcher.waitForFirstWindow(pid: pid, timeout: launchTimeout) else {
            return .skipped(bundleID: bundleID, reason: .launchTimeout)
        }
        guard let window = findRestorableWindow(for: bundleID, usedWindowIDs: usedWindowIDs) else {
            return .skipped(bundleID: bundleID, reason: .noWindow)
        }

        usedWindowIDs.insert(window.window.id)
        let candidate = ResolvedCandidate(bundleID: bundleID, resolved: window)
        let placed = await placeCandidate(candidate, slot: slot, visibleFrame: visibleFrame, primaryHeight: primaryHeight)
        return placed ? .placed(window.window.id) : .skipped(bundleID: bundleID, reason: .noWindow)
    }

    private func findRestorableWindow(
        for bundleID: String,
        usedWindowIDs: Set<CGWindowID>
    ) -> ResolvedWindow? {
        var candidates: [ResolvedWindow] = []
        if let pid = launcher.runningProcessIdentifier(bundleID: bundleID) {
            candidates = accessibilityService.resolvedWindows(of: pid)
        }
        if candidates.isEmpty {
            candidates = accessibilityService.allVisibleManagedWindows()
                .filter { $0.bundleIdentifier == bundleID }
                .map { ResolvedWindow(window: $0, element: nil) }
        }

        return candidates
            .filter { candidate in
                candidate.window.kind.isRestorable
                    && candidate.window.frame.width > 0
                    && candidate.window.frame.height > 0
                    && !usedWindowIDs.contains(candidate.window.id)
            }
            .sorted { ($0.window.frame.width * $0.window.frame.height) > ($1.window.frame.width * $1.window.frame.height) }
            .first
    }

    // MARK: - Framing and Placement

    private func placeCandidate(
        _ candidate: ResolvedCandidate,
        slot: PresetAppSlot,
        visibleFrame: CGRect,
        primaryHeight: CGFloat
    ) async -> Bool {
        let appKitFrame: CGRect
        if let normRect = slot.normalizedRect {
            appKitFrame = WorkspaceManager.frameFromNormalizedRect(
                normRect,
                in: visibleFrame,
                gap: preferencesStore.windowGap
            )
        } else {
            appKitFrame = layoutEngine.frame(
                for: slot.zone,
                in: visibleFrame,
                gap: preferencesStore.windowGap
            )
        }

        let axFrame = CoordinateTransformer.toAX(rect: appKitFrame, primaryScreenHeight: primaryHeight)
        do {
            try await windowManager.move(candidate.resolved.window, to: axFrame, element: candidate.resolved.element)
            launcher.reveal(bundleID: candidate.bundleID)
            return true
        } catch {
            presetLogger.error("Failed to move window \(candidate.resolved.window.id): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Window Group Linking

    private func linkWindowGroupIfNeeded(preset: WorkspacePreset, placedWindowIDs: Set<CGWindowID>) {
        guard preset.autoGroupWindows, placedWindowIDs.count >= 2 else { return }
        windowGroupManager?.createGroup(name: preset.name, windowIDs: placedWindowIDs, syncOptions: .all)
    }
}

import AppKit
import CoreGraphics
import Foundation

/// Core coordinator managing multi-display topology profiles, auto-snapshotting on disconnect,
/// and zero-prompt auto-restoration on reconnect.
///
/// Traces to: US-DISP-016, REQ-DISP-004..007, BR-DISP-009..013, ASM-DISP-004..006.
@MainActor
public final class TopologyProfileManager: TopologyProfileManaging {

    // MARK: - Dependencies

    private let displayManager: any DisplayManaging
    private let accessibilityService: any AccessibilityService
    private let layoutEngine: any LayoutCalculating
    private let hotPlugObserver: (any DisplayHotPlugObserving)?
    private let userDefaults: UserDefaults

    private static let storageKey = "com.flowsnap.topologyProfiles"

    // MARK: - State

    public private(set) var profiles: [String: DisplayTopologyProfile] = [:]
    public private(set) var currentFingerprint: TopologyFingerprint?
    public var autoRestoreOnReconnect: Bool = true

    // MARK: - Initialization

    public init(
        displayManager: any DisplayManaging,
        accessibilityService: any AccessibilityService,
        layoutEngine: any LayoutCalculating = LayoutEngine(),
        hotPlugObserver: (any DisplayHotPlugObserving)? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.displayManager = displayManager
        self.accessibilityService = accessibilityService
        self.layoutEngine = layoutEngine
        self.hotPlugObserver = hotPlugObserver
        self.userDefaults = userDefaults

        loadProfiles()
        setupObserverBinding()
    }

    private func setupObserverBinding() {
        hotPlugObserver?.onTopologyChanged = { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                await self.handleTopologyChange(event)
            }
        }
    }

    // MARK: - Topology Change Handling

    public func handleTopologyChange(_ event: DisplayTopologyChangeEvent) async {
        switch event {
        case .hotUnplugDisconnected(let newFingerprint, let departingFingerprint):
            currentFingerprint = newFingerprint
            await handleHotUnplug(departingFingerprint: departingFingerprint)

        case .hotPlugConnected(let newFingerprint, _):
            currentFingerprint = newFingerprint
            await handleHotPlug(newFingerprint: newFingerprint)

        case .geometryChanged(let newFingerprint):
            currentFingerprint = newFingerprint
        }
    }

    private func handleHotUnplug(departingFingerprint: TopologyFingerprint) async {
        // Auto-snapshot departing topology if not already saved
        if profiles[departingFingerprint.rawValue] == nil {
            _ = await captureProfile(for: departingFingerprint, name: nil)
        }

        // Clamp windows falling outside the remaining displays
        guard let primary = await displayManager.primaryDisplay else { return }
        let allWindows = accessibilityService.allVisibleManagedWindows()

        for window in allWindows {
            // Check if window is partially or completely outside primary visible frame
            let needsClamping = !primary.visibleFrame.contains(window.frame)
            if needsClamping {
                let clamped = FrameClampingHelper.clamp(
                    frame: window.frame,
                    to: primary.visibleFrame,
                    minVisibilityRatio: 1.0
                )
                if let element = accessibilityService.windowElement(for: window) {
                    try? accessibilityService.setFrame(clamped, for: element)
                }
            }
        }
    }

    private func handleHotPlug(newFingerprint: TopologyFingerprint) async {
        guard autoRestoreOnReconnect else { return }

        if let existingProfile = profiles[newFingerprint.rawValue] {
            _ = await restoreProfile(existingProfile)
        } else {
            _ = await captureProfile(for: newFingerprint, name: nil)
        }
    }

    // MARK: - Profile Capture

    public func captureProfile(
        for fingerprint: TopologyFingerprint,
        name: String? = nil
    ) async -> DisplayTopologyProfile {
        let displays = await displayManager.displays
        let sortedDisplays = sortDisplaysHorizontally(displays)
        let windows = accessibilityService.allVisibleManagedWindows()

        var placements: [String: WindowPlacement] = [:]
        var displayIndices: [String: Int] = [:]

        for window in windows {
            guard let bundleID = window.bundleIdentifier, !bundleID.isEmpty else { continue }
            guard let winDisplay = await displayManager.display(for: window.frame, cursorPoint: nil) else { continue }

            let displayIdx = sortedDisplays.firstIndex(where: { $0.id == winDisplay.id }) ?? 0
            displayIndices[bundleID] = displayIdx

            let visFrame = winDisplay.visibleFrame
            let normX = visFrame.width > 0 ? (window.frame.minX - visFrame.minX) / visFrame.width : 0
            let normY = visFrame.height > 0 ? (window.frame.minY - visFrame.minY) / visFrame.height : 0
            let normW = visFrame.width > 0 ? window.frame.width / visFrame.width : 1
            let normH = visFrame.height > 0 ? window.frame.height / visFrame.height : 1

            let normalizedRect = CGRect(x: normX, y: normY, width: normW, height: normH)
            let placement = WindowPlacement(
                bundleIdentifier: bundleID,
                zone: .maximize,
                normalizedRect: normalizedRect
            )
            placements[bundleID] = placement
        }

        let profile = DisplayTopologyProfile(
            fingerprint: fingerprint,
            name: name,
            windowPlacements: placements,
            displayIndexMap: displayIndices
        )

        saveProfile(profile)
        return profile
    }

    // MARK: - Profile Restoration

    public func restoreProfile(_ profile: DisplayTopologyProfile) async -> Bool {
        let displays = await displayManager.displays
        guard !displays.isEmpty else { return false }

        let sortedDisplays = sortDisplaysHorizontally(displays)
        let primary = await displayManager.primaryDisplay ?? sortedDisplays[0]
        let allWindows = accessibilityService.allVisibleManagedWindows()

        for (bundleID, placement) in profile.windowPlacements {
            guard let window = allWindows.first(where: { $0.bundleIdentifier == bundleID }) else {
                continue // Missing app resilience: skip gracefully (REQ-DISP-007)
            }

            let targetIdx = profile.displayIndexMap[bundleID] ?? 0
            let targetDisplay = (targetIdx < sortedDisplays.count) ? sortedDisplays[targetIdx] : primary

            let targetFrame: CGRect
            if let norm = placement.normalizedRect {
                let vis = targetDisplay.visibleFrame
                let calcX = vis.minX + norm.origin.x * vis.width
                let calcY = vis.minY + norm.origin.y * vis.height
                let calcW = max(200, norm.width * vis.width)
                let calcH = max(200, norm.height * vis.height)
                let unconstrained = CGRect(x: calcX, y: calcY, width: calcW, height: calcH)
                targetFrame = FrameClampingHelper.clamp(frame: unconstrained, to: vis, minVisibilityRatio: 1.0)
            } else {
                targetFrame = layoutEngine.frame(for: placement.zone, in: targetDisplay.visibleFrame)
            }

            if let element = accessibilityService.windowElement(for: window) {
                try? accessibilityService.setFrame(targetFrame, for: element)
            }
        }

        return true
    }

    // MARK: - Persistence & Storage

    public func saveProfile(_ profile: DisplayTopologyProfile) {
        profiles[profile.fingerprint.rawValue] = profile
        persistProfiles()
    }

    private func persistProfiles() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(profiles) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    private func loadProfiles() {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: DisplayTopologyProfile].self, from: data) {
            self.profiles = decoded
        }
    }

    private func sortDisplaysHorizontally(_ displays: [Display]) -> [Display] {
        displays.sorted { d1, d2 in
            if d1.frame.minX != d2.frame.minX { return d1.frame.minX < d2.frame.minX }
            return d1.frame.minY < d2.frame.minY
        }
    }
}

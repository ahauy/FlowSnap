import CoreGraphics
import Foundation
@testable import FlowSnap

/// Shared fixtures for the US-WORK-011 capture/restore tests (T009–T011).
///
/// Lives in one place because all three suites need the same hand-computable
/// display topology and window factory; duplicating the geometry across files is
/// how a "correct" test ends up asserting the wrong numbers.
///
/// Coordinate conventions (the crux of these tests):
///   - `ManagedWindow.frame` and `Display.visibleFrame` are **AppKit** (y-up,
///     origin bottom-left of the primary display).
///   - `WindowManaging.move(_:to:)` expects **AX** (y-down from the primary
///     display's top). `CoordinateTransformer.toAX` is the bridge.
@MainActor
enum WorkspaceTestFixtures {

    /// A single 1440×900 primary display with no menu-bar inset, so every zone
    /// frame is a clean fraction of 1440×900.
    static let singleDisplay: [Display] = [
        Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
    ]

    /// A laptop (1440×900) plus a right-adjacent 2560×1440 secondary, for the
    /// cross-display test (E8).
    static let dualDisplay: [Display] = [
        Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        ),
        Display(
            id: 2,
            frame: CGRect(x: 1440, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 1440, y: 0, width: 2560, height: 1440),
            scaleFactor: 1.0,
            isPrimary: false
        )
    ]

    /// An AppKit-space window rectangle.
    static func window(
        id: CGWindowID,
        bundle: String,
        pid: pid_t = 1000,
        appKitFrame: CGRect,
        kind: WindowKind = .normal,
        isMinimized: Bool = false
    ) -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid,
            bundleIdentifier: bundle,
            title: "\(bundle) window",
            frame: appKitFrame,
            isMinimized: isMinimized,
            kind: kind
        )
    }

    /// A `PreferencesStore` pinned to a known gap, backed by an isolated
    /// UserDefaults suite so it never touches the real app's defaults.
    static func preferences(gap: CGFloat = 0) -> PreferencesStore {
        let suite = "flowsnap-workspace-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(Double(gap), forKey: "windowGap")
        return PreferencesStore(defaults: defaults)
    }

    /// The AX frame the restore pass is expected to hand `WindowManaging.move`
    /// for a zone on a given display, computed independently of the production
    /// code path so the test is a real oracle rather than a restatement.
    static func expectedAXFrame(
        for zone: LayoutZone,
        display: Display,
        gap: CGFloat = 0
    ) -> CGRect {
        let appKit = LayoutEngine().frame(for: zone, in: display.visibleFrame, gap: gap)
        return CoordinateTransformer.toAX(rect: appKit, primaryScreenHeight: display.frame.height)
    }
}

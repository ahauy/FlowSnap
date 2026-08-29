import AppKit
import CoreGraphics
import Foundation

/// Concrete implementation of `DisplayManaging` leveraging macOS `NSScreen` and CoreGraphics.
///
/// Isolated to `@MainActor` for seamless AppKit interaction and UI thread safety.
/// Observes `NSApplication.didChangeScreenParametersNotification` to update display topologies.
///
/// Traces to US-SNAP-003, BR-DISP-001, BR-DISP-002, BR-DISP-004, BR-DISP-005, BR-DISP-006.
@MainActor
public final class DisplayManager: DisplayManaging {

    // MARK: - State

    private final class TokenBox: @unchecked Sendable {
        let token: any NSObjectProtocol
        init(_ token: any NSObjectProtocol) { self.token = token }
        deinit {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private var cachedDisplays: [Display] = []
    private var observerToken: TokenBox?
    private let displayProvider: (@Sendable () -> [Display])?

    // MARK: - Initialization

    /// Creates a production `DisplayManager` querying AppKit `NSScreen.screens`.
    public init() {
        self.displayProvider = nil
        self.cachedDisplays = Self.querySystemDisplays()
        setupNotificationObserver()
    }

    /// Creates a testable `DisplayManager` with a custom display provider closure.
    public init(displayProvider: @escaping @Sendable () -> [Display]) {
        self.displayProvider = displayProvider
        self.cachedDisplays = displayProvider()
        self.observerToken = nil
    }

    // MARK: - DisplayManaging Protocol

    public var displays: [Display] {
        cachedDisplays
    }

    public var primaryDisplay: Display? {
        cachedDisplays.first(where: { $0.isPrimary }) ?? cachedDisplays.first
    }

    public var primaryScreenHeight: CGFloat {
        primaryDisplay?.frame.height ?? 0
    }

    public func display(containing point: CGPoint) -> Display? {
        if let exact = cachedDisplays.first(where: { $0.frame.contains(point) }) {
            return exact
        }
        // Fallback for points exactly on the boundary (x == maxX or y == maxY) or pushed slightly outside by mouse acceleration
        return cachedDisplays.first(where: { $0.frame.insetBy(dx: -30, dy: -30).contains(point) })
    }

    public func display(for windowFrame: CGRect, cursorPoint: CGPoint? = nil) -> Display? {
        // Step 1: Evaluate maximum intersection area (BR-DISP-002)
        var bestDisplay: Display?
        var maxArea: CGFloat = 0

        for display in cachedDisplays {
            let intersection = windowFrame.intersection(display.frame)
            if !intersection.isNull && !intersection.isEmpty {
                let area = intersection.width * intersection.height
                if area > maxArea {
                    maxArea = area
                    bestDisplay = display
                }
            }
        }

        if let bestDisplay = bestDisplay {
            return bestDisplay
        }

        // Step 2: Off-screen fallback to cursor point if available
        if let cursorPoint = cursorPoint,
           let cursorDisplay = display(containing: cursorPoint) {
            return cursorDisplay
        }

        // Step 3: Ultimate fallback to primary display
        return primaryDisplay
    }

    public func nextDisplay(after currentDisplay: Display) -> Display? {
        guard cachedDisplays.count > 1 else {
            // BR-DISP-006: Single display guard returns nil
            return nil
        }

        if let currentIndex = cachedDisplays.firstIndex(where: { $0.id == currentDisplay.id }) {
            let nextIndex = (currentIndex + 1) % cachedDisplays.count
            return cachedDisplays[nextIndex]
        }

        return primaryDisplay
    }

    // MARK: - Display Refresh & Notification Handling

    /// Manually refreshes the cached display list from the provider or system screens.
    public func refreshDisplays() {
        if let provider = displayProvider {
            cachedDisplays = provider()
        } else {
            cachedDisplays = Self.querySystemDisplays()
        }
    }

    private func setupNotificationObserver() {
        let token = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshDisplays()
            }
        }
        observerToken = TokenBox(token)
    }

    // MARK: - System Query (MainActor isolated AppKit reads)

    private static func querySystemDisplays() -> [Display] {
        let screens = NSScreen.screens
        var result: [Display] = []

        for screen in screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)

            // BR-DISP-005: Coalesce mirrored displays to the mirror master
            if CGDisplayIsInMirrorSet(displayID) != 0 {
                let mirrorMaster = CGDisplayMirrorsDisplay(displayID)
                if mirrorMaster != kCGNullDirectDisplay {
                    // This is a secondary mirror; skip to avoid duplicate identical snap targets
                    continue
                }
            }

            let display = Display(
                id: displayID,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                scaleFactor: screen.backingScaleFactor,
                isPrimary: screen.frame.origin == .zero
            )
            result.append(display)
        }

        // Ensure primary display is ordered first if present
        result.sort { (d1, d2) -> Bool in
            if d1.isPrimary { return true }
            if d2.isPrimary { return false }
            return d1.id < d2.id
        }

        return result
    }
}

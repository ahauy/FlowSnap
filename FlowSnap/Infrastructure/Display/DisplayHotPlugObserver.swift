import AppKit
import CoreGraphics
import Foundation

/// Infrastructure observer listening for system display parameter change notifications with debouncing.
///
/// Traces to: US-DISP-016, REQ-DISP-001, REQ-DISP-002, BR-DISP-008, ASM-DISP-005.
@MainActor
public final class DisplayHotPlugObserver: DisplayHotPlugObserving {

    // MARK: - State

    private final class TokenBox: @unchecked Sendable {
        let token: any NSObjectProtocol
        init(_ token: any NSObjectProtocol) { self.token = token }
        deinit {
            NotificationCenter.default.removeObserver(token)
        }
    }

    public var onTopologyChanged: (@MainActor @Sendable (DisplayTopologyChangeEvent) -> Void)?

    private let debounceDuration: Duration
    private let displayProvider: @MainActor () -> [Display]

    private var observerToken: TokenBox?
    private var debounceTask: Task<Void, Never>?
    private var lastFingerprint: TopologyFingerprint?
    private var lastDisplayCount: Int = 0

    // MARK: - Initialization

    /// Creates an observer with a custom or default (600ms) debounce duration.
    public init(
        debounceDuration: Duration = .milliseconds(600),
        displayProvider: @escaping @MainActor () -> [Display] = {
            NSScreen.screens.map { screen in
                let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
                let displayID = CGDirectDisplayID(screenNumber?.uint32Value ?? 0)
                return Display(
                    id: displayID,
                    frame: screen.frame,
                    visibleFrame: screen.visibleFrame,
                    scaleFactor: screen.backingScaleFactor,
                    isPrimary: screen.frame.origin == .zero
                )
            }
        }
    ) {
        self.debounceDuration = debounceDuration
        self.displayProvider = displayProvider
        let initialDisplays = displayProvider()
        self.lastFingerprint = TopologyFingerprint.generate(from: initialDisplays)
        self.lastDisplayCount = initialDisplays.count
    }

    deinit {
        debounceTask?.cancel()
    }

    // MARK: - Lifecycle

    public func startObserving() {
        guard observerToken == nil else { return }

        // Refresh baseline on start
        let initialDisplays = displayProvider()
        lastFingerprint = TopologyFingerprint.generate(from: initialDisplays)
        lastDisplayCount = initialDisplays.count

        let token = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleNotificationReceived()
            }
        }
        observerToken = TokenBox(token)
    }

    public func stopObserving() {
        observerToken = nil
        debounceTask?.cancel()
        debounceTask = nil
    }

    // MARK: - Notification Handling & Coalescing Debounce

    private func handleNotificationReceived() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: self?.debounceDuration ?? .milliseconds(600))
            } catch {
                return
            }

            guard !Task.isCancelled, let self = self else { return }
            self.evaluateCurrentTopology()
        }
    }

    private func evaluateCurrentTopology() {
        let currentDisplays = displayProvider()
        let newFingerprint = TopologyFingerprint.generate(from: currentDisplays)

        guard let previousFingerprint = lastFingerprint else {
            lastFingerprint = newFingerprint
            lastDisplayCount = currentDisplays.count
            return
        }

        guard newFingerprint != previousFingerprint else {
            return
        }

        let oldCount = lastDisplayCount
        let departingFingerprint = previousFingerprint
        lastFingerprint = newFingerprint
        lastDisplayCount = currentDisplays.count

        let event: DisplayTopologyChangeEvent
        if currentDisplays.count > oldCount {
            event = .hotPlugConnected(newFingerprint: newFingerprint, addedCount: currentDisplays.count - oldCount)
        } else if currentDisplays.count < oldCount {
            event = .hotUnplugDisconnected(newFingerprint: newFingerprint, departingFingerprint: departingFingerprint)
        } else {
            event = .geometryChanged(newFingerprint: newFingerprint)
        }

        onTopologyChanged?(event)
    }
}

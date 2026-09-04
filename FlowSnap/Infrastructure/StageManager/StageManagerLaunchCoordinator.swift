import AppKit
import Foundation

/// Coordinates Stage Manager multi-window cohesion when applications launch.
///
/// Prevents macOS Stage Manager from isolating newly launched apps into separate stages
/// by snapshotting active Stage windows and coordinating `kAXRaiseAction` when new windows appear.
/// See ADR-0015.
@MainActor
public final class StageManagerLaunchCoordinator: StageManagerLaunchCoordinating {

    // MARK: - Dependencies

    private let stageManagerDetector: StageManagerDetecting
    private let accessibilityService: AccessibilityService
    private let applicationObserver: ApplicationObserving

    private final class TokenBox: @unchecked Sendable {
        let token: any NSObjectProtocol
        let notificationCenter: NotificationCenter

        init(_ token: any NSObjectProtocol, notificationCenter: NotificationCenter) {
            self.token = token
            self.notificationCenter = notificationCenter
        }

        deinit {
            notificationCenter.removeObserver(token)
        }
    }

    private var workspaceToken: TokenBox?

    // MARK: - Properties

    public var isCoexistenceEnabled: Bool

    // MARK: - Initialization

    public init(
        stageManagerDetector: StageManagerDetecting,
        accessibilityService: AccessibilityService,
        applicationObserver: ApplicationObserving,
        isCoexistenceEnabled: Bool = true
    ) {
        self.stageManagerDetector = stageManagerDetector
        self.accessibilityService = accessibilityService
        self.applicationObserver = applicationObserver
        self.isCoexistenceEnabled = isCoexistenceEnabled
    }

    public func startObservingWorkspace(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        let token = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor in
                await self.handleApplicationLaunched(
                    processIdentifier: app.processIdentifier,
                    bundleIdentifier: app.bundleIdentifier
                )
            }
        }
        workspaceToken = TokenBox(token, notificationCenter: notificationCenter)
    }

    // MARK: - Coordination

    public func handleApplicationLaunched(processIdentifier: pid_t, bundleIdentifier: String?) async {
        guard isCoexistenceEnabled && stageManagerDetector.isStageManagerEnabled else {
            return
        }

        // Snapshot existing windows on current Stage
        let currentStageWindows = accessibilityService.allVisibleManagedWindows()
            .filter { $0.pid != processIdentifier }
        guard !currentStageWindows.isEmpty else { return }

        // Observe launch until first window creation
        await applicationObserver.observe(pid: processIdentifier, bundleID: bundleIdentifier)

        // Wait for windowCreated event with timeout
        let deadline = Date().addingTimeInterval(5.0)
        var windowDetected = false

        for await event in applicationObserver.events {
            switch event {
            case .windowCreated(let pid, _):
                if pid == processIdentifier {
                    windowDetected = true
                }
            case .failed(let pid, _), .timeout(let pid):
                if pid == processIdentifier {
                    windowDetected = false
                }
            }
            if windowDetected || Date() >= deadline {
                break
            }
        }

        applicationObserver.stopObserving(pid: processIdentifier)

        // Re-raise all previous stage windows onto current Stage
        for window in currentStageWindows {
            accessibilityService.raise(window: window)
        }
    }
}

import CoreGraphics
import Foundation

/// A window being tracked and managed by FlowSnap.
///
/// Represents a snapshot of a window's state. Does not hold
/// a reference to the underlying AXUIElement — that mapping
/// lives in the Infrastructure layer (AccessibilityService).
public struct ManagedWindow: Identifiable, Hashable, Sendable {
    public let id: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let title: String

    public var frame: CGRect
    public var minSize: CGSize?
    public var isMinimized: Bool
    public var isResizable: Bool
    public var kind: WindowKind

    public init(
        id: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String? = nil,
        title: String,
        frame: CGRect,
        minSize: CGSize? = nil,
        isMinimized: Bool = false,
        isResizable: Bool = true,
        kind: WindowKind = .normal
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.frame = frame
        self.minSize = minSize
        self.isMinimized = isMinimized
        self.isResizable = isResizable
        self.kind = kind
    }
}

extension ManagedWindow {
    /// Friendly human-readable application name resolved from bundle identifier or title.
    public var displayAppName: String {
        if let bundle = bundleIdentifier?.lowercased() {
            if bundle.contains("brave") { return "Brave" }
            if bundle.contains("chrome") { return "Chrome" }
            if bundle.contains("safari") { return "Safari" }
            if bundle.contains("antigravity") { return "Antigravity IDE" }
            if bundle.contains("vscode") || bundle.contains("visualstudio") { return "VS Code" }
            if bundle.contains("cursor") { return "Cursor" }
            if bundle.contains("xcode") { return "Xcode" }
            if bundle.contains("finder") { return "Finder" }
            if bundle.contains("terminal") || bundle.contains("iterm") { return "Terminal" }
            if bundle.contains("slack") { return "Slack" }
            if bundle.contains("notes") { return "Notes" }
            if let last = bundle.components(separatedBy: ".").last, !last.isEmpty {
                return last.capitalized
            }
        }
        return title.isEmpty ? "App" : "Window"
    }

    /// Clean tab, document, or page content with redundant trailing app names stripped.
    public var displayDetailTitle: String {
        guard !title.isEmpty else { return "(Untitled Window)" }
        var cleanTitle = title
        let suffixes = [
            " - Brave", " — Brave",
            " - Google Chrome", " — Google Chrome",
            " — Antigravity IDE", " - Antigravity IDE",
            " - Visual Studio Code", " — Visual Studio Code",
            " - Code", " — Code",
            " - Cursor", " — Cursor",
            " - Safari", " — Safari",
            " - Xcode", " — Xcode"
        ]
        for suffix in suffixes {
            if cleanTitle.hasSuffix(suffix) {
                cleanTitle = String(cleanTitle.dropLast(suffix.count))
                break
            }
        }
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanTitle.isEmpty ? "(Untitled Window)" : cleanTitle
    }

    /// Formatted composite string such as "Brave: YouTube" or "Antigravity: RUN_AND_TEST.md".
    public var formattedDisplayName: String {
        let app = displayAppName
        let detail = displayDetailTitle
        if detail == "(Untitled Window)" || detail.caseInsensitiveCompare(app) == .orderedSame {
            return app
        }
        return "\(app): \(detail)"
    }
}

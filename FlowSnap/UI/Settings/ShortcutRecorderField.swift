import AppKit
import SwiftUI

/// Interactive keyboard shortcut recorder field for macOS.
///
/// Features:
/// - Click to record key combination
/// - Intercepts local keydown events
/// - Enforces modifier presence (BR-SET-002)
/// - Escape cancels recording
/// - Backspace / Delete clears shortcut
/// - Clear button (x)
/// - Collision / Conflict indicator (BR-SET-003)
public struct ShortcutRecorderField: View {

    public let shortcut: KeyboardShortcut?
    public let conflictAction: ShortcutAction?
    public let onRecord: (KeyboardShortcut) -> Void
    public let onClear: () -> Void

    @State private var isRecording: Bool = false
    @State private var eventMonitor: Any?

    public init(
        shortcut: KeyboardShortcut?,
        conflictAction: ShortcutAction? = nil,
        onRecord: @escaping (KeyboardShortcut) -> Void,
        onClear: @escaping () -> Void
    ) {
        self.shortcut = shortcut
        self.conflictAction = conflictAction
        self.onRecord = onRecord
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleRecording) {
                HStack(spacing: 4) {
                    if isRecording {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                        Text("Type keys...")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.primary)
                    } else if let shortcut = shortcut {
                        Text(shortcut.displayString)
                            .font(.system(.body, design: .monospaced).weight(.medium))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Record Shortcut")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isRecording
                                ? Color.accentColor
                                : (conflictAction != nil ? Color.orange : Color.gray.opacity(0.3)),
                            lineWidth: isRecording ? 2 : 1
                        )
                )
            }
            .buttonStyle(.plain)

            // Clear button
            if shortcut != nil && !isRecording {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }

            // Conflict warning badge
            if let conflict = conflictAction {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .help("Conflicts with '\(conflict.displayName)'")
            }
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopMonitoring()
            isRecording = false
        } else {
            isRecording = true
            startMonitoring()
        }
    }

    private func startMonitoring() {
        stopMonitoring()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] event in
            // Escape key (kVK_Escape = 53): cancel recording
            if event.keyCode == 53 {
                Task { @MainActor in
                    self.stopMonitoring()
                    self.isRecording = false
                }
                return nil
            }

            // Delete / Backspace key (kVK_Delete = 51, kVK_ForwardDelete = 117): clear shortcut
            if event.keyCode == 51 || event.keyCode == 117 {
                Task { @MainActor in
                    self.onClear()
                    self.stopMonitoring()
                    self.isRecording = false
                }
                return nil
            }

            // Capture valid key combination with modifiers
            if let newShortcut = KeyboardShortcut(from: event) {
                Task { @MainActor in
                    self.onRecord(newShortcut)
                    self.stopMonitoring()
                    self.isRecording = false
                }
                return nil
            }

            return nil
        }
    }

    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

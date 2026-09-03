import AppKit
import SwiftUI

/// FlowSnap Lab — Debug & testing application.
///
/// A separate target for validating Accessibility, window control,
/// multi-display topologies, and global hotkey dispatching.
@main
struct FlowSnapLabApp: App {
    var body: some Scene {
        SwiftUI.WindowGroup {
            FlowSnapLabView()
        }
    }
}

/// Lab UI for testing core functionality.
struct FlowSnapLabView: View {

    private let accessibilityService: AccessibilityService = AXAccessibilityService()
    private let windowRegistry = WindowRegistry()
    private let layoutEngine = LayoutEngine()
    private let displayManager = DisplayManager()
    private let hotkeyManager: GlobalHotkeyManaging = GlobalHotkeyManager()

    @State private var isTrusted = false
    @State private var focusedWindow: ManagedWindow?
    @State private var lastInspectionTime = Date()
    @State private var statusMessage = ""
    @State private var connectedDisplays: [Display] = []
    @State private var primaryScreenHeight: CGFloat = 0
    @State private var activeHotkeys: [HotkeyBinding] = []
    @State private var lastDispatchedCommandText = "None"

    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("FlowSnap Lab")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    // Permission indicator badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isTrusted ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isTrusted ? "Trusted" : "Untrusted")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(isTrusted ? .green : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }

                GroupBox("Accessibility & Window Discovery (US-SNAP-001)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Permission Status:")
                                .fontWeight(.medium)
                            Text(isTrusted ? "Granted" : "Denied / Not Granted")
                                .foregroundStyle(isTrusted ? .green : .red)

                            if !isTrusted {
                                Spacer()
                                Button("Open Settings") {
                                    accessibilityService.openSystemSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }

                        Divider()

                        if let window = focusedWindow {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focused Window Details:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("Title: \(window.title)")
                                    .font(.system(.body, design: .monospaced))
                                Text("Bundle: \(window.bundleIdentifier ?? "nil") (PID: \(window.pid))")
                                    .font(.system(.caption, design: .monospaced))
                                Text("Kind: \(window.kind.rawValue) | Snappable: \(window.kind.isSnappable ? "YES" : "NO")")
                                    .font(.system(.caption, design: .monospaced))
                                Text("Frame: x=\(Int(window.frame.origin.x)), y=\(Int(window.frame.origin.y)), w=\(Int(window.frame.width)), h=\(Int(window.frame.height))")
                                    .font(.system(.caption, design: .monospaced))
                            }
                        } else {
                            Text(isTrusted ? "No focused window detected (bring another app to front)" : "Grant Accessibility permission to inspect windows.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Core Layout & Snap Engine (US-SNAP-002)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Simulate Snap on Focused Window:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            Button("Left 50%") {
                                triggerSnap(.zone(.leftHalf))
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(focusedWindow == nil || !isTrusted)

                            Button("Right 50%") {
                                triggerSnap(.zone(.rightHalf))
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(focusedWindow == nil || !isTrusted)

                            Button("Maximize") {
                                triggerSnap(.zone(.maximize))
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(focusedWindow == nil || !isTrusted)

                            Button("Restore") {
                                triggerSnap(.restore)
                            }
                            .buttonStyle(.bordered)
                            .disabled(focusedWindow == nil || !isTrusted)
                        }

                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Multi-Monitor & Displays (US-SNAP-003)") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Displays (\(connectedDisplays.count)):")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Primary Height: \(Int(primaryScreenHeight))pt")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(connectedDisplays) { display in
                            HStack {
                                Circle()
                                    .fill(display.isPrimary ? Color.blue : Color.orange)
                                    .frame(width: 6, height: 6)
                                Text("Display \(display.id) \(display.isPrimary ? "(Primary)" : "")")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(display.frame.width))x\(Int(display.frame.height)) @ \(String(format: "%.0fx", display.scaleFactor))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if connectedDisplays.count > 1 {
                            Button("Move Window to Next Display (Left Half)") {
                                triggerMoveToNextDisplay()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(focusedWindow == nil || !isTrusted)
                            .padding(.top, 4)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Global Hotkeys & Dispatcher Daemon (US-SNAP-004)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("System Shortcuts Registered:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Latency Budget: < 50ms")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.green)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(activeHotkeys) { binding in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(binding.isRegistered ? Color.green : Color.orange)
                                        .frame(width: 6, height: 6)
                                    Text(binding.shortcut.displayString)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                    Text("→ \(commandTitle(binding.command))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            }
                        }

                        HStack {
                            Text("Last Dispatched:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(lastDispatchedCommandText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 4)

                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(statusMessage.contains("✅") ? .green : (statusMessage.contains("⚠️") ? .orange : .red))
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Menu Bar & Quick Snap Controls (US-SNAP-005)") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Interactive Menu Bar Dropdown Preview:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Agent App: LSUIElement")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 16) {
                            // Embedded Live MenuBarView
                            VStack(alignment: .leading) {
                                Text("Live Component:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                MenuBarView(viewModel: makeMenuBarViewModel())
                                    .background(Color(NSColor.windowBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            // Info & Actions Guide
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Feature Highlights:")
                                    .font(.caption)
                                    .fontWeight(.bold)

                                Text("• Auto-dismisses on snap click")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("• Displays warning banner if untrusted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("• Quick 10-zone mouse snapping")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("• Settings (⌘,) & Quit (⌘Q)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 18)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Interactive Drag-to-Snap & HUD Snap Preview (US-SNAP-006)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("HUD Snap Preview Controls:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Liquid Glass NSPanel")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            Button("Left 50%") {
                                if let screen = NSScreen.main {
                                    let targetFrame = layoutEngine.frame(for: .leftHalf, in: screen.visibleFrame)
                                    SnapPreviewPanel.shared.showPreview(frame: targetFrame, displayID: 0)
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Right 50%") {
                                if let screen = NSScreen.main {
                                    let targetFrame = layoutEngine.frame(for: .rightHalf, in: screen.visibleFrame)
                                    SnapPreviewPanel.shared.showPreview(frame: targetFrame, displayID: 0)
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Maximize") {
                                if let screen = NSScreen.main {
                                    let targetFrame = layoutEngine.frame(for: .maximize, in: screen.visibleFrame)
                                    SnapPreviewPanel.shared.showPreview(frame: targetFrame, displayID: 0)
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Flash Outline") {
                                if let screen = NSScreen.main {
                                    let targetFrame = layoutEngine.frame(for: .leftHalf, in: screen.visibleFrame)
                                    SnapPreviewPanel.shared.flashSnapSuccess(frame: targetFrame)
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Hide") {
                                SnapPreviewPanel.shared.hidePreview(animated: true)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Top-Edge Snap Layout Picker (US-SNAP-007)") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Windows 11-Style Top-Edge Flyout:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Top-Center Dwell")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            Button("Show Picker (Primary)") {
                                Task {
                                    let displays = await displayManager.displays
                                    if let primary = displays.first(where: { $0.isPrimary }) ?? displays.first {
                                        SnapLayoutPickerManager.shared.showPicker(on: primary)
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Hide Picker") {
                                SnapLayoutPickerManager.shared.hidePicker(animated: true)
                            }
                            .buttonStyle(.bordered)

                            Button("Snap Left 70%") {
                                triggerSnap(.leftTwoThirds)
                            }
                            .buttonStyle(.bordered)
                            .disabled(focusedWindow == nil || !isTrusted)

                            Button("Snap Center 1/3") {
                                triggerSnap(.centerThird)
                            }
                            .buttonStyle(.bordered)
                            .disabled(focusedWindow == nil || !isTrusted)
                        }

                        // Embedded Mini Layout Picker View for visual inspection
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Picker Component Preview:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            SnapLayoutPickerView(
                                templates: LayoutTemplate.standardTemplates,
                                hoveredSlotId: "twoColAsym-left"
                            )
                            .scaleEffect(0.9)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Actions") {
                    HStack(spacing: 12) {
                        Button("Inspect Focused Window") {
                            refreshStatus()
                        }
                        .buttonStyle(.bordered)

                        if !isTrusted {
                            Button("Open Accessibility Settings") {
                                accessibilityService.openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 560, height: 640)
        .onAppear {
            setupHotkeys()
            refreshStatus()
        }
        .onReceive(timer) { _ in
            refreshStatus()
        }
    }

    private func setupHotkeys() {
        let bindings = hotkeyManager.registerDefaultHotkeys { command in
            Task { @MainActor in
                self.lastDispatchedCommandText = "\(command)"
                if !self.accessibilityService.isTrusted {
                    self.statusMessage = "⚠️ Phím tắt đã nhận (\(command)), nhưng quyền Accessibility chưa được cấp! Vui lòng ấn 'Open Settings' để cấp quyền."
                    return
                }
                guard let window = self.accessibilityService.focusedManagedWindow() else {
                    self.statusMessage = "⚠️ Phím tắt đã nhận (\(command)), nhưng không phát hiện cửa sổ nào đang được focus. Vui lòng click chọn cửa sổ ứng dụng khác (Safari, Notes, Finder...) trước!"
                    return
                }
                let windowManager = WindowManager(accessibilityService: self.accessibilityService)
                let snapEngine = SnapEngine(
                    layoutEngine: self.layoutEngine,
                    windowRegistry: self.windowRegistry,
                    displayManager: self.displayManager
                )
                let dispatcher = CommandDispatcher(
                    windowManager: windowManager,
                    snapEngine: snapEngine,
                    displayManager: self.displayManager
                )
                do {
                    try await dispatcher.dispatch(command)
                    self.statusMessage = "✅ Đã snap \(command) thành công trên '\(window.title.isEmpty ? (window.bundleIdentifier ?? "Window") : window.title)'"
                    self.refreshStatus()
                } catch {
                    self.statusMessage = "❌ Lỗi dispatch: \(error.localizedDescription)"
                }
            }
        }
        activeHotkeys = bindings
    }

    private func commandTitle(_ command: WindowCommand) -> String {
        switch command {
        case .snap(let target, _):
            switch target {
            case .zone(let z): return z.rawValue
            case .restore: return "restore"
            case .layout: return "layout"
            }
        case .maximize: return "maximize"
        case .restore: return "restore"
        case .minimize: return "minimize"
        case .moveToDisplay(let id): return "display \(id)"
        case .moveToNextDisplay: return "next display"
        case .moveToPreviousDisplay: return "previous display"
        case .restoreWorkspace: return "workspace"
        case .saveWorkspace: return "save"
        case .restorePreset(let id): return "preset \(id)"
        }
    }

    private func refreshStatus() {
        isTrusted = accessibilityService.isTrusted
        if isTrusted {
            focusedWindow = accessibilityService.focusedManagedWindow()
        } else {
            focusedWindow = nil
        }
        lastInspectionTime = Date()

        Task {
            let displays = await displayManager.displays
            let height = await displayManager.primaryScreenHeight
            await MainActor.run {
                self.connectedDisplays = displays
                self.primaryScreenHeight = height
                self.activeHotkeys = self.hotkeyManager.activeBindings
            }
        }
    }

    private func triggerSnap(_ target: SnapTarget) {
        guard let window = focusedWindow, window.kind.isSnappable else {
            statusMessage = "Cannot snap: window is not resizable or non-standard."
            return
        }

        Task {
            let windowManager = WindowManager(accessibilityService: self.accessibilityService)
            let snapEngine = SnapEngine(
                layoutEngine: layoutEngine,
                windowRegistry: windowRegistry,
                displayManager: displayManager
            )
            let dispatcher = CommandDispatcher(
                windowManager: windowManager,
                snapEngine: snapEngine,
                displayManager: displayManager
            )

            do {
                try await dispatcher.dispatch(.snap(target))
                await MainActor.run {
                    statusMessage = "Dispatched \(target) successfully"
                    refreshStatus()
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Dispatch error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func triggerMoveToNextDisplay() {
        guard let window = focusedWindow, window.kind.isSnappable else {
            statusMessage = "Cannot move: window is not resizable or non-standard."
            return
        }

        Task {
            let snapEngine = SnapEngine(
                layoutEngine: layoutEngine,
                windowRegistry: windowRegistry,
                displayManager: displayManager
            )

            if let (targetFrame, nextDisplay) = await snapEngine.calculateFrameOnNextDisplay(
                for: .zone(.leftHalf),
                window: window,
                displayManager: displayManager
            ) {
                if let axElement = accessibilityService.focusedWindow() {
                    do {
                        try accessibilityService.setFrame(targetFrame, for: axElement)
                        await MainActor.run {
                            statusMessage = "Moved to Display \(nextDisplay.id): \(Int(targetFrame.width))x\(Int(targetFrame.height))"
                            refreshStatus()
                        }
                    } catch {
                        await MainActor.run {
                            statusMessage = "Failed to move: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }

    private func makeMenuBarViewModel() -> MenuBarViewModel {
        let windowManager = WindowManager(accessibilityService: self.accessibilityService)
        let snapEngine = SnapEngine(
            layoutEngine: layoutEngine,
            windowRegistry: windowRegistry,
            displayManager: displayManager
        )
        let dispatcher = CommandDispatcher(
            windowManager: windowManager,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        let vm = MenuBarViewModel(
            accessibilityService: accessibilityService,
            commandDispatcher: dispatcher,
            windowManager: windowManager
        )
        vm.dismissHandler = {
            self.statusMessage = "✅ MenuBar Action Triggered & Dismissed"
            self.refreshStatus()
        }
        return vm
    }
}

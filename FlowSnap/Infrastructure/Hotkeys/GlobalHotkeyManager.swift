import Carbon
import Foundation
import OSLog

private let hotkeyLogger = Logger(subsystem: "com.flowsnap", category: "GlobalHotkeyManager")

/// Carbon C callback function for dispatched hotkey events.
private func carbonEventHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event, let userData = userData else { return noErr }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr else { return noErr }

    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKeyTriggered(id: hotKeyID.id)
    return noErr
}

/// Concrete implementation of GlobalHotkeyManaging using Carbon Event Hotkeys.
///
/// Provides system-wide, non-blocking shortcut listening with collision tolerance.
/// Conforms to Swift 6 Sendable using internal lock protection.
public final class GlobalHotkeyManager: GlobalHotkeyManaging, @unchecked Sendable {

    private let lock = NSLock()
    private var bindings: [UInt32: HotkeyBinding] = [:]
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actionHandler: (@Sendable (WindowCommand) -> Void)?
    private var eventHandlerRef: EventHandlerRef?

    public init() {
        installCarbonEventHandlerIfNeeded()
    }

    deinit {
        unregisterAll()
        removeCarbonEventHandler()
    }

    public var activeBindings: [HotkeyBinding] {
        lock.withLock {
            Array(bindings.values).sorted { $0.id < $1.id }
        }
    }

    @discardableResult
    public func register(
        _ binding: HotkeyBinding,
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> Bool {
        lock.withLock {
            self.actionHandler = action
            installCarbonEventHandlerIfNeeded()

            // Unregister prior registration for this ID if any
            if let existingRef = hotKeyRefs[binding.id] {
                UnregisterEventHotKey(existingRef)
                hotKeyRefs.removeValue(forKey: binding.id)
            }

            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x464C5350) // 'FLSP'
            hotKeyID.id = binding.id

            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.shortcut.keyCode,
                binding.shortcut.carbonModifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                hotKeyRefs[binding.id] = ref
                let registeredBinding = binding.withRegistrationStatus(true)
                bindings[binding.id] = registeredBinding
                hotkeyLogger.info("Successfully registered hotkey '\(binding.shortcut.displayString)' (ID: \(binding.id))")
                return true
            } else {
                // BR-HOTKEY-002: Collision tolerance — record failure gracefully without throwing
                let unregisteredBinding = binding.withRegistrationStatus(false)
                bindings[binding.id] = unregisteredBinding
                hotkeyLogger.warning("Failed to register hotkey '\(binding.shortcut.displayString)' (ID: \(binding.id)), OSStatus: \(status). Collision skipped gracefully.")
                return false
            }
        }
    }

    @discardableResult
    public func registerDefaultHotkeys(
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> [HotkeyBinding] {
        let defaultShortcuts: [(UInt32, Int, Int, WindowCommand)] = [
            (1, 123, controlKey | optionKey, .snap(.zone(.leftHalf))),     // ⌃⌥← Left
            (2, 124, controlKey | optionKey, .snap(.zone(.rightHalf))),    // ⌃⌥→ Right
            (3, 126, controlKey | optionKey, .maximize),                   // ⌃⌥↑ Maximize
            (4, 125, controlKey | optionKey, .restore),                    // ⌃⌥↓ Restore
            (5, 18, controlKey | optionKey, .snap(.zone(.topLeft))),       // ⌃⌥1 Top-Left
            (6, 19, controlKey | optionKey, .snap(.zone(.topRight))),      // ⌃⌥2 Top-Right
            (7, 20, controlKey | optionKey, .snap(.zone(.bottomLeft))),    // ⌃⌥3 Bottom-Left
            (8, 21, controlKey | optionKey, .snap(.zone(.bottomRight)))    // ⌃⌥4 Bottom-Right
        ]

        var registeredList: [HotkeyBinding] = []
        for (id, keyCode, modifiers, command) in defaultShortcuts {
            let shortcut = KeyboardShortcut(keyCode: keyCode, carbonModifiers: modifiers)
            let binding = HotkeyBinding(id: id, shortcut: shortcut, command: command)
            register(binding, action: action)
            if let active = activeBindings.first(where: { $0.id == id }) {
                registeredList.append(active)
            }
        }
        return registeredList
    }

    @MainActor
    @discardableResult
    public func registerShortcuts(
        from preferencesStore: PreferencesStore,
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> [HotkeyBinding] {
        unregisterAll()

        var idCounter: UInt32 = 1
        var registeredList: [HotkeyBinding] = []

        // Standard Snap Shortcuts
        for actionType in ShortcutAction.allCases {
            guard let shortcut = preferencesStore.shortcut(for: actionType) else {
                continue
            }
            let binding = HotkeyBinding(
                id: idCounter,
                shortcut: shortcut,
                command: actionType.defaultCommand
            )
            register(binding, action: action)
            if let active = activeBindings.first(where: { $0.id == idCounter }) {
                registeredList.append(active)
            }
            idCounter += 1
        }

        // Preset Shortcuts (US-WORK-012)
        for preset in BuiltinPresetFactory.allBuiltinPresets {
            guard let shortcut = preferencesStore.shortcut(forPresetID: preset.id) else {
                continue
            }
            let binding = HotkeyBinding(
                id: idCounter,
                shortcut: shortcut,
                command: .restorePreset(preset.id)
            )
            register(binding, action: action)
            if let active = activeBindings.first(where: { $0.id == idCounter }) {
                registeredList.append(active)
            }
            idCounter += 1
        }

        return registeredList
    }

    public func unregisterAll() {
        lock.withLock {
            for (_, ref) in hotKeyRefs {
                UnregisterEventHotKey(ref)
            }
            hotKeyRefs.removeAll()
            bindings.removeAll()
        }
    }

    // MARK: - Internal Event Dispatch

    func handleHotKeyTriggered(id: UInt32) {
        let (command, handler): (WindowCommand?, (@Sendable (WindowCommand) -> Void)?) = lock.withLock {
            let cmd = bindings[id]?.command
            return (cmd, actionHandler)
        }

        guard let command = command, let handler = handler else { return }

        // BR-HOTKEY-003: Offload work asynchronously to avoid blocking Carbon event loop
        Task {
            handler(command)
        }
    }

    // MARK: - Private Carbon Lifecycle

    private func installCarbonEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            carbonEventHotKeyHandler,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        if status == noErr {
            hotkeyLogger.debug("Carbon event handler installed successfully.")
        } else {
            hotkeyLogger.error("Failed to install Carbon event handler, OSStatus: \(status)")
        }
    }

    private func removeCarbonEventHandler() {
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}

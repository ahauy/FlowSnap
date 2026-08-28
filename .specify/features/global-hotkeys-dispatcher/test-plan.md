# Test Plan: Global Hotkeys & Command Dispatcher (US-SNAP-004)

**Feature slug**: `global-hotkeys-dispatcher`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (`backend-developer`) — Stage TDD (before implementation)  
**Traces to**: `.specify/features/global-hotkeys-dispatcher/spec/user-stories.md`

---

## 1. Unit Tests

### `KeyboardShortcut` & `HotkeyBinding`

#### TC-HOTKEY-001: Arrow Keys Glyph Formatting

```gherkin
Given a KeyboardShortcut with controlKey + optionKey modifiers
When the keyCode is kVK_LeftArrow (123) or kVK_RightArrow (124)
Then .displayString returns "⌃⌥←" and "⌃⌥→" respectively
```

- **File**: `FlowSnapTests/Domain/KeyboardShortcutTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.3` Scenario 3.1

#### TC-HOTKEY-002: Maximize & Restore Glyph Formatting

```gherkin
Given a KeyboardShortcut with controlKey + optionKey modifiers
When the keyCode is kVK_UpArrow (126) or kVK_DownArrow (125)
Then .displayString returns "⌃⌥↑" and "⌃⌥↓" respectively
```

- **File**: `FlowSnapTests/Domain/KeyboardShortcutTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.3` Scenario 3.1

#### TC-HOTKEY-003: Quarters 1..4 Glyph Formatting

```gherkin
Given a KeyboardShortcut with controlKey + optionKey modifiers
When the keyCode is kVK_ANSI_1 (18), 2 (19), 3 (20), or 4 (21)
Then .displayString returns "⌃⌥1", "⌃⌥2", "⌃⌥3", "⌃⌥4" respectively
```

- **File**: `FlowSnapTests/Domain/KeyboardShortcutTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.3` Scenario 3.1

#### TC-HOTKEY-004: Shortcut Codable Serialization & Hashing

```gherkin
Given a KeyboardShortcut instance
When encoded and decoded via JSONEncoder / JSONDecoder
Then the restored shortcut is equal to the original and produces the identical hashValue
```

- **File**: `FlowSnapTests/Domain/KeyboardShortcutTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.3`

---

### `GlobalHotkeyManaging` & `GlobalHotkeyManager`

#### TC-HOTKEY-005: Default 8 Hotkeys Registration Tracking

```gherkin
Given a fresh GlobalHotkeyManager
When registerDefaultHotkeys is called with an action handler
Then 8 hotkey bindings are created and activeBindings count equals 8
```

- **File**: `FlowSnapTests/Infrastructure/GlobalHotkeyManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.1` Scenario 1.1

#### TC-HOTKEY-006: Non-blocking Collision Tolerance

```gherkin
Given a hotkey binding that encounters a Carbon collision error
When registered
Then the binding is recorded with isRegistered == false
And subsequent valid hotkeys continue to register without error
```

- **File**: `FlowSnapTests/Infrastructure/GlobalHotkeyManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.1` Scenario 1.2

#### TC-HOTKEY-007: Safe Teardown & Unregister All

```gherkin
Given active registered hotkeys
When unregisterAll() is invoked
Then all system registrations are released and activeBindings is empty
```

- **File**: `FlowSnapTests/Infrastructure/GlobalHotkeyManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.1` Scenario 1.3

---

### `CommandDispatcher`

#### TC-HOTKEY-008: Left Half Snap Dispatch

```gherkin
Given a focused ManagedWindow and target display
When CommandDispatcher dispatches .snap(.zone(.leftHalf))
Then WindowManaging.move is invoked with the calculated left 50% frame in AX coordinates
```

- **File**: `FlowSnapTests/Core/CommandDispatcherTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.2` Scenario 2.1

#### TC-HOTKEY-009: Maximize and Restore Dispatch

```gherkin
Given a focused window at standard bounds
When CommandDispatcher dispatches .maximize followed by .restore
Then the window first fills visible bounds, and then restores to its exact pre-snap frame
```

- **File**: `FlowSnapTests/Core/CommandDispatcherTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.2` Scenario 2.2

#### TC-HOTKEY-010: Guard Against Nil Focused Window

```gherkin
Given WindowManaging.focusedWindow() returns nil
When CommandDispatcher dispatches any snap command
Then dispatch exits gracefully without throwing and no move call is made
```

- **File**: `FlowSnapTests/Core/CommandDispatcherTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.2` Scenario 2.4

#### TC-HOTKEY-011: Latest-Wins Debouncing Under Rapid Input

```gherkin
Given rapid consecutive dispatches (.snap(.zone(.leftHalf)) followed immediately by .snap(.zone(.rightHalf)))
When executed within the 50ms debounce window
Then only the final command (Right Half) executes
```

- **File**: `FlowSnapTests/Core/CommandDispatcherTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-004.2` Scenario 2.3

# User Stories: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Feature**: `global-hotkeys-dispatcher`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (User Stories for Bounded Task)

---

### Story 1: Carbon Hotkey Registration & Event Interception

**ID**: `US-SNAP-004.1`  
**As a** Mac user,  
**I want** FlowSnap to register system-wide hotkeys with `Control + Option` modifiers,  
**So that** I can trigger window management actions instantly from any active application without mouse clicks.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 1.1 (Happy Path - Default Hotkeys Registration)**:
  - **Given** FlowSnap launches
  - **When** `GlobalHotkeyManager.registerDefaultHotkeys(...)` is invoked
  - **Then** 8 standard shortcuts (`⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`, `⌃⌥1`, `⌃⌥2`, `⌃⌥3`, `⌃⌥4`) are registered with Carbon Event Hotkeys
  - **And** all bindings have `isRegistered == true`.

- **Scenario 1.2 (Collision Tolerance - Conflict Graceful Skip)**:
  - **Given** another application has already registered `⌃⌥←`
  - **When** `GlobalHotkeyManager` attempts to register the default hotkey set
  - **Then** registration of `⌃⌥←` returns non-fatal failure with `isRegistered == false`
  - **And** the remaining 7 shortcuts register successfully without crashing or aborting startup.

- **Scenario 1.3 (Teardown & Clean Unregister)**:
  - **Given** active registered hotkeys
  - **When** `unregisterAll()` is called (e.g. at quit or re-binding)
  - **Then** all `EventHotKeyRef` instances are uninstalled from Carbon and `activeBindings` is empty.

---

### Story 2: Asynchronous Command Dispatch & Latency Budget

**ID**: `US-SNAP-004.2`  
**As a** software engineer,  
**I want** hotkey presses to be routed asynchronously to `CommandDispatcher` and executed within 50ms,  
**So that** my typing flow is never interrupted by UI freezes or keypress lag.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 2.1 (Happy Path - Left Snap Dispatch)**:
  - **Given** a focused snappable window on a display
  - **When** the user presses `⌃⌥←` (Snap Left)
  - **Then** `CommandDispatcher` routes `WindowCommand.snap(.zone(.leftHalf))`
  - **And** moves the window to the left 50% of the active display's visible bounds in AX coordinates.

- **Scenario 2.2 (Happy Path - Maximize & Restore Dispatch)**:
  - **Given** a focused window at normal bounds
  - **When** the user presses `⌃⌥↑` (Maximize)
  - **Then** the window fills 100% of visible screen bounds and pre-snap bounds are saved
  - **And** when the user subsequently presses `⌃⌥↓` (Restore), the window returns to its pre-snap frame.

- **Scenario 2.3 (Rapid Consecutive Keystrokes & Debouncing)**:
  - **Given** a window undergoing rapid consecutive hotkey inputs (`⌃⌥←` then immediately `⌃⌥→` within 30ms)
  - **When** commands are dispatched
  - **Then** `CommandDispatcher` cancels/drops the superseded snap task
  - **And** executes the latest intent (`Right Half`) without queue pile-up.

- **Scenario 2.4 (Guard - No Focused Window)**:
  - **Given** no focused application window (e.g. Finder desktop or modal alert active)
  - **When** a global hotkey is pressed
  - **Then** `CommandDispatcher` exits gracefully with zero errors and no crash.

---

### Story 3: Human-Readable Shortcut Formatting

**ID**: `US-SNAP-004.3`  
**As a** user viewing shortcuts in the Menu Bar or preferences,  
**I want** keyboard shortcuts to display clean macOS modifier glyphs,  
**So that** I can intuitively read which keys to press (e.g., `⌃⌥←`, `⌃⌥1`).

#### Acceptance Criteria (Given-When-Then):

- **Scenario 3.1 (Modifier & Key Code Rendering)**:
  - **Given** a `KeyboardShortcut` with `controlKey + optionKey` and Left Arrow keycode
  - **When** accessing `.displayString`
  - **Then** the output string is `"⌃⌥←"`.

# Elicitation: Settings UI & Shortcut Customization (US-SNAP-010)

## Problem & Pain Points
1. **Shortcut Inflexibility**: Users who use competing apps (Rectangle, Magnet, Raycast, BetterTouchTool) have ingrained muscle memory for different shortcut combinations. Fixed hardcoded shortcuts create high switching friction.
2. **Shortcut Collisions & Conflicts**: Without conflict detection, users can accidentally bind identical key combinations to multiple snap actions, leading to non-deterministic behavior.
3. **Behavioral Customization**: Users want to toggle Drag-to-Snap on/off, adjust preview dwell timing, and configure launch at login without editing property lists.

## Confirmed Domain Decisions & Baseline (6 Domain Pillars)

### 1. RBAC & Access Control
- Standard macOS user context. No elevated privileges required for preferences editing.
- Accessibility permission status is displayed with live status indicator and quick link to System Settings.

### 2. State Machine & Lifecycle
- `ShortcutRecorderField` finite state machine:
  - `idle`: Displays current shortcut glyph or "Record Shortcut" placeholder.
  - `recording`: Listens to incoming keydown events. Outer border pulses / glows accent color.
  - `conflict`: Indicates if the newly recorded combination clashes with an existing FlowSnap shortcut.
  - `cancelled`: Pressing Escape reverts to prior shortcut without changes.
  - `cleared`: Pressing Backspace/Delete or clicking (x) clears the shortcut (sets to unassigned/nil).

### 3. Business Rules & Formulas
- **BR-SET-001 (Configurable Actions)**: FlowSnap supports customizing shortcuts for 10 core window actions (Left Half, Right Half, Top Half, Bottom Half, Maximize, Restore, Top-Left, Top-Right, Bottom-Left, Bottom-Right) and optional display navigation (Next Display, Previous Display).
- **BR-SET-002 (Modifier Requirement)**: Custom shortcuts must include at least one modifier key (`⌃`, `⌥`, `⌘`, or `⇧`) to avoid capturing alphanumeric typing keys.
- **BR-SET-003 (Conflict Detection)**: If a user attempts to record a shortcut already assigned to another action, FlowSnap displays a visual conflict badge and highlights the clashing action.
- **BR-SET-004 (Reset to Defaults)**: A dedicated "Restore Defaults" button resets all shortcuts to the default 8 Carbon bindings (`⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`, `⌃⌥1..4`).
- **BR-SET-005 (Instant Persistence & Dynamic Re-registration)**: Any shortcut change in `PreferencesStore` immediately updates `UserDefaults` and signals `GlobalHotkeyManager` to re-register Carbon hotkey handlers without requiring app restart.
- **BR-SET-006 (Drag-to-Snap Preferences)**: Users can toggle Drag-to-Snap on/off (`isDragToSnapEnabled`) and choose dwell timing presets (50ms Fast, 150ms Normal, 300ms Relaxed).

### 4. Workflows & Edge Cases
- **Escape Key**: Exits shortcut recording mode immediately.
- **System Reserved Keys**: Warns or disallows reserved system keys (e.g. Cmd+Tab, Cmd+Space).
- **Unassigned Shortcuts**: Actions can be left unassigned without errors.

### 5. Data & Privacy
- Stored exclusively in local `UserDefaults` under `com.flowsnap.app` domain. Zero network telemetry.

### 6. UX / NFRs
- Native macOS look and feel with 4 standard tabs: General, Shortcuts, App Rules, About.
- Responsive layout (minimum size 540x440), smooth transitions, high contrast WCAG AA compliant badges.

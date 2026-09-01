# 01 — Elicitation Record (Stage 2) — window-groups-presets

> Interview anchored on roadmap AC for US-WORK-012. Only underspecified / high-risk branches were grilled.
> Confirmed decisions: `ASM-GROUP-001`, `ASM-GROUP-002`, `ASM-GROUP-003`.

## Confirmed Decisions

### ASM-GROUP-001 — Smart App Category Fallbacks for Built-in Presets

- **Decision**: Built-in Presets specify intentional application categories (`.editor`, `.browser`, `.terminal`, `.notes`, `.design`, `.document`) with prioritized fallback bundle ID lists.
  - **Editor**: `["com.microsoft.VSCode", "com.apple.dt.Xcode", "com.panic.Nova", "com.apple.TextEdit"]`
  - **Browser**: `["com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser", "com.brave.Browser"]`
  - **Terminal**: `["com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty", "io.alacritty"]`
  - **Notes / Knowledge**: `["com.apple.Notes", "notion.id", "md.obsidian"]`
  - **Writing / Docs**: `["com.apple.Pages", "com.microsoft.Word", "com.apple.TextEdit"]`
  - **Design**: `["com.figma.Desktop", "com.bohemiancoding.sketch3", "com.adobe.illustrator"]`
- **Resolution Strategy**:
  1. If a matching application from the fallback chain is already running with open windows, map that window immediately.
  2. If none are running, resolve the first installed application in the chain via `NSWorkspace.urlForApplication(withBundleIdentifier:)` and launch it with public `NSWorkspace.open`.
  3. If no candidate app is installed on the Mac, skip that placement slot and report gracefully in `RestoreSummary`.
- **Rationale**: Eliminates hardcoded app lock-in. A user without VS Code gets Xcode or TextEdit seamlessly without breaking the layout ratio.

### ASM-GROUP-002 — Window Group Synchronization & Dynamic Lifecycle

- **Decision**: `WindowGroup` establishes a live synchronized link across 2 or more managed windows (`CGWindowID`).
  - **Simultaneous Minimize / Unminimize**: Minimizing any grouped window automatically minimizes all member windows in the group; restoring/un-minimizing one un-minimizes the entire group.
  - **Simultaneous Focus / Bring to Front**: Activating any grouped window brings all member windows to the front while preserving relative z-order.
  - **Simultaneous Move / Space Shift**: Dragging or snapping a group anchor window can reposition the associated group members across displays or zones.
  - **Lifecycle & Auto-Pruning**: Groups are managed by `WindowGroupManager` in memory. As windows close (`kAXUIElementDestroyedNotification`), the group automatically removes the window. If fewer than 2 windows remain, the group cleanly dissolves.
  - **Preset Auto-Grouping**: Applying a preset offers an option (default: true) to link the restored windows into a live `WindowGroup`.
- **Rationale**: Provides macOS users with cohesive workspace grouping without requiring private window-server hacks or containerized spaces.

### ASM-GROUP-003 — Global Hotkey Routing & Collision Prevention

- **Decision**: Presets and user Workspaces support dedicated, customizable global keyboard shortcuts routed via `CommandDispatcher.dispatch(.restorePreset(id))` and `CommandDispatcher.dispatch(.restoreWorkspace(id))`.
  - Default preset shortcuts:
    - Coding: `⌃⌥C` (Control + Option + C)
    - Research: `⌃⌥R` (Control + Option + R)
    - Writing: `⌃⌥W` (Control + Option + W)
    - Design: `⌃⌥D` (Control + Option + D)
  - Collision Prevention: `PreferencesStore` and `ShortcutRecorderField` validate candidate key combinations against existing snap commands (`ShortcutAction.allCases`). Collisions are rejected in UI with explicit feedback.
- **Rationale**: Provides instant muscle-memory switching between workflows while maintaining zero conflict with core snapping hotkeys.

---

## Anchored (not re-asked) — settled by roadmap AC & tech context

- **Stack & Concurrency**: Swift 6 strict concurrency (`Sendable`, actor isolation, zero data races).
- **Public API Policy**: Exclusively Public macOS APIs (`NSWorkspace`, AX API, AppKit / SwiftUI); zero private CGS APIs.
- **Persistence**: Built-in presets are static code constants (`PresetFactory`); user customizations & hotkeys persist to `PreferencesStore` (UserDefaults); custom saved workspaces persist to `workspaces.json` via `WorkspaceStore`.
- **Display Geometry**: Intent-based layout mapping recomputed against the active display's `visibleBounds`.
- **Error Handling**: Graceful degradation; timeout on app launch (≤10s); no force unwraps (`!`), no `try!`, no `as!`.

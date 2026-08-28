# Risk Register & Scope Lock: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

## 1. Risk Register

| Risk ID         | Description                                                                                            | Impact | Probability | Mitigation Strategy                                                                                                                                  |
| :-------------- | :----------------------------------------------------------------------------------------------------- | :----- | :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RISK-MENU-001` | Focusing MenuBar steals focus from target window, causing `focusedWindow()` to return FlowSnap or nil. | High   | High        | Cache `lastFocusedWindow` before menu activates, or query window list for the frontmost third-party process during action dispatch.                  |
| `RISK-MENU-002` | `MenuBarExtra` style differences in SwiftUI macOS 14+ (Menu vs Window style event handling).           | Med    | Med         | Use standard clean SwiftUI view or AppKit `NSStatusItem` + `NSPopover` with `@MainActor` control to ensure reliable dismissal and click propagation. |
| `RISK-MENU-003` | Permission state polling overhead causing CPU wakeups.                                                 | Low    | Low         | Check permission lazily when menu opens or on app activation/notification rather than continuous timer polling.                                      |

---

## 2. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - Menu Bar status item with dark/light mode icon.
  - Background agent app execution (`LSUIElement = true`).
  - Interactive quick snap controls (Left, Right, Maximize, Restore, 4 Corners).
  - Accessibility permission indicator & direct link to macOS Privacy & Security.
  - Auto-dismiss on snap click and target window focus restoration.
  - Settings and Quit buttons.
- **Won't-Have (US-SNAP-005 Scope)**:
  - Custom drag-and-drop rearrangement of menu items (deferred to Settings Epic 9).
  - Workspace restoration dropdown list (deferred to Workspace Epic 10).
  - Update check network engine (Sparkle / GitHub API integration in future release).

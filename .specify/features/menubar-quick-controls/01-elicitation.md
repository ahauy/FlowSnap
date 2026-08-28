# Elicitation Record: US-SNAP-005 Menu Bar Status Item & Quick Snap Controls

## 1. Interview Summary & Confirmed Answers

- **Date**: 2026-08-28
- **Participants**: User (PO/Architect) & Business Analyst Agent

### Question 1: Target Window Resolution & Menu Dismissal

- **Confirmed Decision**: **Option A (Snap Active App & Auto-Dismiss)**
- **Detail**: When opening or clicking in the Menu Bar dropdown, the system captures/retains the previously frontmost application window (`lastFocusedWindow`). When any Quick Snap action button is triggered, the command executes on this window, the menu/popover is automatically dismissed, and focus is restored to the snapped target window.

### Question 2: Accessibility Permission Status & Indicator

- **Confirmed Decision**: **Option A (Contextual Warning Banner & Quick Fix)**
- **Detail**: If Accessibility permission (`AXIsProcessTrustedWithOptions`) is not granted or gets revoked, the Menu Bar displays a warning badge / indicator icon, and the top section of the dropdown presents a contextual warning banner: `⚠️ Accessibility Permission Required [Grant Permission]`. Clicking it directly opens macOS System Settings > Privacy & Security > Accessibility. Once granted, the warning banner is automatically hidden and the standard snap grid is displayed.

---

## 2. Identified Assumptions & Scope Boundaries

- `ASM-MENU-001`: Menu Bar item operates as a standard macOS agent item (`LSUIElement = true`), with zero dock icon.
- `ASM-MENU-002`: Menu bar layout provides quick snap actions for Left Half, Right Half, Top Half, Bottom Half, Maximize, Restore, Top-Left, Top-Right, Bottom-Left, Bottom-Right, accompanied by shortcut badges (e.g. `⌃⌥←`).
- `ASM-MENU-003`: System section includes: Check for Updates (placeholder/disabled or version info in Sprint 1), Settings (`⌘,` or opens settings scene), Quit FlowSnap (`⌘Q`).

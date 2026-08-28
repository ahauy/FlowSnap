# Domain Decision Baseline: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0  
**Feature Slug**: `menubar-quick-controls`  
**Date**: 2026-08-28

---

## 1. Executive Summary

FlowSnap requires a permanent, accessible macOS Menu Bar presence that acts as a low-friction control hub for window snapping, permission status monitoring, and app management.

This baseline establishes:

1. **Background Agent Architecture**: The app operates with `LSUIElement = true` (zero Dock icon), staying resident in the system status bar (`NSStatusItem`).
2. **Auto-Dismiss & Target Window Resolution**: Snapping via the Menu Bar targets the most recently active non-FlowSnap window, automatically dismisses the menu/popover, and restores focus seamlessly.
3. **Accessibility Permission Feedback**: If accessibility permissions are not granted or revoked, a contextual warning banner with a direct system settings link is surfaced; when granted, clean snap controls are displayed.
4. **Comprehensive Quick Snap Matrix**: Instant mouse access to Halves (Left, Right, Top, Bottom), Full/Restore (Maximize, Restore), and Quarters (4 Corners) complete with keyboard shortcut reference badges.
5. **System Actions**: Standard Mac menu entries for Settings (`⌘,`) and Quit (`⌘Q`).

---

## 2. Settled Elicitation & Grilling Decisions

| Item                                              | Decision                                             | Rationale                                                                                                                                                    |
| :------------------------------------------------ | :--------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Q1: Target Window Resolution & Menu Dismissal** | **Option A (Snap Active App & Auto-Dismiss)**        | Retains the last active app window before menu interaction, executes snap, auto-dismisses dropdown, and restores focus for frictionless workflow continuity. |
| **Q2: Accessibility Status Indicator**            | **Option A (Contextual Warning Banner & Quick Fix)** | Surfaces interactive warning banner when permissions are missing with a 1-click link to System Settings, automatically hiding once permission is granted.    |

---

## 3. Core Business Rules

- **BR-MENU-001 (Agent App Execution)**: `LSUIElement = true` ensures background operation without Dock clutter.
- **BR-MENU-002 (Target Window Preservation)**: Resolves and snaps the frontmost non-FlowSnap window.
- **BR-MENU-003 (Instant Action & Auto-Dismiss)**: Dispatches via `CommandDispatcher`, closes menu, and returns focus.
- **BR-MENU-004 (Permission Status Feedback)**: Displays warning banner and deep-links to macOS Accessibility preferences if unprivileged.
- **BR-MENU-005 (Quick Snap Grid Layout)**: Visual buttons for 8 canonical snap zones plus Maximize and Restore.
- **BR-MENU-006 (Standard System Actions)**: Direct access to Settings and clean Quit handling.

---

## 4. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - Menu Bar status item with dynamic Light/Dark mode icon.
  - Quick snap buttons for Left, Right, Maximize, Restore, Top, Bottom, and 4 Quarters.
  - Accessibility permission warning banner & deep-link when untrusted.
  - Auto-dismiss on snap click and target window focus restoration.
  - Settings and Quit buttons.
- **Won't-Have (US-SNAP-005 Scope)**:
  - Custom drag-and-drop menu item customization (deferred to Epic 9).
  - Workspace preset dropdown lists (deferred to Epic 10).

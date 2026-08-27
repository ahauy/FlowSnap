# Elicitation Record: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Date**: 2026-08-27
- **Feature Slug**: `accessibility-window-discovery`
- **Protocol Depth**: Bounded Task (Light interview, skipping Stage 3 gap-analysis)

---

## Stage 1 — Business Value

- **Problem & Pain Point**:
  FlowSnap relies on macOS Accessibility APIs (`AXUIElement`) to detect, inspect, and resize windows. Without Accessibility permissions, the app cannot operate. Additionally, querying windows naively can cause crashes or corrupt system UI (e.g. attempting to resize Spotlight, menubar extras, or modal sheets).
- **Target Personas**:
  All macOS FlowSnap users (Engineers, Designers, Knowledge Workers) who need fast, seamless window snapping without permission friction or UI errors.
- **Success Metrics**:
  - P95 latency of focused window discovery < 10ms.
  - Zero crashes when querying non-standard, headless, or permission-restricted windows.
  - 100% accurate classification between snappable standard windows (`.normal`) and dialogs/sheets/system panels.

---

## Pillar 1 — Accessibility Permission & Recovery Workflow

**Q1: Permission Prompting & Dynamic Recovery**

- **Decision**: **Option A** (Confirmed by User).
  Show a lightweight, non-blocking alert with an **"Open System Settings"** button directing to `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
  FlowSnap observes application activation (`NSApplication.didBecomeActiveNotification`) and runs a 1-second polling timer while active to dynamically detect when the user grants permission without requiring an app relaunch.

---

## Pillar 2 — System Windows & Non-Snappable Window Classification

**Q2: System Windows & Non-Snappable Window Classification**

- **Decision**: **Option A** (Confirmed by User).
  Strict filtering based on `kAXRoleAttribute` and `kAXSubroleAttribute`. Only windows with `kAXRoleAttribute == kAXWindowRole` and `kAXSubroleAttribute == kAXStandardWindowSubrole` (with `kAXSizeAttribute` resizable) are classified as `.normal` (snappable).
  Floating panels, modal sheets, dialogs, and system widgets are classified as `.dialog`, `.sheet`, or `.system` and safely excluded from snapping.

---

## Pillar 3 — Fallback Identity for Headless or Empty-Title Windows

**Q3: Fallback Identity for Headless or Empty-Title Windows**

- **Decision**: **Option A** (Confirmed by User).
  Extract `pid` via `AXUIElementGetPid()`, query `NSRunningApplication(processIdentifier: pid)` for `localizedName` and `bundleIdentifier`. If `kAXTitleAttribute` is empty or nil, fallback to `localizedName` (e.g., "Google Chrome", "Terminal") so `ManagedWindow.title` remains descriptive and non-empty.

---

## Assumptions Confirmed

- **ASM-SNAP-001**: Permission polling occurs at a 1-second interval only when the app is active / settings window is visible, avoiding idle CPU/battery wakeups.
- **ASM-SNAP-002**: Only standard application windows (`kAXWindowRole` + `kAXStandardWindowSubrole`) with settable `kAXSizeAttribute` are eligible for window snapping.
- **ASM-SNAP-003**: Windows lacking `kAXTitleAttribute` fallback to `NSRunningApplication.localizedName` or `"Unknown Window"` if localizedName is also unavailable.
- **ASM-SNAP-004**: `AXUIElement` references are strictly retained within the Infrastructure layer (`AXAccessibilityService`) and never passed to Domain or Core layers.

---

## Open Questions

- None. All 3 elicitation questions confirmed by user (`1A, 2A, 3A`).

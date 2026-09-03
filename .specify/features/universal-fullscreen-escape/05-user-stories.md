# 05 — User Stories & Acceptance Criteria — universal-fullscreen-escape

## Feature: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-019)

As a macOS Power User restoring a workspace or moving windows,  
I want FlowSnap to reliably exit Full Screen mode for any application—including Electron and Chromium apps like VS Code, Brave, Slack, or Antigravity,  
So that my multi-window layout can be restored seamlessly without windows getting stuck in separate fullscreen spaces.

---

### Scenario 1: Native Cocoa Application Exits via Fast Attribute Write (Tier 0)

**Given** an open window of a standard Cocoa application (e.g. Safari, TextEdit, Finder) in Full Screen mode  
**When** FlowSnap requests to reposition or restore the window  
**Then** FlowSnap sets `AXFullscreen = false` via `AXUIElementSetAttributeValue`  
**And** the attribute write succeeds immediately (< 1ms)  
**And** FlowSnap proceeds to the adaptive polling phase without triggering Tier 1 or Tier 2.

---

### Scenario 2: Electron Application Exits via AX FullScreen Button Press (Tier 1)

**Given** an open window of an Electron/Chromium application (e.g. VS Code, Brave) in Full Screen mode  
**When** FlowSnap attempts Tier 0 attribute write and receives `cannotComplete`  
**Then** FlowSnap automatically cascades to Tier 1  
**And** FlowSnap locates the window's Full Screen button via `kAXFullScreenButtonAttribute`  
**And** FlowSnap executes `AXUIElementPerformAction(button, kAXPressAction)`  
**And** the window initiates the macOS space exit transition.

---

### Scenario 3: Custom Application Exits via Synthesized `⌃⌘F` CGEvent (Tier 2)

**Given** an application in Full Screen mode where both attribute write fails and no AX Full Screen button is exposed  
**When** FlowSnap triggers the escape sequence  
**Then** FlowSnap cascades to Tier 2  
**And** FlowSnap activates the target application via `NSRunningApplication.activate`  
**And** FlowSnap posts a `Control + Command + F` key event sequence directly to the target application's PID via `CGEvent`  
**And** the macOS WindowServer receives the shortcut and triggers the Full Screen exit animation.

---

### Scenario 4: Adaptive Polling Returns Early Upon Space Transition

**Given** an application that has received an exit Full Screen signal  
**When** the system completes the space exit animation in 300ms  
**Then** FlowSnap's adaptive polling loop detects that the window frame no longer spans the full display  
**And** FlowSnap terminates the wait early at 300ms (instead of waiting the full 800ms budget)  
**And** immediately applies the desired target frame via `setFrame`.

---

### Scenario 5: Non-Destructive Failure Handling

**Given** a stubborn or unresponsive window where all 3 escape tiers fail to trigger an exit  
**When** the 800ms timeout budget is reached  
**Then** FlowSnap logs a diagnostic warning message  
**And** does not throw an unhandled fatal error or crash  
**And** continues restoring the remaining windows in the workspace pass.

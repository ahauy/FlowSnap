# Test Plan: 3D Interactive macOS Desktop Simulator (US-WEB-026)

**Feature slug**: `web-desktop-sandbox`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)
**Traces to**: `.specify/features/web-desktop-sandbox/06-spec-and-stories.md`

---

## Component & E2E Test Cases

### Suite: Virtual macOS Desktop & Mock Window (`DesktopSimulator.astro`)

#### TC-001: Desktop frame & initial mock window geometry

```gherkin
Given the DesktopSimulator component is mounted on the page
When  the DOM is ready
Then  the virtual desktop frame has a 16:10 aspect ratio with macOS Menu Bar and Dock
  And the mock window is positioned in the center floating area (approx 20% left, 20% top)
  And the mock window titlebar displays traffic lights and badge "Zone: Free Float"
  And the code editor renders the Swift 6 snippet without text overflow
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-001`, `REQ-SANDBOX-001`, `REQ-SANDBOX-002`

---

#### TC-002: Drag window to top edge triggers Top-Edge Picker

```gherkin
Given the mock window is at floating position
When  the user drags the titlebar to Y <= 32px of the virtual desktop top edge
Then  the Top-Edge Layout Picker slides down from the top edge
  And 4 layout template cards are displayed (2 Columns 50/50, 2 Columns 70/30, 3 Columns, 4 Quarters)
  And dragging preserves pointer capture without cursor slip
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-001`, `REQ-SANDBOX-003`

---

#### TC-003: Hover zone in picker activates HUD Preview and snap release

```gherkin
Given the mock window is being dragged and Top-Edge Picker is open
When  pointer hovers over "Left 50%" zone card
Then  the "Left 50%" zone card is highlighted
  And the translucent HUD Preview overlay expands over the left 50% of the desktop
When  the user releases the pointer (pointerup)
Then  the mock window animates to Left 50% bounds with spring easing
  And the Top-Edge Picker slides back up to closed state
  And the window titlebar badge updates to "Zone: Left 50%"
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-002`, `REQ-SANDBOX-004`, `REQ-SANDBOX-005`

---

#### TC-004: Direct desktop edge snap (left and right edges)

```gherkin
Given the mock window is being dragged
When  pointer moves within 24px of the virtual desktop's left edge
Then  the HUD Preview activates for Left 50%
When  pointer moves within 24px of the right edge
Then  the HUD Preview activates for Right 50%
When  pointer is released near the right edge
Then  the mock window snaps to the right 50% bounds
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-002`, `REQ-SANDBOX-004`

---

#### TC-005: 3D Perspective Tilt and IntersectionObserver pause

```gherkin
Given the simulator is visible in viewport
When  the user moves the pointer across the showcase section (without dragging)
Then  the desktop frame tilts via CSS transform rotateX and rotateY clamped to +/- 5 degrees
  And a dynamic glare highlight moves across the surface
When  prefers-reduced-motion is detected or user scrolls the showcase off-screen
Then  3D tilt is disabled or suspended with zero animation/pointer computation (0.0% idle CPU)
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-003`, `REQ-SANDBOX-006`

---

#### TC-006: Reset button and traffic light actions

```gherkin
Given the mock window is snapped to any zone
When  the user clicks the "Reset Sandbox" button
Then  the mock window transitions back to the center floating coordinates
  And the snap status badge returns to "Zone: Free Float"
When  the user clicks the Green traffic light button
Then  the window toggles to Maximize (fullscreen within desktop) and restores on second click
When  the user clicks the Red traffic light button
Then  the window resets to center floating coordinates
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-SANDBOX-004`, `REQ-SANDBOX-007`

---

#### TC-007: Mobile Quick-Snap Toolbar fallback

```gherkin
Given viewport width is mobile sized (< 768px)
When  the simulator is viewed
Then  the Quick Snap Toolbar displays below the desktop frame
When  the user taps "Left 50%" quick snap chip
Then  the mock window snaps directly to Left 50% bounds without requiring fine titlebar drag
```

**File**: `web/tests/desktop-simulator.spec.ts`
**Priority**: Should-Have
**Traces to**: `REQ-SANDBOX-007`

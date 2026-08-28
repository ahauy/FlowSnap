# User Stories: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature**: `display-aware-manipulation`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (User Stories Only for Bounded Task)

---

### Story 1: AppKit ↔ Accessibility Coordinate Inversion

**ID**: `US-SNAP-003.1`  
**As a** window management engine,  
**I want** to convert rectangular coordinates and points between AppKit (bottom-left origin) and Accessibility API (top-left of Primary screen origin),  
**So that** calculated layout frames are placed exactly on the screen without vertical inversion errors or multi-screen offsets.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 1.1 (Happy Path - Primary Display Frame)**:
  - **Given** a primary display with height `900` points
  - **When** converting an AppKit rect `(x: 0, y: 450, width: 720, height: 450)` (top half in AppKit) to AX coordinates
  - **Then** the resulting AX rect is `(x: 0, y: 0, width: 720, height: 450)`.

- **Scenario 1.2 (Happy Path - Exact Involution)**:
  - **Given** any valid rect `R` and primary screen height `H = 1080`
  - **When** converting `toAppKit(toAX(R, H), H)`
  - **Then** the recovered rect exactly matches `R` with zero precision loss.

- **Scenario 1.3 (Edge Case - Secondary Display with Negative Y in AppKit)**:
  - **Given** a primary display of height `1000` and an external display positioned below it (e.g. AppKit `y: -800, height: 800`)
  - **When** converting a window rect on that display to AX coordinates
  - **Then** the vertical inversion maintains absolute spatial consistency: $Y_{AX} = 1000 - (-800 + 800) = 1000$.

- **Scenario 1.4 (Sub-pixel Precision)**:
  - **Given** a frame with fractional coordinates `(x: 100.5, y: 200.25, width: 600.75, height: 400.5)` and primary height `900`
  - **When** converting to AX coordinates
  - **Then** fractional values are preserved identically: `(x: 100.5, y: 299.25, width: 600.75, height: 400.5)`.

---

### Story 2: Target Display Identification for Multi-Monitor Layouts

**ID**: `US-SNAP-003.2`  
**As a** multi-monitor macOS user,  
**I want** FlowSnap to detect which screen my window is on even when it straddles two displays,  
**So that** snap commands calculate layout zones against the screen where the majority of the window is visible.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 2.1 (Window straddling two screens)**:
  - **Given** Display 1 at `(0, 0, 1440, 900)` and Display 2 at `(1440, 0, 1920, 1080)`
  - **When** a window frame is `(1300, 100, 500, 400)` (having 140x400 = 56,000 pt² on Display 1 and 360x400 = 144,000 pt² on Display 2)
  - **Then** the target display resolved is Display 2 because it has the maximum intersection area.

- **Scenario 2.2 (Window fully within single display)**:
  - **Given** Display 1 and Display 2
  - **When** a window is entirely inside Display 1
  - **Then** the target display resolved is Display 1.

- **Scenario 2.3 (Window dragged off-screen with zero intersection)**:
  - **Given** two displays and a window positioned completely outside any screen bounds
  - **When** resolving the target display with current mouse cursor on Display 2
  - **Then** the target display falls back to Display 2 (cursor location).

---

### Story 3: Screen Parameters Reconfiguration & Mirrored Mode

**ID**: `US-SNAP-003.3`  
**As a** laptop user connecting external monitors or projecting slides,  
**I want** FlowSnap to automatically discover screen changes and handle mirrored displays cleanly,  
**So that** layout operations always target valid, non-redundant screens.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 3.1 (Screen Parameters Changed Notification)**:
  - **Given** a running `DisplayManager`
  - **When** `NSApplication.didChangeScreenParametersNotification` is broadcast by macOS
  - **Then** `DisplayManager` re-queries connected displays and updates its cached displays and primary screen height asynchronously.

- **Scenario 3.2 (Mirrored Displays Coalescing)**:
  - **Given** an external display mirroring the primary display
  - **When** querying `displays` on `DisplayManager`
  - **Then** only the master display is enumerated, avoiding duplicated identical targets.

---

### Story 4: Cross-Display Sequential Navigation

**ID**: `US-SNAP-003.4`  
**As a** power user with multiple displays,  
**I want** to query the next display in sequence,  
**So that** windows can be moved between monitors while keeping their relative layout.

#### Acceptance Criteria (Given-When-Then):

- **Scenario 4.1 (Cyclic Navigation across 2+ Displays)**:
  - **Given** Display A and Display B
  - **When** calling `nextDisplay(after: Display A)`
  - **Then** Display B is returned.
  - **When** calling `nextDisplay(after: Display B)`
  - **Then** Display A is returned (wrap-around).

- **Scenario 4.2 (Single Display Guard)**:
  - **Given** only Display A is connected
  - **When** calling `nextDisplay(after: Display A)`
  - **Then** `nil` is returned (no-op).

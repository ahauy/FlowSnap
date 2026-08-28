# Risk Register & Scope Lock: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature**: `display-aware-manipulation`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner (Bounded Task)

---

## 1. Risk Register

| Risk ID           | Category       | Description                                                                                                                                                            | Likelihood | Impact | Mitigation Strategy                                                                                                                                                                             |
| :---------------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------- | :----- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-DISP-001** | Geometry       | Secondary display placed above or left of primary screen has negative AppKit coordinates ($X < 0$ or $Y < 0$). Naive bounding assumptions would corrupt target frames. | High       | High   | `CoordinateTransformer` operates purely on algebraic arithmetic without clamping coordinates to positive quadrants. Mathematical unit tests cover negative origin geometries.                   |
| **RISK-DISP-002** | Hardware Drift | External display disconnected while user has windows on it; stale frames refer to non-existent display bounds.                                                         | Medium     | Medium | Target display detection computes intersection area against currently active displays. If intersection is zero, gracefully falls back to cursor display, then primary display (`ASM-DISP-004`). |
| **RISK-DISP-003** | Concurrency    | `NSApplication.didChangeScreenParametersNotification` posts on main thread while window snap requests occur across Swift 6 concurrency boundaries.                     | Medium     | Medium | `DisplayManager` is designed with strict concurrency compliance, using Actor isolation or `@MainActor` to serialize screen parameter reads.                                                     |
| **RISK-DISP-004** | Retina Drift   | Differing display scales (e.g. 1x external display + 2x Retina MacBook) might be conflated between points and physical pixels.                                         | Low        | High   | Standardize all layout and accessibility coordinates on logical points. Maintain `scaleFactor` strictly as metadata for UI/rendering layers.                                                    |

---

## 2. Consolidated Assumptions Register

| Assumption ID    | Description                                                                                                  | Source / Gate       |
| :--------------- | :----------------------------------------------------------------------------------------------------------- | :------------------ |
| **ASM-DISP-001** | Primary screen AppKit origin is always `(0, 0)`; its height $H_{Primary}$ is the global inversion reference. | Confirmed (Stage 2) |
| **ASM-DISP-002** | All AppKit and AX coordinates are expressed in points (logical units).                                       | Confirmed (Stage 2) |
| **ASM-DISP-003** | Target display selection uses maximum intersection area (`CGRectIntersection`).                              | Confirmed (Stage 2) |
| **ASM-DISP-004** | Off-screen windows with zero intersection area fallback to mouse cursor location, then Primary display.      | Confirmed (Stage 2) |
| **ASM-DISP-005** | Passive reactive updates: display parameters are updated on notification, but windows are not force-moved.   | Confirmed (Stage 2) |

---

## 3. Scope Lock (MoSCoW)

### Must-Have (P0)

- `Display` model with `isPrimary: Bool` and full geometry fields (`frame`, `visibleFrame`, `scaleFactor`).
- `CoordinateTransformer` pure math utility with bidirectional rect and point conversions between AppKit and AX coordinates.
- `DisplayManaging` protocol and production `DisplayManager` tracking `NSScreen.screens` and observing `didChangeScreenParametersNotification`.
- Target display resolution by maximum intersection area with cursor/primary fallback.
- Unit test suite verifying multi-monitor layouts (side-by-side, vertically stacked, negative origin offsets, mixed resolutions).

### Should-Have (P1)

- Mock display manager for deterministic multi-display unit testing without requiring physical displays.

### Won't-Have (Out of Scope for US-SNAP-003)

- Moving windows across macOS Spaces (Virtual Desktops) via private APIs (Strictly prohibited by FlowSnap Zero Private API policy).
- Automatic relocation of windows upon monitor disconnect (handled passively; windows snap when user triggers snap).

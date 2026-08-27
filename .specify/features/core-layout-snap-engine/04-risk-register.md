# Risk & Contradiction Register: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Date**: 2026-08-28
- **Feature Slug**: `core-layout-snap-engine`
- **Protocol Depth**: Bounded Task (Light risk scan and scope lock)

---

## 1. Consolidated Assumptions

| ID                 | Statement                                                                                       | Status    | Evidence / Confirmation             |
| :----------------- | :---------------------------------------------------------------------------------------------- | :-------- | :---------------------------------- |
| **ASM-LAYOUT-001** | Available screen area is always bounded by `visibleFrame`, excluding Menu Bar and Dock.         | Confirmed | Elicitation interview Q1            |
| **ASM-LAYOUT-002** | Odd-pixel dimensions allocate remainder to right/bottom partitions via flooring.                | Confirmed | Elicitation interview Q1 (Option A) |
| **ASM-LAYOUT-003** | Consecutive snaps preserve the initial user-positioned frame as the single restore destination. | Confirmed | Elicitation interview Q2 (Option A) |
| **ASM-LAYOUT-004** | Applications with minimum sizes exceeding snap zones anchor to the zone's outer edge/corner.    | Confirmed | Elicitation interview Q3 (Option A) |
| **ASM-LAYOUT-005** | `LayoutEngine` is 100% pure mathematics with zero dependencies on AppKit or Accessibility APIs. | Confirmed | DDD Deep Module rule                |

---

## 2. Risk Register & Mitigations

| Risk ID             | Description                                                                                                              | Severity | Likelihood | Mitigation Strategy                                                                                                                                                                            |
| :------------------ | :----------------------------------------------------------------------------------------------------------------------- | :------- | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-LAYOUT-001** | Coordinate confusion between AppKit (bottom-left) and Accessibility (top-left) in multi-screen setups.                   | High     | Medium     | `LayoutEngine` operates purely within localized `visibleBounds` ($x \in [0, W]$, $y \in [0, H]$). Hardware coordinate inversion across multiple screens is strictly isolated to `US-SNAP-003`. |
| **RISK-LAYOUT-002** | Fixed-size applications (e.g. System Settings, Calculator) clip or overflow screen edges when snapped to small quarters. | Medium   | High       | `BR-LAYOUT-005` anchors the window to the outer boundary and clamps dimensions to `max(calculated, minSize)` expanding inward, preventing off-screen drift.                                    |
| **RISK-LAYOUT-003** | Stale `preSnapFrame` remaining in memory after a window is closed.                                                       | Low      | Low        | `WindowRegistry.remove(windowId)` cleans up tracked frames when a window or process terminates.                                                                                                |

---

## 3. MoSCoW Scope Lock

### Must-Have (P0) — In Scope

- Pure calculation for 9 standard zones (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `maximize`).
- Odd-pixel floor allocation formula guaranteeing zero gaps and zero screen overflows.
- Pre-snap frame storage on initial snap and restoration via `restore` target.
- FlowSnapLab interactive verification buttons (`[Snap Left]`, `[Snap Right]`, `[Maximize]`, `[Restore]`).
- 100% unit test coverage across resolutions (1440x900, 1920x1080, 2560x1440, 3840x2160, portrait 1080x1920).

### Should-Have (P1)

- Optional `gap` parameter in `LayoutEngine` defaulting to 0px (ready for future gap styling).

### Won't-Have (Strictly Out of Scope for US-SNAP-002)

- Multi-monitor coordinate inversion and screen switching (`US-SNAP-003`).
- Global Carbon hotkeys and background daemon (`US-SNAP-004`).
- Menu Bar icon and Popover controls (`US-SNAP-005`).
- Drag-to-snap edge detection and HUD preview panel (`US-SNAP-006`).
- Asymmetric custom ratios (60/40, 70/30) and adaptive divider resizing (`US-SNAP-008`, `US-SNAP-009`).

# Data Model & Contracts: 3D Interactive macOS Desktop Simulator (US-WEB-026)

## 1. TypeScript Interfaces & Types

```typescript
/**
 * Canonical FlowSnap layout template identifiers for the Top-Edge Picker.
 */
export type SnapLayoutType =
  | "two-col-equal" // 50% / 50%
  | "two-col-asym" // 70% / 30%
  | "three-col" // 25% / 50% / 25%
  | "four-quarters"; // 4 x 25%

/**
 * Unique snap target zone identifiers.
 */
export type SnapZoneId =
  | "two-col-left"
  | "two-col-right"
  | "two-col-asym-left"
  | "two-col-asym-right"
  | "three-col-left"
  | "three-col-center"
  | "three-col-right"
  | "quarter-top-left"
  | "quarter-top-right"
  | "quarter-bottom-left"
  | "quarter-bottom-right"
  | "fullscreen";

/**
 * Normalized snap geometry percentages relative to the virtual desktop canvas.
 */
export interface SnapZoneGeometry {
  readonly id: SnapZoneId;
  readonly label: string;
  readonly leftPercent: number; // 0 - 100
  readonly topPercent: number; // 0 - 100 (relative to usable area)
  readonly widthPercent: number; // 0 - 100
  readonly heightPercent: number; // 0 - 100
}

/**
 * Definition of a layout template rendered inside the Top-Edge Snap Picker.
 */
export interface LayoutTemplateDefinition {
  readonly type: SnapLayoutType;
  readonly title: string;
  readonly zones: readonly SnapZoneGeometry[];
}

/**
 * Runtime state of the mock draggable window inside the simulator.
 */
export interface WindowRuntimeState {
  x: number; // px relative to virtual desktop
  y: number; // px relative to virtual desktop
  width: number; // px
  height: number; // px
  isDragging: boolean;
  isMaximized: boolean;
  activeZoneId: SnapZoneId | null;
  dragOffset: { x: number; y: number };
}

/**
 * 3D Perspective Tilt state.
 */
export interface PerspectiveTiltState {
  rotateX: number; // degrees (-5 to +5)
  rotateY: number; // degrees (-5 to +5)
  glareX: number; // percentage (0% to 100%)
  glareY: number; // percentage (0% to 100%)
  isHovered: boolean;
}
```

---

## 2. Canonical Layout Definitions

```typescript
export const CANONICAL_LAYOUT_TEMPLATES: readonly LayoutTemplateDefinition[] = [
  {
    type: "two-col-equal",
    title: "2 Columns (50 / 50)",
    zones: [
      {
        id: "two-col-left",
        label: "Left 50%",
        leftPercent: 0,
        topPercent: 0,
        widthPercent: 50,
        heightPercent: 100,
      },
      {
        id: "two-col-right",
        label: "Right 50%",
        leftPercent: 50,
        topPercent: 0,
        widthPercent: 50,
        heightPercent: 100,
      },
    ],
  },
  {
    type: "two-col-asym",
    title: "2 Columns (70 / 30)",
    zones: [
      {
        id: "two-col-asym-left",
        label: "Left 70%",
        leftPercent: 0,
        topPercent: 0,
        widthPercent: 70,
        heightPercent: 100,
      },
      {
        id: "two-col-asym-right",
        label: "Right 30%",
        leftPercent: 70,
        topPercent: 0,
        widthPercent: 30,
        heightPercent: 100,
      },
    ],
  },
  {
    type: "three-col",
    title: "3 Columns (25 / 50 / 25)",
    zones: [
      {
        id: "three-col-left",
        label: "Left 25%",
        leftPercent: 0,
        topPercent: 0,
        widthPercent: 25,
        heightPercent: 100,
      },
      {
        id: "three-col-center",
        label: "Center 50%",
        leftPercent: 25,
        topPercent: 0,
        widthPercent: 50,
        heightPercent: 100,
      },
      {
        id: "three-col-right",
        label: "Right 25%",
        leftPercent: 75,
        topPercent: 0,
        widthPercent: 25,
        heightPercent: 100,
      },
    ],
  },
  {
    type: "four-quarters",
    title: "4 Quarters (25% Each)",
    zones: [
      {
        id: "quarter-top-left",
        label: "Top Left",
        leftPercent: 0,
        topPercent: 0,
        widthPercent: 50,
        heightPercent: 50,
      },
      {
        id: "quarter-top-right",
        label: "Top Right",
        leftPercent: 50,
        topPercent: 0,
        widthPercent: 50,
        heightPercent: 50,
      },
      {
        id: "quarter-bottom-left",
        label: "Bottom Left",
        leftPercent: 0,
        topPercent: 50,
        widthPercent: 50,
        heightPercent: 50,
      },
      {
        id: "quarter-bottom-right",
        label: "Bottom Right",
        leftPercent: 50,
        topPercent: 50,
        widthPercent: 50,
        heightPercent: 50,
      },
    ],
  },
];
```

---

## 3. Geometry & Boundary Constants

| Constant              | Value                           | Description                                                             |
| :-------------------- | :------------------------------ | :---------------------------------------------------------------------- |
| `MENU_BAR_HEIGHT`     | `28px`                          | Height of the virtual top macOS menu bar                                |
| `DOCK_HEIGHT`         | `56px`                          | Height of the virtual bottom macOS dock area                            |
| `PICKER_TRIGGER_Y`    | `32px`                          | Cursor Y threshold from top edge to trigger picker slide-down           |
| `PICKER_DISMISS_Y`    | `70px`                          | Cursor Y threshold beyond which the picker closes if not over cards     |
| `EDGE_SNAP_THRESHOLD` | `24px`                          | Margin from desktop left/right/top edges to trigger direct edge preview |
| `MAX_3D_TILT_DEG`     | `5.0deg`                        | Maximum perspective rotation angle along X and Y axes                   |
| `SPRING_EASING`       | `cubic-bezier(0.16, 1, 0.3, 1)` | Apple-style spring easing for window snaps and transitions              |

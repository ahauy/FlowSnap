# Feature: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

- **Feature Slug**: `drag-to-snap-preview`
- **Epic**: `EPIC 06: Interactive Drag-to-Snap & HUD Snap Preview Overlay`
- **Sprint**: Sprint 2
- **Status**: Completed & Verified (`78/78` tests passing)

---

## 1. Background & Business Value

While keyboard shortcuts provide instant snapping for power users, mouse and trackpad users require an intuitive drag-to-snap interaction. `US-SNAP-006` introduces real-time mouse drag observation, display boundary zone detection, and a translucent Liquid Glass HUD Snap Preview overlay (`SnapPreviewPanel`) that snaps the window upon mouse release.

Key accomplishments:

1. **Passive Global Mouse Tracking (`MouseDragTracker`)**: Observes `.leftMouseDragged` and `.leftMouseUp` via `NSEvent.addGlobalMonitorForEvents` with a 60fps (~16ms) throttle cadence to prevent CPU overhead.
2. **Display-Aware Snap Zone Detection (`SnapDetector`)**: Evaluates cursor coordinates against display boundaries with a 4px threshold across 8 canonical zones (Left Half, Right Half, Top/Maximize, Bottom Half, and 4 Corners).
3. **Multi-Monitor Boundary Intelligence (`BR-DRAG-001`)**: Distinguishes outer display boundaries (100ms dwell threshold) from internal shared borders between adjacent displays (250ms dwell threshold), preventing accidental snaps when moving windows across screens.
4. **Liquid Glass HUD Preview Overlay (`SnapPreviewPanel` / `SnapPreviewView`)**: Floating, non-activating `NSPanel` rendering a translucent glassmorphic preview (`NSVisualEffectView` .hudWindow material / SwiftUI) with 10px corner radius and macOS accent highlight stroke (`Color.accentColor`).
5. **Release-to-Snap Execution (`BR-DRAG-004`)**: When `leftMouseUp` is received while a preview is active, the window is instantly snapped via `CommandDispatcher` and the preview overlay is dismissed.

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph UI ["UI Layer (SwiftUI + AppKit)"]
        SPP["SnapPreviewPanel (NSPanel, @MainActor)"]
        SPV["SnapPreviewView (SwiftUI Liquid Glass)"]
    end

    subgraph Core ["Core Layer"]
        DTC["DragToSnapCoordinator (@MainActor)"]
        SD["SnapDetector (Pure Geometry Math, Sendable)"]
        CD["CommandDispatcher (@MainActor)"]
        DM["DisplayManaging"]
        AX["AccessibilityService"]
    end

    subgraph Infra ["Infrastructure Layer"]
        MDT["MouseDragTracker (NSEvent Global Monitor)"]
    end

    MDT -->|OnDrag(point) / OnRelease(point)| DTC
    DTC -->|Query Active Display| DM
    DTC -->|Evaluate Zone & Adjacency| SD
    DTC -->|Show/Hide Preview Overlay| SPP
    SPP -->|Renders| SPV
    DTC -->|Dispatch Snap Command on Mouse Up| CD
```

---

## 3. Snap Zones & Dwell Timing Matrix

| Snap Zone        | Geometry Condition                                           | Dwell Threshold (Outer) | Dwell Threshold (Internal Adjacent) | Target Frame                |
| :--------------- | :----------------------------------------------------------- | :---------------------: | :---------------------------------: | :-------------------------- |
| **Left Half**    | $x \le \text{minX} + 4\text{px}$ (middle 60% height)         |          100ms          |                250ms                | Left 50% of visible frame   |
| **Right Half**   | $x \ge \text{maxX} - 4\text{px}$ (middle 60% height)         |          100ms          |                250ms                | Right 50% of visible frame  |
| **Maximize**     | $y \ge \text{maxY} - 4\text{px}$ (middle 60% width)          |          100ms          |                250ms                | 100% of visible frame       |
| **Bottom Half**  | $y \le \text{minY} + 4\text{px}$ (middle 60% width)          |          100ms          |                250ms                | Bottom 50% of visible frame |
| **Top-Left**     | Left edge $\cap$ top 20% or Top edge $\cap$ left 20%         |          100ms          |                250ms                | Top-Left 25% quadrant       |
| **Top-Right**    | Right edge $\cap$ top 20% or Top edge $\cap$ right 20%       |          100ms          |                250ms                | Top-Right 25% quadrant      |
| **Bottom-Left**  | Left edge $\cap$ bottom 20% or Bottom edge $\cap$ left 20%   |          100ms          |                250ms                | Bottom-Left 25% quadrant    |
| **Bottom-Right** | Right edge $\cap$ bottom 20% or Bottom edge $\cap$ right 20% |          100ms          |                250ms                | Bottom-Right 25% quadrant   |

---

## 4. Key Components & Deep Module Design

### 4.1 `SnapDetector` (`FlowSnap/Core/Layout/SnapDetector.swift`)

- Pure mathematical geometry engine implementing `SnapDetecting` (`Sendable`).
- Evaluates coordinates against screen bounds, partitions corners (20% ratio), and inspects adjacent displays for shared borders.

### 4.2 `MouseDragTracker` (`FlowSnap/Infrastructure/macOS/MouseDragTracker.swift`)

- Manages `NSEvent.addGlobalMonitorForEvents` for `.leftMouseDragged` and `.leftMouseUp`.
- Throttles mouse drag event processing to 60fps (~16ms cadence) to maintain $< 1\%$ CPU load.

### 4.3 `SnapPreviewPanel` (`FlowSnap/UI/SnapPreview/SnapPreviewPanel.swift`)

- Non-activating, floating `NSPanel` (`ignoresMouseEvents = true`) preventing focus disruption.
- Renders `SnapPreviewView` with Liquid Glass styling, 10px rounded corners, 1.5px accent stroke, and 150ms fade transitions.

### 4.4 `DragToSnapCoordinator` (`FlowSnap/Core/Layout/DragToSnapCoordinator.swift`)

- `@MainActor` state machine managing dwell timers, cancellation on move-away ($> 20\text{px}$), and snap execution on mouse release.

---

## 5. Verification & Testing

- **SnapDetector Unit Tests**: `FlowSnapTests/Core/SnapDetectorTests.swift` (7 test cases covering 4 halves, 4 corners, multi-monitor adjacency, and interior deadzones).
- **DragToSnapCoordinator Integration Tests**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift` (5 test cases covering outer vs adjacent dwell times, release-to-snap, move-away cancellation, and untrusted permission guards).
- **Total Test Suite**: `78/78` tests passing across 18 test suites.

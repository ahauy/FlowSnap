# Technical Architecture Plan: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

## 1. Architecture Overview

```mermaid
graph TD
    subgraph UI ["UI Layer (SwiftUI + AppKit)"]
        SPP["SnapPreviewPanel (NSPanel, @MainActor)"]
        SPV["SnapPreviewView (SwiftUI Liquid Glass)"]
    end

    subgraph Core ["Core Layer"]
        DTC["DragToSnapCoordinator (@MainActor)"]
        SD["SnapDetector (Pure Geometry Math, Sendable)"]
        SE["SnapEngine"]
        DM["DisplayManaging"]
        AX["AccessibilityServing"]
    end

    subgraph Infra ["Infrastructure Layer"]
        MDT["MouseDragTracker (NSEvent Global Monitor)"]
    end

    MDT -->|OnDrag(point) / OnRelease(point)| DTC
    DTC -->|Query Displays| DM
    DTC -->|Detect Zone(point, display, adjacent)| SD
    DTC -->|Show/Hide Preview Frame| SPP
    SPP -->|Embeds| SPV
    DTC -->|Snap active window on mouse up| SE
    SE -->|Move window| AX
```

---

## 2. Deep Module Decomposition & Seam Discipline

1. **`SnapDetector` (Deep Module)**:
   - _Public Interface_: A simple, minimal method `detectZone(at:on:adjacentDisplays:) -> SnapDetectionResult?`.
   - _Hidden Complexity_: Screen margin math, 4 corners vs 4 halves partition, and multi-monitor adjacent border detection. Zero dependency on macOS UI or AppKit classes.
2. **`MouseDragTracker` (Infrastructure Deep Module)**:
   - _Public Interface_: `startTracking(onDrag:onRelease:)`, `stopTracking()`, `isTracking`.
   - _Hidden Complexity_: `NSEvent` global monitor lifetime, memory leak prevention, event throttling cadence (60fps).
3. **`SnapPreviewPanel` & `SnapPreviewView` (UI Deep Module)**:
   - _Public Interface_: `show(frame:displayID:)`, `hide(animated:)`, `flash(frame:)`.
   - _Hidden Complexity_: Floating non-activating NSPanel setup, frame morphing animation, NSVisualEffectView glassmorphic blur with system accent outline.
4. **`DragToSnapCoordinator` (Core Coordinator)**:
   - _Public Interface_: `start()`, `stop()`, lifecycle binding in `AppDependencies`.
   - _Hidden Complexity_: Dwell timer state machine (100ms outer vs 250ms internal adjacent), coordinating between drag tracker, detector, preview panel, and snap engine.

---

## 3. Implementation Phases

### Phase 1: Domain & Contracts

- Create `SnapDetecting.swift`, `MouseDragTracking.swift`, `SnapPreviewManaging.swift` in `FlowSnap/Domain/Layout/` and `FlowSnap/Core/Layout/`.

### Phase 2: Core Snap Zone Geometry (`SnapDetector`)

- Implement `SnapDetector.swift` with 8 canonical zones and multi-monitor edge adjacency checks.
- Implement unit tests covering all 8 zones and single/multi-display scenarios.

### Phase 3: Infrastructure Mouse Drag Tracking (`MouseDragTracker`)

- Implement `MouseDragTracker.swift` in `FlowSnap/Infrastructure/macOS/` using `NSEvent.addGlobalMonitorForEvents`.
- Implement event throttling (16ms) and safe teardown.

### Phase 4: UI Preview Overlay (`SnapPreviewPanel` & `SnapPreviewView`)

- Enhance `SnapPreviewPanel.swift` and `SnapPreviewView.swift` in `FlowSnap/UI/SnapPreview/`.
- Add Liquid Glass blur, 10px corner radius, 1.5px accent stroke, and frame morphing / fade transitions.

### Phase 5: Core Coordinator & Integration (`DragToSnapCoordinator`)

- Implement `DragToSnapCoordinator.swift` in `FlowSnap/Core/Layout/`.
- Wire into `AppDependencies.swift` and `FlowSnapApp.swift` / `AppDelegate.swift`.

### Phase 6: Verification & Lab UI

- Add Drag-to-Snap test harnesses in `FlowSnapLab`.
- Run complete test suite (`swift test` / `xcodebuild test`).

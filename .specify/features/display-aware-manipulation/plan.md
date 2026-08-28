# Technical Implementation Plan: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature**: `display-aware-manipulation`
- **Architect**: `system-architect`
- **Status**: Ready for Review (Gate 2)

---

## 1. Architectural Architecture & Module Topology

```mermaid
graph TD
    subgraph Domain ["Domain Layer (Zero Framework Dependencies)"]
        D1["Display.swift (Sendable, isPrimary, scaleFactor)"]
    end

    subgraph Core ["Core Layer (Deep Modules, Pure Logic)"]
        C1["CoordinateTransformer.swift (Pure Math, Involution)"]
        C2["DisplayManaging.swift (Protocol, Spatial Queries)"]
        C3["SnapEngine.swift (Coordinates Display + Zone + AX Inversion)"]
    end

    subgraph Infrastructure ["Infrastructure Layer (AppKit / macOS System)"]
        I1["DisplayManager.swift (Actor, NSScreen, didChangeScreenParameters)"]
    end

    subgraph Tests ["Test Layer (Swift Testing @Test)"]
        T1["CoordinateTransformerTests.swift"]
        T2["DisplayManagerTests.swift"]
        T3["MultiMonitorSnapEngineTests.swift"]
    end

    subgraph Harness ["Harness Layer"]
        H1["FlowSnapLab (Live Multi-Display Inspector)"]
    end

    D1 --> C1
    D1 --> C2
    C1 --> C3
    C2 --> C3
    C2 --> I1
    C1 --> T1
    C2 --> T2
    C3 --> T3
    I1 --> H1
```

---

## 2. Implementation Slices

### Slice 1: Domain & Core Math (Data & Logic)

- Update `FlowSnap/Domain/Display/Display.swift` to add `isPrimary: Bool` with default initializer resolution (`frame.origin == .zero`).
- Implement `FlowSnap/Core/Display/CoordinateTransformer.swift` providing pure static bidirectional mapping:
  - `toAX(rect:primaryScreenHeight:)`
  - `toAppKit(rect:primaryScreenHeight:)`
  - `toAX(point:primaryScreenHeight:)`
  - `toAppKit(point:primaryScreenHeight:)`
- Implement failing test suite `FlowSnapTests/Core/CoordinateTransformerTests.swift` proving mathematical involution and edge cases (negative coordinates, sub-pixel precision).

### Slice 2: Core Abstraction & Infrastructure Adapter (API & System)

- Create `FlowSnap/Core/Display/DisplayManaging.swift` defining `displays`, `primaryDisplay`, `primaryScreenHeight`, `display(containing:)`, `display(for:cursorPoint:)`, and `nextDisplay(after:)`.
- Create `FlowSnap/Infrastructure/Display/DisplayManager.swift` actor:
  - Maps `NSScreen.screens` to `Display` domain entities.
  - Detects and coalesces mirrored screens using `CGDisplayIsInMirrorSet` and `CGDisplayMirrorsDisplay`.
  - Calculates maximum intersection area for windows straddling monitors.
  - Listens to `NSApplication.didChangeScreenParametersNotification` on MainActor and updates state.
- Create `FlowSnapTests/Infrastructure/DisplayManagerTests.swift` using mock screen topologies.

### Slice 3: SnapEngine Multi-Display Integration (Coordination)

- Enhance `FlowSnap/Core/Layout/SnapEngine.swift` to support display-aware snapping:
  - Resolves target display from `displayManager` if not explicitly specified.
  - Performs layout calculation in `targetDisplay.visibleFrame`.
  - Converts target AppKit frame to AX frame using `CoordinateTransformer.toAX(rect:primaryScreenHeight:)`.
  - Adds `calculateFrame(for:window:onNextDisplay:)` utilizing `displayManager.nextDisplay(after:)`.
- Create `FlowSnapTests/Core/MultiMonitorSnapEngineTests.swift`.

### Slice 4: FlowSnapLab & Verification

- Update `FlowSnapLabApp.swift` with multi-monitor inspection view.
- Run `xcodegen generate`.
- Run full test suite: `xcodebuild test -project FlowSnap.xcodeproj -scheme FlowSnapTests -destination 'platform=macOS'`.

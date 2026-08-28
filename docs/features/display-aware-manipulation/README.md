# Feature: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature Slug**: `display-aware-manipulation`
- **Epic**: `EPIC 03: Display-Aware Coordinate System & Multi-Monitor Support`
- **Sprint**: Sprint 1
- **Status**: Completed & Verified

---

## 1. Background & Business Value

In multi-monitor macOS setups (e.g. MacBook Retina + external 4K or ultra-wide displays arranged side-by-side or stacked), window management utilities frequently place windows on the wrong monitor or in negative off-screen space due to the fundamental inversion between macOS coordinate systems:

1. **AppKit (`NSScreen`)**: Origin `(0, 0)` at **bottom-left** of the Primary Screen; Y coordinates grow **upward**.
2. **Accessibility API (`AXUIElement`)**: Origin `(0, 0)` at **top-left** of the Primary Screen; Y coordinates grow **downward**.

`US-SNAP-003` establishes a rock-solid, display-aware foundation for FlowSnap:

- **Pure Functional Inversion (`CoordinateTransformer`)**: Self-inverse involution math with zero framework dependencies.
- **Dynamic Display Topology (`DisplayManager`)**: Tracks connected displays, handles display connect/disconnect events reactively, and coalesces mirrored displays to the mirror master.
- **Maximum Overlap Resolution (`BR-DISP-002`)**: Windows straddling multiple displays are accurately assigned to the display containing the largest visible intersection area.
- **Cross-Display Migration (`BR-DISP-006`)**: Enables seamless window movement across multiple monitors while preserving normalized snap zones.

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph UI ["UI Layer (FlowSnapLab)"]
        Lab["FlowSnapLabApp (@MainActor)"]
    end

    subgraph Core ["Core Layer (Pure Logic & Protocols)"]
        CT["CoordinateTransformer (Pure Math Involution)"]
        DMProto["protocol DisplayManaging (Sendable)"]
        SE["SnapEngine (Sendable)"]
    end

    subgraph Domain ["Domain Layer"]
        D["struct Display (Sendable)"]
        MW["struct ManagedWindow (Sendable)"]
    end

    subgraph Infrastructure ["Infrastructure Layer"]
        DM["DisplayManager (@MainActor, NSScreen, NotificationCenter)"]
        AX["AXAccessibilityService"]
    end

    Lab --> SE
    Lab --> DM
    SE --> DMProto
    SE --> CT
    DM ..|> DMProto
    DM ..> D
    SE ..> D
    SE ..> MW
    Lab --> AX
```

### Module Boundaries:

- **`Domain/Display/Display.swift`**: Immutable Sendable struct capturing `id`, `frame`, `visibleFrame`, `scaleFactor`, and `isPrimary`.
- **`Core/Display/CoordinateTransformer.swift`**: Pure static functions mapping `CGRect` and `CGPoint` between AppKit and AX coordinates using $H_{Primary}$.
- **`Core/Display/DisplayManaging.swift`**: Protocol abstracting display topology, spatial queries, and multi-monitor navigation.
- **`Infrastructure/Display/DisplayManager.swift`**: `@MainActor` implementation querying `NSScreen.screens`, coalescing mirrored screens, and observing screen parameter change notifications.
- **`Core/Layout/SnapEngine.swift`**: Coordinates layout calculation, target display resolution, and Accessibility API coordinate inversion.

---

## 3. Business Rules Implemented

| Rule ID         | Name                       | Description                                                                                                                                        |
| :-------------- | :------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| **BR-DISP-001** | Primary Reference Height   | Screen at AppKit `origin == .zero` is Primary Display. Its total frame height ($H_{Primary}$) anchors all global AX coordinate conversions.        |
| **BR-DISP-002** | Target Display Resolution  | Target display is resolved by `argmax(area(CGRectIntersection(windowFrame, displayFrame)))`. If zero, falls back to cursor location, then Primary. |
| **BR-DISP-003** | Inversion Involution Math  | AppKit-to-AX transformation is an exact involution: $Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$. Round-trip has zero floating point drift.      |
| **BR-DISP-004** | Reactive Screen Updates    | Listens to `didChangeScreenParametersNotification` to update display topologies asynchronously without disrupting existing windows.                |
| **BR-DISP-005** | Mirrored Screen Coalescing | Secondary mirrored displays are filtered out, preserving only the active primary mirror master.                                                    |
| **BR-DISP-006** | Cyclic Display Navigation  | For $\ge 2$ displays, `nextDisplay(after:)` cycles through displays ($0 \to 1 \to \dots \to 0$); returns `nil` for single screen.                  |
| **BR-DISP-007** | Sub-pixel Precision        | All coordinate transformations preserve exact `CGFloat` points without premature integer truncation.                                               |

---

## 4. Test Verification Summary

All 43 tests across 10 test suites pass with 100% success rate in 0.012 seconds:

- `CoordinateTransformerTests`: Standard inversions, mathematical involution roundtrip, negative coordinate external screens, and sub-pixel precision.
- `DisplayManagerTests`: Straddling window overlap resolution, contained window resolution, off-screen fallback to cursor, cyclic navigation, single screen guard, and primary screen height.
- `MultiMonitorSnapEngineTests`: Multi-monitor target frame calculation with AX inversion on primary and secondary displays, and cross-monitor zone migration.
- `AccessibilityServiceTests`: System permission states and active window discovery.
- `ManagedWindowTests`: Semantic window kind classification and hashing.
- `LayoutEngineTests`: Halves, quarters, and maximize calculations on standard resolutions.
- `LayoutEngineOddPixelTests`: Odd-pixel flooring policy and boundary isolation.
- `LayoutZoneTests`: Zone definitions and normalized rects.
- `WindowRegistryTests`: Actor-isolated thread-safe frame caching.
- `SnapEngineTests`: Snap coordination and restore lifecycle.

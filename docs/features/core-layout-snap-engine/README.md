# Feature: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Feature Slug**: `core-layout-snap-engine`
- **Epic**: `EPIC 02: Core Layout Calculation & Basic Snap Engine`
- **Sprint**: Sprint 1
- **Status**: Completed & Verified

---

## 1. Background & Business Value

While `US-SNAP-001` provided window discovery and metadata inspection via macOS Accessibility APIs, `US-SNAP-002` provides the pure mathematical brain of FlowSnap.

Without deterministic, hardware-independent geometric calculation, window snapping on macOS suffers from rounding errors that cause 1px gaps or borders clipped off-screen. Furthermore, when users snap windows, they frequently want to return to their free-form position; without tracking the pre-snap frame, restore functionality is impossible or unreliable.

This module delivers:

1. **Pure Functional Geometry (`LayoutEngine`)**: Zero side effects, zero system or AppKit dependencies. Computes exact pixel-perfect `CGRect` frames for 9 standard zones (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, 4 corner quarters, and `maximize`).
2. **Odd-Pixel Flooring Policy (`BR-LAYOUT-002`)**: Guarantees zero gaps and zero screen overflows when dividing odd-pixel dimensions (e.g. 1441x901) by allocating $\lfloor D/2 \rfloor$ to the primary half and $D - \lfloor D/2 \rfloor$ to the adjacent half.
3. **Pre-Snap Frame Preservation & Single-Step Restore (`BR-LAYOUT-004`)**: Records the user's initial window frame prior to the first snap and preserves it across consecutive snaps until consumed by a Restore action.
4. **Minimum Window Size Anchoring (`BR-LAYOUT-005`)**: Handles fixed-size applications gracefully by clamping to `max(calculated, minSize)` and anchoring to the target zone boundary, preventing off-screen drift.

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph UI ["UI Layer (FlowSnapLab)"]
        Lab["FlowSnapLabApp (@MainActor)"]
    end

    subgraph Core ["Core Layer"]
        SE["SnapEngine (Sendable)"]
        LE["LayoutEngine : LayoutCalculating"]
        WR["actor WindowRegistry"]
    end

    subgraph Domain ["Domain Layer"]
        LZ["enum LayoutZone (Sendable)"]
        ST["enum SnapTarget (Sendable)"]
        MW["struct ManagedWindow (Sendable)"]
        LC["protocol LayoutCalculating (Sendable)"]
    end

    subgraph Infrastructure ["Infrastructure Layer"]
        AX["AccessibilityService"]
    end

    Lab --> SE
    Lab --> WR
    SE --> LE
    SE --> WR
    SE --> AX
    LE ..|> LC
    LE ..> LZ
    SE ..> ST
    SE ..> MW
```

### Module Boundaries:

- **`Domain/Layout/LayoutZone.swift`**: 9-case enum (`leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `maximize`) with `normalizedRect`.
- **`Domain/Commands/SnapTarget.swift`**: Command destination supporting `.zone(LayoutZone)`, `.restore`, and `.layout(Layout)`.
- **`Core/Layout/LayoutCalculating.swift`**: Abstraction protocol for single-zone and multi-window layout computation.
- **`Core/Layout/LayoutEngine.swift`**: Pure mathematical layout calculation engine implementing the flooring policy.
- **`Core/Window/WindowRegistry.swift`**: Actor-isolated state maintaining window caches and `preSnapFrames`.
- **`Core/Layout/SnapEngine.swift`**: Coordinator handling pre-snap lifecycle, layout delegation, and minimum size clamping.

---

## 3. Business Rules Implemented

| Rule ID           | Name                      | Description                                                                                                            |
| :---------------- | :------------------------ | :--------------------------------------------------------------------------------------------------------------------- |
| **BR-LAYOUT-001** | Visible Bounds Isolation  | All calculation math operates strictly within the target display's `visibleFrame` (excluding macOS Menu Bar and Dock). |
| **BR-LAYOUT-002** | Odd-Pixel Flooring Policy | $Primary = \lfloor D / 2.0 \rfloor, \quad Adjacent = D - Primary$. Guarantees 0px gap and 0px screen overflow.         |
| **BR-LAYOUT-003** | Standard Zone Geometry    | 9 standard partition zones mapping deterministically to half, quarter, and maximize bounds.                            |
| **BR-LAYOUT-004** | Pre-Snap Preservation     | The user-dragged frame before the first snap is preserved across consecutive snaps and consumed upon Restore.          |
| **BR-LAYOUT-005** | Min Size Anchoring        | Applications with minimum dimensions exceeding snap zones clamp to `max(calc, minSize)` and anchor to outer edges.     |

---

## 4. Test Verification Summary

All 26 tests across 7 test suites pass with 100% success rate:

- `LayoutZoneTests`: All 9 cases, normalized coordinates, and Codable roundtripping.
- `LayoutEngineTests`: 50/50 splits on 1440x900 & 1920x1080, four quarters, maximize with Dock/Menu bar offsets, 2K/4K/portrait determinism, and multi-window layout mapping.
- `LayoutEngineOddPixelTests`: Odd-pixel width & height (1441x901), odd quarters, and offset origin math asserting zero gaps and zero overflow.
- `SnapEngineTests`: Consecutive snaps pre-frame preservation, single-step restore lifecycle, restore on unsnapped window as safe no-op, and minimum size boundary anchoring.
- `AccessibilityServiceTests`: Trusted/untrusted permission transitions and window discovery.
- `ManagedWindowTests`: Semantic classification and property invariants.
- `WindowRegistryTests`: Actor-isolated thread-safe state management.

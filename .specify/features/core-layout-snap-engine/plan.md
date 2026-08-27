# Architecture Plan: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Feature**: `core-layout-snap-engine`
- **Architect**: `system-architect`
- **Status**: Complete (Pending Gate 2 Review)
- **Derived from**: [spec.md](spec.md)

---

## 1. Technical Context & Stack Baseline

| Component / Layer   | Choice                                    | Rationale                                                              |
| :------------------ | :---------------------------------------- | :--------------------------------------------------------------------- |
| **Language**        | Swift 6.0                                 | Strict Concurrency (`Complete`), Sendable types, Actor isolation.      |
| **Architecture**    | Domain-Driven Design (DDD) & Deep Modules | Pure functional computation in `LayoutEngine`; zero AppKit/AX imports. |
| **Concurrency**     | Swift Actor (`WindowRegistry`)            | Thread-safe concurrent storage of pre-snap frames without data races.  |
| **Testing**         | Swift Testing (`@Test`) & XCTest          | Deterministic tests over multiple display resolution profiles.         |
| **Target Platform** | macOS 14.0+                               | Hardened Runtime enabled.                                              |

---

## 2. Architecture & Deep Module Seams

```mermaid
graph TD
    subgraph UI ["UI Layer (FlowSnapLab)"]
        Lab["FlowSnapLabApp (@MainActor)"]
    end

    subgraph Core ["Core Layer (Layout & State Coordination)"]
        SE["SnapEngine (Sendable)"]
        LE["LayoutEngine : LayoutCalculating"]
        WR["actor WindowRegistry"]
    end

    subgraph Domain ["Domain Layer (Pure Models)"]
        LZ["enum LayoutZone"]
        ST["enum SnapTarget"]
        MW["struct ManagedWindow"]
        LC["protocol LayoutCalculating"]
    end

    subgraph Infra ["Infrastructure Layer (macOS Window Control)"]
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

### Seam Discipline & Module Boundaries:

1. **Domain Layer**:
   - `LayoutZone`: Immutable enum (`Sendable`, `CaseIterable`, `Codable`, `Hashable`) defining the 9 canonical partitions.
   - `SnapTarget`: Value enum representing snap commands (`zone(LayoutZone)`, `restore`, `layout(Layout)`).
   - `LayoutCalculating`: Protocol separating layout calculation from window manipulation.
2. **Core Layer**:
   - `LayoutEngine`: Pure math deep module. Takes `LayoutZone`, available bounds `CGRect`, and optional gap. Returns concrete `CGRect`. Contains zero state and zero I/O.
   - `SnapEngine`: Coordinator. Interacts with `WindowRegistry` to record pre-snap bounds and dispatches target frames to `AccessibilityService`.
   - `WindowRegistry`: `actor` maintaining thread-safe `windows` and `preSnapFrames` mapping.
3. **Infrastructure Layer**:
   - `AccessibilityService`: Invoked by `SnapEngine` or caller to set window frames via `setFrame(_:for:)`.
4. **UI Layer (`FlowSnapLab`)**:
   - Provides quick interactive buttons to trigger Snap Left, Snap Right, Maximize, and Restore on the active focused window.

---

## 3. Mathematical Formula & Flooring Policy

Let $Origin = (X_{0}, Y_{0})$ and $Size = (W, H)$ represent the display's `visibleFrame`.

For any dimension split:
$$Half_{1} = \lfloor \text{Dimension} / 2.0 \rfloor$$
$$Half_{2} = \text{Dimension} - Half_{1}$$

### Zone Coordinate Definitions:

- `leftHalf`: Origin = $(X_{0}, Y_{0})$, Size = $(\lfloor W/2 \rfloor, H)$
- `rightHalf`: Origin = $(X_{0} + \lfloor W/2 \rfloor, Y_{0})$, Size = $(W - \lfloor W/2 \rfloor, H)$
- `topHalf`: Origin = $(X_{0}, Y_{0})$, Size = $(W, \lfloor H/2 \rfloor)$
- `bottomHalf`: Origin = $(X_{0}, Y_{0} + \lfloor H/2 \rfloor)$, Size = $(W, H - \lfloor H/2 \rfloor)$
- `topLeft`: Origin = $(X_{0}, Y_{0})$, Size = $(\lfloor W/2 \rfloor, \lfloor H/2 \rfloor)$
- `topRight`: Origin = $(X_{0} + \lfloor W/2 \rfloor, Y_{0})$, Size = $(W - \lfloor W/2 \rfloor, \lfloor H/2 \rfloor)$
- `bottomLeft`: Origin = $(X_{0}, Y_{0} + \lfloor H/2 \rfloor)$, Size = $(\lfloor W/2 \rfloor, H - \lfloor H/2 \rfloor)$
- `bottomRight`: Origin = $(X_{0} + \lfloor W/2 \rfloor, Y_{0} + \lfloor H/2 \rfloor)$, Size = $(W - \lfloor W/2 \rfloor, H - \lfloor H/2 \rfloor)$
- `maximize`: Origin = $(X_{0}, Y_{0})$, Size = $(W, H)$

---

## 4. Concurrency & Performance Budget

- **Thread Safety**:
  - `LayoutEngine` is a stateless struct conforming to `Sendable`.
  - `WindowRegistry` is an `actor`, eliminating concurrent mutation races for `preSnapFrames`.
  - `SnapEngine` methods are non-blocking or perform bounded local IPC calls.
- **Latency Budget**:
  - Layout computation: < 0.05ms per call (pure arithmetic).
  - Overall snap dispatch: < 5ms (including AX IPC call).

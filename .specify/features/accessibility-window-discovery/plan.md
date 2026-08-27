# Architecture Plan: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Feature**: `accessibility-window-discovery`
- **Architect**: `system-architect`
- **Status**: Complete (Pending Gate 2 Review)
- **Derived from**: [spec.md](spec.md)

---

## 1. Technical Context & Stack Baseline

| Technology / Layer | Choice                                           | Rationale                                                                                   |
| :----------------- | :----------------------------------------------- | :------------------------------------------------------------------------------------------ |
| **Language**       | Swift 6.0                                        | Strict concurrency checking (`Complete`), Sendable types, Actor isolation.                  |
| **Platform**       | macOS 14.0+ (Sonoma / Sequoia)                   | Native AppKit + SwiftUI; Hardened Runtime enabled.                                          |
| **OS Window API**  | `ApplicationServices.HIServices` (`AXUIElement`) | Only public Apple API capable of querying third-party application windows.                  |
| **Architecture**   | Domain-Driven Design (DDD) & Deep Modules        | Zero AXUIElement references leak outside Infrastructure; Domain is pure Swift.              |
| **Concurrency**    | Swift Concurrency                                | `@MainActor` for UI and AppKit bridges; `actor WindowRegistry` for thread-safe state.       |
| **Testing**        | Swift Testing (`@Test`) & Protocol Mocks         | Protocol-based DI container (`AppDependencies`) with zero production side effects in tests. |

---

## 2. Architecture & Deep Module Seams

```mermaid
graph TD
    subgraph UI ["UI Layer (FlowSnapLab / MenuBar)"]
        Lab["FlowSnapLabView (@MainActor)"]
    end

    subgraph Core ["Core Layer (Window Coordination)"]
        WM["WindowManager"]
        WR["actor WindowRegistry"]
    end

    subgraph Domain ["Domain Layer (Pure Models & Protocols)"]
        MW["struct ManagedWindow (Sendable)"]
        WK["enum WindowKind (Sendable)"]
        ASP["protocol AccessibilityService (Sendable)"]
    end

    subgraph Infra ["Infrastructure Layer (macOS Adapters)"]
        AX["final class AXAccessibilityService"]
        Router["struct SystemSettingsRouter"]
        AXAPI["macOS AXUIElement API"]
    end

    Lab --> WM
    WM --> WR
    WM --> ASP
    AX ..|> ASP
    AX --> AXAPI
    Router --> Infra
    WM --> MW
    WR --> MW
    MW --> WK
```

### Seam Discipline & Module Boundaries:

1. **Domain Layer**:
   - `ManagedWindow`: Immutable value type (`Sendable`, `Identifiable`, `Hashable`). Holds snapshot data (`id`, `pid`, `bundleIdentifier`, `title`, `frame`, `isResizable`, `kind`).
   - `WindowKind`: Enum categorizing standard vs modal vs system elements.
   - `AccessibilityService`: Domain/Core facing protocol abstracting low-level OS calls.
2. **Infrastructure Layer**:
   - `AXAccessibilityService`: Deep module encapsulating all CoreFoundation / AXUIElement complexity, memory management, and error handling. Core never imports `ApplicationServices`.
   - `SystemSettingsRouter`: Deep link handler for System Settings.
3. **Core Layer**:
   - `WindowRegistry`: Thread-safe `actor` maintaining recent window state.
4. **Testing Strategy**:
   - `MockAccessibilityService`: In-memory mock simulating trusted/untrusted states, missing titles, and varied window hierarchies for deterministic unit testing.

---

## 3. Concurrency & Performance Budget

- **Thread Safety**:
  - `AXAccessibilityService` methods are non-blocking or perform bounded local IPC calls.
  - `WindowRegistry` is an `actor` ensuring serial isolation for shared dictionary mutations.
  - UI surfaces (`FlowSnapLabView`) are `@MainActor` bound.
- **Latency Budget**:
  - `isTrusted`: < 1ms (`AXIsProcessTrustedWithOptions(nil)` is an in-process Mach port check).
  - `focusedWindow()`: < 8ms (Querying frontmost app pid + 1 copy attribute call). Total P95 well within the 10ms budget.
- **Memory Safety**:
  - Direct CoreFoundation release / Swift ARC bridging for all `CFTypeRef` values copied via `AXUIElementCopyAttributeValue`.

---

## 4. Build Configuration Fix

- Target `FlowSnapTests` in `project.yml` will be updated with:
  ```yaml
  settings:
    base:
      GENERATE_INFOPLIST_FILE: YES
  ```
  This resolves Xcode 16 bundle code signing failure during unit test runs.

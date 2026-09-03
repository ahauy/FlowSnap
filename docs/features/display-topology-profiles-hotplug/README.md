# Feature: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

- **Feature Slug**: `display-topology-profiles-hotplug`
- **Epic**: `EPIC 13: Advanced Multi-Monitor Topology & Cross-Display Navigation`
- **Sprint**: Sprint 4 (Multi-Monitor Excellence)
- **Status**: Completed & Verified (`376/376` tests passing, zero private CGS/SLS symbols)
- **Specifications**: [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/spec.md) | [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/baseline.md) | [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/plan.md) | [tasks.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/tasks.md) | [data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/data-model.md) | [ADR-0011](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0011-display-topology-profiles-hotplug.md)

---

## 1. Overview & Business Value

When external displays are connected or disconnected (e.g. plugging into a desk dock with multiple monitors, or unplugging to take the MacBook to a meeting), macOS abruptly shifts windows, often placing title bars off-screen, under the Menu Bar, or scrambling carefully arranged multi-window layouts.

`US-DISP-016` introduces **Display Topology Profiles & Hot-Plug Rebalancer**, turning FlowSnap into a multi-monitor adaptive workspace engine:

1. **Deterministic Topology Fingerprinting (`TopologyFingerprint`)**:
   - Computes a stable SHA-256 hash identifying the physical monitor setup using only public macOS APIs (spatial coordinate sorting, screen UUIDs, localized names, and visible bounds).
2. **Coalescing Debounce Observer (`DisplayHotPlugObserver`)**:
   - Listens to `NSApplication.didChangeScreenParametersNotification` with a 600ms coalescing timer.
   - Prevents "screen flapping" (multiple rapid-fire notification bursts) when waking from sleep or connecting multi-port docks.
3. **Hot-Unplug Proportional Clamping & Auto-Snapshot**:
   - When an external monitor is disconnected, FlowSnap auto-snapshots the departing multi-monitor arrangement.
   - Windows pushed onto the primary laptop display are clamped inside `primaryDisplay.visibleFrame` via `FrameClampingHelper`.
   - Guaranteed title bar safety (height ≥ 36pt), preventing windows from being lost under the Menu Bar or off the edges of the display.
4. **Zero-Prompt Auto-Restore on Reconnect**:
   - When a known monitor setup is reconnected, FlowSnap automatically retrieves the saved `DisplayTopologyProfile` and returns open windows to their designated screens and layout zones without interrupting the user.
5. **Missing Application Resilience**:
   - If an application recorded in a profile was closed prior to reconnecting, FlowSnap skips it gracefully without throwing errors or halting the restoration of remaining apps.

---

## 2. Architecture & Seam Discipline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    NSApplication.didChangeScreenParameters                   │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ notification
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                          DisplayHotPlugObserver                              │
│         (Infrastructure/Display/DisplayHotPlugObserver.swift)                │
│                                                                              │
│  • 600ms coalescing debounce timer (cancels in-flight tasks)                 │
│  • Compares new TopologyFingerprint against baseline                         │
│  • Emits: .hotPlugConnected / .hotUnplugDisconnected / .geometryChanged       │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ @MainActor event
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                          TopologyProfileManager                              │
│             (Core/Display/TopologyProfileManager.swift)                      │
│                                                                              │
│  • On Hot-Unplug:                                                            │
│       ├─ Auto-snapshot departing profile keyed by departing fingerprint      │
│       └─ Clamps off-screen windows into primaryDisplay.visibleFrame          │
│  • On Hot-Plug:                                                              │
│       ├─ Looks up profiles[fingerprint.rawValue]                             │
│       └─ Auto-restores placements to target screens with missing-app guard   │
│  • Persists profiles to UserDefaults (com.flowsnap.topologyProfiles)         │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
┌─────────────────────────┐                           ┌─────────────────────────┐
│   TopologyFingerprint   │                           │   FrameClampingHelper   │
│ (Domain/Display/        │                           │ (Core/Policy/           │
│  TopologyFingerprint.s) │                           │  FrameClampingHelper.s) │
└─────────────────────────┘                           └─────────────────────────┘
```

---

## 3. Key Components & Implementation Files

| Component                                                                                                                                     | Path                                                   | Responsibility                                                                        |
| :-------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------- | :------------------------------------------------------------------------------------ |
| [`TopologyFingerprint`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Display/TopologyFingerprint.swift)                 | `Domain/Display/TopologyFingerprint.swift`             | SHA-256 hash generator from spatially ordered display attributes.                     |
| [`DisplayTopologyProfile`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Display/DisplayTopologyProfile.swift)           | `Domain/Display/DisplayTopologyProfile.swift`          | Codable model storing window placements mapped to a display topology.                 |
| [`DisplayHotPlugObserving`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Infrastructure/Display/DisplayHotPlugObserving.swift) | `Infrastructure/Display/DisplayHotPlugObserving.swift` | Protocol and event enum for screen parameter notifications.                           |
| [`DisplayHotPlugObserver`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Infrastructure/Display/DisplayHotPlugObserver.swift)   | `Infrastructure/Display/DisplayHotPlugObserver.swift`  | Debounced listener for `didChangeScreenParametersNotification`.                       |
| [`TopologyProfileManaging`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Display/TopologyProfileManaging.swift)           | `Core/Display/TopologyProfileManaging.swift`           | Protocol defining profile capture, restore, and event handling.                       |
| [`TopologyProfileManager`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Display/TopologyProfileManager.swift)             | `Core/Display/TopologyProfileManager.swift`            | Coordinator executing clamping on unplug and auto-restore on reconnect.               |
| [`FrameClampingHelper`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Policy/FrameClampingHelper.swift)                    | `Core/Policy/FrameClampingHelper.swift`                | Pure mathematical utility guaranteeing window visibility inside screen visibleBounds. |

---

## 4. Verification Evidence

- **Unit Test Suites**:
  - `FlowSnapTests/Domain/TopologyFingerprintTests.swift`: Hashing determinism, resolution sensitivity, codable round-trip.
  - `FlowSnapTests/Infrastructure/DisplayHotPlugObserverTests.swift`: 600ms coalescing debounce, hot-plug and hot-unplug event dispatch.
  - `FlowSnapTests/Core/Display/TopologyProfileManagerTests.swift`: Unplug auto-snapshotting, primary visible frame clamping, and zero-prompt auto-restoration.
- **Code Quality**: Clean build, zero warnings, 100% Sendable & `@MainActor` thread safety.
- **Public API Audit**: 100% Public macOS APIs (`NSScreen`, `CGDisplayCreateUUIDFromDisplayID`, `AXUIElement`).

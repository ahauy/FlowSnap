# Test Plan: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

**Feature slug**: `display-topology-profiles-hotplug`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Phase**: Phase 5 TDD (Pre-Implementation)  
**Traces to**: `.specify/features/display-topology-profiles-hotplug/spec.md` (`REQ-DISP-001..007`, `US-DISP-016-01..03`)

---

## 1. Mapping Summary

| User Story / Requirement                  | TC ID       | Verification Target                                                                          | Test File                                                                |
| :---------------------------------------- | :---------- | :------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------- |
| `REQ-DISP-003` (Fingerprint)              | `TC-016-01` | Deterministic SHA-256 hash identical regardless of input array order                         | `FlowSnapTests/Domain/TopologyFingerprintTests.swift`                    |
| `REQ-DISP-003` (Fingerprint)              | `TC-016-02` | Distinct fingerprints produced for different display resolutions / counts                    | `FlowSnapTests/Domain/TopologyFingerprintTests.swift`                    |
| `REQ-DISP-001`, `REQ-DISP-002` (Debounce) | `TC-016-03` | Rapid notification burst (< 600ms apart) coalesces to a single debounced callback            | `FlowSnapTests/Infrastructure/Display/DisplayHotPlugObserverTests.swift` |
| `REQ-DISP-005` (Clamping)                 | `TC-016-04` | Windows outside primary screen are clamped inside `visibleFrame` with titlebar safe height   | `FlowSnapTests/Core/Display/TopologyProfileManagerTests.swift`           |
| `REQ-DISP-004` (Unplug Snapshot)          | `TC-016-05` | Hot-unplug event (`2 -> 1` displays) triggers auto-snapshot for the departing topology       | `FlowSnapTests/Core/Display/TopologyProfileManagerTests.swift`           |
| `REQ-DISP-006` (Auto-Restore)             | `TC-016-06` | Hot-plug event (`1 -> 2` displays) matching known profile restores windows to target screens | `FlowSnapTests/Core/Display/TopologyProfileManagerTests.swift`           |
| `REQ-DISP-007` (Missing App Resilience)   | `TC-016-07` | Application no longer open during reconnect is skipped cleanly without throwing error        | `FlowSnapTests/Core/Display/TopologyProfileManagerTests.swift`           |

---

## 2. Test Specifications (Gherkin Scenarios)

### TC-016-01: Deterministic Topology Fingerprint Generation

```gherkin
Given two displays: Display A at (0, 0, 1512, 982) and Display B at (1512, 0, 1920, 1080)
When TopologyFingerprint.generate is called with [Display A, Display B]
  And TopologyFingerprint.generate is called with [Display B, Display A]
Then both calls produce the exact same rawValue SHA-256 hash string
```

### TC-016-02: Distinct Fingerprints for Different Topologies

```gherkin
Given Display A (MacBook 1512x982)
  And Display B (FHD 1920x1080)
  And Display C (4K 3840x2160)
When generating fingerprint for [Display A, Display B]
  And generating fingerprint for [Display A, Display C]
Then the two fingerprints have different rawValue hashes
```

### TC-016-03: Coalescing 600ms Debounce Observer

```gherkin
Given a DisplayHotPlugObserver listening to system screen notifications
When 4 screen change notifications are posted within 300ms of each other
Then the observer does not trigger any callback during the burst
  And exactly 600ms after the 4th notification, onTopologyChanged is called exactly once
```

### TC-016-04: Frame Clamping on Primary Display Unplug

```gherkin
Given a primary display visibleFrame of (0, 25, 1512, 957)
  And a window formerly on an external monitor at (1800, 100, 1200, 800)
When FrameClampingHelper.clamp is invoked
Then the resulting frame origin X >= 0 and maxX <= 1512
  And origin Y >= 25 and maxY <= 982
```

### TC-016-05: Hot-Unplug Auto-Snapshot

```gherkin
Given a dual-monitor setup with a saved topology
When an unplug event transitions displays from 2 to 1
Then TopologyProfileManager automatically snapshots current window positions
  And stores the profile keyed by the 2-display TopologyFingerprint
```

### TC-016-06: Hot-Plug Zero-Prompt Auto-Restore

```gherkin
Given a previously snapshotted 2-display profile
When the user connects the 2nd display
  And the 600ms debounce expires
Then TopologyProfileManager identifies the known fingerprint
  And dispatches windows to their designated displays and zones automatically
```

### TC-016-07: Missing App Resilience

```gherkin
Given a profile containing placements for "com.apple.Safari" and "com.microsoft.VSCode"
  And "com.microsoft.VSCode" is not running when reconnecting
When the profile is auto-restored
Then Safari is restored to its target display
  And missing VSCode is skipped without error
```

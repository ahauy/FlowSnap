# 02 — Gap Analysis: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

## 1. AS-IS State (Current Implementation)

FlowSnap currently possesses:

- `DisplayManaging` / `DisplayManager`: Queries `NSScreen.screens`, filters mirrored screens, maps between coordinate systems, and tracks `primaryDisplay`.
- `DisplayNavigator`: Sorts displays spatially left-to-right (`x` origin ascending) and handles cyclic next/previous display navigation (`US-DISP-015`).
- `RelativeFrameScaler`: Converts proportional frames across displays.
- `WorkspaceManager` & `WorkspaceStore`: Captures and restores application window placements by bundle ID and `LayoutZone`.
- In `DisplayManager.swift`, `NSApplication.didChangeScreenParametersNotification` is observed, but it only triggers an immediate synchronous call `refreshDisplays()`.

### Limitations of AS-IS:

1. **Zero Coalescing / Debounce**: `didChangeScreenParametersNotification` is fired multiple times in rapid succession during cable hot-plug or sleep-wake wakeups (hardware negotiation). Synchronous immediate refresh causes churn and race conditions.
2. **No Topology Identification**: No concept of a `TopologyFingerprint` or display configuration hashing. The app cannot distinguish between being docked at an office desk vs connected to a single home monitor vs operating standalone.
3. **No Hot-Unplug Window Clamping**: When an external monitor is disconnected, macOS collapses windows onto the primary display, often pushing title bars off-screen or positioning windows partially off the visible bounds. FlowSnap has no automatic clamping mechanism (`FrameClampingHelper`).
4. **No Hot-Plug Auto-Restoration**: When a previously used external monitor is re-connected, windows that were pushed to the laptop screen remain clustered on the laptop screen. The user must manually move and re-snap every window.

---

## 2. TO-BE State (Desired Capabilities)

1. **Deterministic Topology Fingerprinting**:
   - Compute a SHA-256 fingerprint (`TopologyFingerprint`) uniquely identifying the current display topology using public APIs: display UUIDs (`CGDisplayCreateUUIDFromDisplayID`), localized screen names, and visible frame dimensions.
2. **Debounced Screen Change Observer (`DisplayHotPlugObserver`)**:
   - Observe `NSApplication.didChangeScreenParametersNotification` with a 600ms coalescing debounce timer.
   - Detect topological transitions: Single -> Multi (Hot-Plug), Multi -> Single / Multi -> Different Multi (Hot-Unplug / Configuration Change).
3. **Automatic Hot-Unplug Proportional Clamping & Snapshot**:
   - When external screen disconnects: Capture current window placements for that topology before dồn cửa sổ, then apply `FrameClampingHelper` to ensure all windows landing on the primary screen fit within `visibleFrame` with fully visible title bars.
4. **Zero-Prompt Auto-Restore on Hot-Plug Reconnect**:
   - When a known topology is reconnected: Retrieve the saved `DisplayTopologyProfile` and automatically dispatch windows back to their target displays and zones.

---

## 3. Four Gap Categories

### 3.1 Data / Schema Gaps

- Need domain entity `TopologyFingerprint` (Codable, Hashable, Sendable, rawValue string).
- Need domain entity `DisplayTopologyProfile` (Codable, Sendable) containing timestamp, fingerprint, and window placements by display index / UUID.
- Need storage integration in `PreferencesStore` or `WorkspaceStore` to persist active profiles for known fingerprints.

### 3.2 Logic / Service Gaps

- Need `FrameClampingHelper` (Core): Pure geometric algorithm ensuring `CGRect` fits within `visibleFrame` with minimum margins (titlebar safe height ≥ 36pt).
- Need `TopologyProfileManager` (Core): Orchestrator maintaining topology state machine, taking automatic snapshots upon disconnection, and triggering zero-prompt restores upon reconnection.
- Need `DisplayHotPlugObserver` (Infrastructure): Notification listener bridging `didChangeScreenParametersNotification` into an async stream or debounced callback on `@MainActor`.

### 3.3 Interface / Contract Gaps

- Protocol `DisplayHotPlugObserving`: Abstraction for testing display change notifications without requiring real hardware disconnects.
- Protocol `TopologyProfileManaging`: Abstraction for querying, saving, and applying topology profiles.

### 3.4 Non-Functional Requirements (NFR) Gaps

- **Debounce coalescing**: 600ms timer prevents flapping during sleep-to-wake or dock negotiation.
- **Strict Concurrency**: All coordinators `@MainActor` isolated; all data models `Sendable`.
- **Zero Private API**: Public `NSScreen`, `CGDisplayCreateUUIDFromDisplayID`, and AppKit APIs only.

---

## 4. Transition & Migration Plan

- Non-breaking additive changes.
- Existing `DisplayManager` and `WorkspaceManager` interfaces remain fully backwards-compatible.
- `DisplayHotPlugObserver` attaches to the existing notification bus and delegates to `TopologyProfileManager`.

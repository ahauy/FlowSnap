# Functional Specification: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

## 1. Requirements (`REQ-DISP-###`)

- **`REQ-DISP-001` (Hot-Plug Notification Listening)**:
  - The system SHALL register for `NSApplication.didChangeScreenParametersNotification` on the main application lifecycle.
  - _Derived from_: `US-DISP-016`, `BR-DISP-008`.

- **`REQ-DISP-002` (600ms Debounce Coalescing)**:
  - The system SHALL delay topology re-evaluation by 600ms following every notification event. Subsequent notifications within the window SHALL reset the timer.
  - _Derived from_: `ASM-DISP-005`, `BR-DISP-008`, `RISK-DISP-001`.

- **`REQ-DISP-003` (Deterministic Topology Fingerprinting)**:
  - The system SHALL generate a unique SHA-256 `TopologyFingerprint` representing the connected display setup based on sorted screens, UUIDs, localized names, and dimensions.
  - _Derived from_: `ASM-DISP-006`, `BR-DISP-007`.

- **`REQ-DISP-004` (Hot-Unplug Auto-Snapshot)**:
  - When an unplug event reduces the display count, the system SHALL automatically capture a snapshot of window locations for the departing topology before executing any rebalancing.
  - _Derived from_: `ASM-DISP-004`, `BR-DISP-009`.

- **`REQ-DISP-005` (Proportional Frame Clamping on Primary Display)**:
  - When windows are moved from a disconnected screen onto the primary display, the system SHALL clamp their geometry using `FrameClampingHelper`, guaranteeing the title bar (≥ 36pt) remains accessible below the Menu Bar.
  - _Derived from_: `ASM-DISP-004`, `BR-DISP-010`, `BR-DISP-011`, `RISK-DISP-003`.

- **`REQ-DISP-006` (Zero-Prompt Auto-Restore on Reconnect)**:
  - When a known `TopologyFingerprint` is detected after hot-plug, the system SHALL automatically restore the saved multi-monitor window arrangement without requiring user interaction.
  - _Derived from_: `ASM-DISP-005`, `BR-DISP-012`.

- **`REQ-DISP-007` (Missing Application Resilience)**:
  - If a saved app in the profile is not currently open, the system SHALL skip that app gracefully and restore all other available apps.
  - _Derived from_: `BR-DISP-013`, `RISK-DISP-004`.

---

## 2. User Stories & Acceptance Scenarios

### `US-DISP-016-01`: Safe Window Clamping on Monitor Unplug

- **Given**: The user has 2 monitors connected (Laptop + External 4K) with VS Code and Chrome open on the External 4K monitor.
- **When**: The user unplugs the external monitor cable.
- **Then**:
  - `DisplayHotPlugObserver` captures the notification and debounces for 600ms.
  - The layout of the 2-monitor setup is snapshotted to `TopologyProfileManager`.
  - VS Code and Chrome are clamped into the primary display's `visibleFrame`.
  - Their title bars remain fully visible and clickable below the macOS Menu Bar.

### `US-DISP-016-02`: Zero-Prompt Auto-Restore on Monitor Reconnect

- **Given**: The user previously used a dual-monitor setup with VS Code snapped to Left Half and Chrome snapped to Right Half on the external display, and then unplugged.
- **When**: The user plugs the same external monitor back in.
- **Then**:
  - `DisplayHotPlugObserver` detects the monitor reconnection after the 600ms debounce.
  - `TopologyFingerprint` matches the previously saved profile.
  - VS Code is automatically moved back to the external display's Left Half.
  - Chrome is automatically moved back to the external display's Right Half.
  - The user did not need to click any confirmation popup.

### `US-DISP-016-03`: Multiple Flapping Events during Sleep/Wake

- **Given**: The Mac wakes from sleep connected to a USB-C multi-monitor dock, causing macOS to fire 3 screen change notifications within 400ms.
- **When**: The notifications are received by `DisplayHotPlugObserver`.
- **Then**:
  - The timer coalesces all 3 events into a single evaluation pass 600ms after the final event.
  - Windows are repositioned exactly once, preventing screen flickering or jitter.

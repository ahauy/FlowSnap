# 04 — Risk Register & Contradiction Scan: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

## 1. Risk Register

| Risk ID           | Title & Vulnerability                                                                                                                                                                                                                                             | Severity | Probability | Mitigation Strategy                                                                                                                                                                                |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------- | :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-DISP-001** | **Display Flapping during Sleep/Wake or Docking**<br>Connecting a multi-port USB-C dock or waking macOS triggers 2–5 `didChangeScreenParametersNotification` events in < 1 second. Processing each immediately causes race conditions and erratic window jumping. | High     | High        | **600ms Coalescing Debounce**: All notifications reset a single coalescing timer. State changes only evaluate once the bus has remained quiescent for 600ms (`BR-DISP-008`).                       |
| **RISK-DISP-002** | **Identical Dual Monitor Fingerprint Collision**<br>Connecting two identical monitors of the same make and model (e.g. 2x Dell U2720Q) might yield identical vendor IDs and resolutions.                                                                          | Medium   | Medium      | **Spatial Ordering & CGDirectDisplayID / UUID**: Distinguish monitors by their distinct `CGDisplayCreateUUIDFromDisplayID` and spatial coordinates (`origin.x, origin.y`).                         |
| **RISK-DISP-003** | **Window Sunk Below Menu Bar / Dock (Lost Titlebar)**<br>When macOS cascades windows from disconnected screens, the window title bar can be positioned under the Menu Bar (`y < visibleFrame.minY`), making it impossible for the user to drag the window.        | High     | Medium      | **`FrameClampingHelper` Guarantee**: Strict mathematical clamp forcing `y >= visibleFrame.minY + 36pt` (titlebar safe height) and `maxX <= visibleFrame.maxX` (`BR-DISP-010`).                     |
| **RISK-DISP-004** | **Restoring Closed or Crashed Applications**<br>If an application in a saved topology profile was closed or crashed prior to re-plugging the monitor, attempts to move it via Accessibility will fail (`cannotComplete`).                                         | Low      | High        | **Graceful Missing App Handling**: Verify app PID and window existence before dispatching AX repositioning. Silently skip missing windows without crashing or interrupting others (`BR-DISP-013`). |
| **RISK-DISP-005** | **Infinite Notification Loop**<br>If window repositioning inadvertently triggers screen parameters change, it could trigger another hotplug event.                                                                                                                | High     | Low         | **Decoupled Architecture**: Repositioning windows via AX calls does NOT alter `NSScreen.screens` geometry. Observers strictly filter for topology fingerprint changes before taking any action.    |

---

## 2. Contradiction & Logic Scan

- **Contradiction Scan**:
  - _Conflict_: If the user manually moves a window after unplugging, does reconnecting overwrite their manual work?
  - _Resolution_: Yes, but only for the specific apps saved in that multi-monitor profile. If a user does not want automatic restore, a setting `AutoRestoreOnReconnect` in `PreferencesStore` can be toggled (defaults to true per user preference in Stage 2 interview).
- **State Deadlock Check**:
  - The FSM transitions through `Debouncing` -> `Evaluation` -> `Action` -> `IdleStable`. There are no circular transitions or unhandled timeouts.
- **Backward Compatibility**:
  - Existing `DisplayManaging` and `WorkspaceManager` methods remain untouched and fully compatible.

---

## 3. MoSCoW Scope Lock

### Must-Have (P0) — In Scope

- [x] Lắng nghe `didChangeScreenParametersNotification` với debounce 600ms.
- [x] Thuật toán băm `TopologyFingerprint` từ public display properties (`CGDisplayCreateUUIDFromDisplayID`, `localizedName`, `bounds`).
- [x] Tự động snapshot bố cục khi rút màn hình ngoài (`newCount < oldCount`).
- [x] Thuật toán `FrameClampingHelper` dồn và co giãn cửa sổ an toàn vào `primaryDisplay.visibleFrame` với titlebar safe zone.
- [x] Tự động khôi phục (Zero-prompt Auto-restore) các cửa sổ về đúng màn hình ngoài khi cắm lại màn hình đã lưu profile.

### Should-Have (P1) — In Scope

- [x] Lưu trữ danh sách `DisplayTopologyProfile` vào `UserDefaults` / JSON local storage.
- [x] Bỏ qua các ứng dụng không còn chạy khi khôi phục mà không văng lỗi.

### Could-Have (P2) — Deferred / Out of Scope for US-DISP-016

- [ ] Giao diện tùy chỉnh đặt tên topology profile trong Settings UI (chức năng cốt lõi tự động hoạt động mà không cần UI cấu hình phức tạp).

### Won't-Have (P3) — Deliberately Excluded

- ❌ Private SkyLight / CGS APIs (vi phạm chính sách Zero Private API).
- ❌ Can thiệp vào macOS Spaces chuyển đổi ảo bằng phím tắt không được hỗ trợ.
- ❌ Cố định vị trí các cửa sổ hệ thống (Finder desktop icons, Spotlight, Notification Center).

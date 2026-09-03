# Traceability Matrix: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

| Requirement ID | Business Rule                | Decision / ASM | Test Case Target | Architecture Component                    |
| :------------- | :--------------------------- | :------------- | :--------------- | :---------------------------------------- |
| `REQ-DISP-001` | `BR-DISP-008`                | `ASM-DISP-005` | `TC-DISP-001`    | `DisplayHotPlugObserver`                  |
| `REQ-DISP-002` | `BR-DISP-008`                | `ASM-DISP-005` | `TC-DISP-002`    | `DisplayHotPlugObserver` (Debounce)       |
| `REQ-DISP-003` | `BR-DISP-007`                | `ASM-DISP-006` | `TC-DISP-003`    | `TopologyFingerprint` / `DisplayManager`  |
| `REQ-DISP-004` | `BR-DISP-009`                | `ASM-DISP-004` | `TC-DISP-004`    | `TopologyProfileManager` (Auto-Snapshot)  |
| `REQ-DISP-005` | `BR-DISP-010`, `BR-DISP-011` | `ASM-DISP-004` | `TC-DISP-005`    | `FrameClampingHelper`                     |
| `REQ-DISP-006` | `BR-DISP-012`                | `ASM-DISP-005` | `TC-DISP-006`    | `TopologyProfileManager` (Auto-Restore)   |
| `REQ-DISP-007` | `BR-DISP-013`                | `ASM-DISP-005` | `TC-DISP-007`    | `TopologyProfileManager` (App Resilience) |

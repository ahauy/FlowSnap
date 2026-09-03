# Risk Register & Scope Boundary (Stage 5) — per-app-rules-floating-stack

- **Feature**: `per-app-rules-floating-stack`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner

---

## 1. Risk Register

| Risk ID             | Description                                                                  | Severity | Likelihood | Mitigation Strategy                                                                                                                                                      |
| :------------------ | :--------------------------------------------------------------------------- | :------: | :--------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-POLICY-001** | Window restored into invisible coordinates after external display disconnect |   High   |    High    | Enforce `BR-POLICY-003`: clamp and re-center remembered `CGRect` inside the currently active display's `visibleBounds` with at least 80% visibility.                     |
| **RISK-POLICY-002** | App has minimum window size larger than assigned snap zone                   |  Medium  |   Medium   | Respect the application's reported `kAXSizeAttribute` minimums; if layout engine target is smaller than minimum size, scale up to minimum size anchoring at zone origin. |
| **RISK-POLICY-003** | Stale window reference in `SmartFocusStack` when floating window closes      |   Low    |   Medium   | Verify target `AXUIElement` validity and `pid_t` liveness before issuing `setFocus`. If invalid, pop to the next valid element or defer to macOS focus.                  |
| **RISK-POLICY-004** | Duplicate or conflicting rules for the same bundle identifier                |  Medium  |    Low     | Use unique dictionary mapping (`[String: AppPolicyRule]`) keyed by normalized lowercase `bundleIdentifier`. UI prevents duplicate entries.                               |
| **RISK-POLICY-005** | Private API temptation for floating window level                             | Critical |    Low     | Strictly adhere to Zero Private APIs rule. Floating windows remain standard level with layout exemption and focus tracking; no `CGSSetWindowLevel`.                      |

---

## 2. MoSCoW Scope Boundary

### Must-Have

- `WindowPolicy` enum expansion (`.currentSpace`, `.currentDisplay`, `.floating`, `.rememberPosition`, `.assignedLayout(LayoutZone)`).
- Specific app rule priority over default policy (`BR-POLICY-001`).
- Display visible bounds clamping for `.rememberPosition` (`BR-POLICY-003`).
- Canonical zone placement for `.assignedLayout` (`BR-POLICY-005`).
- Exclusion of `.floating` windows from tiling/grid snaps (`BR-POLICY-002`).

### Should-Have

- `SmartFocusStack` tracking focused windows and restoring focus when floating apps close (`BR-POLICY-004`).
- Interactive `ApplicationRulesView` in Settings with application list, add app button, and policy pickers.
- Persistence of user rules and remembered frames in `PreferencesStore`.

### Won't-Have (Scope Boundary)

- Elevating third-party windows to `kCGFloatingWindowLevel` using undocumented WindowServer APIs.
- Cloud / iCloud synchronization of per-app rules (local only for v1.0).
- Arbitrary non-standard custom polygon window masks.

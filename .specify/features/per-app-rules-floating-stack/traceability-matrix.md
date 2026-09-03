# Requirement Traceability Matrix — per-app-rules-floating-stack

| Business Rule   | Requirement ID   | User Story Scenario | Domain Entity / Component                   | Test Case Verification                         |
| :-------------- | :--------------- | :------------------ | :------------------------------------------ | :--------------------------------------------- |
| `BR-POLICY-001` | `REQ-POLICY-001` | `US-WORK-014-01`    | `WindowPolicyManager.policy(forBundleID:)`  | App-specific rule overrides default            |
| `BR-POLICY-002` | `REQ-POLICY-002` | `US-WORK-014-02`    | `SnapEngine` / `WindowPolicy.floating`      | Floating windows excluded from snap layout     |
| `BR-POLICY-003` | `REQ-POLICY-003` | `US-WORK-014-03`    | `RememberedFrameStore.clampedFrame`         | Clamping prevents off-screen placement         |
| `BR-POLICY-004` | `REQ-POLICY-005` | `US-WORK-014-02`    | `SmartFocusStack.popAndRestoreFocus`        | Focus restores to previous non-floating window |
| `BR-POLICY-005` | `REQ-POLICY-004` | `US-WORK-014-01`    | `WindowPolicyManager.applyPolicy`           | Assigned canonical zone snaps correctly        |
| N/A             | `REQ-POLICY-006` | `US-WORK-014-04`    | `ApplicationRulesView` / `PreferencesStore` | Rules persist and update reactively in UI      |

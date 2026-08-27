# Risk Register & Scope Lock: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Date**: 2026-08-27
- **Feature Slug**: `accessibility-window-discovery`
- **Protocol**: Bounded Task (Stage 5)

---

## 1. Contradiction Scan

- **Logic Contradictions**: None detected. Permission checks strictly gate all AX element querying.
- **State Deadlocks**: None detected. Permission state transitions are fully bidirectional (`Untrusted` ↔ `Trusted`).
- **Backward Compatibility**: Fully compatible. Updates to `ManagedWindow` are purely additive; existing tests and scaffolding remain non-broken.

---

## 2. Risk Register

| ID                | Risk Description                                                  | Prob. | Impact | Mitigation Strategy                                                                                        |
| :---------------- | :---------------------------------------------------------------- | :---: | :----: | :--------------------------------------------------------------------------------------------------------- |
| **RISK-SNAP-001** | macOS TCC permission resets during ad-hoc rebuilds in development | High  |  Med   | Add clear instructions in FlowSnapLab; detect untrusted state gracefully and deep link to System Settings. |
| **RISK-SNAP-002** | Non-standard Electron/web apps omitting standard AX attributes    |  Med  |  Low   | Implement BR-SNAP-003 fallback to `NSRunningApplication.localizedName` and defensive attribute checking.   |
| **RISK-SNAP-003** | Race condition if target window closes mid-inspection             |  Low  |  Low   | Catch `kAXErrorInvalidUIElement` or `kAXErrorCannotComplete` and return `nil` without crashing.            |

---

## 3. Assumptions & Constraints Log

- **ASM-SNAP-001**: Permission polling occurs at a 1-second interval only when app is active (`didBecomeActiveNotification`).
- **ASM-SNAP-002**: Only standard application windows (`kAXWindowRole` + `kAXStandardWindowSubrole`) with resizable size are treated as `.normal`.
- **ASM-SNAP-003**: Missing window title falls back to `NSRunningApplication.localizedName` or `"Unknown Window"`.
- **ASM-SNAP-004**: `AXUIElement` instances remain strictly within Infrastructure (`AXAccessibilityService`).
- **Constraint-01**: Strictly zero private Apple APIs (public `ApplicationServices.HIServices` only).
- **Constraint-02**: Swift 6 Strict Concurrency compliant.

---

## 4. MoSCoW Scope Table

### Must-Have (P0) — In Scope for US-SNAP-001

- Check Accessibility trust status (`AXIsProcessTrustedWithOptions`).
- Deep link navigation to `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
- Query active application's focused window (`kAXFocusedWindowAttribute`).
- Read geometric position and size (`kAXPositionAttribute`, `kAXSizeAttribute`).
- Filter and classify `WindowKind` (`.normal`, `.dialog`, `.sheet`, `.system`, `.unsupported`).
- Fallback resolution for missing titles.
- Thread-safe actor storage in `WindowRegistry`.

### Should-Have (P1)

- Dynamic polling on app activation to auto-detect granted permission without relaunch.

### Could-Have (P2)

- Detailed AX error diagnostic logging in `FlowSnapLab`.

### Won't-Have (Explicitly Out of Scope for US-SNAP-001)

- Mutating window position or size (deferred to `US-SNAP-002: Core Layout & Snap Engine`).
- Multi-display coordinate conversion (deferred to `US-SNAP-003`).
- Global keyboard shortcuts (deferred to `US-SNAP-004`).
- Window drag overlays or HUD previews (deferred to Sprint 2).

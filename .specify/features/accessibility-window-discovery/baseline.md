# Domain Decision Baseline: Accessibility & Focused Window Discovery (US-SNAP-001)

**Status**: SIGNED-OFF  
**Version**: 1.0  
**Signed off by**: User (2026-08-27)  
**Feature Slug**: `accessibility-window-discovery`  
**Epic**: `EPIC 01: Accessibility Permission & Focused Window Discovery`

---

## 1. Executive Summary & Problem Statement

FlowSnap requires macOS Accessibility privileges (`AXUIElement`) to detect, inspect, and position application windows. To provide a world-class, frictionless native experience:

1. FlowSnap verifies its permissions via `AXIsProcessTrustedWithOptions` and guides the user via a direct link to `Privacy & Security > Accessibility` in System Settings, auto-detecting permission grants dynamically.
2. When granted, FlowSnap queries `kAXFocusedWindowAttribute` from the frontmost application to extract geometric bounds, process ID, bundle identifier, and window title with robust fallbacks.
3. FlowSnap semantically classifies windows into `WindowKind` (`.normal`, `.dialog`, `.sheet`, `.system`, `.unsupported`) so that subsequent snap engines only operate on valid resizable application windows.

---

## 2. Approved Domain Models & Business Rules

Detailed specifications are documented in [03-domain-model.md](03-domain-model.md):

- **BR-SNAP-001**: Pre-flight permission enforcement before calling AX APIs.
- **BR-SNAP-002**: Window kind classification strictly separating `.normal` standard windows from `.dialog`, `.sheet`, and `.system` windows.
- **BR-SNAP-003**: Window title fallback querying `NSRunningApplication.localizedName` or `"Unknown Window"`.
- **BR-SNAP-004**: Safe geometric extraction of `CGPoint` and `CGSize` into `CGRect`.
- **Ubiquitous Language**: Synced in [CONTEXT.md](../../../CONTEXT.md) (`ManagedWindow`, `WindowKind`).

---

## 3. Scope Boundaries (MoSCoW)

Detailed risk analysis and scope bounds are documented in [04-risk-register.md](04-risk-register.md):

- **Must-Have (P0)**:
  - Trust check (`isTrusted`) & System Settings router.
  - Focused window discovery & `ManagedWindow` construction.
  - Safe geometric attribute extraction.
  - Semantic classification into `WindowKind`.
  - Thread-safe actor storage in `WindowRegistry`.
- **Should-Have (P1)**:
  - Dynamic active polling (1s while app active) to detect permission grant without relaunch.
- **Won't-Have (Explicitly Out of Scope for US-SNAP-001)**:
  - Window frame positioning/resizing (`US-SNAP-002`).
  - Multi-monitor coordinate inversion (`US-SNAP-003`).
  - Global hotkeys (`US-SNAP-004`).

---

## 4. Specification & Verification Deliverables

- **User Stories**: [spec/user-stories.md](spec/user-stories.md) (`US-SNAP-001a`, `US-SNAP-001b`, `US-SNAP-001c`)
- **Validation Report**: [validation-report.md](validation-report.md) — 100% PASS on all 8 IEEE 29148 quality criteria.
- **Traceability Matrix**: [traceability-matrix.md](traceability-matrix.md)

---

## 5. Handover Brief for Technical Planning (Speckit)

- **Target Architecture**:
  - `Domain/Window`: Extend `ManagedWindow` and introduce `WindowKind` enum.
  - `Infrastructure/Accessibility`: Implement `AXAccessibilityService` conforming to `AccessibilityService`.
  - `Infrastructure/macOS`: Implement `SystemSettingsRouter` for opening accessibility settings.
  - `Core/Window`: Enhance `WindowRegistry` Actor for thread-safe window tracking.
  - `FlowSnapLab`: Add live Permission Check and Focused Window Inspector UI.
  - `FlowSnapTests`: Add mock double `MockAccessibilityService` and unit tests with Swift Testing (`@Test`).
- **Next Lifecycle Phase**: Hand off to `system-architect` (Phases 2–4: Speckit) upon user sign-off.

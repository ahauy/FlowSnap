# 01 — Elicitation Record (Stage 2) — per-app-rules-floating-stack

> Interview anchored on roadmap AC for US-WORK-014. Only underspecified / high-risk branches were grilled.
> Confirmed decisions: `ASM-POLICY-001`, `ASM-POLICY-002`, `ASM-POLICY-003`.

## Confirmed Decisions

### ASM-POLICY-001 — Floating Window & Smart Stack Stacking Protocol

- **Decision**: Windows configured with the `.floating` policy are exempt from grid tiling, preserve the standard macOS window level, and participate in a Most-Recently-Used (MRU) focus stack.
  - **Grid Exemption**: When tiling or snapping other windows on the screen (or during auto-layout), windows marked as `.floating` are never resized or forcibly repositioned.
  - **Standard Level Safety**: Avoid intrusive private CGS hacks or continuous AX elevation. Third-party floating apps operate cleanly in standard window hierarchies.
  - **Smart Window Stack & Focus Return**: FlowSnap tracks the window focus transition. When a floating app (such as Telegram, Slack, or a calculator) is closed (`kAXUIElementDestroyedNotification`), hidden, or dismissed, FlowSnap automatically restores focus to the previously active underlying tiled window via `AccessibilityService.setFocus`.
- **Rationale**: Completely eliminates disruptions to working desktop layouts without resorting to brittle private window server APIs.

### ASM-POLICY-002 — Clamped & Display-Aware Remembered Position

- **Decision**: Windows configured with `.rememberPosition` remember their last closed or moved frame bounds, with multi-monitor clamping safety.
  - **Frame Persistence**: When a window closes or unmounts, FlowSnap persists its last known `CGRect` associated with the application's `bundleIdentifier`.
  - **Display Reconnection Clamping**: Upon application relaunch, if the remembered display is unavailable or has different resolution/visible bounds, FlowSnap clamps and scales the origin and size so the window is guaranteed to appear fully visible inside the current display's `visibleBounds` (minimum 80% visibility, never off-screen or underneath the menu bar/dock).
- **Rationale**: Guarantees that windows never "disappear" into disconnected external monitor coordinates when switching between desktop and portable configurations.

### ASM-POLICY-003 — Predefined Canonical Snap Zones for Assigned Layout

- **Decision**: The `.assignedLayout` policy allows binding an application to standard canonical `LayoutZone` targets.
  - **Supported Canonical Zones**: Left Half (50%), Right Half (50%), Top Half (50%), Bottom Half (50%), Maximize (100%), Left Two-Thirds (70/30 or 66/33), Right One-Third, Top-Left, Top-Right, Bottom-Left, Bottom-Right.
  - **Zone Application**: When the application launches or its first window is created, `WindowPolicyManager` calculates the target `CGRect` using `LayoutEngine` against the current display's `visibleBounds` and repositions the window instantly.
  - **User Experience**: Settings UI provides a clean dropdown picker populated with canonical zones and clear human-readable labels.
- **Rationale**: Keeps configuration simple and robust, leveraging the rock-solid geometric calculations of `LayoutEngine` rather than fragile pixel offsets.

---

## Anchored (not re-asked) — settled by roadmap AC & tech context

- **Stack & Concurrency**: Swift 6 strict concurrency (`Sendable`, actor isolation, `@MainActor`).
- **Public API Policy**: 100% Public macOS APIs (`NSWorkspace`, AX API, AppKit / SwiftUI); zero private CGS APIs.
- **Rule Precedence**: Specific app bundle ID rule strictly overrides the default policy (`policy(forBundleID:) -> WindowPolicy`).
- **Persistence**: Per-app policy configurations and remembered window frames persist reactively in `PreferencesStore` (`UserDefaults` JSON serialization).
- **Settings UI**: `ApplicationRulesView.swift` updated with live list of configured apps, an "Add Application" sheet/dialog selecting from `/Applications` or running apps, and policy selector dropdowns.

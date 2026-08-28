# Handover Brief: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

**Baseline version**: 1.0 (signed off 2026-08-28)  
**Spec documents**: [spec/user-stories.md](spec/user-stories.md)  
**Validation report**: [validation-report.md](validation-report.md)  
**Deliverables status**: Completed & Verified (`US-SNAP-003` is `[x]`)

---

## 1. What Was Built

FlowSnap now features full multi-monitor awareness and precision coordinate translation between macOS AppKit and Accessibility APIs:

- **`Display` Domain Model**: Includes `isPrimary: Bool` with default `frame.origin == .zero`, `frame`, `visibleFrame`, and `scaleFactor`.
- **`CoordinateTransformer`**: A pure, stateless mathematical involution providing 100% exact bidirectional conversion:
  $$Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$$
  $$Y_{AppKit} = H_{Primary} - (Y_{AX} + Height)$$
- **`DisplayManager`**: `@MainActor` actor-isolated service enumerating `NSScreen.screens`, coalescing mirrored screens into the active master (`CGDisplayMirrorsDisplay`), resolving maximum intersection area for straddling windows (`BR-DISP-002`), and reacting to `didChangeScreenParametersNotification` (`BR-DISP-004`).
- **`SnapEngine`**: Multi-display coordinate calculation, AX conversion, and cross-monitor zone migration (`calculateFrameOnNextDisplay`).
- **`FlowSnapLab`**: Interactive multi-monitor inspector with live display listings, primary screen height, and "Move Window to Next Display" button.

---

## 2. What Is Explicitly Out of Scope (Won't-Have)

- **Zero Private APIs for Spaces**: No private CoreGraphics APIs (`CGSSetWindowSpaces`) to force-move windows across virtual desktop spaces.
- **No Disruptive Auto-Jumping**: No automatic window relocation on monitor disconnect until user explicitly snaps/restores.

---

## 3. Known Accepted Risks & Mitigations

- **Negative Coordinates on External Screens**: Handled cleanly via pure algebraic arithmetic in `CoordinateTransformer` without arbitrary boundary clamping.
- **Thread Safety**: AppKit `NSScreen` reads and notifications are isolated to `@MainActor` with safe observer lifecycle management via `TokenBox`.

---

## 4. Handover to Next Milestone

With `US-SNAP-003` completed, verified (43/43 tests passing in 0.012s), and signed off, the project is officially unlocked for the next User Story on the roadmap:
👉 **`US-SNAP-004: Phím tắt Toàn cục & Hệ thống Điều phối Lệnh (Global Hotkeys & Command Dispatcher)`**

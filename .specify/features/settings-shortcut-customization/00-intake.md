# Intake: Settings UI & Shortcut Customization (US-SNAP-010)

- **Date**: 2026-08-30
- **Requested by**: FlowSnap Product Roadmap / EPIC 09 (SwiftUI Settings UI & Custom Shortcut Management)
- **Classification**: Full Feature
- **Classification signals**:
  - New/changed domain entities: 2 (`ShortcutAction`, `PreferencesStore` state extensions)
  - Existing persistence schema change: Yes (`UserDefaults` keys for custom shortcut bindings, drag-to-snap switches, dwell delay)
  - Screens/flows touched: 4 (General Tab, Shortcuts Tab with interactive `ShortcutRecorderField`, Application Rules Tab, About Tab)
  - User roles affected: 1 (Mac power user / FlowSnap user)
  - Cross-cutting impact: Yes (Links UI -> PreferencesStore -> GlobalHotkeyManager & DragToSnapCoordinator)
  - Estimated code lines changed: ~400-600 lines
  - Reversible without user impact: Yes (Reset to default shortcuts & preferences)
- **Protocol selected**: Full Feature Pipeline (Stages 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8).
- **Override**: None (Matches roadmap Epic 09, Effort `M`).

## One-line problem statement

Provide an intuitive, macOS-native SwiftUI Settings window that allows users to customize keyboard shortcuts with live conflict detection, configure window gaps and layout ratios, toggle drag-to-snap behaviors, and manage app-specific policies with instant persistence.

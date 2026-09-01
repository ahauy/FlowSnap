# Requirements Checklist: Workspace Snapshot & Restoration (US-WORK-011)

**Feature Slug:** `workspace-snapshot-restoration` · Spec: spec.md · Plan: plan.md

## Complete & Unambiguous

- [x] All SRS REQ-WORK-001…011 mapped to FR-1…FR-9 in spec.md §3
- [x] Save/restore algorithms specified step-by-step (contracts §3)
- [x] Skip reasons enumerated: notInstalled / launchTimeout / noWindow
- [x] Zone inference deterministic (max-IoU + allCases-order tie-break)

## Dependencies & Ordering

- [x] US-SNAP-010 (PreferencesStore) merged to main — verified via git
- [x] Reused modules identified with exact protocols: AccessibilityService, DisplayManaging,
      LayoutCalculating, WindowManaging, PreferencesStore
- [x] Task ordering respects type → store → manager → UI chain (tasks.md Dependency Notes)

## DoD Alignment

- [x] Swift 6 strict concurrency: actor store, @MainActor manager, Sendable value types
- [x] No force unwrap: existing `.first!` in WorkspaceStore stub scheduled for removal (T004)
- [x] Zero private API: NSWorkspace + AX only (BR-010)
- [x] Test strategy: Swift Testing @Test, injectable directory/launcher/mocks
- [x] Mandatory cross-display restore test (E8) has a dedicated task (T011)

## Risks Covered

- [x] AX launch hang → bounded 10s/100ms poll (T006, T008)
- [x] JSON corruption → atomic write + typed error + empty-list degradation (T004, T005)
- [x] Cascade overflow → clamped offsets (T008, T010)
- [x] Actor races → single actor owns file I/O (ADR-003)

## Scope Discipline (MoSCoW lock)

- [x] No exclusive-mode implementation (v1.1 additive field only)
- [x] No presets (US-WORK-012), no pixel persistence, no multi-display targets
- [x] layouts.json stub removal is cleanup, not scope creep (never implemented, no callers)

## Open Items for Gate 2

- [ ] User approval of ADR-001…004 (spec.md §6 / plan.md §3)
- [ ] User approval of UI placement (new UI/Workspace group + Settings tab)

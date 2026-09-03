# Intake: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

- **Date**: 2026-09-03
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — Sprint 4)
- **Classification**: Full Feature
- **Classification signals**:
  - New/changed domain entities: 2+ (`TopologyFingerprint`, `DisplayTopologyProfile`, `FrameClampingHelper`)
  - Existing storage schema change: Additive (Topology profiles in `PreferencesStore` / `workspaces.json`)
  - Screens/flows touched: 2+ (System screen notification rebalancer, Settings UI Display Profiles)
  - User roles affected: 1 (macOS Desktop Power User with external monitors)
  - Cross-cutting impact: Display topology, window geometry, sleep/wake event coalescing, workspace restoration
  - Estimated code lines changed: 250–400 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Full Feature (Stages 1 → 8 with interactive elicitation interview at Stage 2)
- **Override**: None

## One-line problem statement

Khi cắm hoặc rút màn hình rời, macOS thường làm dồn hoặc kẹt các cửa sổ ngoài tầm nhìn và xáo trộn bố cục làm việc; FlowSnap cần nhận diện dấu vân tay màn hình (Topology Fingerprint), tự động cân đối cửa sổ an toàn khi rút cáp và khôi phục nguyên vẹn bố cục khi cắm lại màn hình.

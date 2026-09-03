# Domain Decision Baseline: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0.0  
**Story ID**: `US-DISP-016`  
**Feature Slug**: `display-topology-profiles-hotplug`  
**Date**: 2026-09-03

---

## Executive Summary

US-DISP-016 cung cấp khả năng tự động thích ứng với các thay đổi cấu hình màn hình (Display Topology Hot-Plug & Hot-Unplug):

1. **Rút màn hình ngoài (Hot-Unplug)**: Tự động snapshot bố cục cũ, sử dụng `FrameClampingHelper` để co giãn và dồn các cửa sổ từ màn hình rời vào trong vùng hiển thị an toàn (`visibleFrame`) của màn hình chính (Laptop), đảm bảo thanh tiêu đề (title bar ≥ 36pt) luôn nằm dưới Menu Bar và có thể nhấp/kéo được.
2. **Cắm lại màn hình ngoài (Hot-Plug Reconnect)**: Nhận diện cấu hình qua dấu vân tay xác thực SHA-256 (`TopologyFingerprint`), tự động khôi phục (Zero-prompt Auto-restore) các cửa sổ về đúng màn hình ngoài và vùng snap tương ứng mà không làm phiền người dùng.
3. **Chống giật màn hình (Debounce Coalescing)**: Bộ đệm trễ 600ms triệt tiêu hiện tượng flapping notifications khi Mac thức dậy từ Sleep hoặc khi cắm dock USB-C.

---

## 1. Traceability & Decision Matrix

- **Intake**: [00-intake.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/00-intake.md) (Full Feature, Effort: L, multi-session).
- **Tech Context**: [00-tech-context.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/00-tech-context.md).
- **Elicitation Decisions**: [01-elicitation.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/01-elicitation.md) (`ASM-DISP-004`, `ASM-DISP-005`, `ASM-DISP-006`).
- **Gap Analysis**: [02-gap-analysis.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/02-gap-analysis.md).
- **Domain Model & State Machine**: [03-domain-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/03-domain-model.md) (`BR-DISP-007`..`014`).
- **Risk Register & MoSCoW**: [04-risk-register.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/04-risk-register.md) (`RISK-DISP-001`..`005`).
- **Functional Requirements**: [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/spec.md) (`REQ-DISP-001`..`007`).
- **Data Model**: [data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/data-model.md).
- **Validation Report**: [validation-report.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-topology-profiles-hotplug/validation-report.md) (IEEE 29148 PASS).
- **Architectural Decision Record**: [adr/0011-display-topology-profiles-hotplug.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0011-display-topology-profiles-hotplug.md).

---

## 2. Handover Brief for Technical Planning (Phase 2)

- **Input Artifacts**: `03-domain-model.md`, `data-model.md`, `spec.md`, `adr/0011-display-topology-profiles-hotplug.md`.
- **Target Components**:
  - `Domain/Display/`: `TopologyFingerprint.swift`, `DisplayTopologyProfile.swift`.
  - `Core/Display/`: `FrameClampingHelper.swift`, `TopologyProfileManaging.swift`, `TopologyProfileManager.swift`.
  - `Infrastructure/Display/`: `DisplayHotPlugObserver.swift` (bọc `didChangeScreenParametersNotification` với 600ms debounce).
  - `Tests/`: `FrameClampingHelperTests.swift`, `TopologyFingerprintTests.swift`, `TopologyProfileManagerTests.swift`.
- **Handover Acceptance Sign-Off**: Ready for `speckit-plan` and task decomposition.

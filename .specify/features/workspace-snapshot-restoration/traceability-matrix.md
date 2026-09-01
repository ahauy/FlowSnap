# Traceability Matrix: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 7/8: Traceability & Sign-off
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)

---

## 1. Business Goal → Rule → Story → Scenario → Test

| Business Goal / Need | Business Rule / Assumption | PRD Requirement | SRS Requirement | User Story & Scenarios | Target Test Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **G-01: One-key workspace restoration** (OBJ-WORK-01) | BR-WORK-003, BR-WORK-004, ASM-WORK-001 | PRD-WORK-003, PRD-WORK-004 | REQ-WORK-004, REQ-WORK-005 | US-WORK-011.3: Sc. 3.1 (launch+place), 3.2 (not installed), 3.3 (timeout) | `WorkspaceManagerTests` (auto-launch, skip reasons, summary) |
| **G-02: Portable intent-based layouts** (OBJ-WORK-02) | BR-WORK-001, BR-WORK-007 | PRD-WORK-001, PRD-WORK-007 | REQ-WORK-001, REQ-WORK-002 | US-WORK-011.1: Sc. 1.1 (save, no pixels); US-WORK-011.2: Sc. 2.2 (different display size) | `WorkspaceManagerTests`, `DisplayManagerTests` (mandatory different-size integration test) |
| **G-03: Count-aware multi-window mapping** (OBJ-WORK-01) | BR-WORK-002, ASM-WORK-002 | PRD-WORK-002 | REQ-WORK-003 | US-WORK-011.2: Sc. 2.1 (stacking); US-WORK-011.3: Sc. 3.4 (clamped cascade) | `WorkspaceManagerTests` (zone math, clamp) |
| **G-04: Non-destructive restore** (OBJ-WORK-03) | BR-WORK-005, ASM-WORK-003 | PRD-WORK-005 | REQ-WORK-006 | US-WORK-011.2: Sc. 2.3 (non-workspace windows untouched) | `WorkspaceManagerTests` (additive semantics) |
| **G-05: Trustworthy persistence** (OBJ-WORK-04) | BR-WORK-006, BR-WORK-009 | PRD-WORK-006 | REQ-WORK-007, REQ-WORK-008 | US-WORK-011.1: Sc. 1.4 (store failure); US-WORK-011.4: Sc. 4.4 (corrupt file) | `WorkspaceStoreTests` (atomic write, degrade-not-crash) |
| **G-06: Disambiguated workspace identity** | BR-WORK-008 | PRD-WORK-008 | REQ-WORK-009 | US-WORK-011.1: Sc. 1.2 (duplicate blocked), Sc. 1.3 (empty name) | `WorkspaceStoreTests` (case-insensitive rejection) |
| **G-07: Manageable workspace list** | BR-WORK-006 | PRD-WORK-009 | REQ-WORK-010 | US-WORK-011.4: Sc. 4.1 (list/rename), 4.2 (delete confirm), 4.3 (empty state) | UI test / manual (Popover + Settings) |
| **G-08: Safe restore preconditions** | BR-WORK-004, BR-WORK-010 | PRD-WORK-010 | REQ-WORK-011 | US-WORK-011.2: Sc. 2.4 (AX permission missing) | `WorkspaceManagerTests` + manual (zero partial moves) |

## 2. Assumption Traceability

| Assumption | Business Rules | PRD | SRS | User Story Scenarios |
| :--- | :--- | :--- | :--- | :--- |
| **ASM-WORK-001** | BR-WORK-003, BR-WORK-004 | PRD-WORK-003, PRD-WORK-004 | REQ-WORK-004, REQ-WORK-005 | US-WORK-011.3 Sc. 3.1–3.3 |
| **ASM-WORK-002** | BR-WORK-002 | PRD-WORK-002 | REQ-WORK-003 | US-WORK-011.2 Sc. 2.1; US-WORK-011.3 Sc. 3.4 |
| **ASM-WORK-003** | BR-WORK-005 | PRD-WORK-005 | REQ-WORK-006 | US-WORK-011.2 Sc. 2.3 |

## 3. Risk Traceability

| Risk | Mitigating Requirement(s) |
| :--- | :--- |
| RISK-WORK-001 | REQ-WORK-004, REQ-WORK-005 |
| RISK-WORK-002 | REQ-WORK-005 |
| RISK-WORK-003 | REQ-WORK-002 (+ mandatory different-display-size test) |
| RISK-WORK-004 | REQ-WORK-008 |
| RISK-WORK-005 | REQ-WORK-007, NFR-WORK-001 |
| RISK-WORK-006 | REQ-WORK-003 |
| RISK-WORK-007 | REQ-WORK-006 |
| RISK-WORK-008 | REQ-WORK-011 |
| RISK-WORK-009 | NFR-WORK-005 |
| RISK-WORK-010 | REQ-WORK-009 |

## 4. Coverage Summary

- 10/10 BR-WORK-### mapped to PRD and SRS requirements.
- 11/11 REQ-WORK-### mapped to at least one user-story scenario and test target.
- 3/3 assumptions (ASM-WORK-001/002/003) traced end-to-end.
- 10/10 risks (RISK-WORK-001…010) covered by at least one requirement.
- No orphan requirements; no orphan scenarios.

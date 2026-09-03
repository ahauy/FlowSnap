# Slice Plan: Verified Workspace Restoration Enhancement

| Slice | Layer | REQ/BR covered | Depends on | Parallel-safe with |
|---|---|---|---|---|
| SLICE-WRV-01 | Domain + AX adapter | REQ-WRV-002, 004, 005, 006, BR-WRV-002, 004, 007 | — | UI slice after result contract is known |
| SLICE-WRV-02 | Core restore logic | REQ-WRV-001, 003, 005, 007, 008, 009, BR-WRV-001, 003, 005–011 | SLICE-WRV-01 | UI slice after result contract is known |
| SLICE-WRV-03 | UI + consumers | REQ-WRV-007, 010, 011, BR-WRV-010, 012 | SLICE-WRV-01 | SLICE-WRV-02 |

## Execution order

1. SLICE-WRV-01 establishes typed results/policy and AX seam.
2. SLICE-WRV-02 implements the reusable restore pipeline and P0 core tests.
3. SLICE-WRV-03 updates the existing summary banner and consumer compatibility.
4. A fresh adversarial review checks all slices against `spec/user-stories.md`
   and `03-domain-model.md`; findings use narrowly scoped fix agents.

# Software Requirements Specification: Verified Workspace Restoration Enhancement

**Feature:** `workspace-restore-verification`  
**Source story:** US-WORK-011 post-sign-off enhancement  
**Status:** Draft  
**Scope:** P0 manual restore from Menu Bar/Settings; reusable core/service seam

## Functional requirements

### REQ-WRV-001: Verify placement post-conditions

**Category:** Restore correctness  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** After each `setFrame` attempt, the restore core MUST read the actual AX frame and minimized/fullscreen state. It MUST classify a placement as `placed` only when every frame component is within the configured tolerance and the window is neither minimized nor fullscreen. AX write success alone MUST NOT classify success.  
**Derived from:** BR-WRV-001, BR-WRV-002, BR-WRV-003, ASM-WRV-001  
**Non-Functional Requirements:** Deterministic, public AX APIs only.  
**Dependencies:** REQ-WRV-003

### REQ-WRV-002: Use named verification policy

**Category:** Restore correctness  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** Restore verification MUST use `RestoreVerificationPolicy` constants: frame tolerance 30 points; maximum three total placement attempts; 100ms and 200ms retry backoffs; fullscreen timeout 2 seconds with a 100ms polling interval. Literals MUST NOT be embedded in orchestration logic.  
**Derived from:** BR-WRV-002, BR-WRV-005, BR-WRV-007, ASM-WRV-004, ASM-WRV-005  
**Dependencies:** REQ-WRV-001, REQ-WRV-003

### REQ-WRV-003: Retry recoverable move and verification failures

**Category:** Restore correctness  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** The core MUST retry thrown `setFrame`/move errors and post-condition mismatches up to three total attempts, waiting 100ms after attempt 1 and 200ms after attempt 2. It MUST perform no fourth attempt. `windowNotFound`, `applicationNotFound`, `notTrusted`, `attributeUnsupported`, `invalidGeometry`, a missing AX element, and fullscreen exit failure/timeout are non-recoverable and MUST NOT enter move retry; `cannotComplete` is recoverable unless the implementation has evidence that the target disappeared.  
**Derived from:** BR-WRV-005, BR-WRV-006, ASM-WRV-004  
**Dependencies:** REQ-WRV-001, REQ-WRV-002

### REQ-WRV-004: Require an exact AX element

**Category:** Target safety  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** A restore placement MUST use the `AXUIElement` paired with its resolved snapshot. If `resolved.element == nil`, the core MUST NOT call `setFrame` or resolve another element by frame; it MUST return an unverifiable outcome.  
**Derived from:** BR-WRV-004, ASM-WRV-008  
**Dependencies:** REQ-WRV-007

### REQ-WRV-005: Gate placement on fullscreen exit

**Category:** Window preparation  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** For a fullscreen target, the core MUST call synchronous throwing `exitFullScreen`, then poll `isFullScreen` every 100ms for at most 2 seconds. It MUST call `setFrame` only after a confirmed false state. A throw or timeout MUST record `fullscreenTransitionTimeout` and perform zero placement attempts. Fixed 700ms sleep MUST NOT be used as synchronization.  
**Derived from:** BR-WRV-007, ASM-WRV-005  
**Dependencies:** REQ-WRV-002, REQ-WRV-006

### REQ-WRV-006: Expose fullscreen state through the AX seam

**Category:** Accessibility adapter  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** `AccessibilityService` MUST expose `isFullScreen(_:) -> Bool`, and `AXAccessibilityService` MUST implement it by reusing its existing fullscreen classification strategies. All conformers and test doubles MUST implement the interface without private APIs.  
**Derived from:** BR-WRV-007, RISK-WRV-003, ASM-WRV-005  
**Dependencies:** None

### REQ-WRV-007: Return typed placement outcomes and summary counters

**Category:** Result contract  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** The restore core MUST produce typed per-placement outcomes and aggregate `RestoreSummary` with `placedCount`, `failedCount`, `unverifiableCount`, `skippedCount`, `totalPlacements`, and separate `failed`, `unverifiable`, and `skipped` issue collections. P0 reason values MUST include `.moveFailed`, `.unverifiablePlacement`, `.fullscreenTransitionTimeout`, `.notInstalled`, `.launchTimeout`, and `.noWindow`. Counts MUST sum to `totalPlacements`. A final verification mismatch or unreadable verification is `.unverifiablePlacement`; a move operation that throws after its allowed retries is `.moveFailed`.  
**Derived from:** BR-WRV-010, BR-WRV-011, ASM-WRV-007  
**Dependencies:** REQ-WRV-003, REQ-WRV-004, REQ-WRV-005

### REQ-WRV-008: Continue after per-placement failure

**Category:** Restore orchestration  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** The pass MUST process placements sequentially in ascending `orderIndex` and continue after any placement-level failed, unverifiable, or skipped outcome. Accessibility denial remains the only preflight pass-level abort. Existing app launch discovery MUST retain `.notInstalled`, `.launchTimeout`, and `.noWindow` reasons.  
**Derived from:** BR-WRV-008, BR-WRV-011, ASM-WRV-006  
**Dependencies:** REQ-WRV-007

### REQ-WRV-009: Apply one final best-effort focus

**Category:** Visibility/focus  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** The core MUST NOT activate or reveal apps during placement. After all placements, it MUST select the verified result with the lowest `orderIndex` and perform at most one best-effort reveal/focus. If no placement is verified, it MUST perform no reveal/focus. Reveal/focus result MUST NOT alter placement classification or claim current-Space visibility.  
**Derived from:** BR-WRV-008, BR-WRV-009, BR-WRV-010, ASM-WRV-003, ASM-WRV-006  
**Dependencies:** REQ-WRV-007, REQ-WRV-008

### REQ-WRV-010: Preserve non-blocking summary UX

**Category:** UI feedback  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** `RestoreSummaryBanner` MUST remain the only summary surface. It MUST present placed, failed, unverifiable, and skipped groups with reasons, preserve the existing compact/expanded behavior and auto-dismiss timeout, and remain non-blocking for partial failures. Existing localization and accessibility conventions MUST be preserved.  
**Derived from:** ASM-WRV-010, Stage 1 success definition, gap user-impact analysis  
**Dependencies:** REQ-WRV-007

### REQ-WRV-011: Emit privacy-safe diagnostics

**Category:** Observability/privacy  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** Restore diagnostics MUST use the existing logging abstraction when available and MUST be limited to bundle ID, phase, reason, attempt, and technical error/code. They MUST NOT include window title, window content, UI text, screenshots, or other user data; bundle IDs do not require masking.  
**Derived from:** BR-WRV-012, ASM-WRV-010  
**Dependencies:** REQ-WRV-003, REQ-WRV-007

### REQ-WRV-012: Preserve workspace data and bound follow-ups

**Category:** Compatibility/scope  
**Priority:** Must-Have  
**Status:** Draft  
**Description:** The enhancement MUST not change the persisted workspace JSON schema or require migration. It MUST update existing summary/service consumers and mocks in one compatibility pass. Cross-Space capability investigation, picker app names, resolve-by-frame fallback, and cancellation MUST remain outside P0 acceptance.  
**Derived from:** BR-WRV-013, BR-WRV-014, ASM-WRV-002, ASM-WRV-003, ASM-WRV-009  
**Dependencies:** REQ-WRV-006, REQ-WRV-007

## Non-functional requirements

### NFR-WRV-001: Bounded execution

Each fullscreen preparation is bounded to 2 seconds; each placement has at most three attempts and 300ms total retry backoff, excluding the existing app launch budget. Restore remains sequential and has no P0 cancellation control.

### NFR-WRV-002: Public API and concurrency safety

Implementation MUST use macOS 14+ public AX/AppKit APIs, Swift 6 strict concurrency, existing dependency-injection seams, and no private Space API.

### NFR-WRV-003: Regression safety

Existing workspace, preset, summary-banner, and Accessibility test suites MUST remain green, with new tests covering P0 silent-ignore, unreadable frame, minimized/fullscreen state, missing element, retry, timeout, ordering, and final focus scenarios.

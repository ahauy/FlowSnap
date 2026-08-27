# Software Requirements Specification (SRS): Core Layout Calculation & Basic Snap Engine

- **Feature Slug**: `core-layout-snap-engine`
- **Parent Epic**: `EPIC 02: Core Layout Calculation & Basic Snap Engine`
- **Standard**: IEEE 29148

---

## 1. Functional Requirements

### REQ-LAYOUT-001: Standard Halves & Quarters Calculation

- **Statement**: The system SHALL calculate target frames for left half, right half, top half, bottom half, and 4 corner quarters with exact pixel dimensions matching the visible display area.
- **Derived from**: `BR-LAYOUT-001`, `BR-LAYOUT-003`, `ASM-LAYOUT-001`.
- **Verification**: Unit testing across standard resolutions.

### REQ-LAYOUT-002: Odd-Pixel Floor Allocation

- **Statement**: When dividing odd-pixel dimensions, the system SHALL allocate $\lfloor \text{dimension} / 2.0 \rfloor$ to the primary (left or top) zone and the exact difference to the adjacent (right or bottom) zone, ensuring zero pixel gaps and zero screen edge overflow.
- **Derived from**: `BR-LAYOUT-002`, `ASM-LAYOUT-002`.
- **Verification**: Unit tests on odd screen widths (e.g. 1441x901).

### REQ-LAYOUT-003: Maximize Window Zone

- **Statement**: The system SHALL compute a maximize frame that occupies 100% of the display's `visibleFrame` (excluding macOS Menu Bar and Dock).
- **Derived from**: `BR-LAYOUT-001`, `BR-LAYOUT-003`.
- **Verification**: Unit tests asserting equivalence with `visibleFrame`.

### REQ-LAYOUT-004: Pre-Snap Frame Preservation & Single-Step Restore

- **Statement**: The system SHALL record the window's original user-positioned frame prior to applying the first snap in a consecutive sequence, and SHALL restore the window to that recorded frame and clear the record when a restore command is issued.
- **Derived from**: `BR-LAYOUT-004`, `ASM-LAYOUT-003`.
- **Verification**: Actor state inspection and coordinator test scenarios.

### REQ-LAYOUT-005: Minimum Window Size Clamping & Anchoring

- **Statement**: If an application specifies minimum dimensions larger than the computed zone, the system SHALL clamp the frame dimensions to `max(computed, minSize)` and anchor the window to the outer boundary of the target zone.
- **Derived from**: `BR-LAYOUT-005`, `ASM-LAYOUT-004`.
- **Verification**: Tests with mock windows possessing min size constraints.

---

## 2. Non-Functional Requirements (NFRs)

### NFR-LAYOUT-001: Performance Latency

- The computation of any snap zone frame SHALL complete in less than 1.0 millisecond.

### NFR-LAYOUT-002: Architectural Seam & Zero System Dependencies

- `LayoutEngine` SHALL be implemented as a pure functional module with zero imports of AppKit, ApplicationServices, or AXUIElement.

# Functional Specification: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

## 1. Functional Requirements (`REQ-DIST-###`)

- **`REQ-DIST-001` (Direct DMG Download Card & Metadata)**:
  - The `#download` section SHALL feature a prominent primary download card targeting macOS desktop users.
  - The primary download button SHALL link directly to `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg` with `target="_blank"` and `rel="noopener noreferrer"`.
  - The card SHALL display clear, verified metadata badges:
    - Version: `v1.3.1` (Latest Production Release).
    - Architecture: `Universal Binary` (Native Apple Silicon M1/M2/M3/M4 & Intel x86_64).
    - Minimum OS: `macOS 14.0+ (Sonoma & Sequoia)`.
    - File Size: `~14.2 MB`.
    - License: `MIT (Free & Open Source)`.
  - A secondary link SHALL allow users to browse previous releases: `https://github.com/ahauy/FlowSnap/releases`.
  - _Derived from_: `US-WEB-028 AC 2`, `BR-DIST-001`, `DEC-DIST-002`.

- **`REQ-DIST-002` (Tabbed Terminal One-Line Installer)**:
  - The installation section SHALL feature an authentic macOS Terminal box for developer 1-line installation.
  - The Terminal box SHALL support two selectable installation tabs:
    - **Tab 1 (`cURL` — Default)**:
      ```bash
      curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash
      ```
    - **Tab 2 (`Homebrew`)**:
      ```bash
      brew install --cask ahauy/tap/flowsnap
      ```
  - The Terminal window header SHALL feature macOS window control dots (red, yellow, green) and an active tab switcher with keyboard navigation support (`Tab`, `Left/Right Arrow`, `Enter`).
  - Switching tabs SHALL update the active command string and copy target synchronously without layout shift.
  - _Derived from_: `US-WEB-028 AC 1`, `BR-DIST-002`, `DEC-DIST-001`.

- **`REQ-DIST-003` (1-Click Clipboard Copy with Micro-Interactions)**:
  - Both the Terminal installer box and the Gatekeeper guide SHALL provide an accessible 1-click Copy button.
  - Clicking the Copy button (or pressing Enter/Space when focused) SHALL:
    1. Write the exact active command string into the user's system clipboard without extra newlines or whitespace.
    2. Provide dual fallback: attempt `navigator.clipboard.writeText(...)`; if unavailable or permission denied, fall back to an invisible `<textarea>` selection and `document.execCommand('copy')`.
    3. Update the button UI state immediately to a confirmed state: green checkmark icon and text "Copied!".
    4. Maintain the confirmed state for exactly `2000ms`, then revert smoothly to the neutral "Copy" state.
    5. Announce the copy status to screen readers via an `aria-live="polite"` status element.
  - _Derived from_: `US-WEB-028 AC 1`, `BR-DIST-003`, `BR-DIST-004`, `ASM-DIST-003`, `ASM-DIST-004`.

- **`REQ-DIST-004` (Privacy & Trust Manifesto)**:
  - The distribution hub SHALL incorporate a dedicated Privacy & Security Manifesto presenting 3 immutable pillars:
    1. **100% Offline Architecture**: Zero outbound network requests, zero cloud dependencies, zero account requirement.
    2. **Zero Telemetry / No Tracking**: Zero analytics SDKs (no Google Analytics, Sentry, Mixpanel, or cookies).
    3. **Accessibility (`AXUIElement`) Transparency**: Reassuring, plain-language explanation that macOS Accessibility permission is required solely for calculating window geometry and dispatching window frame mutations, with **Zero Keystroke Logging** and 100% open-source auditability on GitHub.
  - Each pillar SHALL display an identifiable semantic vector icon, a clear heading, and concise bulleted guarantees.
  - _Derived from_: `US-WEB-028 AC 3`, `BR-DIST-005`, `DEC-DIST-002`.

- **`REQ-DIST-005` (Frictionless Gatekeeper Remediation Accordion)**:
  - The distribution section SHALL include an interactive collapsible accordion or callout addressing macOS security prompts ("Unidentified Developer" / Gatekeeper quarantine).
  - The accordion SHALL clearly explain why macOS quarantine applies to community-built open-source DMG packages that are not notarized through Apple's paid developer program.
  - The guide SHALL provide the deterministic 1-step remediation command:
    ```bash
    xattr -cr /Applications/FlowSnap.app
    ```
  - The command SHALL have its own dedicated 1-click copy button with the same `2000ms` visual feedback behavior.
  - _Derived from_: `US-WEB-028 AC 4`, `BR-DIST-006`, `DEC-DIST-003`.

- **`REQ-DIST-006` (Responsive Split Layout & Design System Fidelity)**:
  - The `#download` section SHALL feature a balanced 2-column Split Layout on Desktop (>= 1024px):
    - Left Column: Direct DMG Download Card + Tabbed Terminal Installer.
    - Right Column: Privacy Manifesto Cards + Gatekeeper Guidance Accordion.
  - On Tablet & Mobile (< 1024px), the layout SHALL seamlessly transition to a single-column stacked hierarchy preserving visual hierarchy.
  - All visual tokens (colors, 1px borders, radii, fonts, button hover physics) SHALL strictly comply with `web/DESIGN.md` and Anti-AI-Slop guidelines.
  - _Derived from_: `BR-DIST-007`, `DEC-DIST-002`.

---

## 2. Non-Functional Requirements (`NFR-DIST-###`)

- **`NFR-DIST-001` (Zero Layout Shift)**: CLS = 0.0 during tab switches and accordion toggles.
- **`NFR-DIST-002` (Payload & Performance)**: Zero external npm dependencies; minimal inline client JS (< 3KB unminified).
- **`NFR-DIST-003` (Accessibility)**: Full WCAG 2.2 AA contrast compliance; all interactive buttons keyboard accessible with `var(--color-primary-glow)` focus rings.

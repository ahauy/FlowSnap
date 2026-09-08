# Feature: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (`web-distribution-hub`)

## Overview

- **User Story**: `US-WEB-028` (Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto)
- **Epic**: `EPIC 16` — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal (Sprint 8)
- **Platform**: Web (`web/`), static HTML generation via Astro v7
- **Design System**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)

---

## Architectural Highlights

1. **2-Column Split Distribution Hub (`DistributionHub.astro`)**:
   - Replaces the placeholder `#download` section on the landing page (`web/src/pages/index.astro`).
   - Balances installation velocity (Acquisition) with security and user trust (Privacy Manifesto & Gatekeeper help).
   - Desktop layout (>= 1024px): 2 balanced columns.
   - Mobile layout (< 1024px): Responsive single-column stacked hierarchy.

2. **Direct DMG Download Card (`DmgCard.astro`)**:
   - Prominent primary CTA button linked directly to the latest production release `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg`.
   - Displays clear, verified metadata:
     - Version: `v1.3.1` (with live green pulse dot).
     - Architecture: `Universal Binary` (Native Apple Silicon M1/M2/M3/M4 & Intel x86_64).
     - Minimum macOS: `macOS 14.0+ (Sonoma & Sequoia)`.
     - File size: `~14.2 MB`.
     - License: `MIT License (100% Free & Open Source)`.
   - Secondary link navigating to all GitHub releases.

3. **Simulated macOS Terminal One-Line Installer (`TerminalInstaller.astro`)**:
   - Realistic macOS Terminal window chrome with 3 colored window control dots (red, yellow, green).
   - Dynamic tab toggle for developer preferences:
     - **Tab 1 (`cURL`)**: `curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash`
     - **Tab 2 (`Homebrew`)**: `brew install --cask ahauy/tap/flowsnap`
   - Accessible 1-click Copy button with dual fallback (`navigator.clipboard` -> temporary off-screen `<textarea>`).
   - Visual feedback: checkmark icon, "Copied!" text, and `aria-live="polite"` announcement for exactly 2000ms.

4. **Privacy & Trust Manifesto (`PrivacyManifesto.astro`)**:
   - 3 structured guarantee cards with semantic vector icons:
     1. **100% Offline Operation**: Zero outbound network requests, zero accounts or logins required, fully operational in air-gapped environments.
     2. **Zero Telemetry & Tracking**: Zero analytics SDKs (no Google Analytics, Sentry, Mixpanel, or cookies), 100% open-source auditability.
     3. **Accessibility (`AXUIElement`) Transparency**: Reassuring explanation that macOS Accessibility permission is used solely for computing window geometry and moving/resizing windows, with a **Zero Keylogging** guarantee.
   - Audit link directly to `github.com/ahauy/FlowSnap`.

5. **Frictionless Gatekeeper Guidance Accordion (`GatekeeperGuide.astro`)**:
   - Interactive `<details>` / `<summary>` disclosure element addressing macOS "Unidentified Developer" / quarantine prompt.
   - 3-step numbered walkthrough with dedicated 1-click copy box for:
     ```bash
     xattr -cr /Applications/FlowSnap.app
     ```
   - Includes its own 2000ms copy feedback animation and screen reader live region.

---

## Deliverables & File Tree

```
web/
├── src/
│   ├── data/
│   │   └── distribution-data.ts        # Type-safe constants (Metadata, Tabs, Privacy, Gatekeeper)
│   ├── components/
│   │   ├── DmgCard.astro               # Direct DMG download card & version metadata
│   │   ├── TerminalInstaller.astro     # Terminal window with cURL/brew tabs & 1-click copy
│   │   ├── PrivacyManifesto.astro      # 3 trust pillars (Offline, Zero Telemetry, AXUIElement)
│   │   ├── GatekeeperGuide.astro       # Collapsible quarantine troubleshooting & xattr copy
│   │   └── DistributionHub.astro       # Main 2-column container & responsive layout
│   └── pages/
│       └── index.astro                 # Integrated into section #download
└── tests/
    └── distribution-hub.test.mjs       # Automated test suite (6/6 test cases passing)
```

---

## Verification & Quality Evidence

- **Automated Tests (`web/tests/distribution-hub.test.mjs`)**:
  - `TC-DIST-001`: Direct DMG link, badges (v1.3.1, Universal Binary, macOS 14.0+, ~14.2 MB) — **PASSED**
  - `TC-DIST-002`: Tabbed Terminal window with cURL and Homebrew commands — **PASSED**
  - `TC-DIST-003`: 1-click clipboard copy with 2000ms micro-interaction — **PASSED**
  - `TC-DIST-004`: 3 Privacy manifesto pillars with AXUIElement & Zero Keylogging — **PASSED**
  - `TC-DIST-005`: Accessible `<details>` Gatekeeper accordion & `xattr -cr` copy button — **PASSED**
  - `TC-DIST-006`: Integration into `#download` and complete elimination of placeholder — **PASSED**
- **Regression Tests**:
  - `web/tests/bento-shortcuts.test.mjs`: 8/8 test cases — **PASSED**
  - `web/tests/desktop-simulator.test.mjs`: 8/8 test cases — **PASSED**
- **Static Build**: `npm run build` generates 100% clean static output (`dist/index.html`) with zero errors.

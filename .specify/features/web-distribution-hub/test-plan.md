# Test Plan: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

**Feature slug**: `web-distribution-hub`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)  
**Traces to**: `.specify/features/web-distribution-hub/06-spec-and-stories.md`

---

## Component & Unit Test Cases

### Suite 1: Direct DMG Download Card (`DmgCard.astro`)

#### TC-DIST-001: Direct DMG Link & Release Metadata

```gherkin
Given the DmgCard component is mounted in #download
When  the HTML page renders
Then  the primary download link points directly to 'https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg'
  And the link has target="_blank" and rel="noopener noreferrer"
  And the version badge displays 'v1.3.1'
  And the architecture badge displays 'Universal Binary' (Apple Silicon & Intel)
  And the minimum OS requirement displays 'macOS 14.0+'
  And the file size indicates '~14.2 MB'
  And the card includes a link to the GitHub releases archive
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-DIST-001`, `REQ-DIST-001`

---

### Suite 2: Tabbed Terminal Installer (`TerminalInstaller.astro`)

#### TC-DIST-002: Terminal Box Header & Dual Tabs

```gherkin
Given the TerminalInstaller component is mounted
When  the HTML page renders
Then  the terminal window contains 3 macOS control dots (red, yellow, green)
  And two tabs are rendered: 'cURL' and 'Homebrew'
  And the 'cURL' tab is active by default with aria-selected="true"
  And the displayed command contains 'curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash'
  And switching to the 'Homebrew' tab activates the command 'brew install --cask ahauy/tap/flowsnap'
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-DIST-002`, `REQ-DIST-002`

#### TC-DIST-003: 1-Click Clipboard Copy & Feedback Behavior

```gherkin
Given a user clicks the Copy button on the Terminal installer box
When  the copy action is triggered
Then  the active command string is passed to the clipboard API
  And the button transitions to confirmed state with 'Copied!' label and checkmark icon
  And the button reverts to neutral 'Copy' state after 2000ms
  And an invisible fallback textarea handles environments without navigator.clipboard
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-DIST-003`, `REQ-DIST-003`

---

### Suite 3: Privacy & Security Manifesto (`PrivacyManifesto.astro`)

#### TC-DIST-004: 3 Trust Pillars (Offline, Zero Telemetry, AXUIElement)

```gherkin
Given the PrivacyManifesto component is mounted
When  the HTML page renders
Then  exactly 3 privacy pillars are rendered:
  1. '100% Offline' (Zero Network Outbound)
  2. 'Zero Telemetry & Tracking' (No Tracking SDKs)
  3. 'Accessibility Transparency' (AXUIElement Only, Zero Keylogging)
  And each pillar has a dedicated semantic vector icon and guarantee bullet points
  And a link to the open-source GitHub repository is present for auditability
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-DIST-004`, `REQ-DIST-004`

---

### Suite 4: Gatekeeper Remediation Guide (`GatekeeperGuide.astro`)

#### TC-DIST-005: Collapsible Gatekeeper Accordion & xattr Command

```gherkin
Given the GatekeeperGuide component is mounted
When  inspecting the component
Then  it uses an accessible <details> / <summary> element
  And the title addresses the macOS 'Unidentified Developer' / quarantine prompt
  And the 3 clear installation steps are described
  And the remediation command 'xattr -cr /Applications/FlowSnap.app' is provided with its own dedicated copy button
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-DIST-005`, `REQ-DIST-005`

---

### Suite 5: Hub Assembly & Landing Page Integration (`DistributionHub.astro`)

#### TC-DIST-006: Integration into `#download` and Clean Layout

```gherkin
Given the landing page index.astro is rendered
When  inspecting section #download
Then  the previous placeholder box 'Terminal 1-Click & DMG Hub arriving in US-WEB-028' is completely removed
  And the DistributionHub component is mounted in its place
  And the layout establishes a 2-column split on desktop (>= 1024px) and stacked column on mobile
  And all buttons and interactive controls strictly comply with web/DESIGN.md tokens
```

- **File**: `web/tests/distribution-hub.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-DIST-006`

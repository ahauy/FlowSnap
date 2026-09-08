# Tech Context: FlowSnap Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1) and `web/DESIGN.md`.
> This file is the single source of truth for tech-stack facts of the web distribution hub feature.
> Subagents and execution phases read this file first.

## Stack

- **framework**: Astro (v7.3.1, static output mode, zero-JS baseline where possible)
- **language**: TypeScript / JavaScript (ESM)
- **styling**: Vanilla CSS + Semantic CSS Variables (`web/src/styles/design-tokens.css`)
- **design system**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)
- **typography**: System font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif`, `"SF Mono", Menlo, monospace`)
- **client interactivity**: Lightweight vanilla JS for clipboard copy API with fallback (`navigator.clipboard.writeText`), copied state animation, tab toggle for installation modes (curl / brew / direct DMG) and Gatekeeper modal/accordion.
- **performance & accessibility**: WCAG 2.2 AA compliant contrast, zero layout shift (CLS 0.0), keyboard-accessible copy triggers with ARIA live regions for screen readers.
- **browser support**: Modern Evergreen Browsers (Safari 16+, Chrome 110+, Firefox 115+, Edge).

## Relevant Subsystems for US-WEB-028

- `web/src/components/DistributionHub.astro` (or decomposed into `TerminalInstaller.astro`, `DmgCard.astro`, `PrivacyManifesto.astro`, `GatekeeperGuide.astro`):
  - **1-Click Terminal Installer**: One-line bash/curl command with syntax highlighting, copy button with micro-animation and visual feedback ("Copied to clipboard").
  - **Direct DMG Download Card**: Prominent primary CTA button linking to GitHub Releases with release version badge, architecture info (Universal Binary: Apple Silicon M1/M2/M3/M4 & Intel x86_64), macOS 14.0+ badge, and checksum (SHA-256).
  - **Privacy & Security Manifesto**: Distinct cards or grid detailing 100% Offline operation, Zero Telemetry / Zero Tracking, and clear, reassuring explanation of macOS `AXUIElement` Accessibility permission.
  - **Gatekeeper & Security Guidance**: Step-by-step instructions (with 1-click command `xattr -cr /Applications/FlowSnap.app`) explaining why macOS shows "unidentified developer" on unsigned/ad-hoc community builds and how to safely open it.
- `web/src/pages/index.astro`: Replace the placeholder box in `<section id="download">` with the comprehensive, responsive distribution hub component.

## Hard Constraints (from web/DESIGN.md & Anti-AI-Slop Governance)

- **Zero Generic AI Slop**: Strictly forbid unrequested multi-color neon gradients, floating glass orbs, or fake marketing claims.
- **Hairline Precision**: 1px borders using `var(--color-border)` (`rgba(255, 255, 255, 0.08)` dark, `#e4e4e7` light).
- **Subtle Terminal Visuals**: Terminal prompt must feel authentic to macOS Terminal/iTerm with subtle top header, dot controls (red/yellow/green or muted monochrome dots), SF Mono font, and clear copy feedback.
- **Responsive Layout**: Adapts gracefully from 2-column or grid on desktop to single column stack on mobile (< 768px).

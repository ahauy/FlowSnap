# Functional Specification: Astro Baseline, Shadcn-Inspired Design Tokens & Base Layout (US-WEB-025)

## 1. Functional Requirements (`REQ-WEB-###`)

- **`REQ-WEB-001` (Astro Baseline & Zero-JS Static Output)**:
  - The web application SHALL be built with Astro in static mode (`output: "static"`).
  - The static build output in `web/dist/` SHALL achieve sub-1s initial page load and 0 Cumulative Layout Shift (CLS).
  - The typography SHALL strictly use native system fonts (`SF Pro Display`, `SF Pro Text`, `SF Mono`, `Inter`) without external webfont HTTP requests to achieve 0ms FCP/LCP (Zero FOIT/FOUT).
  - _Derived from_: `US-WEB-025` (AC 1), `BR-WEB-001`, `NFR-1`.

- **`REQ-WEB-002` (Design Tokens Integration)**:
  - The application SHALL import and adhere to `web/src/styles/design-tokens.css` conforming to `web/DESIGN.md`.
  - All surface colors, border widths (1px hairline), radii (`--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-full`), and spring transition easing (`cubic-bezier(0.16, 1, 0.3, 1)`) SHALL be defined as CSS custom properties.
  - Dark mode canvas SHALL default to Obsidian `#09090b` with border `rgba(255, 255, 255, 0.08)`.
  - Light mode canvas SHALL default to `#ffffff` with border `#e4e4e7`.
  - _Derived from_: `US-WEB-025` (AC 2), `BR-WEB-001`.

- **`REQ-WEB-003` (Zero-FOUC Theme Management & Persistence)**:
  - An inline blocking JavaScript snippet SHALL be injected directly into the `<head>` of `BaseLayout.astro`.
  - The script SHALL synchronously check `localStorage.getItem('flowsnap-theme')`. If unassigned, it SHALL fall back to `window.matchMedia('(prefers-color-scheme: dark)').matches`.
  - The script SHALL set `document.documentElement.setAttribute('data-theme', theme)` before the DOM renders to prevent any white/black flash (Zero FOUC).
  - `ThemeToggle.astro` SHALL provide an interactive button toggling between `dark` and `light` modes, updating both the `data-theme` attribute and `localStorage`.
  - The script SHALL wrap `localStorage` access in `try...catch` blocks to prevent exceptions in private browsing or restricted environments.
  - _Derived from_: `US-WEB-025` (AC 3), `BR-WEB-001`, `ASM-WEB-001`, `RISK-WEB-001`.

- **`REQ-WEB-004` (Sticky Navigation Header)**:
  - `Header.astro` SHALL be pinned to the top of the viewport (`position: sticky; top: 0; z-index: 50`).
  - The header SHALL render macOS Liquid Glass styling: `backdrop-filter: blur(20px)`, `-webkit-backdrop-filter: blur(20px)`, and a 1px hairline bottom border (`var(--border-color)`).
  - The header SHALL include:
    1. Brand Icon & Title ("FlowSnap").
    2. Version Pill Badge (`v1.3.1`).
    3. Smooth-scroll navigation links: `#features`, `#showcase`, `#shortcuts`, `#download`.
    4. GitHub repository link (`https://github.com/ahauy/FlowSnap`) with GitHub Stars badge/button.
    5. Interactive `ThemeToggle` component.
  - _Derived from_: `US-WEB-025` (AC 4), `BR-WEB-002`, `ASM-WEB-002`.

- **`REQ-WEB-005` (Anchor Scroll Margin Protection)**:
  - All section targets (`section[id]`) SHALL have `scroll-margin-top: 80px` configured in CSS to ensure header visibility does not cover section headings upon anchor jumping.
  - _Derived from_: `BR-WEB-002`, `RISK-WEB-004`.

- **`REQ-WEB-006` (Open-Source Attribution & Footer)**:
  - `Footer.astro` SHALL render at the bottom of every page with:
    1. Copyright statement and MIT License attribution.
    2. Author profile link to `@ahauy` (`https://github.com/ahauy`).
    3. Project links (GitHub Repository, Releases, User Guides).
    4. Architectural manifesto: "Swift 6 • Zero Private APIs • Apple HIG Compliant".
  - _Derived from_: `US-WEB-025` (AC 5), `BR-WEB-004`.

- **`REQ-WEB-007` (SEO, Canonical & OpenGraph Metadata Baseline)**:
  - `BaseLayout.astro` SHALL declare semantic HTML5 structure with:
    - `<html lang="en">`
    - Standard meta tags: `charset="utf-8"`, `viewport="width=device-width, initial-scale=1.0"`, `generator`.
    - Canonical URL: `https://ahauy.github.io/FlowSnap`.
    - Page title default: `FlowSnap — macOS Window Manager with Intent & Snap Precision`.
    - Description default: `Native macOS window manager with Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs.`
    - OpenGraph tags: `og:type="website"`, `og:url`, `og:title`, `og:description`, `og:site_name="FlowSnap"`.
    - Twitter card tags: `twitter:card="summary_large_image"`, `twitter:title`, `twitter:description`.
  - _Derived from_: `US-WEB-025` (AC 3), `ASM-WEB-003`.

- **`REQ-WEB-008` (Responsive Scalability & Anti-Overflow)**:
  - The layout SHALL dynamically adapt between mobile (`< 640px`), tablet (`640px – 1024px`), and desktop (`> 1024px`).
  - Mobile view SHALL collapse verbose navigation links while maintaining prominent brand, GitHub button, and ThemeToggle.
  - Maximum content container width SHALL be constrained to `1200px` centered with auto margins.
  - Horizontal overflow scrollbar SHALL be strictly 0 on all viewports (`overflow-x: hidden` on body wrapper).
  - _Derived from_: `US-WEB-025` (AC 2), `BR-WEB-003`, `RISK-WEB-003`.

---

## 2. Acceptance Scenarios Mapping

| Scenario ID     | Test Case Title                                       | Target Requirement                          |
| :-------------- | :---------------------------------------------------- | :------------------------------------------ |
| **SCN-WEB-001** | Zero FOUC Initial Page Load with System Fonts         | `REQ-WEB-001`, `REQ-WEB-002`, `REQ-WEB-003` |
| **SCN-WEB-002** | Dark/Light Theme Switching & LocalStorage Persistence | `REQ-WEB-003`                               |
| **SCN-WEB-003** | Sticky Header Appearance & Smooth Anchor Navigation   | `REQ-WEB-004`, `REQ-WEB-005`                |
| **SCN-WEB-004** | Open-Source Footer Attribution & License Links        | `REQ-WEB-006`                               |
| **SCN-WEB-005** | Mobile Viewport Scalability & Overflow Protection     | `REQ-WEB-008`                               |
| **SCN-WEB-006** | LocalStorage Restricted / Private Browsing Fallback   | `REQ-WEB-003`                               |

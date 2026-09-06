# Architecture & Implementation Plan: web-baseline-layout (US-WEB-025)

## 1. Architectural Strategy

- **Static-First & Zero Runtime Overhead**: Use Astro's static site generation (`output: 'static'`) with vanilla CSS variables from `web/src/styles/design-tokens.css`.
- **Zero FOUC Inline Script Injection**: Inject a synchronous, blocking `<script is:inline>` at the top of `<head>` in `BaseLayout.astro`. This checks `localStorage.getItem('flowsnap-theme')` or `prefers-color-scheme` and sets `data-theme` on `<html>` before any paint occurs.
- **Deep Component Seams**:
  - `BaseLayout.astro`: Outer document boundary handling `<head>`, SEO meta tags, OpenGraph, theme script injection, and body wrapper.
  - `Header.astro`: Self-contained sticky navigation component with brand, version badge, navigation links, GitHub stars button, and theme toggle.
  - `ThemeToggle.astro`: Isolated theme switching button with accessible `aria-label`, smooth icon transition, and safe `localStorage` synchronization.
  - `Footer.astro`: Self-contained footer component adhering to open-source and Apple HIG aesthetics.
  - `index.astro`: Entry page assembling `BaseLayout`, `Header`, main placeholder content, and `Footer`.

---

## 2. File Modification & Creation Manifest

```
web/
├── src/
│   ├── components/
│   │   ├── Header.astro           # [NEW] Sticky header with nav anchors & actions
│   │   ├── Footer.astro           # [NEW] Open-source MIT footer
│   │   └── ThemeToggle.astro      # [NEW] Dark/Light mode switcher
│   ├── layouts/
│   │   └── BaseLayout.astro       # [NEW] Root HTML layout with anti-FOUC script & SEO
│   ├── pages/
│   │   └── index.astro            # [MODIFY] Render BaseLayout, Header, and sections
│   └── styles/
│       └── design-tokens.css      # [MODIFY] Add layout & navigation utility classes
```

---

## 3. Implementation Phasing

1. **Phase 1: Token & Layout Style Enhancements (`design-tokens.css`)**:
   - Add `.page-container`, `section[id] { scroll-margin-top: 80px; }`, `.action-pill`, and badge styles.
2. **Phase 2: BaseLayout with Zero-FOUC Script & SEO (`BaseLayout.astro`)**:
   - Construct HTML skeleton, meta tags, canonical URL, OpenGraph, and inline theme script.
3. **Phase 3: Theme Toggle Component (`ThemeToggle.astro`)**:
   - Build accessible button with SVG icons (Sun & Moon) and click handler with safe `try...catch`.
4. **Phase 4: Sticky Header & Footer Components (`Header.astro`, `Footer.astro`)**:
   - Implement sticky header with glass backdrop and footer with links.
5. **Phase 5: Page Integration & Verification (`index.astro`)**:
   - Wire layout and run `npm run build` in `web/` to verify zero compile or bundle warnings.

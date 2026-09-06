# Test Plan: Astro Baseline, Shadcn-Inspired Design Tokens & Base Layout (US-WEB-025)

## 1. Test Strategy & Scope

- **Feature Under Test**: `US-WEB-025` (`web-baseline-layout`)
- **Testing Approach**:
  - Static HTML & AST Verification: Ensure `<head>`, meta tags, canonical URL, and inline theme script render correctly.
  - Component Verification: Ensure `BaseLayout.astro`, `Header.astro`, `Footer.astro`, `ThemeToggle.astro` render properly without missing props or broken markup.
  - Build Validation: Run `npm run build` in `web/` to confirm zero compilation errors, zero warnings, and successful output in `web/dist/`.
  - Browser Verification: Verify theme toggle, absence of FOUC, responsive viewport scaling, and anchor scroll behaviors.

---

## 2. Test Cases Mapping (`TC-WEB-###`)

| Test ID        | User Story Scenario | Description                           | Target Component                    | Expected Result                                                                      |
| :------------- | :------------------ | :------------------------------------ | :---------------------------------- | :----------------------------------------------------------------------------------- |
| **TC-WEB-001** | SCN-WEB-001         | Zero-FOUC Blocking Script in `<head>` | `BaseLayout.astro`                  | Synchronous `<script is:inline>` sets `data-theme` on `<html>` before any DOM paint. |
| **TC-WEB-002** | SCN-WEB-001         | System Font Stack & Semantic Tokens   | `design-tokens.css`                 | Native system fonts (`SF Pro`, `SF Mono`) configured; 1px hairline borders defined.  |
| **TC-WEB-003** | SCN-WEB-002         | ThemeToggle Interaction & Storage     | `ThemeToggle.astro`                 | Click updates `data-theme` and `localStorage` safely; catches storage exceptions.    |
| **TC-WEB-004** | SCN-WEB-003         | Sticky Header & Navigation Anchors    | `Header.astro`                      | Sticky header with blur, FlowSnap brand, `v1.3.1` badge, 4 anchors, GitHub button.   |
| **TC-WEB-005** | SCN-WEB-004         | Open-Source Footer Attribution        | `Footer.astro`                      | MIT License statement, `@ahauy` link, guides/releases links present.                 |
| **TC-WEB-006** | SCN-WEB-005         | Responsive Viewport & Scroll Margin   | `Header.astro`, `design-tokens.css` | No horizontal scrollbar on mobile (< 640px); `scroll-margin-top: 80px` on sections.  |
| **TC-WEB-007** | SCN-WEB-001         | Astro Static Build Verification       | `npm run build`                     | Zero build errors; static `/index.html` generated in `dist/`.                        |

---

## 3. Automated & Manual Verification Commands

```bash
# 1. Build Verification
cd web && npm run build

# 2. Verify Output Files Exist
test -f dist/index.html && echo "dist/index.html generated successfully"
```

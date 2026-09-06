# Data Model & Contracts: web-baseline-layout (US-WEB-025)

## 1. TypeScript Interfaces & Types

```typescript
/**
 * SEO & OpenGraph page metadata contract.
 */
export interface SiteMetadata {
  title?: string;
  description?: string;
  canonicalUrl?: string;
  ogImage?: string;
  lang?: string;
}

/**
 * Navigation anchor item for Header and Footer.
 */
export interface NavItem {
  label: string;
  href: string;
  isExternal?: boolean;
  ariaLabel?: string;
}

/**
 * Theme mode discriminator.
 */
export type ThemeMode = "dark" | "light";

/**
 * Project release & repository constants.
 */
export interface ProjectConstants {
  readonly name: "FlowSnap";
  readonly version: "v1.3.1";
  readonly githubUrl: "https://github.com/ahauy/FlowSnap";
  readonly authorUrl: "https://github.com/ahauy";
  readonly license: "MIT";
}
```

---

## 2. Client Storage Contract (LocalStorage)

| Storage Key      | Type     | Allowed Values      | Default Value                                     | Description                                         |
| :--------------- | :------- | :------------------ | :------------------------------------------------ | :-------------------------------------------------- |
| `flowsnap-theme` | `string` | `'dark' \| 'light'` | `'dark'` (or derived from `prefers-color-scheme`) | Stores active UI theme preference selected by user. |

---

## 3. CSS Variable Design Tokens Contract

Defined in `web/src/styles/design-tokens.css`:

```css
:root {
  --bg-color: #ffffff;
  --surface-color: #fafafa;
  --surface-elevated: #f4f4f5;
  --border-color: #e4e4e7;
  --border-subtle: #f4f4f5;
  --border-focus: #0071e3;
  --text-primary: #09090b;
  --text-secondary: #52525b;
  --text-tertiary: #71717a;
  --accent-blue: #0071e3;
  --accent-blue-vibrant: #0a84ff;
  --accent-swift: #fa7343;
  --liquid-glass-bg: rgba(0, 113, 227, 0.12);
  --liquid-glass-border: rgba(0, 113, 227, 0.4);
  --glass-blur: blur(20px);
}

[data-theme="dark"],
:root:not([data-theme="light"]) {
  --bg-color: #09090b;
  --surface-color: #121215;
  --surface-elevated: #18181b;
  --border-color: rgba(255, 255, 255, 0.08);
  --border-subtle: rgba(255, 255, 255, 0.04);
  --border-focus: #0a84ff;
  --text-primary: #f4f4f5;
  --text-secondary: #a1a1aa;
  --text-tertiary: #71717a;
  --accent-blue: #0a84ff;
  --liquid-glass-bg: rgba(10, 132, 255, 0.18);
  --liquid-glass-border: rgba(10, 132, 255, 0.5);
}
```

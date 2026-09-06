---
name: FlowSnap Web Design System
version: 1.0.0
license: MIT
metadata:
  author: "@ahauy"
  framework: Astro + Tailwind/Vanilla CSS
  style: "Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision"
colors:
  dark:
    background: "#09090b"
    surface: "#121215"
    surface-elevated: "#18181b"
    border: "rgba(255, 255, 255, 0.08)"
    border-subtle: "rgba(255, 255, 255, 0.04)"
    border-focus: "#0a84ff"
    text-primary: "#f4f4f5"
    text-secondary: "#a1a1aa"
    text-tertiary: "#71717a"
  light:
    background: "#ffffff"
    surface: "#fafafa"
    surface-elevated: "#f4f4f5"
    border: "#e4e4e7"
    border-subtle: "#f4f4f5"
    border-focus: "#0071e3"
    text-primary: "#09090b"
    text-secondary: "#52525b"
    text-tertiary: "#71717a"
  brand:
    apple-blue: "#0071e3"
    apple-blue-vibrant: "#0a84ff"
    swift-orange: "#FA7343"
    liquid-glass-tint: "rgba(10, 132, 255, 0.15)"
    liquid-glass-border: "rgba(10, 132, 255, 0.4)"
  semantic:
    success: "#30d158"
    warning: "#ffd60a"
    danger: "#ff453a"
typography:
  display:
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif'
    weights: "600, 700"
    letterSpacing: "-0.025em"
  body:
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", sans-serif'
    weights: "400, 500"
    lineHeight: "1.6"
  mono:
    fontFamily: '"SF Mono", "JetBrains Mono", Menlo, Consolas, monospace'
    weights: "400, 500, 600"
  scale:
    xs: "0.75rem" # 12px
    sm: "0.875rem" # 14px
    base: "1rem" # 16px
    lg: "1.125rem" # 18px
    xl: "1.25rem" # 20px
    2xl: "1.5rem" # 24px
    3xl: "2rem" # 32px
    4xl: "2.5rem" # 40px
    5xl: "3.5rem" # 56px
rounded:
  sm: "6px"
  md: "10px"
  lg: "14px"
  xl: "18px"
  full: "9999px"
spacing:
  scale: "4 / 8 / 12 / 16 / 20 / 24 / 32 / 48 / 64 / 80 / 96"
effects:
  hairline: "1px solid var(--color-border)"
  glass-blur: "blur(20px)"
  glass-backdrop: "saturate(180%) blur(20px)"
  elevation-sm: "0 1px 2px 0 rgba(0, 0, 0, 0.05)"
  elevation-md: "0 4px 12px -2px rgba(0, 0, 0, 0.12), 0 2px 6px -1px rgba(0, 0, 0, 0.08)"
  elevation-lg: "0 20px 25px -5px rgba(0, 0, 0, 0.25), 0 10px 10px -5px rgba(0, 0, 0, 0.15)"
---

# FlowSnap Web Design System

## 1. Visual Identity & Design Philosophy

FlowSnap's landing page embodies the craftsmanship of native macOS applications:

- **Precision & Restraint**: Geometry is sharp, purposeful, and structured. We avoid arbitrary paddings and floating decorative elements.
- **macOS Materiality**: Subtle translucency, liquid glass overlays, and 1px hairline borders that feel directly sourced from macOS Sonoma and Sequoia.
- **Instant Tactility**: Every button, shortcut tag, and interactive window provides snappy visual feedback with authentic spring curves (`cubic-bezier(0.16, 1, 0.3, 1)`).

---

## 2. Anti-AI-Slop Governance (Strict Rules)

### DO:

1. **Semantic Tokens First**: Always reference CSS custom properties (`var(--color-bg)`, `var(--color-border)`) instead of raw hex values.
2. **True System Font Stack**: Use `-apple-system, BlinkMacSystemFont` for zero-latency font rendering and instant 0ms FCP/LCP.
3. **High Contrast & WCAG 2.2 AA**: All text must maintain a minimum contrast ratio of `4.5:1` against its background.
4. **Stable Outer Anchors for Hover**: Wrap interactive translating elements in a stable container to prevent 60Hz hover jitter.
5. **Hairline Precision**: Card borders, dividers, and modal frames must strictly be `1px solid` with low opacity (`rgba(255,255,255,0.08)` on dark mode).

### DON'T:

1. **NO Generic AI Gradients**: Strictly forbid unrequested rainbow or purple-to-pink gradient text (`bg-gradient-to-r from-purple-500 to-pink-500`).
2. **NO Floating Neon Orbs**: Do not place blurred background blobs that serve no semantic function.
3. **NO Fake Testimonials or Mock Numbers**: Every metric must be real (`Swift 6 Strict Concurrency`, `0 Private APIs`, `470+ Unit Tests`).
4. **NO Excessive Glassmorphism**: Do not abuse heavy glass blurs that impair readability or cause GPU compositing lag.

---

## 3. Component Design Patterns

### A. The Action Pill (CTA)

- Shape: `rounded-full`
- Dark Mode: Background `#ffffff`, text `#000000`, font-weight `600`, 1px border `rgba(0,0,0,0.1)`.
- Light Mode: Background `#000000`, text `#ffffff`, font-weight `600`.
- Hover: Gentle scale `1.02` with slight lift (`translateY(-1px)`).
- Active: Scale `0.98`.

### B. Keyboard Shortcut Pill

- Shape: `rounded-md` (`6px`)
- Font: Monospace (`SF Mono`), size `12px`, letter-spacing `0.05em`.
- Appearance: Embossed keycap look (`border: 1px solid var(--border)`, `background: var(--surface-elevated)`).

### C. The Interactive macOS Window Frame

- Title Bar: Height `38px`, integrated with traffic light buttons (Red `#ff5f56`, Yellow `#ffbd2e`, Green `#27c93f` at `12px` diameter, `8px` spacing).
- Corner Radius: `12px` or `14px` matching native macOS window curvature.
- Border: `1px solid var(--border)`.
- Shadow: `var(--elevation-lg)` with deep ambient occlusion.

### D. The Liquid Snap Overlay (HUD)

- Background: `rgba(10, 132, 255, 0.18)`
- Border: `1.5px solid rgba(10, 132, 255, 0.6)`
- Backdrop Filter: `blur(16px)`
- Animation: Spring ease (`cubic-bezier(0.34, 1.56, 0.64, 1)`) with `200ms` duration.

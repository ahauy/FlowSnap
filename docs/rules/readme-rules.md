# Root GitHub README.md Specification (Project Showcase & Landing Page)

Strict rules and guidelines for AI agents when generating, updating, or reviewing the **root `README.md`** of a repository on GitHub.

> [!IMPORTANT]
> **Scope & Boundary:**
> This specification applies **EXCLUSIVELY to the root `README.md` at the repository base**, which serves as the public GitHub storefront, product landing page, and developer entry point.
>
> It does **NOT** apply to internal sub-directory READMEs (such as `docs/features/<feature-slug>/README.md`, `docs/user-guides/README.md`, or module-level docs), which follow feature specifications and Diataxis standards defined in `technical-documentation`.

---

## 1. Core Mission: The GitHub Landing Page

The root `README.md` is marketing and onboarding for developers and end-users. A visitor landing on the GitHub repository decides within **10 to 30 seconds** whether to star, download, contribute, or leave.

Within that window, the AI **must** ensure the README answers three questions:

1. **What is this?** (A clear, compelling 1–2 sentence pitch without corporate fluff).
2. **Why do I care?** (The core pain point it solves compared to existing tools).
3. **How do I get started right now?** (Copy-pasteable install/run command or direct download link).

---

## 2. Mandatory Dual-Audience Structure

Most GitHub repositories serve two distinct types of visitors. The AI **must never mix them up**:

1. **End-Users / Consumers (Priority #1):**
   - Goal: Download, install, or run the application/library immediately.
   - Wants: Binary release links (`.dmg`, `.exe`, `.pkg`), package managers (`brew install`, `npm i`, `pip install`), or pre-built container commands.
   - Does **NOT** want: To clone the repo, install build toolchains (Xcode, Rust compiler, Go SDK), or configure dev environments.

2. **Contributors / Developers (Priority #2):**
   - Goal: Build from source, run tests, understand architecture, and submit PRs.
   - Needs: Prerequisites, build steps, test suites, architecture overview, and `CONTRIBUTING.md`.

> [!WARNING]
> **Anti-Pattern:** Never force end-users to "Clone the repository and build from source" as the only installation method if binary releases, packages, or containers exist.

---

## 3. GitHub Root README Standard Structure

The AI must follow this structure, including sections based on the project type:

| Order  | Section                                     | Requirement           | Notes for AI                                                                                                                         |
| ------ | ------------------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **1**  | **Hero & Pitch**                            | Mandatory             | Project Title (`# <Name>`) + centered badge bar + 1–2 sentence high-impact tagline.                                                  |
| **2**  | **Hero Visual (Demo / GIF / Video)**        | Mandatory if UI/CLI   | Screenshot, animated GIF, or video player showing the product in action. Must support dark/light mode.                               |
| **3**  | **The Problem & Value ("Why?")**            | Mandatory             | 1–2 short paragraphs on the pain point and why this solution is superior.                                                            |
| **4**  | **Key Features (with Visual Proof)**        | Mandatory             | 4–7 bulleted or illustrated features. Pair major features with screenshots or GIFs when available.                                   |
| **5**  | **System Requirements & Prerequisites**     | Mandatory if specific | Minimum OS (e.g. macOS 14+), runtime versions, and system permissions (Accessibility, Screen Recording, Root).                       |
| **6**  | **Installation & Quickstart (User-facing)** | Mandatory             | 1-line copy-pasteable command or release download links (DMG, Homebrew, npm, etc.).                                                  |
| **7**  | **Quick Usage / Common Examples**           | Mandatory             | Minimal working example showing real inputs and real outputs. Zero `...` placeholders.                                               |
| **8**  | **Building from Source (Developer Setup)**  | When open-source      | Dedicated developer section: prerequisites (Xcode, CMake, etc.), build commands, and local run.                                      |
| **9**  | **Architecture & Engineering Highlights**   | Recommended           | Deep module directory tree, DDD structure, and engineering guarantees (strict concurrency, zero private APIs, sub-millisecond perf). |
| **10** | **Testing & Verification**                  | Mandatory             | Exact command to run the test suite (`swift test`, `pnpm test`, `pytest`). Include test count / pass status if available.            |
| **11** | **Troubleshooting & Common Gotchas**        | Recommended           | 2–3 quick solutions to the most common first-run hurdles (Gatekeeper, permissions, port conflicts).                                  |
| **12** | **Documentation & Navigation**              | Mandatory             | Table of links pointing deeper into `docs/` (User Guides, Feature specs, Architecture ADRs).                                         |
| **13** | **Contributing & Community**                | Mandatory             | Short welcome note with direct link to `CONTRIBUTING.md` and community channels.                                                     |
| **14** | **Security & Responsible Disclosure**       | Mandatory             | Instructions for private disclosure; link to `SECURITY.md`. Do not direct users to public issues.                                    |
| **15** | **License**                                 | Mandatory             | Name of the license (e.g. MIT, Apache 2.0) with a link to `LICENSE`.                                                                 |

---

## 4. Strict AI Authoring Rules (Anti-Hallucination & Quality)

1. **Zero Hallucination of Commands or Versions:**
   - The AI must inspect project files (`package.json`, `project.yml`, `Cargo.toml`, `Package.swift`, `version.json`) to extract **real** build commands, version numbers, and dependency requirements.
   - Never invent imaginary CLI flags or default configurations.

2. **No Hand-Waving or Lazy Placeholders:**
   - Every code snippet must be complete and runnable. Never use `// ... insert your code here` or omit required imports.

3. **Media & Asset Discipline for GitHub:**
   - **Dark/Light Mode Awareness:** Use GitHub-compatible `<picture>` tags when screenshots have light/dark backgrounds so they look stunning in both GitHub themes:
     ```html
     <picture>
       <source
         media="(prefers-color-scheme: dark)"
         srcset="docs/assets/demo-dark.png"
       />
       <source
         media="(prefers-color-scheme: light)"
         srcset="docs/assets/demo-light.png"
       />
       <img alt="Demo" src="docs/assets/demo-light.png" width="800" />
     </picture>
     ```
   - **Repository Weight Control:** Never commit 20MB uncompressed screen recordings to git history. Optimize GIFs (< 5MB) or embed video links.

4. **Anti-Wiki Rule (Keep it under 400 lines):**
   - The root README is a funnel, not an archive.
   - Detailed user guides belong in `docs/user-guides/`.
   - Feature technical specs belong in `docs/features/`.
   - Architecture ADRs belong in `adr/` or `docs/architecture/`.
   - Changelog belongs in `CHANGELOG.md`.

5. **Security Disclosure Protocol:**
   - Never write "Report security bugs by opening an issue on GitHub".
   - Always specify private reporting (via GitHub Security Advisories or contact email).

---

## 5. Tailoring by Repository Type

| Repository Type                       | Root README Focus                                                      | Must-Have Highlights                                                                                       |
| ------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Desktop / GUI App** (e.g. FlowSnap) | Visual showcase, download DMG/installer, OS & permission requirements. | Screenshots/GIFs of UI in action, Accessibility/Sandbox permissions, DMG build script or release link.     |
| **CLI Tool**                          | Speed, terminal aesthetics, installation via package manager.          | Terminal SVG/GIF demo (e.g. vhs/asciinema), `brew install` / `cargo install`, table of common subcommands. |
| **Library / SDK / Framework**         | Ease of integration, bundle size, clean API design.                    | `npm install` / SPM snippet, minimal import-and-run code sample, API link, TypeScript/Concurrency types.   |
| **Web App / Fullstack Service**       | Live demo link, Docker quickstart, environment configuration.          | Live URL badge, `docker compose up -d` quickstart, `.env.example` reference table.                         |

---

## 6. AI Pre-Publication Checklist

Before presenting or committing an updated root `README.md`, the AI must verify:

- [ ] Does the first screenful answer _What is it?_, _Why care?_, and _How to start?_
- [ ] Is end-user installation separated from developer build instructions?
- [ ] Are system prerequisites and permissions clearly listed before install steps?
- [ ] Were all CLI commands and code snippets verified against actual project files?
- [ ] Are images optimized and responsive to GitHub Dark/Light modes?
- [ ] Is the document concise (< 400 lines), linking to `docs/` for deep dives?
- [ ] Are all relative links (`docs/...`, `LICENSE`, `CONTRIBUTING.md`) valid and working?

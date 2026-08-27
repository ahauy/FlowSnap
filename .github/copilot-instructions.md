# GitHub Copilot Custom Instructions

This repository adheres strictly to the **Universal Agent Development Workflow**.
All architectural guidelines, multi-agent lifecycle protocols, behavioral constraints, and coding standards are defined in:

👉 **[AGENTS.md](../AGENTS.md)**

## Core Directives for GitHub Copilot:

1. **Single Source of Truth**: Always read and adhere to the guidelines in [AGENTS.md](../AGENTS.md) and project terminology in [CONTEXT.md](../CONTEXT.md).
2. **Language Specialization**:
   - For language-specific standards (Swift, Go, Python, Rust, TypeScript), consult the corresponding rules in `.agents/rules/` and skills in `.agents/skills/engineering/`.
   - When reviewing or generating code, refer to `.agents/agents/<lang>-reviewer.md` for the language's memory safety, concurrency, and security invariants.
3. **Strict Anti-AI-Slop**:
   - Zero unrequested multi-color gradients, neon accents, or floating glassmorphism.
   - Clean 1px hairline borders, intentional palettes, and stable outer anchors for hover animations.
4. **TDD & Surgical Changes**:
   - Write tests first following TDD discipline.
   - Touch only what is strictly required to fulfill the user request. Never reformat or refactor unrelated code.
5. **Git Discipline**:
   - Never generate autonomous git commit/push commands. Staging, committing, and pushing can only be initiated by the human developer or via `/command-git-push`.

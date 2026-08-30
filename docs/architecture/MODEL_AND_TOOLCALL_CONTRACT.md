# Model and Tool-Call Delivery Contract

Status: normative. Fixes in this contract are what make subagents callable on
weak tool-calling models (GLM, Qwen, and similar local/self-hosted families),
not just on frontier models.

Audience: anyone editing `.agents/agents/*.md`, `.agents/skills/**/SKILL.md`,
`AGENTS.md`, `.agents/AGENTS.md`, or the installer.

---

## 1. Three layers, three different failure modes

A subagent call passes through three independent layers. Each layer can break
the call in its own way, and the error message you see rarely names the layer
that actually failed.

``` <!-- validate-agents:ignore -->
  agent(task=..., subagent_type="planner")
        |
        v
  [A] TOOL-CALL SERIALIZATION      model emits the call as text
        |
        v
  [B] DISPATCH                     harness resolves subagent_type -> a real agent
        |
        v
  [C] EXECUTION                    the agent runs with its model/tools/frontmatter
```

| Layer | Typical symptom | Root cause | Fixed by |
|---|---|---|---|
| A | `unmatched '` / `unknown parameter:` / `Expected object, got string` | the model emitted single-quoted pseudo-JSON | §2, §3 |
| B | `unknown agent 'foo'` / `agent 'foo' is not available` | the agent was filtered out before the session started | §4 |
| C | wrong tone, missing sections, ignored constraints | frontmatter or prompt content | §5 |

Layer A and B failures are **infrastructure** failures. They are fixable in
this repository. Layer C failures are prompt-quality problems and are not.

---

## 2. Layer A: the tool-call contract

### 2.1 The problem

A tool call is a JSON document. Strong models emit valid JSON. Weaker models
often emit *Python-flavored pseudo-JSON* instead:

``` <!-- validate-agents:ignore -->
agent(task='Review the PR', subagent_type='code-reviewer')      <- single quotes
agent(task="Review the PR", subagent_type="code-reviewer")      <- double quotes, no braces
```

Both are rejected. The parser reports `unmatched '` or `Expected object, got
string`, and the message points at the *value*, which sends people hunting for
a bad apostrophe in their prompt text. The actual defect is the quoting style
and the missing braces, neither of which the prompt controls.

### 2.2 The contract

Every place this repository shows a subagent call, it shows the **canonical
JSON form**:

```
agent({
  "task": "Review the PR against the plan.",
  "subagent_type": "code-reviewer"
})
```

Rules:

1. The arguments are wrapped in `{ }`. A bare `key=value` list is not a tool call.
2. Argument names are double-quoted JSON strings, followed by `:`.
3. String values use double quotes. Single quotes never appear as delimiters.
4. The value of `task` contains no double quote characters at all (§3).

Rule 4 is the load-bearing one. A double quote inside a single-quoted value is
what turns an almost-correct call into an unparseable one, and it is the only
part of the failure an author can actually control from a prompt.

---

## 3. Layer A: the text contract for `task` values

Anything you put in a `task` value is the most quote-hostile content possible:
it is a string inside a string that a weak model has to serialize correctly.

### 3.1 Banned inside a `task` value

| Character | Why it breaks | Use instead |
|---|---|---|
| `"` | closes the JSON string early | `'...'` for prose, or drop the quoting |
| `` ` `` | Markdown inline code; models copy it into JSON where it is not a delimiter | plain words, or `'file.py'` |
| `$` | shell expansion inside double-quoted bash strings; also reads as a math delimiter | write the command in the prompt body, not the task string |
| `\` | JSON escape lead-in; a lone `\` invalidates the whole object | rephrase |
| `{` `}` | the parser may try to read a nested object | rephrase |
| `'` | safe in JSON, but it is what a model latches onto and starts delimiting with | prefer it anyway — it cannot break JSON |

### 3.2 Worked example

Before (breaks on three counts — backticks, double quotes, and a `$`):

``` <!-- validate-agents:ignore -->
agent(task='Read `src/auth.py` and check the "validate_token" function for $USER handling')
```

After:

```
agent({
  "task": "Read src/auth.py and check the validate_token function for how it handles the USER environment variable."
})
```

### 3.3 Where this applies

- `AGENTS.md` and `.agents/AGENTS.md` — the delegation contract.
- Every `SKILL.md` that invokes a subagent.
- Every agent body that tells the orchestrator how to call it.
- Hook context strings injected into the model's input
  (`.agents/scripts/hooks/session-context-init.js`), because those strings are
  re-serialized by the model on every turn.

---

## 4. Layer B: agent discovery and model availability

### 4.1 The problem

Some harnesses read the `model:` frontmatter at load time and **drop any agent
whose model they cannot serve**. With Claude Code, an agent declaring a
Gemini-only ID silently disappears from the registry; the orchestrator then
reports `unknown agent` for a file that plainly exists.

### 4.2 The contract

`model: inherit` is the required default for every agent in this repository,
including language-pack agents. It means "use the model the session is already
running", which is valid on every supported harness.

Per-harness resolution of `inherit`:

| Harness | Resolution point | Notes |
|---|---|---|
| Claude Code | native — `inherit` is a first-class value | no action |
| Codex | `.agents/agents/openai.yaml` | the `default_model` key is a **user preference**, not a load-time filter |
| Qwen Code | `.qwen/settings.json` → `model.name` | installer writes it from `--model` |
| OpenCode | `.opencode/` config | same principle |

### 4.3 Why `openai.yaml` keeps its model IDs

`openai.yaml` is the Codex adapter manifest. Its `default_model` values are
consumed by the Codex runtime as a *preference*, and Codex does not filter
agents on it — so unlike frontmatter, these IDs do not cause Layer B failures.

They are still a portability hazard: an ID that Codex accepts today may be
retired tomorrow, and the file is copied verbatim into every user's project.
Treat them as configuration the user may edit, never as something to mirror
into agent frontmatter. If you are tempted to copy a model ID from
`openai.yaml` into an agent file, that is the Layer B bug this section exists
to prevent.

---

## 5. Layer C: frontmatter hygiene

Beyond `model`, two frontmatter fields cause silent trouble on weak models:

1. **`description`** must stay on a single line. Frontmatter here is parsed by a
   deliberately dependency-free reader (`parse_frontmatter()` in
   `.agents/scripts/validate-agents.py`) that treats one key per line; a folded
   or multi-line value is read as a truncated string. Keep any apostrophe inside
   it typographic (’) rather than ASCII ('), so it cannot terminate a quoted
   string in whatever consumes the description next.
2. **`name`** must equal the filename stem. A mismatch means the orchestrator's
   `subagent_type` does not resolve.

Both are checked mechanically by `.agents/scripts/validate-agents.py`, which
also enforces the Layer A rules of §2.2/§3.1 on every agent body, `SKILL.md`,
`AGENTS.md`, `GEMINI.md`, and `CLAUDE.md` in the tree:

```
python3 .agents/scripts/validate-agents.py --root .
```

Exit status is 1 on any violation, 0 when clean. `--strict` promotes warnings
to failures. The installer runs it as a post-copy verification step.

A contract document has to *show* the anti-pattern to explain it. Those
illustrations opt out explicitly with a `validate-agents:ignore` marker instead
of being excluded by path, so the rest of the file stays under the same rules as
everything else. Put the marker on the opening fence of the example block:

    ``` <!-- validate-agents:ignore -->

The marker suppresses the remainder of that fenced block, or a single line if it
appears outside a block.

---

## 6. Checklist for a new agent or skill

- [ ] `model: inherit`
- [ ] `name` matches the filename stem
- [ ] `description` is one line, no ASCII apostrophes
- [ ] every subagent example in the body uses the canonical JSON form (§2.2)
- [ ] no `"`, `` ` ``, `$`, `\`, `{`, `}` inside any `task` value
- [ ] `python3 .agents/scripts/validate-agents.py --root .` exits 0
- [ ] `node .agents/scripts/test/test-hooks.js` passes

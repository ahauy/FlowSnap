# Repository rulesets

Ruleset definitions for `ahauy/FlowSnap`, enforced by GitHub on **push and PR merge**, not by
any tool in the repo.

GitHub does not read this folder by itself. Each file is the exact request body for the
[create-ruleset API](https://docs.github.com/en/rest/repos/rules).

## Apply

```sh
# See the effect for a week without blocking anything: set "enforcement": "evaluate" first.
gh api -X POST repos/ahauy/FlowSnap/rulesets --input .github/rulesets/main.json
gh api -X POST repos/ahauy/FlowSnap/rulesets --input .github/rulesets/feature-branches.json

# Confirm
gh api repos/ahauy/FlowSnap/rulesets --jq '.[] | {id, name, enforcement, .conditions?}'

# Update an existing ruleset instead of creating a duplicate
gh api -X PATCH repos/ahauy/FlowSnap/rulesets/<id> --input .github/rulesets/main.json

# Remove
gh api -X DELETE repos/ahauy/FlowSnap/rulesets/<id>
```

## Files

| File | Enforces |
| --- | --- |
| `main.json` | A PR is required to land on `main`; `Swift unit tests (macOS)` and `GitGuardian Security Checks` must be green and current (`strict_required_status_checks_policy: true`); no force push (`non_fast_forward`); `main` cannot be deleted; review threads must be resolved; squash or merge only. |
| `feature-branches.json` | Every commit message on any non-`main` branch matches `type(scope): single-line summary` (AGENTS.md "Single-Line English Commits"). |

## Decisions worth knowing

- `required_approving_review_count: 0`. The repo has one owner, and GitHub does not count the
  author's own review. Any number above 0 makes every PR unmergeable.
- `integration_id` values are read from real check runs, not guessed: GitHub Actions is `15368`
  (context `Swift unit tests (macOS)`), GitGuardian is `46505`.
- `bypass_actors` grants the Admin repository role (`actor_id: 5`) bypass, so you can still
  hot-fix `main` from the web UI. Delete that block for zero exceptions.
- `update` and `creation` are deliberately absent on `main`: they block direct pushes and can
  also reject the merge commit a PR produces.
- The commit-message rule applies to feature branches only. Merge commits landing on `main`
  (`Merge pull request #45 …`) would not match it.
- `dependabot/*` is excluded from the message rule because Dependabot writes its own subjects.

Verified against history: the 12 most recent commit subjects on `feat/web-i18n-ux-refactor` all
match; multiline bodies, missing types, uppercase types and missing `: ` are rejected.

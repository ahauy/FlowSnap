# Repository rulesets

Ruleset definitions for `ahauy/FlowSnap`, enforced by GitHub on **push and PR merge**, not by
any tool in the repo.

GitHub does not read this folder by itself. Each file is the exact request body for the
[create-ruleset API](https://docs.github.com/en/rest/repos/rules).

## Apply

```sh
# See the effect for a week without blocking anything: set "enforcement": "evaluate" first.
gh api -X POST repos/ahauy/FlowSnap/rulesets --input .github/rulesets/main.json

# Confirm
gh api repos/ahauy/FlowSnap/rulesets --jq '.[] | {id, name, enforcement, .conditions?}'

# Update an existing ruleset instead of creating a duplicate.
# This deployment answers PATCH with 404 and only accepts PUT (verified 2026-11-05:
# PATCH -> HTTP 404 even for a minimal body, PUT -> HTTP 200).
gh api -X PUT repos/ahauy/FlowSnap/rulesets/26587443 --input .github/rulesets/main.json

# Remove
gh api -X DELETE repos/ahauy/FlowSnap/rulesets/<id>
```

## Files

| File | Enforces |
| --- | --- |
| `main.json` | A PR is required to land on `main`; `Swift unit tests (macOS)` and `GitGuardian Security Checks` must be green and current (`strict_required_status_checks_policy: true`); no force push (`non_fast_forward`); `main` cannot be deleted; review threads must be resolved; squash or merge only. |

## Applied state (verified by reading the API back)

`main.json` is live as ruleset **id `26587443`**, `enforcement: active`, conditions
`refs/heads/main` + `refs/heads/master`, and `bypass_actors` = RepositoryRole `5` (Admin) with
`bypass_mode: always`. GitHub also defaulted `require_extra_approval_for_unattributed_changes: true`.

Because that ruleset requires `Swift unit tests (macOS)` on every PR, the workflow's `paths:`
filters were removed so the check always runs — a docs-only PR would otherwise hang on
"Expected — waiting" forever.

## Pattern rules are not available on this plan

Probing the same endpoint on 2026-11-05:

| Rule tried | Result |
| --- | --- |
| `commit_message_pattern` (`operator: regex`, `matches`, with and without `positive_match`) | `422 Invalid rule 'commit_message_pattern'` |
| `branch_name_pattern` | `422 Invalid rule 'branch_name_pattern'` |
| `max_file_size` | `422 Invalid property /rules/0` (parameter shape also differs from the docs) |
| `required_signatures` | accepted |

So the single-line Conventional Commit rule from AGENTS.md **cannot** be enforced by a ruleset on
this account. It is enforced two other ways instead:

- `.qoder/hooks/flowgate.sh` + `.qoder/hooks/policy.json` block an agent's `git commit` unless the
  user approved it — the message shape is the agent's responsibility there.
- A CI job can reject non-conforming subjects on a PR if you want it enforced for humans too;
  that is the remaining gap.

Do not re-add `feature-branches.json` until the plan supports pattern rules; it will fail to apply.

## Decisions worth knowing

- `required_approving_review_count: 0`. The repo has one owner, and GitHub does not count the
  author's own review. Any number above 0 makes every PR unmergeable.
- `integration_id` values are read from real check runs, not guessed: GitHub Actions is `15368`
  (context `Swift unit tests (macOS)`), GitGuardian is `46505`.
- `bypass_actors` grants the Admin repository role (`actor_id: 5`) bypass, so you can still
  hot-fix `main` from the web UI. Delete that block for zero exceptions.
- `update` and `creation` are deliberately absent on `main`: they block direct pushes and can
  also reject the merge commit a PR produces.

## The commit-message regex, kept for a future CI check

`git log --format=%s` style subjects only, because a ruleset cannot enforce it here:

```
\A(feat|fix|docs|test|chore|refactor|perf|ci|build|revert)(\([a-z0-9._-]+\))?: [^\n]+\z
```

Measured with Ruby `Regexp` (same engine GitHub uses for these patterns): the 12 most recent
subjects on `feat/web-i18n-ux-refactor` match, while `multiline body`, `no type prefix`,
`uppercase type`, `no colon space` and `empty desc` are all rejected. A PR-time job should match
this against each commit subject in the range, and skip merge commits.


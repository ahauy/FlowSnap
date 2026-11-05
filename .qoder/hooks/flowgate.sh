#!/usr/bin/env bash
# flowgate.sh — enforces .qoder/hooks/policy.json on Qoder tool calls.
# Contract (docs.qoder.com/cli/hooks): exit 0 allows; exit 2 blocks and stderr
# is fed back to the agent as an error.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY="$ROOT/.qoder/hooks/policy.json"
[ -f "$POLICY" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // empty')"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"

deny() {
  printf 'flowgate: %s\n' "$1" >&2
  exit 2
}

if [ "$event" = "PreToolUse" ]; then
  [ "$tool" = "Bash" ] || exit 0
  cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
  [ -n "$cmd" ] || exit 0

  approval="$(jq -r '.git.approvalEnv' "$POLICY")"
  case "$cmd" in
  *"$approval"*) exit 0 ;;
  esac

  while read -r flag; do
    case "$cmd" in
    *"$flag"*) exit 0 ;;
    esac
  done < <(jq -r '.git.allowFlags[]?' "$POLICY")

  while read -r sub; do
    if printf '%s' "$cmd" | grep -Eq "(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+${sub}([[:space:];&|]|$)"; then
      deny "'git ${sub}' is a human-in-the-loop action (AGENTS.md: Zero Autonomous Git Execution). Ask the user first; once they approve, run it as: ${approval} git ${sub} …"
    fi
  done < <(jq -r '.git.blockedSubcommands[]' "$POLICY")
  exit 0
fi

[ "$event" = "PostToolUse" ] || exit 0
[ "$tool" = "Edit" ] || [ "$tool" = "Write" ] || [ "$tool" = "MultiEdit" ] || [ "$tool" = "NotebookEdit" ] || exit 0

file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
[ -n "$file" ] && [ -f "$file" ] || exit 0
rel="${file#"$ROOT"/}"

while read -r exempt; do
  case "$rel" in
  "$exempt"*) exit 0 ;;
  esac
done < <(jq -r '.checks.lengthExempt[]' "$POLICY")

while read -r pattern; do
  if LC_ALL=C grep -qE "$pattern" "$file" 2>/dev/null; then
    deny "'$rel' matches secret pattern '${pattern}'. Never commit credentials; move them to .env or Keychain."
  fi
done < <(jq -r '.checks.secretPatterns[]' "$POLICY")

ext=".${file##*.}"
if jq -e --arg e "$ext" '.checks.lengthExtensions | index($e) != null' "$POLICY" >/dev/null; then
  grandfathered=0
  while read -r listed; do
    [ "$rel" = "$listed" ] && grandfathered=1
  done < <(jq -r '.checks.lengthGrandfathered[]?' "$POLICY")
  lines="$(wc -l <"$file" | tr -d ' ')"
  max="$(jq -r '.limits.maxFileLines' "$POLICY")"
  if [ "${lines:-0}" -gt "$max" ] && [ "$grandfathered" = "0" ]; then
    deny "'$rel' is now ${lines} lines (> ${max}, AGENTS.md Code Limits). Split it into modules before continuing."
  fi
fi

if [ "$ext" = ".swift" ] && jq -e '.checks.swiftParse.enabled' "$POLICY" >/dev/null; then
  swift_scoped=0
  while read -r dir; do
    case "$rel" in "$dir"*) swift_scoped=1 ;; esac
  done < <(jq -r '.checks.swiftParse.includeDirs[]' "$POLICY")
  if [ "$swift_scoped" = "1" ]; then
    parse_out="$(xcrun swiftc -parse "$file" 2>&1)" ||
      deny "'$rel' no longer parses: $(printf '%s' "$parse_out" | grep -m2 'error:' | tr '\n' ' ')"
  fi
fi

if [ "$ext" = ".json" ]; then
  jq -e . "$file" >/dev/null 2>&1 || deny "'$rel' is not valid JSON."
  case "$rel" in
  web/src/i18n/*.json)
    if jq -e '.checks.i18nKeyParity.enabled' "$POLICY" >/dev/null; then
      parity="$(python3 - "$ROOT/web/src/i18n/en.json" "$ROOT/web/src/i18n/vi.json" <<'PY'
import json, sys

def flat(node, prefix=""):
    keys = set()
    for key, value in node.items():
        name = f"{prefix}.{key}" if prefix else key
        keys.add(name)
        if isinstance(value, dict):
            keys |= flat(value, name)
    return keys

en = flat(json.load(open(sys.argv[1])))
vi = flat(json.load(open(sys.argv[2])))
missing = sorted(en - vi)
extra = sorted(vi - en)
parts = []
if missing:
    parts.append(f"{len(missing)} key(s) missing in vi.json: {', '.join(missing[:5])}")
if extra:
    parts.append(f"{len(extra)} key(s) missing in en.json: {', '.join(extra[:5])}")
print("; ".join(parts))
PY
)"
      [ -z "$parity" ] || deny "i18n dictionaries drifted — $parity. Both locales must keep the same key set."
    fi
    ;;
  esac
fi

exit 0

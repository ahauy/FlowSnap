#!/usr/bin/env python3
"""Fail if any commit in a range breaks AGENTS.md's single-line Conventional Commit rule."""

import os
import re
import subprocess
import sys

SUBJECT = re.compile(
    r"(feat|fix|docs|test|chore|refactor|perf|ci|build|revert)"
    r"(\([a-z0-9._-]+\))?(!)?: [^\s].*"
)
SKIP_AUTHORS = {"dependabot[bot]", "renovate[bot]", "github-actions[bot]"}
MERGE_PREFIXES = ("Merge ", "Revert \"", "revert \"")


def git(*args: str) -> str:
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if result.returncode:
        # 2 = the check itself could not run (bad revision, shallow clone),
        # which is different from 1 = a real commit-message violation.
        print(f"git {' '.join(args)} failed: {result.stderr.strip()}", file=sys.stderr)
        raise SystemExit(2)
    return result.stdout


def commits(base: str, head: str) -> list[tuple[str, str]]:
    out = git("log", "--no-merges", "--format=%H\x1f%an", f"{base}..{head}")
    return [tuple(line.split("\x1f")) for line in out.splitlines() if line.strip()]


def body_lines(sha: str) -> int:
    return len([line for line in git("show", "-s", "--format=%b", sha).splitlines() if line.strip()])


def main() -> int:
    base = os.environ.get("BASE_SHA") or sys.argv[1]
    head = os.environ.get("HEAD_SHA") or sys.argv[2]
    problems = []

    for sha, author in commits(base, head):
        subject = git("show", "-s", "--format=%s", sha).strip()
        if author in SKIP_AUTHORS or subject.startswith(MERGE_PREFIXES):
            continue
        short = sha[:8]
        if not SUBJECT.fullmatch(subject):
            problems.append(f"{short} subject not Conventional Commits: {subject!r}")
        extra = body_lines(sha)
        if extra:
            problems.append(f"{short} has a {extra}-line body; AGENTS.md requires a single line")

    if problems:
        print("Commit message check failed:\n")
        print("\n".join(f"  - {p}" for p in problems))
        print(
            "\nExpected: type(scope): summary on ONE line, no body.\n"
            "Types: feat fix docs test chore refactor perf ci build revert"
        )
        return 1

    print(f"OK: {len(commits(base, head))} commit(s) follow single-line Conventional Commits.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

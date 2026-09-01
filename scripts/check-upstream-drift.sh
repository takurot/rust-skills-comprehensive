#!/usr/bin/env bash
# Detect whether any file under a skill's declared upstream source paths has changed on
# google/comprehensive-rust's default branch since this repo's pinned commit. Uses the GitHub
# API's commit-compare endpoint (via `gh api`) rather than a local clone of
# ref/comprehensive-rust — that directory is gitignored and not present in CI (see
# docs/WORKFLOW.md §3.3, §6), and compare-by-API is far cheaper than cloning ~56MB just to run
# `git diff` on a handful of paths.
#
# Requires: `gh` CLI, authenticated (already required for this repo's PR workflow; GitHub-hosted
# Actions runners have `gh` preinstalled and GITHUB_TOKEN is enough to read a public repo).
#
# Output convention (grep-able by callers, e.g. .github/workflows/upstream-drift.yml):
#   "DRIFT: <skill> — N changed path(s) under <prefix>: <file>, <file>, ..."  (one per hit)
#   "OK: no upstream changes detected under any mapped skill's source paths"  (when clean)
# Exit code reflects whether the check itself ran successfully — 0 even when drift is found,
# non-zero only on a real failure (e.g. `gh api` error, missing pin). Callers that care whether
# drift was found should grep stdout for "^DRIFT:", not rely on the exit code.
#
# Usage: ./scripts/check-upstream-drift.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
PLAN_FILE="$REPO_DIR/docs/PLAN.md"
UPSTREAM_REPO="google/comprehensive-rust"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: $PLAN_FILE not found" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found — required to query $UPSTREAM_REPO without a local clone" >&2
  exit 1
fi

# Extract the pinned commit from "Upstream pin: `ref/comprehensive-rust` @ `<sha>` (<date>)."
pin="$(grep -oE '^- \*\*Upstream pin\*\*: `ref/comprehensive-rust` @ `[0-9a-f]{7,40}`' "$PLAN_FILE" \
  | grep -oE '[0-9a-f]{7,40}' | tail -1)"

if [[ -z "$pin" ]]; then
  echo "ERROR: could not find the Upstream pin commit in $PLAN_FILE" >&2
  exit 1
fi

# skill -> upstream directory prefix(es), one "skill|prefix" pair per line. Kept as a flat list
# (not an associative array) for bash 3.2 compatibility (docs/WORKFLOW.md §5). Derived from
# each skill's `source:` frontmatter Paths — keep this in sync when a skill's Paths change
# (docs/WORKFLOW.md §8 "skillのsource:pin更新" row).
mapping="
rust-ownership-and-lifetimes|src/borrowing
rust-ownership-and-lifetimes|src/lifetimes
rust-ownership-and-lifetimes|src/memory-management
rust-ownership-and-lifetimes|src/smart-pointers
rust-ownership-and-lifetimes|src/idiomatic/leveraging-the-type-system/borrow-checker-invariants
rust-api-design|src/idiomatic/foundations-api-design
rust-newtype-and-raii|src/idiomatic/leveraging-the-type-system/newtype-pattern
rust-newtype-and-raii|src/idiomatic/leveraging-the-type-system/raii
rust-typestate-and-tokens|src/idiomatic/leveraging-the-type-system/typestate-pattern
rust-typestate-and-tokens|src/idiomatic/leveraging-the-type-system/token-types
rust-polymorphism|src/idiomatic/polymorphism
rust-polymorphism|src/idiomatic/leveraging-the-type-system/extension-traits
rust-concurrency-sync|src/concurrency/threads
rust-concurrency-sync|src/concurrency/channels
rust-concurrency-sync|src/concurrency/send-sync
rust-concurrency-sync|src/concurrency/shared-state
rust-concurrency-sync|src/concurrency/sync-exercises
rust-async|src/concurrency/async
rust-async|src/concurrency/async-control-flow
rust-async|src/concurrency/async-pitfalls
rust-async|src/concurrency/async-exercises
rust-unsafe-fundamentals|src/unsafe-rust
rust-unsafe-soundness|src/unsafe-deep-dive/introduction
rust-unsafe-soundness|src/unsafe-deep-dive/safety-preconditions
rust-unsafe-soundness|src/unsafe-deep-dive/rules-of-the-game
rust-unsafe-soundness|src/unsafe-deep-dive/initialization
rust-unsafe-soundness|src/unsafe-deep-dive/memory-lifecycle
rust-pinning|src/unsafe-deep-dive/pinning
rust-ffi|src/unsafe-deep-dive/ffi
"

changed_files="$(gh api "repos/$UPSTREAM_REPO/compare/${pin}...main" --paginate \
  --jq '.files[]?.filename' 2>&1)" \
  || { echo "ERROR: gh api compare against $UPSTREAM_REPO failed: $changed_files" >&2; exit 1; }

drift_found=0

while IFS='|' read -r skill prefix; do
  [[ -z "$skill" ]] && continue
  matches="$(printf '%s\n' "$changed_files" | grep -E "^${prefix}(/|$)" || true)"
  if [[ -n "$matches" ]]; then
    drift_found=1
    count="$(printf '%s\n' "$matches" | grep -c .)"
    joined="$(printf '%s' "$matches" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
    echo "DRIFT: $skill — $count changed path(s) under $prefix: $joined"
  fi
done <<< "$mapping"

if [[ "$drift_found" -eq 0 ]]; then
  echo "OK: no upstream changes detected under any mapped skill's source paths (pin: $pin)"
fi

exit 0

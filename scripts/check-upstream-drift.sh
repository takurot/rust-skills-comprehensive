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
#   "WARNING: compare result may be truncated ..."  (files list looks incomplete — see below)
# Exit code reflects whether the check itself ran successfully — 0 even when drift is found,
# non-zero only on a real failure (e.g. `gh api` error, missing pin) *or* a suspected-truncated
# compare (see below) — "OK" would be a false negative there. Callers that care whether drift
# was found should grep stdout for "^DRIFT:", not rely on the exit code; callers that need to
# tell truncation apart from a transport error should grep for "^WARNING: compare result may be
# truncated".
#
# Usage: ./scripts/check-upstream-drift.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
PLAN_FILE="${PLAN_FILE:-$REPO_DIR/docs/PLAN.md}"
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
pin_matches="$(grep -oE '^- \*\*Upstream pin\*\*: `ref/comprehensive-rust` @ `[0-9a-f]{7,40}`' "$PLAN_FILE" \
  | grep -oE '[0-9a-f]{7,40}' || true)"

if [[ -z "$pin_matches" ]]; then
  echo "ERROR: could not find the Upstream pin commit in $PLAN_FILE" >&2
  exit 1
fi

pin_count="$(printf '%s\n' "$pin_matches" | grep -c .)"
if [[ "$pin_count" -gt 1 ]]; then
  echo "ERROR: multiple Upstream pin commits found in $PLAN_FILE" >&2
  exit 1
fi
pin="$pin_matches"

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
rust-ffi|src/android/interoperability/with-c
rust-ffi|src/android/interoperability/cpp
"

# Fetch status, truncation signal (`.truncated`), and returned file count on the first line,
# then the changed filenames — one `gh api` call, split with `tail`/`head` so we don't need
# a second round trip. Stderr is captured separately so non-fatal CLI warnings do not corrupt
# parsing of the first meta line.
err_file="$(mktemp "${TMPDIR:-/tmp}/check-drift-err.XXXXXX")"
trap 'rm -f "$err_file"' EXIT

if ! compare_output="$(gh api "repos/$UPSTREAM_REPO/compare/${pin}...main" \
  --jq '([(.status // "unknown"), (.truncated // false | tostring), (.files // [] | length | tostring)] | join(" ")),
        (.files[]?.filename)' 2>"$err_file")"; then
  err_msg="$(cat "$err_file")"
  rm -f "$err_file"
  trap - EXIT
  echo "ERROR: gh api compare against $UPSTREAM_REPO failed: ${err_msg:-$compare_output}" >&2
  exit 1
fi

if [[ -s "$err_file" ]]; then
  cat "$err_file" >&2
fi
rm -f "$err_file"
trap - EXIT

meta_line="$(printf '%s\n' "$compare_output" | head -1)"
status_val="$(printf '%s' "$meta_line" | cut -d' ' -f1)"
truncated="$(printf '%s' "$meta_line" | cut -d' ' -f2)"
files_count="$(printf '%s' "$meta_line" | cut -d' ' -f3)"
changed_files="$(printf '%s\n' "$compare_output" | tail -n +2)"

if [[ "$status_val" != "ahead" && "$status_val" != "identical" ]]; then
  echo "ERROR: compare status is '$status_val' (expected 'ahead' or 'identical'). Upstream branch may have diverged or pin is unreachable from main." >&2
  exit 1
fi

# GitHub's compare-two-commits API caps the `files` array (observed cap: 300 entries) and does
# not expose Link-header pagination over it, so `--paginate` cannot recover files past the cap.
# Treat both an explicit `.truncated: true` and hitting the observed cap as truncation, since a
# capped-but-unflagged response is otherwise indistinguishable from "no changes past this point".
truncation_suspected=0
if [[ "$truncated" == "true" ]] || [[ "$files_count" -ge 300 ]]; then
  truncation_suspected=1
fi

drift_found=0

while IFS='|' read -r skill prefix; do
  [[ -z "$skill" || -z "$prefix" ]] && continue
  matches="$(printf '%s\n' "$changed_files" | awk -v p="$prefix" 'index($0, p) == 1 && (substr($0, length(p)+1, 1) == "/" || length($0) == length(p))')"
  if [[ -n "$matches" ]]; then
    drift_found=1
    count="$(printf '%s\n' "$matches" | grep -c .)"
    joined="$(printf '%s' "$matches" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
    echo "DRIFT: $skill — $count changed path(s) under $prefix: $joined"
  fi
done <<< "$mapping"

if [[ "$truncation_suspected" -eq 1 ]]; then
  # Report even when DRIFT lines were already found above — a truncated compare means paths
  # beyond the cap were never checked, so "no further drift" can't be claimed either way.
  echo "WARNING: compare result may be truncated (files returned: $files_count, pin: $pin) — GitHub's compare API caps the files list around 300 entries with no further pagination. Drift may exist under paths not covered above; update the pin (docs/WORKFLOW.md §8) and re-run, or review manually against a local clone."
  exit 1
fi

if [[ "$drift_found" -eq 0 ]]; then
  echo "OK: no upstream changes detected under any mapped skill's source paths (pin: $pin)"
fi

exit 0

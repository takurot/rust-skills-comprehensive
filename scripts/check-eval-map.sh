#!/usr/bin/env bash
# Verify every upstream path listed in docs/eval/README.md's exercise->skill mapping table
# still exists in the vendored course checkout. This is a *local-only* sanity check — it is
# NOT wired into .github/workflows/ci.yml because ref/comprehensive-rust/ is gitignored and
# not present in CI (see docs/WORKFLOW.md §3.3, §6).
#
# Run this after re-pinning ref/comprehensive-rust to a newer upstream commit, to catch a
# renamed/removed exercise before docs/eval/README.md's mapping goes stale silently.
#
# Usage: ./scripts/check-eval-map.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
REF_DIR="$REPO_DIR/ref/comprehensive-rust/src"
MAP_FILE="$REPO_DIR/docs/eval/README.md"

if [[ ! -d "$REF_DIR" ]]; then
  echo "SKIP: $REF_DIR not present — clone ref/comprehensive-rust first (docs/WORKFLOW.md §3.3)" >&2
  exit 0
fi

status=0

# Pull every backtick-quoted path fragment that looks like an upstream exercise/solution
# reference (contains "exercise" or "solution") out of the mapping table's second column.
# Only literal single-file paths are checked — brace-expansion (`{a,b}.md`) and glob
# (`**/exercise.md`) entries in the table are intentionally skipped rather than
# mis-validated; those rows stay a manual-review concern.
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  # Strip a trailing directory-glob suffix like "**/exercise.md" isn't used here, but handle
  # a leading "{a,b}" brace group defensively by taking it as literal (none currently occur).
  if [[ ! -e "$REF_DIR/$path" ]]; then
    echo "FAIL: docs/eval/README.md references $path — not found under $REF_DIR"
    status=1
  fi
done < <(grep -oE '`[a-zA-Z0-9_/{}.,-]+/(exercise|solution)s?\.md`' "$MAP_FILE" | tr -d '`' | sort -u)

if [[ $status -eq 0 ]]; then
  echo "OK: all mapped exercise/solution paths exist under ref/comprehensive-rust/src"
fi

exit "$status"

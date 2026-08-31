#!/usr/bin/env bash
# Verify `./install.sh --list` reports exactly the skills present under
# skills/ — no directory missing from the listing, and no listed name
# without a matching directory. `install.sh --list` currently derives its
# output directly from `skills/*/`, so this is a regression guard against
# that coupling breaking in the future (e.g. a hardcoded list creeping in),
# not just a snapshot of today's state (docs/WORKFLOW.md §2, issue #2).
#
# Usage: ./scripts/check-install-list-sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
SKILLS_DIR="$REPO_DIR/skills"

status=0

dir_names="$(cd "$SKILLS_DIR" && ls -d */ | sed 's#/$##' | sort)"

# First whitespace-separated column of each "  <name>  <description>" line,
# skipping the "Available skills:" header.
list_names="$("$REPO_DIR/install.sh" --list | tail -n +2 | awk '{print $1}' | sort)"

missing_from_list="$(comm -23 <(printf '%s\n' "$dir_names") <(printf '%s\n' "$list_names") || true)"
if [[ -n "$missing_from_list" ]]; then
  echo "FAIL: skill(s) under skills/ missing from 'install.sh --list':"
  echo "$missing_from_list" | sed 's/^/  - /'
  status=1
fi

missing_dir="$(comm -13 <(printf '%s\n' "$dir_names") <(printf '%s\n' "$list_names") || true)"
if [[ -n "$missing_dir" ]]; then
  echo "FAIL: 'install.sh --list' names skill(s) with no matching skills/ directory:"
  echo "$missing_dir" | sed 's/^/  - /'
  status=1
fi

if [[ $status -eq 0 ]]; then
  count="$(printf '%s\n' "$dir_names" | grep -c .)"
  echo "OK: install.sh --list matches skills/ ($count skill(s))"
fi

exit "$status"

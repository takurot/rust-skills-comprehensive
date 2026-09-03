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
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."
SKILLS_DIR="${SKILLS_DIR:-$REPO_DIR/skills}"
INSTALL_SCRIPT="${INSTALL_SCRIPT:-$REPO_DIR/install.sh}"

status=0

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "FAIL: skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

shopt -s nullglob
dirs=("$SKILLS_DIR"/*/)
dir_names_arr=()
if [[ ${#dirs[@]} -gt 0 ]]; then
  for d in "${dirs[@]}"; do
    dir_names_arr+=("$(basename "$d")")
  done
fi

if [[ ${#dir_names_arr[@]} -gt 0 ]]; then
  dir_names="$(printf '%s\n' "${dir_names_arr[@]}" | LC_ALL=C sort)"
else
  dir_names=""
fi

# Capture install.sh --list output with error handling.
if ! raw_list="$("$INSTALL_SCRIPT" --list 2>&1)"; then
  echo "FAIL: 'install.sh --list' execution failed:" >&2
  echo "$raw_list" >&2
  exit 1
fi

# First whitespace-separated column of each "  <name>  <description>" line,
# skipping the "Available skills:" header and any empty lines.
list_names="$(printf '%s\n' "$raw_list" | awk 'NR>1 && NF {print $1}' | LC_ALL=C sort)"

missing_from_list="$(comm -23 <(if [[ -n "$dir_names" ]]; then printf '%s\n' "$dir_names"; fi) <(if [[ -n "$list_names" ]]; then printf '%s\n' "$list_names"; fi) || true)"
if [[ -n "$missing_from_list" ]]; then
  echo "FAIL: skill(s) under skills/ missing from 'install.sh --list':"
  echo "$missing_from_list" | sed 's/^/  - /'
  status=1
fi

missing_dir="$(comm -13 <(if [[ -n "$dir_names" ]]; then printf '%s\n' "$dir_names"; fi) <(if [[ -n "$list_names" ]]; then printf '%s\n' "$list_names"; fi) || true)"
if [[ -n "$missing_dir" ]]; then
  echo "FAIL: 'install.sh --list' names skill(s) with no matching skills/ directory:"
  echo "$missing_dir" | sed 's/^/  - /'
  status=1
fi

if [[ $status -eq 0 ]]; then
  count="${#dir_names_arr[@]}"
  echo "OK: install.sh --list matches skills/ ($count skill(s))"
fi

exit "$status"

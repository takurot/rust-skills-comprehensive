#!/usr/bin/env bash
# Verify every skills/*/SKILL.md has the required frontmatter keys (name,
# description, source) and stays within the hard line budget from
# docs/WORKFLOW.md §1 (500 lines). Exits non-zero on the first violation
# found, after reporting every violation.
#
# Usage: ./scripts/check-skill-frontmatter.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SKILLS_DIR:-$SCRIPT_DIR/../skills}"
MAX_LINES=500

status=0

shopt -s nullglob
skills=("$SKILLS_DIR"/*/SKILL.md)

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "FAIL: no SKILL.md files found under $SKILLS_DIR" >&2
  exit 1
fi

for skill_md in "${skills[@]}"; do
  name="$(basename "$(dirname "$skill_md")")"

  # Frontmatter must start on line 1 and close with a second '---' line.
  if [[ "$(sed -n '1p' "$skill_md")" != "---" ]]; then
    echo "FAIL: $skill_md — does not start with '---' frontmatter delimiter"
    status=1
    continue
  fi

  if ! awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' "$skill_md"; then
    echo "FAIL: $skill_md — missing closing '---' frontmatter delimiter"
    status=1
    continue
  fi

  frontmatter="$(awk 'NR==1{next} /^---$/{exit} {print}' "$skill_md")"

  for key in name description source; do
    if ! printf '%s\n' "$frontmatter" | grep -qE "^${key}:"; then
      echo "FAIL: $skill_md — missing '${key}:' frontmatter key"
      status=1
    fi
  done

  # name: value should match the directory name.
  fm_name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name: *//p' | head -1)"
  if [[ -n "$fm_name" && "$fm_name" != "$name" ]]; then
    echo "FAIL: $skill_md — frontmatter name '$fm_name' != directory name '$name'"
    status=1
  fi

  # description: is an unquoted YAML plain scalar, so a colon immediately
  # followed by a space ends the value early no matter where it appears
  # (backticks included) — this previously broke the harness's own
  # frontmatter parser (docs/PLAN.md Status log, rust-pinning defect).
  # Similarly, a space followed by '#' starts a YAML comment in an unquoted
  # plain scalar, silently truncating everything after it (issue #24).
  # Skip both checks if the value is quoted (starts with '"' or "'").
  fm_desc="$(printf '%s\n' "$frontmatter" | sed -n 's/^description: *//p' | head -1)"
  case "$fm_desc" in
    '"'*|"'"*) ;;
    *)
      if [[ "$fm_desc" == *": "* ]]; then
        echo "FAIL: $skill_md — description contains ': ' (colon+space), which truncates an unquoted YAML value — rewrite to avoid it (docs/WORKFLOW.md §4.2)"
        status=1
      fi
      if [[ "$fm_desc" == *" #"* ]]; then
        echo "FAIL: $skill_md — description contains ' #' (space+hash), which starts a YAML comment in an unquoted value and truncates everything after it — rewrite to avoid it (docs/WORKFLOW.md §4.2)"
        status=1
      fi
      ;;
  esac

  lines="$(awk 'END{print NR}' "$skill_md")"
  if (( lines > MAX_LINES )); then
    echo "FAIL: $skill_md — $lines lines exceeds the ${MAX_LINES}-line budget (docs/WORKFLOW.md §1)"
    status=1
  fi
done

exit "$status"

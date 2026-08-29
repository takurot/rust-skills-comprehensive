#!/usr/bin/env bash
# Verify every skills/*/SKILL.md has the required frontmatter keys (name,
# description, source) and stays within the hard line budget from
# docs/WORKFLOW.md §1 (500 lines). Exits non-zero on the first violation
# found, after reporting every violation.
#
# Usage: ./scripts/check-skill-frontmatter.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
MAX_LINES=500

status=0

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  name="$(basename "$(dirname "$skill_md")")"

  # Frontmatter must start on line 1 and close with a second '---' line.
  if [[ "$(sed -n '1p' "$skill_md")" != "---" ]]; then
    echo "FAIL: $skill_md — does not start with '---' frontmatter delimiter"
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

  lines="$(wc -l < "$skill_md" | tr -d ' ')"
  if (( lines > MAX_LINES )); then
    echo "FAIL: $skill_md — $lines lines exceeds the ${MAX_LINES}-line budget (docs/WORKFLOW.md §1)"
    status=1
  fi
done

exit "$status"

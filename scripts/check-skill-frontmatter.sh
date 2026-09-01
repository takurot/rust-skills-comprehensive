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

  # description: is an unquoted YAML plain scalar, so a colon immediately
  # followed by a space ends the value early no matter where it appears
  # (backticks included) — this previously broke the harness's own
  # frontmatter parser (docs/PLAN.md Status log, rust-pinning defect).
  fm_desc="$(printf '%s\n' "$frontmatter" | sed -n 's/^description: *//p' | head -1)"
  if [[ "$fm_desc" == *": "* ]]; then
    echo "FAIL: $skill_md — description contains ': ' (colon+space), which truncates an unquoted YAML value — rewrite to avoid it (docs/WORKFLOW.md §4.2)"
    status=1
  fi

  # Same hazard, different character: a space followed by '#' starts a YAML
  # comment in an unquoted plain scalar, silently truncating everything
  # after it — this bit rust-unsafe-soundness's description ("...writing a
  # # Safety doc section...") in exactly the same way as the ': ' case
  # above (issue #24). Skip this check if the value is already quoted
  # (starts with a literal '"' or "'"), where '#' has no special meaning.
  case "$fm_desc" in
    '"'*|"'"*) ;;
    *' #'*)
      echo "FAIL: $skill_md — description contains ' #' (space+hash), which starts a YAML comment in an unquoted value and truncates everything after it — rewrite to avoid it (docs/WORKFLOW.md §4.2)"
      status=1
      ;;
  esac

  lines="$(wc -l < "$skill_md" | tr -d ' ')"
  if (( lines > MAX_LINES )); then
    echo "FAIL: $skill_md — $lines lines exceeds the ${MAX_LINES}-line budget (docs/WORKFLOW.md §1)"
    status=1
  fi
done

exit "$status"

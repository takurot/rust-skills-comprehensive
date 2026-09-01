#!/usr/bin/env bash
# Verify cross-references stay valid across skills/*/SKILL.md (and any
# skills/*/references/*.md), README.md, CONTRIBUTING.md, and docs/**/*.md
# (recursively, including docs/eval/**):
#   - relative Markdown links `[text](target)` resolve to an existing file
#     or directory (relative to the linking file); external links
#     (http(s)://, mailto:) and pure in-page anchors (#foo) are skipped,
#     and a trailing #fragment on a path target is stripped before checking
#   - `[[name]]` references resolve to an existing skills/<name>/ directory
#     (a forward-looking check: no skill currently uses this form)
#
# Deliberately does NOT flag bare-word mentions of skill names in prose
# (e.g. "rust-patterns", "rust-analyzer") — those legitimately reference
# skills/tools that live outside this repo (docs/PLAN.md delineation
# table) or external tooling, and flagging them would be a false positive.
# A skill referencing a not-yet-built sibling skill by bare name is a
# distinct, harder-to-mechanize defect class; catch it with
# `/skill-stocktake`, not this script (docs/WORKFLOW.md §4.2).
#
# Usage: ./scripts/check-links.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."

status=0

check_file() {
  local file="$1"
  local dir
  dir="$(dirname "$file")"

  # Markdown links: [text](target)
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    target="${match#*](}"
    target="${target%)}"
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target="${target%%#*}"
    [[ -z "$target" ]] && continue
    if [[ ! -e "$dir/$target" ]]; then
      echo "FAIL: $file — link target not found: $target"
      status=1
    fi
  done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$file" || true)

  # [[name]] references — must match an existing skills/<name>/ directory.
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ ! -d "$REPO_DIR/skills/$name" ]]; then
      echo "FAIL: $file — [[$name]] does not match any skills/$name/ directory"
      status=1
    fi
  done < <(grep -oE '\[\[[a-zA-Z0-9_-]+\]\]' "$file" | sed -E 's/^\[\[//; s/\]\]$//' || true)
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find "$REPO_DIR/skills" -name '*.md' -print0)

check_file "$REPO_DIR/README.md"
check_file "$REPO_DIR/CONTRIBUTING.md"

# Recursive, not -maxdepth 1 — docs/eval/README.md and docs/eval/results/*.md
# were previously skipped here (issue #27), even though markdownlint's
# docs/**/*.md glob already covers them.
while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find "$REPO_DIR/docs" -name '*.md' -print0)

if [[ $status -eq 0 ]]; then
  echo "OK: no broken relative links or [[name]] references found"
fi

exit "$status"

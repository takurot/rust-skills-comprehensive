#!/usr/bin/env bash
# Install script for rust-skills-comprehensive.
#
# Copies (or symlinks) one or more skills from this repo's skills/ directory
# into a Claude Code skills directory — either a project's .claude/skills/
# or the user's global ~/.claude/skills/.
#
# Usage:
#   ./install.sh                          # install all skills, project-level (./.claude/skills)
#   ./install.sh --global                 # install all skills, global (~/.claude/skills)
#   ./install.sh --dest /path/to/project  # install all skills into <path>/.claude/skills
#   ./install.sh rust-api-design rust-async     # install only the named skills
#   ./install.sh --global rust-pinning          # combine scope + selection
#   ./install.sh --symlink                # symlink instead of copy (repo devs: live-edit)
#   ./install.sh --pause                  # wait for Enter after the final summary
#   ./install.sh --list                   # list available skills and exit
#   ./install.sh --force ...              # overwrite an existing install of the same skill
#
# Re-run any time to pick up updates (add --force to overwrite existing copies;
# symlink installs always reflect the latest content with no re-run needed).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

MODE="copy"          # copy | symlink
DEST=""              # resolved target .../.claude/skills directory
FORCE=0
PAUSE=0
SELECTED=()

CURRENT_TMP=""
CURRENT_BACKUP=""
CURRENT_TARGET=""

cleanup() {
    if [[ -n "${CURRENT_BACKUP:-}" && ( -e "$CURRENT_BACKUP" || -L "$CURRENT_BACKUP" ) ]]; then
        if [[ -n "${CURRENT_TARGET:-}" && ! -e "$CURRENT_TARGET" && ! -L "$CURRENT_TARGET" ]]; then
            mv "$CURRENT_BACKUP" "$CURRENT_TARGET" 2>/dev/null || true
        else
            rm -rf "$CURRENT_BACKUP"
        fi
    fi
    if [[ -n "${CURRENT_TMP:-}" && ( -e "$CURRENT_TMP" || -L "$CURRENT_TMP" ) ]]; then
        rm -rf "$CURRENT_TMP"
    fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

usage() {
    cat <<'EOF'
Install script for rust-skills-comprehensive.

Copies (or symlinks) one or more skills from this repo's skills/ directory
into a Claude Code skills directory — either a project's .claude/skills/
or the user's global ~/.claude/skills/.

Usage:
  ./install.sh                          # install all skills, project-level (./.claude/skills)
  ./install.sh --global                 # install all skills, global (~/.claude/skills)
  ./install.sh --dest /path/to/project  # install all skills into <path>/.claude/skills
  ./install.sh rust-api-design rust-async     # install only the named skills
  ./install.sh --global rust-pinning          # combine scope + selection
  ./install.sh --symlink                # symlink instead of copy (repo devs: live-edit)
  ./install.sh --pause                  # wait for Enter after the final summary
  ./install.sh --list                   # list available skills and exit
  ./install.sh --force ...              # overwrite an existing install of the same skill

Re-run any time to pick up updates (add --force to overwrite existing copies;
symlink installs always reflect the latest content with no re-run needed).
EOF
}

list_skills() {
    echo "Available skills:"
    for d in "$SKILLS_SRC"/*/; do
        name="$(basename "$d")"
        # Strip only the leading "description: " prefix — do NOT split on
        # ': ' generally (awk -F': ' used to do this, and truncated any
        # description containing ': ' elsewhere in its text, e.g. a quoted
        # error message like `"error: something"` — issue #26).
        desc="$(sed -n 's/^description: *//p' "$d/SKILL.md" | head -1)"
        printf '  %-28s %s\n' "$name" "$desc"
    done
}

PROJECT_DIR="$(pwd)"
SCOPE="project"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --global)
            SCOPE="global"
            shift
            ;;
        --dest)
            # Reject a missing argument *and* the next token being another
            # flag (e.g. `--dest --force`) — both used to fall through to
            # PROJECT_DIR="$2" and fail later with a raw, confusing error
            # (an unbound-variable crash, or `mkdir: illegal option --`)
            # instead of this script's own usage message (issue #25 review).
            if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
                echo "error: --dest requires a path argument" >&2
                usage
                exit 1
            fi
            SCOPE="custom"
            PROJECT_DIR="$2"
            shift 2
            ;;
        --symlink)
            MODE="symlink"
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --pause)
            PAUSE=1
            shift
            ;;
        --list)
            list_skills
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            SELECTED+=("$1")
            shift
            ;;
    esac
done

case "$SCOPE" in
    global)
        DEST="$HOME/.claude/skills"
        ;;
    project|custom)
        DEST="$PROJECT_DIR/.claude/skills"
        ;;
esac

if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "error: $SKILLS_SRC not found — run this script from inside the cloned repo." >&2
    exit 1
fi

mkdir -p "$DEST"

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    # Avoid `mapfile`/`readarray` (bash 4+ only) — macOS ships bash 3.2 by default.
    while IFS= read -r name; do
        SELECTED+=("$name")
    done < <(cd "$SKILLS_SRC" && ls -d */ 2>/dev/null | sed 's#/$##')
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "error: no skills found in $SKILLS_SRC" >&2
    exit 1
fi

echo "Installing ${#SELECTED[@]} skill(s) → $DEST  (mode: $MODE)"
echo

installed=0
skipped=0
not_found=0
INSTALLED_NAMES=()
SKIPPED_NAMES=()
FAILED_NAMES=()
for name in "${SELECTED[@]}"; do
    # Reject anything that isn't a plain directory name *before* it's used to build src/target
    # below — a name containing '/' or '..' can walk src/target outside SKILLS_SRC/DEST
    # entirely (arbitrary-path `rm -rf` under --force, since neither rm nor cp validates
    # containment; a single ".." segment is blocked by rm's own "refusing to remove '.' or
    # '..'" guard, but a longer traversal isn't — issue #44).
    case "$name" in
        ''|.|..|*/*)
            echo "  ✗ $name — invalid skill name (must be a plain directory name: no '/', '.', or '..')" >&2
            not_found=$((not_found + 1))
            FAILED_NAMES+=("$name")
            continue
            ;;
    esac

    src="$SKILLS_SRC/$name"
    if [[ ! -d "$src" ]]; then
        echo "  ✗ $name — no such skill in $SKILLS_SRC (see --list)" >&2
        not_found=$((not_found + 1))
        FAILED_NAMES+=("$name")
        continue
    fi

    target="$DEST/$name"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ $FORCE -eq 0 ]]; then
            echo "  – $name — already exists, skipping (use --force to overwrite)"
            skipped=$((skipped + 1))
            SKIPPED_NAMES+=("$name")
            continue
        fi
    fi

    # Stage-then-swap: copy or symlink into a temporary path first so that
    # any failure (e.g. disk full, permission error, Ctrl-C) leaves existing
    # installs intact.
    tmp_target="$DEST/.tmp.$name.$RANDOM.$$"
    backup_target=""
    CURRENT_TMP="$tmp_target"
    CURRENT_TARGET="$target"
    CURRENT_BACKUP=""

    if [[ "$MODE" == "symlink" ]]; then
        ln -s "$src" "$tmp_target"
    else
        cp -R "$src" "$tmp_target"
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        backup_target="$DEST/.old.$name.$RANDOM.$$"
        CURRENT_BACKUP="$backup_target"
        mv "$target" "$backup_target"
    fi

    if ! mv "$tmp_target" "$target"; then
        echo "  ✗ $name — failed to activate target" >&2
        # Exit directly: cleanup() restores $CURRENT_BACKUP to $CURRENT_TARGET
        # if target is missing, deletes $CURRENT_TMP, and never deletes
        # $CURRENT_BACKUP if restoring it fails.
        exit 1
    fi

    if [[ -n "$backup_target" && ( -e "$backup_target" || -L "$backup_target" ) ]]; then
        rm -rf "$backup_target"
    fi

    CURRENT_TMP=""
    CURRENT_BACKUP=""
    CURRENT_TARGET=""

    echo "  ✓ $name"
    installed=$((installed + 1))
    INSTALLED_NAMES+=("$name")
done

exit_status=0
if [[ $not_found -gt 0 ]]; then
    exit_status=1
fi

echo
if [[ $exit_status -eq 0 ]]; then
    echo "Status: Installation complete"
else
    echo "Status: Installation failed"
fi
echo "Destination: $DEST"
echo "Mode: $MODE"

if [[ $installed -eq 0 ]]; then
    echo "Installed (0): none"
else
    echo "Installed ($installed):"
    for name in "${INSTALLED_NAMES[@]}"; do
        echo "  - $name"
    done
fi

if [[ $skipped -eq 0 ]]; then
    echo "Skipped (0): none"
else
    echo "Skipped ($skipped):"
    for name in "${SKIPPED_NAMES[@]}"; do
        echo "  - $name"
    done
fi

if [[ $not_found -eq 0 ]]; then
    echo "Failed (0): none"
else
    echo "Failed ($not_found):"
    for name in "${FAILED_NAMES[@]}"; do
        echo "  - $name"
    done
    echo "error: $not_found skill name(s) did not match any directory under $SKILLS_SRC (see --list)" >&2
fi

if [[ $PAUSE -eq 1 ]]; then
    echo
    printf 'Press Enter to close...'
    if IFS= read -r _; then
        echo
    else
        echo
        echo "warning: --pause requested but stdin reached EOF; continuing without waiting." >&2
    fi
fi

exit "$exit_status"

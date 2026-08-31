Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No speculative error handling for truly internal impossible states. External input, persisted
  state, filesystem, subprocess, authentication, billing, capacity, and security boundaries always
  require explicit validation and fail-closed handling.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Testing

This repo is a content repo (Claude Code skills, not an application), so "testing" means the
gates in `docs/WORKFLOW.md`, not a unit-test suite.

- Changed a `SKILL.md`: run `./scripts/check-skill-frontmatter.sh` (frontmatter keys + line
  budget) and follow the Draft → Validate → Refine cycle in `docs/WORKFLOW.md` §4 — in
  particular the trigger-startup and non-duplication checks, and `/skill-stocktake` for any
  skill you added or changed.
- Changed `install.sh`: run `shellcheck --severity=warning install.sh` and the manual smoke test
  in `docs/WORKFLOW.md` §5 (list / copy install / symlink install / skip-without-`--force` /
  `--force` overwrite). The same checks run in CI (`.github/workflows/ci.yml`) — see
  `docs/WORKFLOW.md` §7 for the full pre-PR gate.
- Before commit, run `git diff --check` for whitespace issues, then the full gate in
  `docs/WORKFLOW.md` §7.

### Content-change workflow (required for skill edits)

1. Read the relevant upstream Comprehensive Rust source page(s) before writing — don't
   paraphrase from memory (`docs/WORKFLOW.md` §3.3, §4.1).
2. Draft the content; state which upstream `source:` pin it derives from.
3. Validate: frontmatter, line budget, trigger-startup, attribution, non-duplication against
   `rust-patterns` and neighboring skills (`docs/WORKFLOW.md` §4.2).
4. Refine based on what Validate found. Do not silently change a skill's `source:` pin, its
   delineation from other skills, or the `skills/` vs `.claude/skills/` symlink structure.

### Verification is required

- Never report a task as complete without running the relevant check command and showing
  output.
- Do not rely on your own summary as proof — the command output is the source of truth.

## 6. Bug Discovery During Other Work

**If you find a bug while doing something else, don't silently fix-and-move-on and don't let it
block the current task.**

When a bug turns up incidentally (not the thing you were asked to fix):
1. Search the codebase for similar patterns that could have the same defect (e.g. same
   copy-pasted logic, the same upstream source reused across multiple skills, the same helper
   misused elsewhere).
2. File a GitHub Issue (`gh issue create`) describing the bug, the affected location(s), and any
   similar patterns found in step 1 — even the ones you didn't confirm are broken.
3. Continue the original task. Only fix the bug inline if it blocks that task or the user asks
   for it directly — otherwise let the issue track it, per [Surgical Changes](#3-surgical-changes).

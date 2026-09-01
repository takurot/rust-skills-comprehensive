# Contributing

`rust-skills-comprehensive` distributes Claude Code **skills** (`SKILL.md` + optional
`references/*.md`), not application code. The full process — planning, drafting, validating,
and the git/PR mechanics — lives in [`docs/WORKFLOW.md`](docs/WORKFLOW.md); this file is a
short entry point into it, plus the checks to run before opening a PR.

Start with [`docs/PLAN.md`](docs/PLAN.md) (skill catalog, design rationale, delineation
between skills, status log) and [`docs/FILE_MAP.md`](docs/FILE_MAP.md) (topic index of the
upstream course) before writing anything.

## Adding or updating a skill

1. **Pick or open an issue.** For anything beyond a typo or a single dead link, work from a
   GitHub Issue. If the issue exists, follow the planning step in
   [`docs/WORKFLOW.md` §2.1](docs/WORKFLOW.md#21-issueからのプランニング) before touching
   code: read the issue, draft a plan against the invariants in
   [`docs/WORKFLOW.md` §1](docs/WORKFLOW.md#1-source-of-truth), and have a planning-only
   subagent (or a human reviewer) check it before implementing. To signal you've started
   manual work on an issue, add the `claude-code` label
   (`gh issue edit <N> --add-label claude-code`) — this only moves the linked Project card to
   "In Progress"; nothing runs automatically against issue content (see
   `.github/workflows/claude-code.yml` for why auto-implementation was removed as a
   prompt-injection risk).
2. **Branch from `main`**: `git switch -c skill/<short-description>` (or `docs/<...>` for a
   docs-only change). One branch = one skill addition/update, or one docs update — see
   [`docs/WORKFLOW.md` §3.2](docs/WORKFLOW.md#32-作業branchを作る).
3. **Draft → Validate → Refine** the skill content per
   [`docs/WORKFLOW.md` §4](docs/WORKFLOW.md#4-skill執筆サイクル): read the relevant upstream
   [Comprehensive Rust](https://google.github.io/comprehensive-rust/) source page(s) first
   (don't paraphrase from memory), keep the `source:` frontmatter's CC-BY-4.0/Apache-2.0
   attribution and pinned commit accurate, stay inside the ~500-line budget, and don't
   duplicate what `rust-patterns` or a neighboring skill already covers.
4. **Sync docs in the same PR** whenever they apply — see the table in
   [`docs/WORKFLOW.md` §8](docs/WORKFLOW.md#8-ドキュメントの同期) (README's skill table,
   `docs/PLAN.md`'s catalog/status, `docs/FILE_MAP.md`, etc.).

## Before opening a PR

Run the full local quality gate from
[`docs/WORKFLOW.md` §7](docs/WORKFLOW.md#7-変更前後の確認quality-gate):

```bash
git status --short --branch
git diff --check                 # whitespace/newline issues
./scripts/check-skill-frontmatter.sh
./scripts/check-install-list-sync.sh
./scripts/check-links.sh
shellcheck --severity=warning install.sh scripts/*.sh
npx --yes markdownlint-cli2 --config .markdownlint-cli2.jsonc "skills/**/*.md" "docs/**/*.md" "README.md" "CONTRIBUTING.md"
```

All of these also run in CI (`.github/workflows/ci.yml`:
`shellcheck` / `skill-frontmatter` / `install-list-sync` / `link-check` / `markdown-lint` /
`install-smoke-test`) — running them locally first just gets you feedback sooner. CI does
**not** check whether a skill's Rust guidance is technically correct or non-duplicative; that
stays a manual step:

- Read the changed `SKILL.md` through from its frontmatter and eyeball the Rust code blocks
  for syntactic validity.
- If you touched `install.sh`, run the manual smoke test in
  [`docs/WORKFLOW.md` §5](docs/WORKFLOW.md#5-installshを変更する場合).
- Run `/skill-stocktake` scoped to any skill you added or changed, and record the Keep/Fix/Drop
  result in `docs/PLAN.md`'s Status section.

Don't report a check as passing without having actually run it and looked at the output.

## Commit messages

Conventional Commits: `<type>: <description>`, where `<type>` is one of `feat`, `fix`,
`refactor`, `docs`, `chore` (adding a skill is `feat`; correcting a skill's content is `fix` or
`docs`; changing `install.sh`'s behavior is `feat`/`fix`). See
[`docs/WORKFLOW.md` §9](docs/WORKFLOW.md#9-コミットとpull-request) for the full commit/push
sequence — stage only the files your change touches, and don't include `ref/` (gitignored
vendor checkout) or personal paths.

## Pull requests

There is no PR template in this repo yet; until one exists, cover in the PR body what
[`docs/WORKFLOW.md` §9](docs/WORKFLOW.md#9-コミットとpull-request) asks for: the motivating
`docs/PLAN.md` section or issue, what changed and why, attribution/duplication/line-budget
impact, which checks above you ran (and which you couldn't, and why), and the
`/skill-stocktake` result.

Before merging:

- Run the mandatory subagent code review over `git diff main...HEAD` — see
  [`docs/WORKFLOW.md` §9.1](docs/WORKFLOW.md#91-pr作成後のサブエージェントレビュー). This
  supplements, not replaces, human review.
- Confirm the branch is conflict-free with `main` and every CI job is green — see
  [`docs/WORKFLOW.md` §9.2](docs/WORKFLOW.md#92-マージ前の確認).

[`docs/WORKFLOW.md` §10](docs/WORKFLOW.md#10-レビューと完了条件) has the full completion
checklist a change must satisfy before it's considered done.

## Feedback from using a skill

Used one of these skills in a real session and it helped (or didn't)? That's worth recording
even without a PR — see [`docs/FEEDBACK.md`](docs/FEEDBACK.md) for the format. It's the
lowest-friction way to surface a gap `/skill-stocktake` and `docs/eval/`'s exercise-based check
can't catch on their own (both check the skill in the abstract, not what actually happened when
someone used it).

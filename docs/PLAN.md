# Plan: Rust Skills from Comprehensive Rust

## Status

**Phases 1–3 built** — 11 skills live under `skills/` (project-level, per the recommendation
below): `rust-ownership-and-lifetimes`, `rust-api-design`, `rust-concurrency-sync`,
`rust-async`, `rust-newtype-and-raii`, `rust-typestate-and-tokens`, `rust-polymorphism`
(absorbed `extension-traits` as planned), `rust-unsafe-fundamentals`, `rust-unsafe-soundness`,
`rust-pinning`, `rust-ffi`. Each carries a `source:` frontmatter field with the CC-BY-4.0 /
Apache-2.0 attribution and upstream path pin. Sizes range 137–233 lines, within the ~500-line
budget.

**Validation pass complete (2026-08-29)**: moved `skills/` → `.claude/skills/` (the former was
not on any path Claude Code scans, so none of the 11 skills could ever trigger — fixed with
user confirmation). Ran `/skill-stocktake` full stocktake scoped to the 11 project skills:
all **Keep**, one defect found and fixed (`rust-polymorphism` referenced a not-yet-built
`rust-bare-metal` skill). Ran a manual trigger test across ~15 representative prompts —
`rust-concurrency-sync`/`rust-async` and `rust-unsafe-fundamentals`/`rust-unsafe-soundness`
correctly self-disambiguate via description vocabulary, no wrong-skill or dead-trigger cases
found. Global 257-skill stocktake was scoped out (out of this request) and left `in_progress`
in `results.json` for a future full run.

**Second defect found post-move, by the harness's own skill listing** (not by the stocktake
script): `rust-pinning`'s description showed up as the bare title "Rust Pinning" instead of
its real `description:` text — the frontmatter parser was tripped up by a colon-inside-
backticks span (`` `T: Unpin` ``) in the description value. Fixed by rewording to avoid a
literal `: ` inside backticks; verified no other skill's description contains the same
pattern. Lesson for future skill authoring in this repo: **avoid a colon followed by a space
inside inline code spans in `description:` frontmatter** — write "an unsatisfied `Unpin`
trait bound" rather than "the trait bound `T: Unpin`".

**Packaged for distribution (2026-08-29)**: canonical skill source moved to top-level
`skills/` (this is now the *distributable* location — see the repo root `README.md` and
`install.sh`); `.claude/skills/*` in this repo are now symlinks into `../../skills/*`, kept
only so this repo continues dogfooding its own skills without duplicating content. This
supersedes the earlier "moved skills/ → .claude/skills/" note above — read that as
historical, not current. `ref/comprehensive-rust/` (the vendored course, ~56MB) is gitignored
and not shipped; consumers who need to re-derive a skill from source should clone it
themselves at the pinned commit. `LICENSE-CODE` (Apache-2.0) and `LICENSE-CONTENT` (CC-BY-4.0)
vendor the upstream course's two license texts at the repo root.

**Not yet done**: Phase 5 (platform skills — still gated on user confirmation). Exercise-based
eval against the course's own exercises/solutions is now piloted for 2 exercises — see the
entry below and `docs/eval/README.md` — with several mapped exercises still deferred to a
follow-up. Phase 4 is done for what's in-scope for this repo — see the entry below.

**CI hardening (2026-08-31, issues #1–#3)**: closed a real gap in `skill-frontmatter` —
the script checked presence of frontmatter keys but never caught the actual `rust-pinning`
regression class above (a `: ` inside an unquoted YAML `description:` value truncates it);
fixed by failing on any `: ` in the description value, not just inside backticks. Added two
new CI jobs: `install-list-sync` (`./install.sh --list` vs `skills/*/` — a regression guard;
`install.sh`'s `--list` already derives from the same glob, so this can't catch drift today,
only a future refactor that reintroduces it) and `link-check` (relative Markdown links and
double-bracket refs (e.g. `[[rust-pinning]]`) across `skills/**/*.md`, `README.md`,
`docs/*.md`). `link-check` intentionally
does not flag bare-word skill-name mentions in prose (`rust-patterns`, `rust-analyzer`, etc.
are legitimate references to things outside this repo) — a dangling bare reference to a
not-yet-built skill (the `rust-bare-metal` defect above) stays a `/skill-stocktake` concern,
not a script one. `shellcheck` job widened to `scripts/*.sh`.

**Markdown lint (2026-09-01, issue #4)**: added `.markdownlint-cli2.jsonc` and a `markdown-lint`
CI job scoped to `skills/**/*.md`, `docs/**/*.md`, `README.md`. Rule selection is deliberately
narrow (heading structure + `MD040` fenced-code-language) rather than the full default
ruleset — this repo's prose is adapted from an external CC-BY-4.0 course, so line-length-style
rules would force rewrites of upstream-derived wording for no content benefit. Fixed the small
number of pre-existing violations this surfaced: missing blank lines after headings in
`FILE_MAP.md`, and three unlabeled fenced code blocks (`PLAN.md`, `README.md`,
`rust-ffi/SKILL.md`) tagged `text`.

**Exercise-based eval (2026-09-01, issue #6)**: added `docs/eval/` — a mapping of upstream
`exercise.md`/`solution.md` coding-exercise pairs to the skill(s) covering them, a
solve-blind/judge-with-solution methodology, and a report format
(`docs/eval/README.md`). Only 3 of the 11 skills have upstream chapters that ship a
self-contained *coding* exercise with a reference solution (`rust-ownership-and-lifetimes`,
`rust-unsafe-fundamentals`, plus the shared-`solutions.md` shape covering
`rust-concurrency-sync`/`rust-async`) — the rest of this skill set derives from
worked-example/prose pages or discussion-only exercises with no code solution to compare
against, so there's nothing this method can run for them; that's not a gap in the eval, see
`docs/eval/README.md`'s mapping table. Ran a first pilot
(`docs/eval/results/2026-09-01-pilot.md`): 2 exercises against `rust-ownership-and-lifetimes`
("Wizard's Inventory" from `borrowing/`, "Protobuf Parsing" from `lifetimes/`), each solved by
a fresh subagent given only the skill + exercise skeleton (no `solution.md`), then judged
against the real `solution.md` by this session. Both **PASS** — the solver's technique matched
`solution.md`'s, and each solver's own report cited the specific skill section that led it
there. Deferred to a follow-up: `unsafe-rust/exercise.md` (no missing dependency — its
`Cargo.toml` already has what it needs — left out purely for the setup time of its larger
skeleton; also straddles `rust-unsafe-fundamentals`/`rust-ffi` rather than cleanly mapping to
one skill) and the `concurrency/*` exercises (need their shared `solutions.md` split
per-exercise before they fit the Assemble step). Not wired into `.github/workflows/ci.yml` —
an LLM-driven solve/judge step doesn't fit the deterministic jobs there;
`scripts/check-eval-map.sh` is a local-only sanity check that the mapping's literal upstream
paths still exist, not a CI job.

**Phase 4 (2026-09-01, issue #9)**: `rust-patterns` is not part of this repo — it lives in a
separate repo (`everything-claude-code`) — so this repo's deliverable is the routing-block
text and gap-check findings, not a direct edit to that skill; see
`docs/rust-patterns-routing-block.md`. Checked every Day 1–2 topic in `docs/FILE_MAP.md`'s
Core Language section against `rust-patterns/SKILL.md` (read in full) and the relevant
upstream page: confirmed the `thiserror`/`anyhow` boundary is already covered correctly (the
"verify before touching" item from this section's earlier note), and found 2 genuine gaps —
`let else` (no example anywhere in `rust-patterns`) and the `?` operator's `From::from`
conversion mechanics (why `#[from]`/cross-error-type `?` works at all, which `rust-patterns`'
own `thiserror` example relies on without explaining). Both are documented as small
recommended edits for whoever maintains the `rust-patterns` repo, not applied here.

**Upstream drift detection (2026-09-01, issue #7)**: added `scripts/check-upstream-drift.sh` —
detects whether any file under a skill's declared `source:` paths changed on
`google/comprehensive-rust`'s default branch since this repo's pinned commit, via the GitHub
compare API (`gh api repos/google/comprehensive-rust/compare/<pin>...main`) rather than a
local `ref/comprehensive-rust` clone (gitignored, absent in CI). Ran it locally: clean against
the current pin (no drift), and verified the DRIFT-reporting path fires correctly against a
deliberately older test commit. `.github/workflows/upstream-drift.yml` runs it weekly (Monday
09:00 UTC) plus on `workflow_dispatch`, and opens/comments on an `upstream-drift`-labeled Issue
when drift is found — notification only, not an auto-fix. See `docs/WORKFLOW.md` §11.

Source map: [`FILE_MAP.md`](./FILE_MAP.md). Goal: turn Google's Comprehensive Rust course into
a set of Claude Code **skills** (`SKILL.md` + `references/`), each scoped tightly enough to
load fast and stay focused, together covering the course's teaching value — not a transcription
of the docs.

- **Upstream pin**: `ref/comprehensive-rust` @ `351fafa` (2026-08-05). Re-check before each
  authoring phase; the course is actively developed.
- **License**: course prose is **CC-BY-4.0**, code samples are **Apache-2.0** (see `LICENSE`,
  `LICENSE-CC-BY`, and the per-page SPDX headers). Any derived skill must carry attribution —
  see [Attribution requirement](#attribution-requirement-must-do).

## Revision note (v2)

v1 of this plan was written from file counts alone. Three findings changed the design:

1. **File count is the wrong weight metric.** Every course page carries a `minutes:` frontmatter
   field. Sizing by teaching-minutes reveals `leveraging-the-type-system` is **450 min** across
   just 35 files — v1 proposed cramming all of it into one skill. Budgets and splits below now
   use minutes.
2. **Lifetimes / borrowing / memory-management were wrongly dismissed** as "Day 1–2 basics
   already covered." They are Day 3, total ~249 min, and `rust-patterns` covers them in a single
   ~20-line "Ownership and Borrowing" section with nothing on lifetime elision, struct lifetimes,
   returning borrows, or reading borrow-checker errors. This is now a Phase 1 skill.
3. **"Complements `rust-patterns`" was hand-waving.** Verified: `rust-patterns` (499 lines)
   already has sections on newtype, trait objects, `Arc<Mutex<T>>`, channels, async/Tokio,
   unsafe, and modules. Every proposed skill overlaps it *somewhere*. The plan now states an
   explicit delineation rule and a routing table instead of asserting non-overlap.

## Design principles

- One skill = one coherent job a session reaches for mid-task ("I'm designing a typestate API"),
  not a subject area ("everything about types").
- **Budget: ≤ ~200 course-minutes per skill.** Anything larger gets split. `SKILL.md` ≤ ~500
  lines (matching existing `rust-patterns`); exhaustive tables and long worked examples go to
  `references/*.md`, loaded on demand.
- Patterns and pitfalls over prose. The course's *exercises* are eval material for the skill,
  not content to transcribe.
- Platform tracks (Android/Chromium/Bare-metal) only if the user's work actually targets them.

## Delineation vs. the existing `rust-patterns` / `rust-testing`

**Rule:** `rust-patterns` answers *"which idiom should I default to?"* in one screen.
The new skills answer *"how do I design and implement this correctly, and what will bite me?"*
when that idiom **is** the task. If a new skill can't say materially more than the
`rust-patterns` section on the same topic, it doesn't earn its place.

| Trigger during a session | Load |
|---|---|
| "write idiomatic Rust here" / general review | `rust-patterns` (unchanged) |
| write or fix tests, coverage, mocks, benches | `rust-testing` (unchanged, verified adequate) |
| borrow checker error, lifetime annotation, `Rc`/`RefCell` cycle | `rust-ownership-and-lifetimes` |
| designing a public API: naming, docs, which traits to impl | `rust-api-design` |
| wrapping a value in a type to enforce an invariant; `Drop` guards | `rust-newtype-and-raii` |
| compile-time state machines, permission/branded tokens | `rust-typestate-and-tokens` |
| `dyn` vs generics, sealed traits, "how do I do inheritance" | `rust-polymorphism` |
| threads, channels, `Send`/`Sync` errors, `Arc<Mutex>` deadlock | `rust-concurrency-sync` |
| async hangs, cancellation bug, `Pin` in a future, blocking executor | `rust-async` |
| writing `unsafe`, justifying a safety comment | `rust-unsafe-fundamentals` → deep-dive |
| calling C/C++ from Rust or vice versa | `rust-ffi` |

Deliverable of Phase 4: add a short "see also" routing block to `rust-patterns` itself so it
hands off rather than competing. Done as of issue #9 — see
[`docs/rust-patterns-routing-block.md`](rust-patterns-routing-block.md) (this repo produces
the block; applying it lives in the `rust-patterns` repo, which this repo doesn't own).

## Module weights (course minutes)

| Module | min | Files | Planned skill |
|---|---:|---:|---|
| `idiomatic/leveraging-the-type-system` | 450 | 35 | **split into 3** |
| ├ raii | 110 | | `rust-newtype-and-raii` |
| ├ token-types | 95 | | `rust-typestate-and-tokens` |
| ├ borrow-checker-invariants | 90 | | `rust-ownership-and-lifetimes` |
| ├ extension-traits | 65 | | → `rust-polymorphism` |
| ├ typestate-pattern | 65 | | `rust-typestate-and-tokens` |
| └ newtype-pattern | 20 | | `rust-newtype-and-raii` |
| `unsafe-deep-dive` | 343 | 83 | **split into 3** (ffi 94, pinning 80, intro 75, rules 44, init 24, preconditions 23) |
| `concurrency` | 332 | 43 | **split into 2** (sync 156 incl. exercises / async 176 incl. exercises) |
| `idiomatic/foundations-api-design` | 194 | 46 | `rust-api-design` |
| `idiomatic/polymorphism` | 182 | 24 | `rust-polymorphism` (+65 extension-traits = 247, watch budget) |
| `unsafe-rust` (intro-level) | 75 | 11 | `rust-unsafe-fundamentals` |
| `borrowing` | 73 | 8 | `rust-ownership-and-lifetimes` |
| `lifetimes` | 63 | 9 | `rust-ownership-and-lifetimes` |
| `memory-management` | 60 | 9 | `rust-ownership-and-lifetimes` |
| `smart-pointers` | 53 | 5 | `rust-ownership-and-lifetimes` |
| android / chromium / bare-metal | n/a | 48/30/41 | Phase 5, optional |

Platform modules don't populate `minutes:` — size them by file count only.

## Skill catalog

### Phase 1 — highest mid-task recall value

**1. `rust-ownership-and-lifetimes`** *(~249 min core + 90 min borrow-checker-invariants)*
Sources: `borrowing/*`, `lifetimes/*`, `memory-management/*`, `smart-pointers/*`,
`idiomatic/.../borrow-checker-invariants/*`.
The headline feature is a **borrow-checker error triage guide** — `borrowing/examples.md` and
`borrowck.md` map real `rustc` messages to causes and fixes. That is exactly the thing a session
needs mid-task and nothing in the current skill set provides it. Also: lifetime elision rules,
lifetimes in structs, returning borrows, `Cell`/`RefCell` choice, `Rc`/`Weak` cycles, aliasing-XOR-
mutability as the underlying model, `PhantomData` for lifetime/variance encoding.
*Draft description:* `Diagnose Rust borrow checker and lifetime errors, and choose between references, Cell/RefCell, Rc/Weak, and owned data. Use when rustc reports E0502/E0499/E0597/E0106, when adding lifetime annotations, or when designing structs that hold borrows.`

**2. `rust-api-design`** *(194 min)*
Sources: `idiomatic/foundations-api-design/*`.
Doc-comment anatomy (what/why, not how/where; signposting; library vs application docs),
the full naming convention set (`new`/`is_`/`_mut`/`with_*`/`try_*`/`from`/`into`/`to_`/`as_`/`by_`),
and a decision guide for which common traits to implement (`Debug`, `Display`, `PartialEq`/`Eq`,
`PartialOrd`/`Ord`, `Hash`, `Clone`, `Copy`, `From`/`Into`, `TryFrom`, serde) and the traps in each.
Highest density-per-minute module in the course; no overlap with the global `api-design` skill,
which is REST.
*Draft description:* `Design predictable Rust public APIs: method naming conventions, doc comment structure, and which std traits to implement. Use when writing a library crate's public surface, reviewing API ergonomics, or naming constructors and conversions.`

**3. `rust-concurrency-sync`** *(156 min)*
Sources: `concurrency/{threads,channels,send-sync,shared-state,sync-exercises}`.
Scoped vs spawned threads, bounded vs unbounded channel semantics, **reading and fixing
`Send`/`Sync` compile errors** (the highest-value part — `rust-patterns` has none of it),
`Arc<Mutex<T>>` lock-ordering and the dining-philosophers deadlock as the canonical failure.

**4. `rust-async`** *(176 min)*
Sources: `concurrency/{async,async-control-flow,async-pitfalls,async-exercises}`.
Lead with `async-pitfalls` (53 min): blocking the executor, `Pin` in futures, async traits,
and **cancellation safety** — real production bugs, and the reason this is separate from #3.
Then the futures/state-machine mental model, Tokio tasks, `join`/`select`.

### Phase 2 — idiomatic deep dives

**5. `rust-newtype-and-raii`** *(130 min)*
Newtype for semantic confusion and parse-don't-validate; encapsulation checks; then the large
RAII half — drop guards, drop bombs, `forget` vs `drop`, scope guards, `Drop` on `Option` fields,
and when `Drop` is *skipped*. `rust-patterns` mentions newtype in ~18 lines and RAII not at all.

**6. `rust-typestate-and-tokens`** *(160 min)*
Typestate pattern including the generic-typestate serializer worked example; token types:
permission tokens, mutex guards as tokens, and the 4-part branded-types series. Compile-time
state machines — a distinct design job from #5.

**7. `rust-polymorphism`** *(247 min — split if it overruns budget)*
Trait refresher (blanket impls, orphan rule, `Sized`, monomorphization and binary size), then
the decision content: `dyn` vs generics, dyn-compatibility, limits of trait objects,
heterogeneous collections, `Any`, sealed traits and sealing with enums, composition over
inheritance, and the "reaching too quickly for `dyn Trait`" pitfall. Absorbs `extension-traits`
(65 min: extending foreign types, method-resolution conflicts, when *not* to).
*Split candidate:* carve `rust-extension-traits` out if the SKILL.md exceeds ~500 lines.

### Phase 3 — unsafe & FFI

**8. `rust-unsafe-fundamentals`** *(75 min)* — `unsafe-rust/*`: raw pointer deref, mutable
statics, unions, unsafe fn/trait/impl, `extern "C"`. The everyday-unsafe skill.

**9. `rust-unsafe-soundness`** *(~166 min)* — `unsafe-deep-dive/{introduction,safety-preconditions,
rules-of-the-game,initialization,memory-lifecycle}`: how to derive and document safety
preconditions, the soundness/unsoundness framework, encapsulated vs exposed unsafe, "crying
wolf," `MaybeUninit` and partial initialization.

**10. `rust-pinning`** *(80 min)* — standalone, as v1 suspected and the minutes confirm.
What a move is, `Pin<Ptr>`, `Unpin`, `PhantomPinned`, the self-referential-buffer worked example
(C++ → raw pointer → offset → `Pin`), and `Pin` + `Drop`. Trips up experienced users; deserves
its own recall path, and `rust-async` links here rather than duplicating.

**11. `rust-ffi`** *(94 min + platform extracts)* — `unsafe-deep-dive/ffi/*` plus the
*general-purpose* parts of `android/interoperability/*` and `chromium/interoperability-with-cpp/*`:
Rust↔C↔C++ representation and semantic differences, bindgen, the `cxx` bridge model, type mapping,
and error handling across the boundary. Deliberately extracts the platform-neutral core so it's
useful outside Android/Chromium.

### Phase 4 — integration & gap-fill

**Done (issue #9)** — see [`docs/rust-patterns-routing-block.md`](rust-patterns-routing-block.md)
for the routing-block text and full gap-check table.

- Add the "see also" routing block to `rust-patterns`.
- Gap-check Day 1–2 content against `rust-patterns`; backfill only genuine gaps as small edits
  (candidates found in the map: `let-else`, try-conversions / `?` conversion mechanics,
  `thiserror` vs `anyhow` boundary — the last is already covered, verify before touching).
  Confirmed: both `let-else` and try-conversions are genuine gaps, `thiserror`/`anyhow` is
  already correctly covered. Since `rust-patterns` isn't part of this repo, backfilling is
  recommended to whoever maintains it rather than applied here.
- `rust-testing` verified adequate against the course's `testing/*` (unit, integration, doc tests,
  proptest, mockall, criterion, llvm-cov, CI all present). **No change planned.** Optional:
  clippy/lint guidance from `testing/lints.md` if not already in `rust-patterns`' tooling section.

### Phase 5 — platform-specific (build only on demand)

`rust-bare-metal` (41 files), `rust-android` (48), `rust-chromium` (30). Large but narrow.
Recommend **skipping unless the user confirms a target platform**; otherwise these are better
served by reading `ref/` directly.

### Explicitly not planned

Day-1/2 syntax basics (types, control flow, structs/enums, pattern matching, generics, closures,
std collections, error handling, modules) — adequately covered by `rust-patterns` plus base model
knowledge. Welcome/day-divider pages, credits, glossary, and the exercise directories as
standalone skills (exercises are eval input instead — see below).

## Attribution requirement (must-do)

Because the course is CC-BY-4.0, every generated skill must include, in `SKILL.md`:

```text
Adapted from Comprehensive Rust (https://google.github.io/comprehensive-rust/),
© Google LLC, CC-BY-4.0. Code samples Apache-2.0. Source pin: 351fafa.
```

Add a `source:` field to the frontmatter listing the specific course paths a skill derives from,
so refreshes against a newer upstream are mechanical.

## Validation

Each skill ships with acceptance criteria before it's considered done:

1. **Exercise-based eval.** The corresponding course exercises + solutions (`*/exercise.md`,
   `*/solution.md`, `exercises/**`) become the eval set: does a session with the skill loaded
   solve them, and does it do so *the way the course teaches*? The `eval-harness` and
   `tdd-workflow` skills already in this environment provide the scaffolding.
2. **Trigger test.** Given 5 realistic task prompts, does the skill's `description` cause it to
   load? A skill that never loads is worse than no skill — this is the #1 failure mode and the
   reason draft descriptions are specified above rather than deferred.
3. **Non-duplication check.** Diff each skill's claims against `rust-patterns`; anything that
   merely restates it gets cut.
4. **Portfolio audit.** Run `/skill-stocktake` after each phase.

## Build order

1. `rust-ownership-and-lifetimes` — highest recall value, fixes the largest real gap
2. `rust-api-design` — self-contained, no dependencies, high day-to-day payoff
3. `rust-concurrency-sync` + `rust-async` (natural pair)
4. `rust-newtype-and-raii` + `rust-typestate-and-tokens` + `rust-polymorphism`
5. Phase 4 integration & gap-fill
6. `rust-unsafe-fundamentals` → `rust-unsafe-soundness` → `rust-pinning` → `rust-ffi`
7. Platform skills only on demand

## Decisions needed

1. **Install location** — recommend **project-level** (`.claude/skills/`) while authoring, so
   they're versioned with this repo and reviewable, then promote the proven ones to
   `~/.claude/skills/`. Confirm or override.
2. **Platform tracks** — do bare-metal / Android / Chromium matter for your work? Default is
   **skip Phase 5 entirely** (saves ~119 files of narrow content).
3. **`rust-polymorphism` size** — start unified at 247 min and split `rust-extension-traits` out
   only if it overruns, or split up front? Recommend **start unified**.

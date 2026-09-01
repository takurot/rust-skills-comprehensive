# Exercise-based skill eval

**Issue:** [#6](https://github.com/takurot/rust-skills-comprehensive/issues/6) — does loading
a skill actually get you to the idiom the course teaches, not just a `/skill-stocktake`-style
description check?

`/skill-stocktake` verifies a skill's `description:` triggers correctly and doesn't duplicate a
neighbor. It says nothing about whether the skill's *content* actually steers someone toward
the course's idiom when they use it to solve a real problem. This eval closes that gap for the
subset of upstream chapters that ship a self-contained coding exercise with a reference
solution.

## Method

Three roles, kept separate so the model that *solves* the exercise never sees the official
solution (a solver that has already read `solution.md` isn't testing whether the skill's
guidance was sufficient — it's testing recall):

1. **Assemble** — take an exercise's student-facing skeleton (the exercise page's code block,
   with `todo!()`s) and the one skill under test. No `solution.md` content goes into this step.
2. **Solve** — a fresh agent (no prior context, no access to `solution.md`) is given only the
   skeleton and the skill's `SKILL.md`, and asked to implement it — compiling and running any
   provided tests where the exercise has them.
3. **Judge** — a separate pass (this can be the orchestrating session, since by this point
   seeing the solution is exactly its job) compares the solver's approach against
   `solution.md`, specifically for the *technique* the skill is supposed to teach (not just
   "did the tests pass" — a solution can pass tests via a different, less idiomatic route).
   Records a verdict below.

Run manually per exercise for now (see `docs/PLAN.md`'s note that this is designed to fold into
CI later, not wired in yet — an LLM-driven step doesn't fit the deterministic jobs in
`.github/workflows/ci.yml` as-is). `ref/comprehensive-rust/` (gitignored, see repo root
`.gitignore`) must be cloned at the pinned commit — see `docs/WORKFLOW.md` §3.3 — before
assembling any exercise.

### Verdict scale

| Verdict | Meaning |
|---|---|
| PASS | Solver's approach uses the same technique `solution.md` uses for the point the skill teaches; tests (if any) pass. |
| PARTIAL | Solves the exercise and tests pass, but via a materially different technique than `solution.md`'s (not necessarily wrong — but doesn't demonstrate the skill's guidance was what drove the choice). |
| FAIL | Doesn't compile, tests fail, or hits the exact pitfall the skill exists to prevent. |

## Exercise → skill mapping

Built by cross-referencing each skill's `source:` frontmatter paths (`docs/PLAN.md`'s catalog)
against `ref/comprehensive-rust/src/**` for `exercise.md`/`exercise.rs` + `solution.md` (or
`solutions.md`) triples that are actual coding exercises (not class-discussion prompts with no
code solution — several `idiomatic/**` exercises are the latter and are excluded below).

| Skill | Upstream exercise | Format | Status |
|---|---|---|---|
| `rust-ownership-and-lifetimes` | `borrowing/exercise.md` ("Wizard's Inventory") | standalone: `exercise.rs` has `// ANCHOR: setup/main/tests`, `solution.md` includes `// ANCHOR: solution` (the whole file) | **Run** — see `results/2026-09-01-pilot.md` |
| `rust-ownership-and-lifetimes` | `lifetimes/exercise.md` ("Protobuf Parsing") | standalone, same ANCHOR structure, larger (~200 lines) | **Run** — see `results/2026-09-01-pilot.md` |
| `rust-unsafe-fundamentals` | `unsafe-rust/exercise.md` ("Safe FFI Wrapper") | standalone, but the *content* is FFI (`CStr`/`OsStr`, wrapping `libc` calls) more than "everyday unsafe" — a good candidate to run with **both** `rust-unsafe-fundamentals` and `rust-ffi` loaded together next time; needs the `libc` crate as a dev-dependency | Mapped, not yet run — see Limitations |
| `rust-concurrency-sync` | `concurrency/sync-exercises/{dining-philosophers,link-checker}.md` | prompt page + starter `.rs` + shared `solutions.md` (multiple solutions in one file, `## Dining Philosophers` / `## Link Checker` headings) | Mapped, not yet run |
| `rust-async` | `concurrency/async-exercises/{dining-philosophers,chat-app}.md` | same shared-`solutions.md` shape as above (`## Dining Philosophers — Async` / `## Broadcast Chat Application`) | Mapped, not yet run |
| `rust-api-design` | `idiomatic/foundations-api-design/**/exercise.md` | class-discussion prompt (fill-in-the-blank naming, "ask the class" narrative) — **no code solution to compare against** | **Excluded** — not this eval's shape |
| `rust-newtype-and-raii`, `rust-typestate-and-tokens`, `rust-polymorphism`, `rust-unsafe-soundness`, `rust-pinning`, `rust-ffi` | — | — | **No `exercise.md`/`solution.md` pair exists under these skills' source paths upstream** (worked-example/prose pages only) — excluded, not a gap in this eval |

## Report format

Each run's results live in `docs/eval/results/<date>-<label>.md` with one section per exercise:

```markdown
## <skill> — <exercise title> (<upstream path>)

**Verdict:** PASS | PARTIAL | FAIL

**Solver setup:** <how the solver was invoked — fresh subagent, model, what it was given>

**Technique comparison:** <what `solution.md` does for the point the skill teaches, vs. what
the solver did — cite the exact skill section, if any, that should have (or did) inform it>

**Test/compile result:** <cargo test output summary, or "not compiled — reason", if the
exercise wasn't run to completion>
```

`docs/PLAN.md`'s Status section links to the latest run.

## Limitations of this pass

- Only 2 of the mapped exercises were actually run end-to-end (compiled + tested) in the pilot;
  the rest are mapped but deferred (`unsafe-rust/exercise.md` needs a `libc` dev-dependency and
  network-independent verification of directory-listing behavior; the `concurrency/*`
  exercises need the shared-`solutions.md` file split per-exercise before they fit the
  Assemble step cleanly — worth a follow-up rather than blocking this issue).
- This eval only covers skills whose upstream chapter shipped a self-contained coding
  exercise. Most of this skill set's advanced-topic skills (typestate, pinning, unsafe
  soundness, FFI, newtype/RAII, polymorphism) come from `idiomatic/leveraging-the-type-system`,
  `idiomatic/polymorphism`, and `unsafe-deep-dive/{pinning,ffi,...}` pages that are
  worked-example prose, not student exercises — there's nothing to run this method against for
  those skills. Their effectiveness stays a `/skill-stocktake` (trigger + non-duplication)
  concern, not this one.

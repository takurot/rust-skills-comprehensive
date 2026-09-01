# `rust-patterns` routing block + Day 1–2 gap check

**Issue:** [#9](https://github.com/takurot/rust-skills-comprehensive/issues/9) — Phase 4
(`docs/PLAN.md`'s "integration & gap-fill" phase, deliverable noted at PLAN.md's Delineation
section and Phase 4 list).

## Scope note

`rust-patterns` is **not part of this repository** — it lives in a separate repo
(`everything-claude-code`) and is installed at `~/.claude/skills/rust-patterns`. This repo's
`docs/WORKFLOW.md` (branches, CI, PR review) governs `rust-skills-comprehensive` only, so this
issue is closed here by producing the routing-block text and the gap-check findings as a
ready-to-apply deliverable — actually pasting the block into `rust-patterns/SKILL.md` and
committing there is a manual follow-up in that other repo, done by whoever maintains it, on its
own review process. Do not silently take that step in this repo's PRs.

## Routing block (paste into `rust-patterns/SKILL.md`)

A short "see also" section, in `rust-patterns`' own house style (plain prose + a compact
table, matching the format of that skill's existing sections). Suggested placement: right
before its own "Quick Reference: Rust Idioms" table, or as a new final section before
"Anti-Patterns to Avoid".

```markdown
## See Also — Deeper Dives

This skill answers "what's the idiomatic default here?" in one screen. When the task **is**
one of these specific problems, load the matching skill from
[`rust-skills-comprehensive`](https://github.com/takurot/rust-skills-comprehensive) instead —
they go deeper than a single screen can:

| When... | Load |
|---|---|
| `rustc` reports a borrow/lifetime error, or choosing `&T` vs `Rc`/`RefCell`/`Cell` | `rust-ownership-and-lifetimes` |
| Designing a library's public API — naming, doc comments, which traits to implement | `rust-api-design` |
| Wrapping a value to enforce an invariant, or using `Drop` to guarantee cleanup | `rust-newtype-and-raii` |
| Compile-time state machines (builders, protocol handshakes), permission/branded tokens | `rust-typestate-and-tokens` |
| `dyn Trait` vs generics, sealing a trait, porting an inheritance-shaped design | `rust-polymorphism` |
| `Send`/`Sync` compile errors, choosing a channel type, an `Arc<Mutex<T>>` deadlock | `rust-concurrency-sync` |
| "Concurrent" async code that isn't, a hang at `.await`, a cancelled future losing state | `rust-async` |
| Writing `unsafe` — raw pointers, mutable statics, `unsafe extern "C"` | `rust-unsafe-fundamentals` |
| Auditing whether an `unsafe fn` is sound for *every* legal input | `rust-unsafe-soundness` |
| `Pin<Ptr>`, `Unpin`, self-referential structs | `rust-pinning` |
| Calling C/C++ from Rust or vice versa | `rust-ffi` |
```

This table is the same delineation this skill set already documents internally
(`docs/PLAN.md`'s "Delineation vs. the existing `rust-patterns` / `rust-testing`" section) —
kept in sync with it; if that table changes, update this block too (and re-apply it in the
`rust-patterns` repo).

## Day 1–2 gap check

Checked every Day 1–2 topic in `docs/FILE_MAP.md`'s "Core Language" section against
`rust-patterns/SKILL.md` (read in full, 500 lines) and, where relevant, the actual upstream
page under `ref/comprehensive-rust/src/**`.

| Topic | Verdict | Notes |
|---|---|---|
| Hello World, Types & Values, Control Flow, Tuples & Arrays, User-Defined Types (structs/enums/const/static) | Not a gap | Base Rust syntax — relies on the model's own Rust knowledge, consistent with `docs/PLAN.md`'s existing "adequately covered by `rust-patterns` plus base model" framing (PLAN.md's Phase-4 section). |
| References (shared/exclusive/slices/dangling) | Not a gap | `rust-ownership-and-lifetimes` (this repo, Phase 1) covers this in depth for when it's the actual task; not `rust-patterns`' job to duplicate it. |
| Pattern Matching — exhaustive `match`, enum modeling | Covered | `rust-patterns`' "Enums and Pattern Matching" section. |
| **Pattern Matching — `let else`** | **Gap** | `rust-patterns` has no `let else` example anywhere. Upstream (`pattern-matching/let-control-flow/let-else.md`) frames it as *the* idiomatic form for "match a pattern or return/break/panic" — currently absent even though the adjacent `if let`/nested-match style is implicitly discouraged elsewhere in the skill (its "Option Combinators Over Nested Matching" section). |
| Methods & Traits, Generics (trait bounds, `impl Trait`, `dyn Trait` vs generics) | Covered | "Traits and Generics" section. |
| Closures (`Fn`/`FnMut`/`FnOnce`, capturing) | Not a gap | Common enough base-model knowledge; not called out in `docs/PLAN.md`'s own Phase-4 candidate list either. Noted here for completeness rather than left silently unchecked. |
| Standard Library Types (`Option`/`Result`/`String`/`Vec`/`HashMap`) | Covered | `Option` combinators, `Result`/`?`, `collect()` into various types. |
| Standard Library Traits (`From`/`Into`, comparisons, `Default`) | Partially covered | `From` appears only inside the `thiserror` example (`#[from] std::io::Error`); no explicit `Into`/`Default` guidance. Not flagged as a standalone gap — see the `?`/`From` finding below, which is the concrete case where this actually bites. |
| Iterators | Covered | "Prefer Iterator Chains Over Manual Loops", `collect()` with type annotation. |
| Modules | Covered | "Module System and Crate Structure" section. |
| Testing | Out of scope for this check | Already verified adequate against the course by a prior pass (`docs/PLAN.md`'s Phase-4 note: "`rust-testing` verified adequate... **No change planned.**"), covered by the separate `rust-testing` skill, not `rust-patterns`. |
| Error Handling — `Result`/`?`, panics discipline | Covered | "Use `Result` and `?` — Never `unwrap()` in Production". |
| Error Handling — `thiserror` vs `anyhow` boundary | **Confirmed already covered** (per `docs/PLAN.md`'s own note to "verify before touching") | `rust-patterns`' "Library Errors with `thiserror`, Application Errors with `anyhow`" section matches the upstream `error-handling/{thiserror,anyhow}.md` split correctly (library → typed errors via `thiserror`; application → `anyhow::Result`/`bail!`). No action needed. |
| **Error Handling — try-conversions (`?`'s `From::from` mechanics)** | **Gap** | `rust-patterns` shows `?` propagating errors but never explains *why* it works when the inner and outer error types differ — upstream's `error-handling/try-conversions.md` is explicit that `expr?` desugars to `match expr { Ok(v) => v, Err(e) => return Err(From::from(e)) }`, so a `From<InnerErr> for OuterErr` impl (as `rust-patterns`' own `thiserror` example actually uses, via `#[from]`) is *why* `?` can cross error-type boundaries at all. Without this, the `#[from]` attribute reads as unexplained magic. |
| Unsafe Rust (intro-level) | Covered, correctly delineated | `rust-patterns`' "Unsafe Code" section (acceptable/not-acceptable, `# Safety` comments) matches the upstream intro page's level; `rust-unsafe-fundamentals`/`rust-unsafe-soundness` (this repo) go deeper for when that's the actual task — no gap, no duplication. |

**Summary: 2 genuine gaps** — `let else`, and the `?`/`From` conversion mechanics behind
`thiserror`'s `#[from]`. Both are small (the upstream pages are 76 and 106 lines respectively,
mostly one code example each) and are recommended as small edits to `rust-patterns` itself
(not this repo) — see the Scope note above for why this repo doesn't apply them directly.

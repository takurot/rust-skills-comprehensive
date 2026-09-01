# rust-skills-comprehensive

Eleven [Claude Code](https://claude.com/claude-code) skills covering intermediate-to-advanced
Rust — ownership/lifetimes, API design, concurrency, async pitfalls, newtype/RAII, typestate,
polymorphism, and unsafe/FFI — adapted from Google's
[Comprehensive Rust](https://google.github.io/comprehensive-rust/) course.

Each skill targets a specific *job*, not a subject area: "diagnose this borrow checker error,"
"decide `dyn Trait` vs generics," "audit this `unsafe fn` for soundness" — not "everything
about ownership." They're meant to complement, not replace, a general Rust-idioms skill: load
one of these when the task at hand genuinely needs that depth, and a general skill otherwise.

## What's here

| Skill | Use it when |
|---|---|
| [`rust-ownership-and-lifetimes`](skills/rust-ownership-and-lifetimes) | `rustc` reports a borrow/lifetime error (E0502, E0499, E0597, E0106), or you're choosing between `&T`, `Cell`/`RefCell`, `Rc`/`Weak`, and owned data |
| [`rust-api-design`](skills/rust-api-design) | Designing a library's public surface — naming conventions, doc comments, which std traits to implement |
| [`rust-concurrency-sync`](skills/rust-concurrency-sync) | `Send`/`Sync` compile errors, choosing a channel type, an `Arc<Mutex<T>>` deadlock or hang |
| [`rust-async`](skills/rust-async) | "Concurrent" async code that isn't, a hang at an `.await`, a cancelled future losing state, an async trait that won't compile with `dyn` |
| [`rust-newtype-and-raii`](skills/rust-newtype-and-raii) | Wrapping a value to enforce an invariant, or using `Drop` to guarantee cleanup/finalization |
| [`rust-typestate-and-tokens`](skills/rust-typestate-and-tokens) | Compile-time state machines (builders, protocol handshakes) and proof-of-permission token types |
| [`rust-polymorphism`](skills/rust-polymorphism) | `dyn Trait` vs generics, porting an inheritance-shaped design, sealing a trait |
| [`rust-unsafe-fundamentals`](skills/rust-unsafe-fundamentals) | Writing everyday `unsafe` — raw pointers, mutable statics, unions, `unsafe extern "C"` |
| [`rust-unsafe-soundness`](skills/rust-unsafe-soundness) | Proving an `unsafe fn` is sound for *every* legal input, not just the ones you tested |
| [`rust-pinning`](skills/rust-pinning) | `Pin<Ptr>`, `Unpin`, self-referential structs, `Drop` on a `!Unpin` type |
| [`rust-ffi`](skills/rust-ffi) | Calling C/C++ from Rust (or vice versa): strings, ownership, `bindgen` vs `cxx` |

Each `SKILL.md` is self-contained (no shared dependencies between skills beyond an occasional
cross-reference), 137–233 lines, and states which upstream course pages it's adapted from in
its frontmatter.

## Install

Requires `bash` (macOS's default 3.2 works fine) and a clone of this repo.

```bash
git clone https://github.com/<you>/rust-skills-comprehensive.git
cd rust-skills-comprehensive
```

### Everything, into the current project

```bash
cd /path/to/your/project
/path/to/rust-skills-comprehensive/install.sh
```

Installs all 11 skills to `./.claude/skills/` in whatever directory you run it from.

### Everything, globally (all your projects)

```bash
./install.sh --global
```

Installs to `~/.claude/skills/`.

### Just the ones you want

```bash
./install.sh rust-ownership-and-lifetimes rust-async rust-pinning
./install.sh --global rust-ffi
```

### Symlink instead of copy

If you cloned this repo somewhere permanent and want installs to always reflect the latest
content without re-running the script:

```bash
./install.sh --symlink
./install.sh --global --symlink
```

### Other flags

```bash
./install.sh --list              # show all available skills with their descriptions
./install.sh --dest /some/path   # install into <path>/.claude/skills instead of cwd/global
./install.sh --force ...         # overwrite an existing install of the same skill(s)
./install.sh --help
```

Re-running is always safe: existing installs are skipped unless you pass `--force`; symlink
installs need no re-run at all to pick up edits.

### Manual install

Skills are plain directories — copying works too:

```bash
cp -R skills/rust-pinning ~/.claude/skills/
# or, for a single project:
cp -R skills/rust-pinning /path/to/project/.claude/skills/
```

### Uninstall

```bash
rm -rf ~/.claude/skills/rust-api-design            # or under <project>/.claude/skills/
```

## Repository layout

```text
rust-skills-comprehensive/
├── install.sh              # installer (see above)
├── skills/                 # the 11 skills — canonical source, this is what install.sh copies from
│   └── <skill-name>/
│       └── SKILL.md
├── .claude/skills/          # this repo's own dogfooding install (symlinks into ../../skills/)
├── docs/
│   ├── PLAN.md              # skill catalog design, module sizing, build order, status log
│   └── FILE_MAP.md          # map of the upstream course's ~450 source pages by topic
├── LICENSE-CODE             # Apache-2.0 — covers the Rust code samples inside each skill
├── LICENSE-CONTENT          # CC-BY-4.0 — covers the prose, adapted from the course
└── ref/                     # (gitignored) local clone of the upstream course, used only
                              #  while authoring/updating skills — not part of this distribution
```

`docs/PLAN.md` is the design document this skill set was built from — read it for *why* the
skills are scoped the way they are, what's deliberately not covered (Day-1/2 Rust basics,
platform-specific tracks), and what's still open.

## Attribution & license

The skills' prose is adapted from [Comprehensive Rust](https://google.github.io/comprehensive-rust/)
by Google LLC, licensed [CC-BY-4.0](LICENSE-CONTENT) — see that file for the full license.
Rust code samples in the original course (and reproduced or adapted in these skills) are
licensed [Apache-2.0](LICENSE-CODE). Each `SKILL.md`'s frontmatter names the exact upstream
paths it draws from and the pinned commit.

If you edit or extend a skill here in a way that still derives from the course text, keep the
attribution note in that skill's frontmatter and this README's license section accurate.

## Updating from a newer course revision

1. Clone the upstream course at the commit you want: `git clone https://github.com/google/comprehensive-rust ref/comprehensive-rust`.
2. Diff the relevant source pages (paths are listed in each skill's frontmatter) against what
   the skill currently says.
3. Update the skill's content and bump the `source:` pin in its frontmatter.
4. Re-run `docs/PLAN.md`'s validation steps that apply (trigger test, non-duplication check
   against any other skills you maintain) before shipping the update.

## Contributing

Issues and PRs welcome — in particular:
- Corrections where a skill's guidance has gone stale against current Rust.
- Gaps found in real use (a symptom/error message the diagnosis tables don't cover).
- The Phase 4/5 work noted as open in `docs/PLAN.md` (platform-specific skills for bare-metal,
  Android, or Chromium Rust — currently out of scope unless there's demand).

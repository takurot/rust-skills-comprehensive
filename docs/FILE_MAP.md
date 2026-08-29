# Comprehensive Rust — File Map

Source: `ref/comprehensive-rust/src/` (Google's Comprehensive Rust course, mdBook format).
All paths below are relative to `ref/comprehensive-rust/src/`. Total: ~450 Markdown pages,
driven by `SUMMARY.md` (the mdBook table of contents — treat it as the authoritative index).

Legend: 📄 file count in subtree · each section lists its own `SUMMARY.md` anchor file first.

## 0. Front matter / meta
- `index.md`, `README.md`, `running-the-course.md` (+`course-structure.md`, `keyboard-shortcuts.md`, `translations.md`)
- `cargo.md` (+`rust-ecosystem.md`, `code-samples.md`, `running-locally.md`)
- `thanks.md`, `glossary.md`, `other-resources.md`, `credits.md`
- `welcome-day-{1,2,3,4}.md`, `welcome-day-{1,2,3,4}-afternoon.md` — day dividers, mostly agenda text, low reuse value for skills.

## 1. Core Language — Day 1–2 (📄 ~100 files)
Fundamentals that almost every Rust skill will want to reference.

| Topic | Anchor | Children |
|---|---|---|
| Hello World | `hello-world.md` | `hello-world/{what-is-rust,benefits,playground}.md` |
| Types & Values | `types-and-values.md` | `types-and-values/{hello-world,variables,values,arithmetic,inference,exercise,solution}.md` |
| Control Flow | `control-flow-basics.md` | `control-flow-basics/{blocks-and-scopes,if,match,functions,macros,exercise,solution}.md`, `loops.md`+`loops/{for,loop}.md`, `break-continue.md`+`break-continue/labels.md` |
| Tuples & Arrays | `tuples-and-arrays.md` | `tuples-and-arrays/{arrays,tuples,iteration,destructuring,exercise,solution}.md` |
| References | `references.md` | `references/{shared,exclusive,slices,strings,dangling,exercise,solution}.md` |
| User-Defined Types | `user-defined-types.md` | `user-defined-types/{named-structs,tuple-structs,enums,aliases,const,static,exercise,solution}.md` |
| Pattern Matching | `pattern-matching.md` | `pattern-matching/{infallible,match,destructuring-structs,destructuring-enums,exercise,solution}.md`, `let-control-flow.md`+`let-control-flow/{if-let,while-let,let-else}.md` |
| Methods & Traits | `methods-and-traits.md` | `methods-and-traits/{methods,deriving,exercise,solution}.md`, `traits.md`+`traits/{implementing,supertraits,associated-types}.md` |
| Generics | `generics.md` | `generics/{generic-functions,trait-bounds,generic-data,generic-traits,impl-trait,dyn-trait,exercise,solution}.md` |
| Closures | `closures.md` | `closures/{syntax,capturing,traits,exercise,solution}.md` |
| Standard Library Types | `std-types.md` | `std-types/{std,docs,option,result,string,vec,hashmap,exercise,solution}.md` |
| Standard Library Traits | `std-traits.md` | `std-traits/{comparisons,operators,from-and-into,casting,read-and-write,default,exercise,solution}.md` |
| Memory Management | `memory-management.md` | `memory-management/{review,approaches,ownership,move,clone,copy-types,drop,exercise,solution}.md` |
| Smart Pointers | `smart-pointers.md` | `smart-pointers/{box,rc,trait-objects,exercise,solution}.md` |
| Borrowing | `borrowing.md` | `borrowing/{shared,borrowck,examples,exercise,solution}.md`, `interior-mutability.md`+`interior-mutability/{cell,refcell}.md` |
| Lifetimes | `lifetimes.md` | `lifetimes/{simple-borrows,returning-borrows,multiple-borrows,borrow-both,borrow-one,lifetime-elision,struct-lifetimes,exercise,solution}.md` |
| Iterators | `iterators.md` | `iterators/{motivation,iterator,helpers,collect,intoiterator,exercise,solution}.md` |
| Modules | `modules.md` | `modules/{modules,filesystem,visibility,encapsulation,paths,exercise,solution}.md` |
| Testing | `testing.md` | `testing/{unit-tests,other,lints,exercise,solution}.md` |
| Error Handling | `error-handling.md` | `error-handling/{panics,result,try,try-conversions,error,thiserror,anyhow,exercise,solution}.md` |
| Unsafe Rust (intro-level) | `unsafe-rust.md` | `unsafe-rust/{unsafe,dereferencing,mutable-static,unions,unsafe-traits,exercise,solution}.md`, `unsafe-functions.md`+`unsafe-functions/{rust,extern-c,calling}.md` |

## 2. Concurrency — Day-length module (📄 43 files)
- `concurrency/welcome.md`, `welcome-async.md`
- Threads: `threads.md` + `threads/{plain,scoped}.md`
- Channels: `channels.md` + `channels/{senders-receivers,unbounded,bounded}.md`
- Send/Sync: `send-sync.md` + `send-sync/{marker-traits,send,sync,examples}.md`
- Shared State: `shared-state.md` + `shared-state/{arc,mutex,example}.md`
- Sync exercises: `sync-exercises.md` + `sync-exercises/{dining-philosophers,link-checker,solutions}.md`
- Async basics: `async.md` + `async/{async-await,futures,state-machine,runtimes,runtimes/tokio,tasks}.md`
- Async control flow: `async-control-flow.md` + `async-control-flow/{channels,join,select}.md`
- Async pitfalls: `async-pitfalls.md` + `async-pitfalls/{blocking-executor,pin,async-traits,cancellation}.md`
- Async exercises: `async-exercises.md` + `async-exercises/{afternoon,dining-philosophers,chat-app,solutions}.md`

## 3. Idiomatic Rust — largest single module (📄 109 files)
- `idiomatic/welcome.md`
- **Foundations of API Design** `idiomatic/foundations-api-design.md`
  - Meaningful Doc Comments: `meaningful-doc-comments.md` + 7 sub-pages (who-are-you-writing-for, library-vs-application-docs, anatomy-of-a-doc-comment, name-drop-signpost, avoid-redundancy, what-isnt-docs, what-why-not-how-where, exercise)
  - Predictable API: `predictable-api.md`
    - Naming conventions: `naming-conventions.md` + 12 sub-pages (new, is, mut, with-constructor, with-copy-setter, with-closure, try, from, into, to, as-and-ref, by, exercise)
    - Common traits: `common-traits.md` + 10 sub-pages (debug, display, partialeq-eq, partialord-ord, hash, clone, copy, from-into, try-from-into, serde)
- **Leveraging the Type System** `idiomatic/leveraging-the-type-system.md`
  - Newtype pattern (+3), RAII (+7), Extension traits (+4), Typestate pattern (+7, incl. `typestate-generics/*`), Borrow-checker invariants (+6, incl. PhantomData series), Token types (+6, incl. branded-token series)
- **Polymorphism** `idiomatic/polymorphism.md`
  - Refresher (+9: traits, trait-bounds, deriving-traits, default-impls, supertraits, blanket-impls, conditional-methods, orphan-rule, sized, monomorphization)
  - From OOP to Rust (+15: inheritance, why-no-inheritance, switch-perspective, supertraits, composition, dynamic-dispatch/{dyn-trait,dyn-compatible,dyn-vs-generics,limits,heterogeneous,any-trait,pitfalls}, sealed-traits, sealing-with-enums, sticking-with-traits, problem-solving)

## 4. Unsafe Deep Dive — advanced module (📄 83 files)
- `unsafe-deep-dive/{welcome,setup}.md`
- Introduction (+15: definition, purpose, two-roles, warm-up/*, characteristics-of-unsafe-rust/*, responsibility-shift, impact-on-workflow, may_overflow)
- Safety Preconditions (+8: common-preconditions, getter, semantic-preconditions, u8-to-bool, determining, references, defining, ascii)
- Rules of the Game (+13: rust-is-sound, copying-memory/*, 3-shapes-of-sound-rust, soundness-proof/*)
- Memory Lifecycle: `memory-lifecycle.md`
- Initialization (+6: maybeuninit + arrays/zeroed-method/write-vs-assignment, how-to-initialize-memory, partial-initialization)
- Pinning (+16: what-pinning-is, what-a-move-is, definition-of-pin, why-difficult, unpin-trait, phantompinned, self-referential-buffer/* (cpp, rust-raw-pointers, rust-offset, rust-pin), pin-and-drop + worked example)
- FFI (+15, overlaps with §5): language-interop, strategies, type-safety, language-differences/*, abs, rand, c-library-example, cpp-library-example

## 5. Platform / Interop modules (own tracks, not part of the 4-day core)
- **Android** (📄 48): setup, build-rules (binary/library), AIDL (birthday-service tutorial + 8 sub-steps, types + 5 sub-types), testing (googletest, mocking), logging, interoperability with C (+5), C++ (+13 incl. cxx bridge/genrules), Java.
- **Chromium** (📄 30): setup, cargo-vs-chromium, policy, build-rules (+unsafe, depending, vscode, exercise), testing (+rust_gtest_interop, build-gn, import-macro, exercise), interoperability-with-cpp (+example-bindings, limitations-of-cxx, error-handling + qr/png examples, using-cxx-in-chromium, exercise), adding-third-party-crates (+11 sub-pages), bringing-it-together, solutions.
- **Bare Metal** (📄 41): no_std (+minimal, alloc), microcontrollers (+mmio, pacs, hals, board-support, type-state, embedded-hal, probe-rs+debugging, other-projects), Application Processors `aps.md` (+entry-point, inline-assembly, mmio, uart+traits/using, better-uart+bitflags/registers/driver, safemmio/*, logging+using, exceptions, aarch64-rt+exceptions, other-projects), useful-crates (zerocopy, aarch64-paging, buddy_system_allocator, tinyvec, spin), android bare-metal (vmbase), exercises (morning/afternoon + compass/rtc + solutions).

## 6. Exercises (📄 12, cross-cutting)
`exercises/bare-metal/*` and `exercises/chromium/*` hold exercise prompts + solutions that live outside their module's own directory — cross-reference when building any "exercises" skill.

## Rough size ranking (for prioritization)
1. Idiomatic Rust — 109 files (deepest, most skill-worthy content: API design, type-system tricks, polymorphism)
2. Unsafe Deep Dive — 83 files (advanced, narrow audience, high value for a dedicated "advanced unsafe" skill)
3. Core Language Day 1–2 — ~100 files across 20 small topics (foundational, likely already partly covered by the existing `rust-patterns`/`rust-testing` skills)
4. Android — 48 files (platform-specific, low general reuse)
5. Concurrency — 43 files (sync + async, high general reuse)
6. Bare Metal — 41 files (platform-specific, niche)
7. Chromium — 30 files (platform-specific, niche)
8. Exercises — 12 files (cross-cutting reference material)

# XIOM Stdlib -- Production Implementation Guide (handoff for the next session)

> Master guide for turning the 400+ comment-only stubs into 100% production-grade,
> optimized, secure stdlib implementations with smoke tests. Written 2026-08-11.
> Companion docs: `docs/STDLIB_AUDIT.md` (the doc->tree map + same-name homes),
> `docs/STDLIB_GENERICS.md` (R1-R9 generic/concrete policy), `docs/COMPILER_BUGS.md`
> (bug status), `docs/stdlib_session.md` S5b (dependency order L0-L4).

---

## 1. Compiler status -- what is a roadblock (checked 2026-08-11)

| Item | Status | Consequence for implementers |
|------|--------|------------------------------|
| BUG 1, 8, 9, 10, 11 | **FIXED** | tuple-of-struct, catalog `&Vec`/private types, float literals, unsafe-extern -- all usable |
| BUG 12 (`Vec[Float64]`/`[N]Float64` element reads) | **FIXED** (`2ae300fd`) | stats float containers, simd vec8/gather, probability stubs are now IMPLEMENTABLE |
| BUG 13 (fp128 helpers) | **FIXED** (`3b8f5415`) | `bigfloat_to_float128` can now land |
| BUG 14 (UInt64->UInt128 sext / UInt128 ashr) | **FIXED** | clean 64x64->128 mulhi available (no 32-bit-half hack needed) |
| BUG 15 (single-var inline mask drop) | **FIXED** | but KEEP the two-var form in new code -- it is the safe style |
| BUG 16/18 (skiplist+trie / string+similarity+time combos) | **FIXED** | smokes can be recombined; still keep stubs comment-only until implemented |
| BUG 17 (`Vec[Str]` element `==`) | **FIXED** | byte-wise compare no longer required (still fine) |
| **BUG 2** (module-global struct FIELD writes lost) | **OPEN** (advisory) | **AVOID** `g.field = x` on module globals -- use whole-value assignment `g = Struct{...}`. Only matters for precision-cached pi/ln10 and `const BIGINT_*` |
| **BUG 3** (module-global fn-call initializers zero) | **OPEN** (advisory) | **AVOID** `var G: T = make();` at module scope -- expose constants as pure constructor fns |
| S7 NASM/SIMD tracks (math/crypto/hash/compress asm, CPUID dispatch) | OPEN -- **off-limits to the stdlib session** (`crates/` + `stdlib/runtime/*.c` are the compiler session's files) | implement **pure-XIOM optimized** first; add `unsafe { asm }`/SIMD hot paths only if/once the compiler session exposes the S7 track, or coordinate with them. The `unsafe { extern }` C-FFI path (ffi.xi, libm) IS available for hot numeric loops with zero external deps (libm is the platform C runtime). |

**Rule: if an implementer hits a NEW compiler bug (any construct that miscompiles,
crashes, or silently corrupts), DO NOT work around it.** Append a dated section to
`docs/COMPILER_BUGS.md` (file, construct, error, repro) and stop that construct (or
leave a `// TODO(compiler): <BUG n>` comment and continue the rest of the batch).
The compiler session will pick it up. No workarounds for real bugs -- production
grade means the compiler gets fixed, then the code lands clean.

---

## 2. The production standard (applies to EVERY implemented function)

Each implemented `pub fn` in a sublib MUST satisfy ALL of these:

1. **Contracts + docs.** Doc comment above each pub fn (`///` or `//` per module
   style): purpose, params, returns, error cases, complexity (Big-O) where
   non-trivial. Add `requires:` / `ensures:` clauses where the language supports
   them (verify they parse -- see the aggregate `--check` caveat below).
2. **No silent failures.** Every fallible path returns `Result[T, Str]` /
   `Option[T]` (or a documented `DateParse`-style struct). No `try {} catch {}`
   swallowing; no unchecked index/div/parse. Log or propagate.
3. **Typed, semantic naming.** `get_user_by_id`, not `get_data`. Match the
   existing module's naming (many stubs already carry the intended names).
4. **Bounds & validation.** Validate/sanitize all inputs before use; index/div
   guards everywhere; no UB (no uninitialized reads, no out-of-bounds Vec/ptr).
5. **Performance.** Prefer pure-XIOM optimized algorithms (match the "expected"
   complexity in the stub). Avoid allocations in hot loops where the type allows.
   Use `unsafe { extern }` (libm/C runtime) ONLY for the documented hot primitives
   (math.xi sqrt/trig/exp already do this -- BUG 11 fixed). Vector/SIMD/asm go via
   S7 (see above) -- write the pure fallback + a clean seam for the dispatch.
6. **Security.** Crypto/hash/random: constant-time where timing matters
   (constant_time_eq pattern), no secret material in strings/logs, validate keys.
   Compression/parsing: guard against decompression bombs / length overruns.
7. **No generic abuse.** Follow `docs/STDLIB_GENERICS.md` R1-R9. Re-check each
   "blocked" stub now that BUG 12/15/17 are fixed -- most are unblocked. The S12
   interface-dispatch limitation still applies: trait-style generics
   (`into_str[T]`, `to_json[T: Serialize]`, `math/interfaces`) stay DECLARE-ONLY
   until compiler impl-dispatch lands -- implement the CONCRETE per-type fns.
8. **Keep the shape.** Keep the module name, keep the aggregate `use` line, keep
   the pub-fn signatures the stubs declared (they are the frozen API). New helper
   fns are `fn` (private) unless genuinely public.
9. **Qualified calls.** In user-facing examples/docs use `math.tower.sqrt`,
   `serialize.json.json_parse` (R9 same-name rule: 37 pairs disambiguate by path).

### Fixing existing modules as we go
The tree has 93 REAL modules written before these standards (bigint, bigfloat,
math.xi, num.xi, collections, fmt, string, geom, hash, etc.). As you implement
nearby sublibs, REFACTOR/repair the existing code to these standards too:
- fix the pre-existing `// TODO`/`_pure` gaps, add missing `requires`/`ensures`,
  add smokes, and split anything that grew past ~400-600 lines into sublibs
  (D4 pattern) -- keeping the module name and aggregate use-line.

---

## 3. Agent orchestration (how to parallelize)

- Work in **batches by category** (one agent per category or per 2-4 sublibs).
  Categories are independent except through `string` + `math.tower`/`num` (their
  shared foundations -- implement those FIRST).
- Each agent is given: the sublib's stub file, `docs/STDLIB_IMPLEMENTATION.md`
  (this guide), `docs/STDLIB_GENERICS.md`, the relevant `docs/STDLIB_AUDIT.md`
  S3 home note, and the module's existing real code (to match style + reuse).
- Each agent must:
  1. Implement every stub `// fn` in its file(s) to the S2 standard.
  2. Write a smoke in `examples/stdlib_smoke/smoke_<sublib>.xi` (exit 0, real
     assertions, covers success + error paths; float compares via tolerance or
     scaled-int).
  3. Run its smoke via the local compiler binary:
     `target/debug/xiom.exe -o <temp>/x.exe <smoke>` then run it -> must exit 0.
  4. UPDATE `docs/STDLIB_AUDIT.md` (flip the module's status STUB -> REAL, note
     the fn count + smoke) and `docs/stdlib_session.md` progress if asked.
  5. If it hits a NEW compiler bug: STOP that construct, append the dated section
     to `docs/COMPILER_BUGS.md`, leave `// TODO(compiler)` and continue the rest.
- Do NOT touch: `crates/`, `stdlib/runtime/*.c`, `xiom-benchmark-chaos/`,
  `.xiom_ai.json`. The compiler session owns those.
- Commit per batch (conventional): `feat(stdlib): <sub> -- <fns>` with the smoke.

### Suggested implementation order (bottoms-up, most-used first)
1. **string/** (string.xi repair + char/utf8/regex), **math/tower.xi** +
   **math/constants** + **math/primitives** (foundations everyone depends on).
2. **num/** (num.xi + bigint + bigfloat repair, bigfloat_to_float128 now),
   **fmt/** (sprintf/sscanf already done -- add missing), **collections/** base.
3. **hash/**, **rand/**, **encoding/**, **convert/**, **time/**, **io/**,
   **os/** core.
4. The rest of **math/** (arithmetic/roots/exponential/trig/special/combinatorics/
   numerical/finance/...), **geom/**, **stats/** (float containers now OK),
   **crypto/** (cipher/sign/keyx/aead), **compress/**, **signal/**, **net/**,
   **serialize/**, specialized math domains (game_theory, information_theory,
   control_theory, machine_learning, ...) -- each as demand/time allows.
5. Re-run gates after each multi-module batch (see S4).

---

## 4. Verification gates

- Per sublib: `xiom.exe --check <file>` for the module; compile+run its smoke
  (exit 0).
- Per batch: `cargo test -p xiom-codegen --test stdlib_tests --test stdlib_api_freeze_tests`
  (the compiler session must FIRST update the path list in `stdlib_tests.rs` to
  the new category layout -- module names are unchanged, only paths moved; ask
  them if it is not yet done) and `--test stdlib_execution_tests` after
  multi-module batches.
- NOTE: `xiom.exe --check` on an AGGREGATE file (math.xi, num.xi, string.xi, ...)
  currently reports pre-existing `extern "C"`/`requires:`/`ensures:` parse errors
  when checked STANDALONE -- this is a checker quirk, NOT a code error; the real
  test is compiling a program that imports the aggregate (the smokes do this).

---

## 5. Compiler bugs to fix next (for the compiler session, prioritized)

Already FIXED this cycle: BUG 12-18. Still OPEN and worth doing:
1. **BUG 2** -- module-global struct FIELD writes lost (unblocks precision-cached
   pi/ln10 and `const BIGINT_*/BIGFLOAT_*`).
2. **BUG 3** -- module-global fn-call initializers zero (same unlocks).
3. **S7 NASM/SIMD** -- expose the asm/CPUID track so hot math/hash/crypto can use
   it (stdlib session writes the pure fallbacks + dispatch seam).
4. **S12 interface dispatch** -- trait-based generic math (`impl Num[T]`)
   unblocks `math/interfaces`, trait-style convert/serialize generics.

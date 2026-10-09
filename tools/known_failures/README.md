# Known-failing reproductions (not part of the probe corpus)

This directory is the intake for minimal reproductions of compiler-lane
findings. Files are excluded from `tools/probes/` so the probe runner and CI
stay green; resolved probes are promoted to `tools/probes/` and ruled-out
ones to `tools/probes/evidence/`. There were no open findings as of
2026-09-22 (compiler R61); the Current section below lists the findings
opened since, and the history records what was here and how each item
closed.

Run one manually with:

```powershell
xiom --force -o out.exe tools/known_failures/<file>.xi
```

## Current

Status check 2026-10-09 (compiler v0.64.2, tag `c51170a6`): every Current
repro below was re-compiled and re-run on the new pin. Observed rcs are
unchanged from the entries except where noted; `p_array_zip_no_truncate.xi`
and `p_sibling_dup_fn_alias.xi` are now RESOLVED (entries in the history
below). The compiler-side batch m222..m242 also fixed deep container
equality, zero-length `[0]T` by value at clang, and the verifier SMT array
model; compiler main has since moved past the tag (d9f146cb, m244 null
guards under `--overflow-checks`). The 2026-10-09 relays are recorded in
`docs/stdlib_session.md` block 83. Wave-98 follow-up: the M7
stdlib-side fix landed (closure rewrite of the four adapters; entry moved
to the history below), the packages rows 168/169 were fixed stdlib-side
(read_file_lines empty file -> zero lines; to_string_char NUL clause),
and a new import-corruption finding was filed (first entry below).

**Open finding 2026-10-09 (compiler v0.64.2): importing
`xiom.convert.tostring` corrupts closure predicate dispatch.** With
`use xiom.convert.tostring ...` in the same module (any alias; the plain
leaf import too), `Range.filter`/`Range.take_while` predicates never see
the values on v0.64.2: `range(0, 6).filter(lt3).next()` returns None and
`take_while` returns None with `done` set, while the identical program
without the tostring import is correct (`iter`+`io`, `iter`+`array`,
`iter`+`array.fixed` combinations all behave). Inline lambdas are
affected exactly like named function pointers; `Range.step_by` (no
predicate) is unaffected. Found while building the wave-98 probe; the
probe was split (`p_wave98_shapes.xi` + `p_wave98_tostring_shapes.xi`) as
the workaround. Repro:
`tools/known_failures/p_tostring_import_breaks_adapters.xi` (rc 1 on
v0.64.2; expected rc 0).

**Open finding 2026-10-08 (compiler v0.64.1): `@pre` on `&mut` parameter
scalar fields aliases the post-mutation value.** Found while landing the
wave-94 sync clauses: a clause
`(x.a@pre < 100) => (x.a == x.a@pre + 1)` on a `&mut Pair` parameter
violates at runtime (`contract violated: ensures`), because `x.a@pre`
reads the value AFTER the body mutation. The same aliasing hit
`sem_try_acquire`/`sem_release`/`cdl_count_down` (`&mut Semaphore` /
`CountDownLatch` field reads); those clauses were rewritten to
post-state forms and the sync surface keeps @pre-free clauses. Self-field
`@pre` on method receivers is correct on the pin (wave-93 `Range.next`,
probe p_wave93_shapes.xi), so this is the `&mut`-parameter half of the
historical R49 entry-snapshot residual (see the
`p_pre_capture_callee`/`p_pre_call_capture` history below). Repro:
`tools/known_failures/p_mut_param_field_pre.xi` (rc 1 on v0.64.1;
expected rc 0).

**Open finding 2026-10-08 (compiler v0.64.1): generic by-reference params
(`&Option[T]`/`&Result[T, E]`, bounded `&Slice[T]`) read wrong or fail
codegen.** Found while probing the wave-94 core clauses:
`core.option_is_some(&o)` returns false for `Some(4)` while the direct
`o.is_some` is true; `option_is_none`/`result_is_ok`/`result_is_err`
silently misread the same way (generic `&Vec[T]` params such as
`cmp.min_of_vec` are correct on the pin). The Slice surface has the same
family of failures: `is_sorted`/`contains`/`min_slice`/`max_slice`
(`T: Ord`/`T: Eq` over `&Slice[T]`) fail
`error[C001]: type 'Slice' does not implement 'Ord': missing method
'compare'` (the bound lands on the argument's full type), the annotated
`Slice[Int]` local from `array.as_slice` reads `.len()` wrong, and
`core.slice_len` is wrong/crashes depending on annotation. Repros:
`tools/known_failures/p_generic_byref_option.xi` (rc 2 on v0.64.1;
expected rc 0) and `tools/known_failures/p_slice_bound_generic_c001.xi`
(compile-fail; expected rc 0). Stdlib impact: those four Option/Result
standalone queries and the whole Slice-param helper set
(`is_sorted`/`all`/`none`/`contains`/`slice_*`/`min_slice`/`max_slice`/
`sum_slice`) stay clause-free until this resolves.

**Open finding 2026-10-08 (compiler v0.64.0): cross-module type paths and
method-style foreign calls.** Two resolution traps found while landing the
wave-89 serialize/json clauses in `tools/probes/p_wave89_shapes.xi`:
(a) with `use xiom.serialize as ser;`, the alias-qualified TYPE path
`ser.SerializeError{...}` fails `T001: unknown type 'ser.SerializeError'`
while the bare `SerializeError{...}` compiles (types import unqualified);
(b) the full path `xiom.serialize.SerializeError{...}` compiles with only
a `warning: unknown type ... defaulting to i64` (silent layout risk);
(c) the method-style call `v.json_get_path(&path)` on a foreign
`JsonValue` fails `C001: unresolved function symbol
'JsonValue.json_get_path'` while the qualified call
`json.json_get_path(v, &path)` works. Repros:
`tools/known_failures/p_alias_module_type_path.xi` (T001) and
`tools/known_failures/p_foreign_method_call.xi` (C001); both expected
rc 0 when fixed. Cross-reference: C-PULSE-12 (alias shadowing by a
consumer module whose last segment collides with a stdlib module) is the
same resolution family; PULSE renamed their module as the workaround.
Workaround in stdlib: use bare type names with alias imports and
qualified function calls for foreign surfaces.

**Open finding 2026-10-07 (compiler v0.64.0): clause payload-length
claims guarded with `(result.is_ok == true) =>` violate at runtime; the
canonical `result is Ok =>` form works.** Found while landing the wave-80
convert base-codec clauses: `(result.is_ok == true) => (result.len() ==
s.len())` on `Result[Str, Str]` aborts with `contract violated: ensures`
for a correct Ok payload, while the identical claim written
`result is Ok => result.len() == s.len()` (the form every canonical
module uses) is green on the same call. The checker should either reject
the implication form at compile time (like other unsupported clause
payload reads) or evaluate it like the guarded form. Repro:
`tools/known_failures/p_ensures_isok_guard.xi` (rc 1 on v0.64.0).
Expected when fixed: rc 0.

**RESOLVED 2026-10-05 (compiler v0.63.1, fix `4bf8cf1e`): the C001
classifier is fixed.**
The direct-form iter-range reducer (`range-sums + contains`) flips between
compiling and failing
`C001: 'contains' receiver does not expose a concrete Vec/Slice/Array
element type` for identical invocations. Six consecutive compiles of the
reducer on v0.62.4 gave 3 failures and 3 passes; the registry lane's
20-run stress measured `smoke_iter_range` 8/20 and
`smoke_iter_find_all_any` 12/20 on v0.62.4 (8/20 and 10/20 on v0.62.3);
`smoke_iter_range` also flaps under the 8-worker corpus runner while
direct compiles pass. Consistent with classifier state derived from
HashMap-iteration order -- the wave-62 "cleared" C001 state was
probabilistic, not fixed. Repro
`tools/known_failures/p_iter_range_contains_c001.xi` (expected rc 0;
current pins compile-fail a random subset of runs). The two flaky smokes
were removed from the release gate on v0.63.1 (20/20 + 20/20 stress);
the C001 carve-out file now holds no exclusions, and ci/heavy keep running
the full corpus.

**RESOLVED 2026-10-09 (wave 98, stdlib-side fix): the M7 `Iterator[T]`
adapters are callable.** Per the compiler-lane diagnosis the fix was
stdlib-side: the four adapters were rewritten to the closure-based shape
the rest of `iter.xi` uses (`next_fn: fn() -> Option[T]`) and are
constructed from Range (`Range.step_by`/`take_while`/`skip_while`/
`inspect`); the `Iterator[T]` interface receivers are gone, so the 5x
"unknown type 'Iterator'" warnings no longer appear for `xiom.iter`
consumers. `p_iter_iterator_type_unresolved.xi` exits 0; the new probe
`p_wave98_shapes.xi` locks the step_by/take_while/skip_while/inspect
sequences and the constructor claims (iter 45.4% -> 46.4%). History: on
v0.64.1/v0.64.2 the receivers could not bind at codegen
(`C001 Iterator.step_by`) and the fields fell back to i64.

**RESOLVED 2026-10-09 (compiler v0.64.2): `array_zip` truncates to the
shorter array in every direction.** Verified on the official v0.64.2 pin:
the M < N, M == 0 (either side) and N <= M directions all return
min(N, M) pairs (the wave-96 repro `p_array_zip_no_truncate.xi` exits 0;
an extended check with both zero-length directions also exits 0). The
array_zip clause keeps the N <= M direction until the next coverage wave
extends it to the full min relation.

**RESOLVED 2026-10-09 (compiler v0.64.2, m242): triplicate sibling
submodule exports resolve again.** `p_sibling_dup_fn_alias.xi` compiles
and exits 0 on the pin; the wave-97 split probe was merged back into
`p_wave97_shapes.xi` (2026-10-09, per the pin-protocol relay) and
re-run green on v0.64.2 -- the single-file import combination works as
well. History: on v0.64.1 importing three sibling submodules that export
the same function name broke alias-qualified calls (`cannot call
'next_pow2' on this expression`) while two-module combinations passed.

**RESOLVED 2026-10-08 (compiler v0.64.1, m200): inline indexing of a
returned `Vec[Float64]` rvalue reads correctly.** Verified rc 0 on the
official pin and PROMOTED to `tools/probes/p_rvalue_float_vec_index.xi`
(regression lock). History: `mk_f()[0]` misread the raw bits on
v0.61.3-v0.64.0 while bound locals and the `Vec[Int]` control were
correct; found by the wave-77 probe; `xiom.stats.moments.quantile` binds
the sorted copy first.

**RESOLVED 2026-10-08 (compiler v0.64.1, m203): the `xiom.iter`
closure-thunk CLAUSE leak.** Re-added `ensures: result >= 0` to
`Range.count` and landed the retried set (contains x2, sum, product,
collect, count-empty, max, min, find, all, any, nth, last), then verified
`smoke_iter` 21/21 (including at -Workers 8, which used to surface the
C001 flake), `p_pin0641_iter_shapes.xi` green pre/post and the repro
PROMOTED to `tools/probes/p_iter_range_collect_forwardref.xi` (rc 0).
History: on v0.62.3-v0.64.0 any Range.count/Range.find clause made
generated `__closure_N` code fail clang with `use of undefined value`
(the call side was already fixed on v0.62.4+). Remaining iter surface
work (chain 14 + fold 8 + the rest of the deferred 40-60 set) continues
as normal coverage waves.

**RESOLVED 2026-10-05 (compiler v0.64.0, m195): `xiom.reflect.all_types()`
no longer heap-corrupts; the probe exits 0.** m195 keeps angle-bracket
generic receivers' type args, fixing the catalog function's return path.
`all_types` now carries `ensures: result.len() == type_count()` and is
exercised by `tools/probes/p_pin0640_shapes.xi` (the repro
`tools/known_failures/p_reflect_all_types_crash.xi` stays as a regression
lock and now exits 0). History: crashed with 0xC0000374 (STATUS_HEAP_CORRUPTION,
run rc -1073740940) on v0.62.3, v0.62.4, v0.63.0, v0.61.3 and the m187+
dev builds; the wave-64 reflect clauses kept all_types clause-free and
probe-excluded until fixed.

**RESOLVED 2026-10-08 (compiler v0.64.1, m201): `multipart_parse` result
Part field reads are correct.** Verified rc 0 on the official pin and
PROMOTED to `tools/probes/p_multipart_parse_name.xi` (regression lock).
History: parsed Part `.name`/`.len()` read corrupt on
v0.61.3-v0.64.0 while direct Part construction was correct; found in
wave 62.

**Open finding 2026-10-02 (compiler v0.61.3 and v0.62.1):
`polyhedra.convex_hull_2d`/`convex_hull_3d` collapse on nonempty inputs.**
The hull of a 4-point square is 2 rows; the hull of a tetrahedron is 0 rows
(empty inputs are correct). The bodies already use the local-copy workaround
for nested float Vec reads, so it is insufficient on both pins; the result
itself is collapsed (caller and callee length reads agree). Repro:
`tools/known_failures/p_polyhedra_nested_hull.xi`. Found while
landing the wave-53 geom clauses; the wave-53 probe keeps only the
empty-input hull checks. `geometry_2d.convex_hull` (Point2 rows) is correct.
COMPILER RELAY 2026-10-07: fixed on m201 (dev build); move out at the
next pin.
V0.64.1 RE-CHECK 2026-10-08: NOT fixed on the official pin -- the square
hull is still 2 rows (rc=1, would be 2 for the tetra), so the repro
STAYS in known_failures. The m201 fix did not cover this instance; the
relay classification needs a correction on the compiler side.

**Open finding 2026-10-01 (stdlib algorithm, not a compiler bug):
`geometry_2d.polygon_difference` intersects b's outside half-planes instead
of taking the difference.** For a closed b the result is usually empty, so
`polygon_difference(a, b)` returns None even for disjoint a and b (where
Some(a) is expected). Found by the wave-52 probe; the existing smoke never
exercised the polygon booleans. Repro:
`tools/known_failures/p_polygon_difference_halfplanes.xi` (returns 1).
Needs a real polygon-clipping implementation; the doc comment now states
the limitation.

**Open finding 2026-10-01 (compiler v0.61.3): `xiom.geom.geometry_3d.Box`
is unnameable from consumers.** The leaf `Box` is shadowed by core's
`Box[T]`; `Box{...}` resolves to the core type ("no field 'min'"), neither
`geometry_3d.Box{...}` ("unknown type") nor `use ...Box as GBox;` works, and
there is no constructor, so `aabb_intersection`/`aabb_contains`/
`ray_box_intersection` cannot be called from any other module. Repro:
`tools/known_failures/p_geom_box_unnameable.xi` (compile-fail on the pin).
Found while landing the wave-52 geom clauses; the wave-52 probe keeps those
three functions clause-only until the geom dedup/rename (queue section C).

**Open finding 2026-09-30 (compiler v0.61.3 and v0.62.1): call-site
inference of `xiom.geom.matrix` `Vec[Vec[Float64]]` results loses a nesting
level.** A local declared without an explicit type (`var z =
matrix.zero(2, 2);`) reads its rows as garbage (`z[0].len()` is 0;
`matrix.one` surfaces the raw double bits as the row length), and the same
happens for tuple elements (`var l2 = lu.0;`). Adding the explicit type
(`var z: Vec[Vec[Float64]] = ...`) fixes both reads. The identical
un-annotated shape via `xiom.geom.mat` (`mat_identity`) is correct, and
single-level `Vec[Float64]` returns are unaffected. Repro:
`tools/known_failures/p_geom_matrix_result_infer.xi`. Found while landing
the wave-50 geom clauses; the wave-50 probe annotates every nested
matrix-module local, and `smoke_geom_mat.xi` already verifies
matrix-module results through det/trace/rank scalars.
COMPILER RELAY 2026-10-07: fixed on m201 (dev build); move out at the
next pin.
V0.64.1 RE-CHECK 2026-10-08: PARTIALLY fixed -- the inferred local (check
1) and the annotation control (checks 2-3) now pass, but the
tuple-element-without-annotation case still fails (`var l2 = lu.0;` ->
`l2[0].len()` is 0, rc=4), so the repro STAYS in known_failures with the
updated expected signature (rc 4 on the official pin).

**Open finding 2026-09-29 (compiler v0.61.3): clause-position indexing of
Float64 vector elements reads garbage.** In an `ensures` clause, indexing a
`Vec[Float64]` return value (`result[0] == 1.0`) or a row of a
`Vec[Vec[Float64]]` return value (`result[0].len() == 2`) fails with
"contract violated: ensures at <line>:12" even though the values were just
stored by the body; length-only claims on the same results (`result.len()`)
are fine, and the identical shapes on `Vec[Int]` / `Vec[Vec[Int]]` PASS.
Repro: `tools/known_failures/p_clause_float_vec_index.xi` (Int controls run
green first, then `bug_f64` violates). Found while landing the wave-49 geom
clauses; the shipped mat clauses were reduced to len-only claims. Expected:
the clause sees the stored elements. Stdlib impact: row/column shape claims
on Float64 matrices (`mat_identity`, `mat_mul`, `mat_transpose`, `mat_det`,
`mat_inv`) are weakened to length/interval claims until this is fixed.

**Open finding 2026-09-28 (compiler v0.61.3): a shape-mismatched `&Vec`
argument compiles silently and crashes.** Passing `&Vec[Float64]` where
`&Vec[Vec[Float64]]` is expected produces no diagnostic; the callee's
nested element read then AVs (run rc 0xC0000005, -1073741819). Repro:
`tools/known_failures/p_vec_shape_arg_mismatch_av.xi` (the same program
with both arguments `Vec[Vec[Float64]]` compiles and runs green in
`tools/probes/p_wave42_shapes.xi`). Expected: a type error at the call
site. Found while writing the wave-42 probe.

**Open finding 2026-09-25 (compiler v0.61.3): Result/Option payload reads
in CATALOG contract clauses are broken and can poison user codegen.**
Reproduced while landing the regex coverage wave:

1. **Clause poisoning (nested-Vec `Option` payload)**: with
   `xiom.regex.regex.Regex.captures` carrying
   `ensures: result is Some => result.value.groups.len() == 1`, every
   user-side call to `captures` fails to COMPILE -- clang rejects the IR
   (`error: '%tmp117' defined with type '%struct.Vec'`). Replacing the
   clause with a payload-free guard (`self.pattern.len() == 0 => result is
   Some`) makes the same program compile and run. Verified by re-adding the
   one-line clause (compile rc 1) and removing it (rc 0). Evidence file:
   `tools/probes/evidence/p_result_payload_ir_repro.xi` (green today; the
   header records the exact one-line trigger).
2. **Result-Ok Str payload reads in catalog clauses**: `regex_unescape`'s
   `result is Ok => result.value.len() <= s.len()` fires a FALSE
   "contract violated: ensures at 66:12" on every Ok call from a user
   module (two inputs observed), and `regex_parse`'s
   `result.value.pattern == pattern` exits 0xC0000005. Int-field consumers
   of the same Ok payload pass in isolation (`group_count <= node_count`
   verified in a small program), BUT the same Int-field clause fails inside
   the larger `smoke_regex` program ("contract violated: ensures at
   101:12") even though both `regex_parse` calls pass in isolation and with
   the smoke's import set -- i.e. it interacts with the documented
   engine-registry/codegen corruption that smoke_regex's header warns about
   (statement order matters). Err-payload length clauses in catalog
   functions pass on WINDOWS (io parse errors), `Option[Str]` payload
   `.len()` clauses pass (error context), and a user-module function with
   the same Ok-Str clause passes -- so the failure needs the catalog
   boundary plus the payload read.
   UPDATE 2026-09-28 (release-blocking, Linux): the Err-payload clause on
   `regex_unescape` (`result is Err => result.value.len() > 0`) passes on
   Windows but VIOLATES on Linux -- the ubuntu release gates for
   stdlib-v0.62.0 failed on smoke_regex with "contract violated: ensures at
   66:12" (run 36487728296), reproduced locally in WSL with the v0.61.3
   Linux binary, and the same clause site is green after removing it. So
   Err-Str payload reads are platform-dependent and must be treated as
   unsafe everywhere, not just for Ok payloads.
   Stdlib mitigation in place: affected clauses replaced with payload-free
   guards (`result is Err => pattern.len() > 0`,
   `pattern.len() == 0 => result is Ok`), and the `regex_unescape`
   Err-payload clause removed 2026-09-28; re-add the full clauses when the
   compiler lane fixes the payload ABI and the engine-registry corruption.
   Minimal repro shape (needs a catalog function): `pub fn f(s: Str) ->
   Result[Str, Str] ensures: result is Ok => result.value.len() <= s.len()`
   called from a user module; the Err variant
   (`ensures: result is Err => result.value.len() > 0`) is the one that
   differs between Windows and Linux.

**Open finding 2026-09-24 (compiler v0.61.3): cross-type generic callback
returns are miscompiled.** A `[T, U]`-style generic whose callback changes
type (`fn(&T) -> U` or `fn(T) -> U`) returns a wrong value whenever `U` is a
different runtime type than `T` (Str / Float64 observed); concrete callbacks
and same-type generic callbacks are correct. Minimal reproductions
(per-file status on official v0.62.3): `p_generic_typechanging_fnptr.xi`
now PASSES; `p_generic_typechanging_map.xi` (run 41),
`p_generic_typechanging_core_map.xi` (run 41) and
`p_generic_typechanging_sortbykey.xi` (run 1) still fail. v0.61.3 status:

- `p_generic_typechanging_fnptr.xi` -- packages-lane `conv[T, U]` shape
  (by-ref callback, Int -> Str): expected 0, observed run 23.
- `p_generic_typechanging_map.xi` -- by-value Vec map, Int -> Str:
  expected 0, observed run 41 (Int -> Float64 also wrong: exit 100).
- `p_generic_typechanging_core_map.xi` -- core `Option[Int].map[U]`:
  expected 0, observed run 41 (the `Result[Int,Str].map` leg fails the same).
- `p_generic_typechanging_sortbykey.xi` -- STDLIB EXPOSURE:
  `xiom.sort.sort_by_key[Int, Str]` mis-sorts silently (expected 0,
  observed run 1); `sort_by_key[Str, Int]` and `[Int, Int]` are correct.

Matrix: Int->Str by-ref/by-value broken; Int->Float64 broken; Int->Int
correct; Str->Int correct; closed-world concrete callbacks correct. Corpus
impact: the shipped smokes only exercise same-type maps
(`smoke_core_option_map`/`smoke_core_result_map` map Int -> Int) and
`sort_by_key` has no smoke at all, so the gate is green while these shapes
are silently wrong. Also affected in the stdlib surface: `array.map[T,U]`
and `iter` `Range.map[U]`/`MapIter.map[V]` for cross-type `U` (verified:
Int -> Str wrong, run 41).
Promote each file to `tools/probes/` (expected run exit 0) when the
compiler lane fixes the callback ABI.

**Resolved 2026-10-03 (stdlib-side, not a compiler regression; found in the
v0.62.3 baseline):** the two cell smokes (`smoke_cell_refcell_basic.xi`,
`smoke_cell_ref_get.xi`) called `borrow()` and then `borrow_mut()` without the
documented `Ref.release()`/`RefMut.release()` (6D.1 made the handles
pointer-based and the caller owns the release until Drop exists). The
v0.61.3-era copy-by-value RefCell never restored borrow counts, so the
omission was accidentally green. Both smokes now release; verified green on
v0.61.3 and official v0.62.3.

**Resolved before 2026-09-22 (compiler R61 `ff293f8e`).** Every probe
that used to be listed here is resolved or ruled; the green locks live in
`tools/probes/`.

- `p_generic_push.xi`, `p_gp_b.xi`, `p_gp_c.xi` -- **RESOLVED 2026-09-22**
  on R61 (`ff293f8e`, e2e_m116): a local explicit-generic call
  (`make_holder[JsonValue]()`) never recorded its substituted return type, so
  the holder field fell to a scalar 8-byte load; all three now compile and
  run green (`A=[42]`, `B=["tree"]`, `C=[9]`). **Moved to `tools/probes/`.**

- `p_result_tuple_vec_loop.xi`, `p_ref_tuple_mangle.xi` -- **RESOLVED
  2026-09-22** on R59/R60 (`2aad5ecd`, stdlib findings): match-slot leak into
  loop bodies and tuple element naming. Both run green on R61. **Moved to
  `tools/probes/`.**

- `p_async_read_line_codegen.xi` -- **RESOLVED stdlib-side 2026-09-22**: the
  compiler lane ruled the 0xC0000409 a stdlib fd/FILE* misuse, not codegen.
  `xiom.async.io` now reads and writes descriptors through the runtime
  `xiom_read`/`xiom_write` helpers in `async_read`, `async_write`,
  `async_read_line` and `async_read_until` (the `fread`/`fwrite` externs stay
  for real FILE* handles in `async_read_file`/`async_write_file`); the probe
  runs green on R61. **Moved to `tools/probes/`.**

- `p_hash_probe.xi` -- **RULED 2026-09-22** (R61, e2e_m117): interface-typed
  parameters erase to i64 and an aggregate argument is now rejected loudly
  (`error[C001]: unsupported: interface-typed parameter ...`) instead of
  silently returning a wrong value; the probe locks the rejection. Not a bug.
  **Archived in `tools/probes/evidence/`** to re-add as a green probe when the
  interface ABI lands.

- `p_fnref.xi` -- **RULED 2026-09-22**: function-value identity is
  unspecified; the observed behaviour (distinct module-qualified fn values
  comparing equal) needs a language-spec decision rather than a compiler fix.
  **Archived in `tools/probes/evidence/`.**

- `q1_verify_all.xi` -- **RESOLVED 2026-09-21** on R58 (watchdog class);
  promoted to `tools/probes/`.
- `p_pre_capture_callee.xi` -- **RESOLVED 2026-09-20** on compiler main
  R52 (R51 `c235b3fe`: the `@pre` walkers descend through Imply/Is so
  implication-wrapped clauses emit entry snapshots), **moved to
  `tools/probes/`**: `--run` exits 0. IMPACT history: the R49 residual
  aliased ref-param entry snapshots when a CALLEE mutated scalar fields /
  computed-index Vec loops, which kept `tools/probes/p_wave8_shapes.xi` red
  and forced `@pre`-free clauses in nine `collect/*` modules; the strong
  size relations are restored and the targeted smoke families (20/20) pass
  on R52. Compiler-side lock: e2e_m104.

- `p_module_path_alias.xi` -- **RESOLVED 2026-09-19** on compiler main
  `306073ba` (R49-1), **moved to `tools/probes/`**: the catalog keys modules
  by their declared header, `process_use` rewrites non-declared paths
  up-front, and the freeze resolver gained a declared-header index. Path
  imports of the 19 mismatched modules (`crypto/legacy/*`,
  `core/{cmp,contracts,platform}`, `os/*`, ...) are `--check` clean and
  `stdlib_api_freeze_tests` is 2/2 (0 missing).

- `p_pre_call_capture.xi` (2026-09-18) -- **RESOLVED 2026-09-19** on compiler
  main `306073ba` (R49, `0f2213bc`), **moved to `tools/probes/`**: `--run`
  exits 0, no contract violation. IMPACT history: after fixing the
  run_smokes runtime-detection bug, 11 corpus smokes were aborting on these
  clauses; every call-`@pre` clause in the stdlib was replaced with an
  `@pre`-free equivalent. The direct shape is fixed, so the restored
  clauses are verified in `collections.xi` (method receivers) and
  `rc`/`sync` clone counters; the callee-mutation residual above still
  blocks scalar-field shapes.

- `p_os_env_set_link.xi` -- **RESOLVED 2026-09-19**, moved to
  `tools/probes/p_os_env_set_link.xi`. `runtime/xiom_runtime.c` now exports
  `xiom_env_set` / `xiom_env_unset` (`_putenv_s` on Windows,
  `setenv`/`unsetenv` elsewhere) and `xiom.os` / `xiom.env` call those, so
  the former Windows link failure (`undefined symbol: setenv`) is gone and
  the probe round-trips set/get/remove on every platform.

- `p_result_payload_contract.xi` -- **RESOLVED 2026-09-19** on compiler main
  `306073ba` (R49-3), **moved to `tools/probes/`**. History: one module with
  two Result-returning functions whose `ensures` clauses read the payload
  (`result.value`) -- a scalar payload (Int) plus a Vec payload -- broke
  clang (`'%tmp46' defined with type '%struct.Vec' but expected 'ptr'`); the
  `is Err` payload form failed the same way combined with a Vec-payload Ok
  contract. Impact: wave-13 kept payload-reading clauses out of io/fs;
  R49-3 unblocked them, and wave 17 (2026-09-21) applies them across
  io/fs, io/console and io/pipe, pre-validated by
  `tools/probes/p_wave17_shapes.xi`.

- `p_sweep_single_param.xi` -- **RESOLVED 2026-09-21** on compiler main
  `7837b194` (R54: large fixed arrays emit memset + address access instead of
  the crashing aggregate zeroinit/whole-array loads). History: the raw
  generated single-param call set failed codegen from v0.60.0 through R52
  (R43 tuple mismatch, then a clang ISel `0xC0000005` on
  `@__unsafe_block_77`; IR deterministic; crash header
  `p_sweep_single_param.clang-crash.txt`). The raw file compiles+links in
  ~51s on the R53/R54 binary. It is unsafe to execute (null-FFI arguments
  fast-fail in the CRT; `async_read_line` at EOF is the separately tracked
  crash), so the promoted regression lock is the runtime-guarded
  `tools/probes/p_sweep_single_param.xi` (the calls sit behind an
  `XIOM_SWEEP_RUN` env guard: type-check and codegen always happen, the
  calls never run) and the raw call set is archived at
  `tools/probes/evidence/p_sweep_single_param_raw.xi`. Regenerate the
  surface with `tools/gen_call_probes.ps1 -MinParams 1 -MaxParams 1
  -Timeout 0` (60 modules / 239 calls as of R53).

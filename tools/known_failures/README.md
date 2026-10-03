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

**Open finding 2026-10-03 (compiler main `659f6ec1` / m178 dev build only;
GREEN on the v0.61.3 gate pin): `xiom.contracts.any_contracts()` crashes
(0xC0000005).** Minimal repro
`tools/known_failures/p_contracts_any_av.xi` (v0.61.3 rc=0; m178 build
rc=0xC0000005). Found bisecting `tools/probes/p_never_called_zeroarg.xi`
(call 3 of 71) during the pre-v0.62.3 tag check.

**Open finding 2026-10-03 (compiler main `659f6ec1` / m178 dev build only;
GREEN on the v0.61.3 gate pin): `xiom.sync.Arc.new(42).strong_count()` is
not 1.** Minimal repro `tools/known_failures/p_sync_arc_count.xi` (v0.61.3
rc=0; m178 build rc=1). Found via `tools/probes/p_sync_sizeof.xi` during
the pre-v0.62.3 tag check.

**Open finding 2026-10-02 (compiler v0.61.3 and v0.62.1): struct literals
with out-of-declaration-order fields compile silently and assign fields
positionally.** `P{ z: 3.0; y: 2.0; x: 1.0 }` for `type P = { x; y; z }`
yields `p.x == 3.0, p.y == 2.0, p.z == 1.0` on both pins (the checker emits
no diagnostic; codegen stores the i-th supplied value in declared slot i).
All other stdlib literals are in declaration order, so one site was
affected: `xiom.geom.quat_from_euler` wrote `Quaternion{ w; x; y; z; }`
(declaration order x; y; z; w), scrambling every Euler-derived rotation --
reordered in wave 54 (fix-first). Repro:
`tools/known_failures/p_struct_literal_field_order.xi` (returns 1).
Expected: name-keyed literal semantics, or at least a checker error for
out-of-order fields.

**Open finding 2026-10-02 (compiler v0.61.3 and v0.62.1):
`polyhedra.convex_hull_2d`/`convex_hull_3d` collapse on nonempty inputs.**
The hull of a 4-point square is 2 rows; the hull of a tetrahedron is 0 rows
(empty inputs are correct). The bodies already use the local-copy workaround
for nested float Vec reads, so it is insufficient on both pins; the result
itself is collapsed (caller and callee length reads agree). Repro:
`tools/known_failures/p_polyhedra_nested_hull.xi` (returns 1). Found while
landing the wave-53 geom clauses; the wave-53 probe keeps only the
empty-input hull checks. `geometry_2d.convex_hull` (Point2 rows) is correct.

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

**Open finding 2026-10-01 (compiler v0.61.3): a fn-typed parameter returning
`Vec[Float64]` loses its result inside catalog bodies.** `curves.curve_length`
calling a `fn(Float64) -> Vec[Float64]` argument sees empty vectors and
returns 0 instead of the arc length; the same function value called directly
returns the correct value. Vec-returning sibling of the fixed Float64-thunk
class. Repro: `tools/known_failures/p_curve_thunk_zero.xi` (returns 2).
Found while landing the wave-51 geom clauses; the wave-51 probe keeps only
the `n < 1 == 0` branch for `curve_length`.
UPDATE 2026-10-02: FIXED compiler-side (m170 a/b, `COMPILER_BUGS.md`
2026-10-02): fn-typed param Vec returns keep their element type and the
erased Option/Result literal payload slot is forced to i64. The stdlib
repro returns rc=0 on the local v0.62.2 dev binary. The m170b half also
fixes the erased Option-of-Vec `.unwrap()` AV class (`vector.refract`).
Promote on the next pin.

**Open finding 2026-10-01 (compiler v0.61.3 and v0.62.1): caller-side
element reads of some `xiom.geom.vector` / `xiom.geom.curves` results are
bit-reinterpreted.** `vector.lerp` returning `(1.5, 2.0)` reads back as
`4.6094342186137e+18` (the bit pattern of 1.5 as a double); same for
`vector.clamp`, `vector.hadamard`, `curves.b_spline`. Callee-side reads are
correct (passing the results into `vector.norm`/`distance` sees the true
values), and `cross`/`normalize`/`unit`/`project`/`reject`/`slerp`/
`reflect`/`outer`/`bezier_quad`/`bezier_cubic`/`bezier_derivative` read
correctly in the caller. Repro:
`tools/known_failures/p_geom_vector_result_bits.xi` (control green, then
   two broken reads). Found while landing the wave-51 geom clauses; the
   wave-51 probe and `smoke_geom_vec.xi` mediate those results through
   dot/norm/distance.
   UPDATE 2026-10-02: FIXED compiler-side (m169, `COMPILER_BUGS.md`
   2026-10-02): same-leaf qualified results now resolve the exact catalog
   key. The stdlib repro returns rc=0 on the local v0.62.2 dev binary
   (pre-fix rc=2). Keep in known_failures until the gate pin carries m169,
   then promote to `tools/probes/` and un-mediate the wave-51 probe/smoke
   reads.

**Open finding 2026-09-30 (compiler v0.61.3 and v0.62.1): call-site
inference of `xiom.geom.matrix` `Vec[Vec[Float64]]` results loses a nesting
level.** A local declared without an explicit type (`var z =
matrix.zero(2, 2);`) reads its rows as garbage (`z[0].len()` is 0;
`matrix.one` surfaces the raw double bits as the row length), and the same
happens for tuple elements (`var l2 = lu.0;`). Adding the explicit type
(`var z: Vec[Vec[Float64]] = ...`) fixes both reads. The identical
un-annotated shape via `xiom.geom.mat` (`mat_identity`) is correct, and
single-level `Vec[Float64]` returns are unaffected. Repro:
`tools/known_failures/p_geom_matrix_result_infer.xi` (returns 1 on the
pin). Found while landing the wave-50 geom clauses; the wave-50 probe
annotates every nested matrix-module local, and `smoke_geom_mat.xi`
already verifies matrix-module results through det/trace/rank scalars.

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
and same-type generic callbacks are correct. Minimal reproductions (all
verified on v0.61.3, compile 0 + wrong run exit):

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

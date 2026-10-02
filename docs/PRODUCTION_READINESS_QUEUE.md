# Production-readiness remaining queue (handoff 2026-09-25)

**70% -- 7 of 10 readiness gates complete.**
**Gates: corpus 951/951, modules 509/509, probes 210/210, barename 0/509.**

Readiness gates (the meter above counts these; each is backed by the battery
recorded in the updates below). Update the two lines above and this list as
gates flip:
1. Modules type-check clean -- MET (509/509).
2. Smoke corpus green -- MET (951/951).
3. Probe corpus green -- MET (210/210).
4. Strict bare-name scan clean -- MET (0/509).
5. Coverage ratchet green -- MET (floors92).
6. Documentation ratchet 100% -- MET.
7. Module-smoke ratchet green -- MET (497/517 modules, 3421/6200 fns).
8. Contract coverage 100% (every public fn carries clauses) -- OPEN (37.7%).
9. Zero open findings (`tools/known_failures/README.md` Current section) --
   OPEN (11: 10 compiler, 1 stdlib algorithm).
10. Beta-exit release cut green (`docs/RELEASE_CHECKLIST.md`) -- OPEN.

Authoritative order for the stdlib lane to reach 100%. State at handoff:
`main` = `a948149` (+ this docs commit), 38 commits ahead of origin, unpushed;
compiler pin `v0.61.3`; all gates green (modules 509/509, corpus 951/951,
probes 181/181, barename 0/509, coverage floors66, doc ratchet, strict-clause
catalog clean); global pub-with-clause 26.2%; release pre-flight ready
(`docs/RELEASE_CHECKLIST.md`, `release-notes/v0.62.0.md` = 2 highlights).

Update 2026-09-25 (wave 30 landed): A1/A2 DONE (`02dde42`, floors67) --
signal 40/40 and exponential 18/18 pub covered; math 8.3% -> 14.1%,
global 26.2% -> 27.1%; gates on the commit: modules 509/509, corpus
951/951, probes 182/182, barename 0/509, both ratchets. Also fixed
`filter_bandstop` order <= 0 (empty-buffer OOB; probe exit 27 -> 0).
Next in order: B part 2b (linear_programming + smoke cases), then coverage waves, C, D, E, F.

Update 2026-09-27 (wave 36 landed): B part 2b DONE -- `linear_programming`
(bounds repair + delegation to lp_simplex) plus the queue-section-B cases in
`tests/smoke/smoke_math_optimization.xi`; probe p_linear_programming.xi
(190th); floors73; math 21.5% -> 21.6%. Next: coverage waves toward 100%
(floors74+: remaining math files, then async 4.5, net 5.4, serialize 5.4,
hash 8.9, reflect 9.1, num 9.6, iter 9.8, geom 10.6, convert 11.5, format 13,
time 13, misc 13.9, os 15.3, rand 16, crypto 17, log 19.1, compress 21.1),
then C, D, E, F.

Update 2026-09-27 (wave 37 landed): coverage wave 1 DONE -- trig family
(`xiom/math/trig.xi`, `trigonometry.xi`, `hyperbolic.xi`) 25 range clauses +
the recon-found `_norm`/`sinpi`/`cospi`/`tanpi` non-finite-reduction hang
fix; probe `p_trig_family.xi`; floors74; math 21.6% -> 24.1%, global 28.2% ->
28.6%. Next: remaining `xiom/math` files, then the low dirs in the order
above, then C, D, E, F.

Update 2026-09-27 (wave 38 landed): coverage wave 2 DONE -- rounding +
angular (26 clauses); probe `p_wave38_shapes.xi`; floors75; math 24.1% ->
26.7%, global 28.6% -> 29.0%. Next: remaining `xiom/math` files (algebra,
algebra_extended, transcendental, number_systems, topology, queueing,
finance, complex, numerical, special, vectors, matrices, graph_theory, ...),
then the low dirs above.

Update 2026-09-27 (wave 39 landed): coverage wave 3 DONE -- algebra +
transcendental (23 clauses) + two fix-first items (angular -0.0 clause
branch; log1p(-1) delegate-requires trap); probe `p_wave39_shapes.xi`;
floors76; math 26.7% -> 29.0%, global 29.0% -> 29.4%. Next: remaining
`xiom/math` files (number_systems safe subset, complex, numerical, special,
vectors, matrices, graph_theory, finance, topology, queueing, ...).

Update 2026-09-27 (wave 40 landed): coverage wave 4 DONE -- complex.xi
(module xiom.complex): 19 NaN-tolerant field clauses; `complex_div` stays
clause-free (mixed inf/NaN components). Probe `p_wave40_shapes.xi`;
floors77; math 29.0% -> 31.0%, global 29.4% -> 29.7%. Next: remaining
`xiom/math` files (number_systems safe subset, numerical, special,
vectors, matrices, graph_theory, finance, topology, queueing, ...).

Update 2026-09-27 (wave 41 landed): coverage wave 5 DONE -- vectors.xi
(27 clauses, NaN-tolerant field/length forms); probe `p_wave41_shapes.xi`;
floors78; math 31.0% -> 33.7%, global 29.7% -> 30.1%. Next: matrices.xi
(fixed-size structs + shape-only claims for the nested-Vec entry points),
then the remaining `xiom/math` files.

Update 2026-09-28 (wave 42 landed): coverage wave 6 -- first family batch
(matrices + number_systems + queueing), 53 clauses, 51 new pub covered;
fix-first: `surd_simplify` odd-exponent bug (probe-caught); new compiler
finding `p_vec_shape_arg_mismatch_av.xi`; floors79; math 33.7% -> 38.8%,
global 30.1% -> 30.9%. Next: num (489 pub, 442 uncovered), then geom.

Update 2026-09-28 (wave 43 landed): num sub-batch (float + convert + base +
precision_integer + precision_rational) 37 clauses; fix-first:
`nextafter`/`_ilogb_abs` skipped representable values at powers of two
(both directions) and `primitives.abs` was NaN-intolerant; exact-step KATs
in smoke_num_float; probe `p_wave43_shapes.xi`; floors80; num 9.6% ->
17.2%, global 30.9% -> 31.4%. Next: bigint (55 pub), bigfloat (75), then
num.xi leaves, then geom.

Update 2026-09-29 (CI incident + 0.62.0 recovery): waves 36-42 floors
wiring broke the YAML indentation of ci/heavy/release (`run:` nested under
`shell:`), so every GitHub run since the release push 0s-failed as
"workflow file issue" and stdlib-v0.62.0 had no assets (registry canary
blocked). Fixed in c491b13 (all workflows PyYAML-clean) and release.yml
gained a `tag` recovery dispatch that builds/publishes from the tag tree.
The first recovery then exposed a second, Linux-only blocker: the
`regex_unescape` Err-Str payload clause (syntax.xi, wave 29) violated on
ubuntu; fixed in 0e63101 (clause removed, finding upgraded in
tools/known_failures). stdlib-v0.62.0 was force-updated to 0e63101
(bypass; new subject sha 0e631018100b157539614cc92fc471f22663baff) and the
tag-triggered run 36495200067 passed ubuntu gates; windows + package +
release + canary follow. Registry lane: re-dispatch publish when assets
land. Rules: YAML edits get a parse check; Err-payload clauses are unsafe
on any platform (known_failures).

Update 2026-09-29 (wave 44 landed): xiom.bigint core -- 33 canonical-form
clauses (shared _trim invariant: negative => digits non-empty; digits
empty => negative false), probe `p_wave44_shapes.xi` (198th, 53 KATs);
floors81; num 17.2% -> 22.7%, global 31.4% -> 31.8%. Next: bigint
remaining (base parsing / to_int families, payload-free pass), then
bigfloat.

Update 2026-09-29 (wave 45 landed): xiom.bigint remainder -- 21 clauses
(parse Err guards, zero-fits conversions, parity/prime predicates,
next_prime, div_mod/sqrt_rem/pow_mod/ext_gcd tuple canonical claims,
exact compare wrappers); probe `p_wave45_shapes.xi` (199th); floors82;
num 22.7% -> 26.4%, global 31.8% -> 32.1%. Next: bigfloat (75 pub).
Pin-gated (compiler relay): the held XIOM_STRICT_BRACKETS flip needs the
3 mixed-bracket sites fixed when the pin bump lands -- io/fs.xi lines
36+244, math/algebra_extended.xi line 311.

Update 2026-09-29 (wave 46 landed): xiom.num.bigfloat core -- 30 clauses
(canonical-form family on the normalized results: non-negative
significand, empty-significand => sign false, sign true => non-empty
significand; exact zero; predicates/ranges; probe `p_wave46_shapes.xi`
(200th)); floors83; num 26.4% -> 31.6%, global 32.1% -> 32.5%. Next:
bigfloat transcendentals, then geom. Note: the module path is
`xiom.num.bigfloat` (smoke_bigfloat exists; the module-smoke scan's
`xiom.bigfloat` manifest alias is a baseline quirk to revisit).

Update 2026-09-29 (wave 47 landed): bigfloat transcendentals -- 24
canonical-form clauses (exp/ln/log10/log2/exp2, trig, atan/atan2, pow_bf,
cbrt, hypot, hyperbolics, inverses, explicit-precision pi/e, to_str_sci);
probe `p_wave47_shapes.xi` (201st, 27 KATs); floors84; num 31.6% ->
35.8%, global 32.5% -> 32.7%. Next: bigfloat remainder (from_ratio/pow10/
*_int/to_bigint), then geom.

Update 2026-09-29 (wave 48 landed): bigfloat remainder -- 9 clauses
(from_float/from_ratio canonical, to_bigint bigint-canonical, pow10
significand, to_str_prec non-empty, zero-fits *_int conversions); probe
`p_wave48_shapes.xi` (202nd); floors85; num 35.8% -> 37.4%, global 32.7%
-> 32.8%. Next: geom (the big geometric family), then the low dirs.
Relay (packages): pin moved 0.61.3 -> 0.62.1 mid-batch; all suites clean,
no stdlib changes needed; their sectest catalog bugs (obs-fold trimming,
max-age=abc) were package-side.

Update 2026-09-29 (wave 49 landed): geom primitives -- first family batch
(xiom.geom.vec + xiom.geom.quat + xiom.geom.mat), 52 clauses (component
mirrors with NaN-tolerant disjunctions, zero-vector canonical forms for the
norm functions, non-negative length bands, quaternion identity/slerp/
axis-angle forms, matrix shape claims, mat_inv presence mirror). New
compiler finding filed: `p_clause_float_vec_index.xi` -- clause-position
indexing of Float64 vector elements reads garbage (`result[0]` on
Vec[Float64] and `result[0].len()` on Vec[Vec[Float64]] violate; Int-vector
and length-only controls pass), so the matrix row-length claims are
len-only. Probe `p_wave49_shapes.xi` (203rd); floors86; geom 10.6% ->
23.2%, global 32.8% -> 33.6%. Next: geom batch 2 (matrix.xi + vector.xi +
quaternion.xi long-name domain), then curves/collision/geometry/polyhedra/
linear.

Update 2026-09-29 (PERF-1 annotation wave landed): all 16 pub fns in
`xiom/sync/atomics.xi` (every one has an unsafe body) carry
`#[unsafe_direct]` above `pub fn`, per the compiler-lane m166 relay;
`tools/doc_scan.ps1` treats attribute lines as transparent for the `///`
association; `release-notes/v0.62.2.md` (1 highlight; merges with the
compiler draft's 5 to the schema max of 6) added for the compiler v0.62.2
checkout. Tag `stdlib-perf1` is the `STDLIB_VERSION` pin for v0.62.2. The
attribute is ignored pre-m166 (gates run on the v0.61.3 pin); under m166
the wrappers compile direct (compiler-lane proof, PERF-1). Next: geom
batch 2 (wave 50) as before.

Update 2026-09-30 (wave 50 landed): geom batch 2 -- the typed matrix +
quaternion domain, 51 clauses (xiom.geom.matrix 32: Mat2/3/4 field
mirrors, len/shape claims on every builder, det/minor/cofactor/trace
bands, inverse/cholesky presence mirrors, rank/nullity bounds,
decomposition tuple lengths, solve_linear 0-or-rows, condition_number
non-negative-or-NaN; xiom.geom.quaternion 19: Quat field mirrors,
identity-or-nonzero forms, euler +-2 bands, slerp endpoint-or-interior,
look_at/between bands). Fix-first: `quat_between`'s opposite-direction
perpendicular-axis choice was inverted (180-degree pairs returned the
identity) -- fixed and locked by the probe. New compiler finding filed:
`p_geom_matrix_result_infer.xi` -- un-annotated `xiom.geom.matrix`
`Vec[Vec[Float64]]` results lose a nesting level at the call site (row
reads 0/raw bits; explicit annotation and annotated tuple extraction fix
it; xiom.geom.mat is unaffected; reproduced on v0.61.3 and v0.62.1). The
v0.62.1 cross-check also caught the `quat_axis` clause reading `.x` on a
`Vec[Float64]` result -- replaced with the len-only claim. Probe
`p_wave50_shapes.xi` (204th, 96 checks, green on both pins); floors87;
geom 23.2% -> 35.5%, global 33.6% -> 34.4%. Next: geom batch 3
(vector.xi + curves/collision), then geometry_2d/3d/extended/polyhedra/
linear, then the geom.xi aggregate.

Update 2026-10-01 (PERF-2 annotation wave + packages intake): all 56
unsafe-bodied pub fns in `xiom/sync/sync.xi` (mutex/rwlock/guards/
condvar/once/barrier/arc/atomic types, the standalone `atomic_*` helpers,
and `cdl_wait_spin`) carry `#[unsafe_direct]` per the compiler-lane
185342f4 relay; the 10 unsafe-free pub fns are untouched; pin-path sync
smokes 22/22. Tag `stdlib-perf2` is the next-pin candidate
(receiver-qualified method trust is the t2 residual). Packages relay
recorded in `docs/STDLIB-WISHLIST.md` (8 of the ~11 rows relayed).
Fix-first: removed the contradicted empty-needle preconditions on
`string.index_of` / `string.str_index_of` / `string.str_replace_all`
(packages defect; probe `p_empty_needle_contracts.xi` RED -> GREEN).
Coverage unchanged (floors87). Next: geom batch 3 (vector.xi +
curves/collision) as before.

Update 2026-10-01 (wave 51 landed): geom batch 3 -- vector/curves/collision,
43 clauses (vector 24: constructor fields, NaN-on-length-mismatch,
non-negative norm bands, len-0-or-input shape claims, refract presence
mirrors, empty => NaN component min/max; curves 7: len-0-or-input point
curves, derivative/b_spline point-count guards, curve_length
non-negative-or-NaN; collision 12: constructor len mirrors and
degenerate-length => false/None implications on every query). Two NEW
compiler findings filed from the probe: `p_geom_vector_result_bits.xi`
(caller-side element reads of vector.lerp/clamp/hadamard and curves.b_spline
are bit-reinterpreted; callee-side reads and the other vector functions are
correct; reproduced on v0.61.3 and v0.62.1; probe mediates via
vector.distance like smoke_geom_vec) and `p_curve_thunk_zero.xi` (a
Vec-returning fn-typed parameter arrives empty inside catalog bodies:
curve_length returns 0 instead of 1.0). Probe `p_wave51_shapes.xi` (206th,
80 checks, green on both pins); floors88; geom 35.5% -> 45.9%, global 34.4%
-> 35.1%. Next: geom batch 4 (geometry_2d 22 + geometry_3d 21 = 43), then
geometry_extended + polyhedra + linear, then the geom.xi aggregate.

Update 2026-10-02 (wave 52 landed): geom batch 4 -- geometry_2d (22) +
geometry_3d (21), 43 clauses (distance bands, degenerate-input
implications, parity/Bool claims, presence mirrors). Two non-compiler
findings filed: `p_polygon_difference_halfplanes.xi` (the difference clips
against b's outside half-planes and intersects them instead of taking a\b
-- disjoint inputs return None; doc updated; a real polygon-clipping
implementation is a follow-up) and `p_geom_box_unnameable.xi`
(`geometry_3d.Box` is shadowed by core's `Box[T]` and has no constructor,
so `aabb_intersection`/`aabb_contains`/`ray_box_intersection` are
uncallable from consumers; those three clauses are compile-checked only).
Probe `p_wave52_shapes.xi` (207th, 78 checks, green on both pins);
floors89; geom 45.9% -> 56.3%, global 35.1% -> 35.7%. Next: geom batch 5
(geometry_extended 14 + polyhedra 10 + linear 15 = 39), then the geom.xi
aggregate.

Update 2026-10-02 (wave 53 landed): geom batch 5 -- geometry_extended (14)
+ polyhedra (10) + linear (15), 39 clauses (shape/degenerate implications,
polyhedra count claims, linear length claims and empty-matrix predicates).
Fix-first: `hyperbolic_geometry` called the non-pub extern `math.log` -- a
silent zero stub on v0.61.3 (the function returned 0 for all distinct
points) and a hard C001 on v0.62.1; switched to the public `math.ln` and
locked by the probe's log(3) KAT. New finding:
`p_polyhedra_nested_hull.xi` (polyhedra convex_hull_2d/3d collapse on
nonempty inputs on both pins; empty inputs correct). Probe
`p_wave53_shapes.xi` (208th, 68 checks, green on both pins); floors90;
geom 56.3% -> 65.7%, global 35.7% -> 36.3%. Next: the geom.xi aggregate
(142 uncovered -> 2-3 waves), then the low dirs.

Update 2026-10-02 (wave 54 landed): geom aggregate batch 1 -- the big
`xiom.geom` aggregate's first 46 of 142 uncovered pub fns (vec2 16, vec3 15,
vec4 3, quaternion core 7, scalar helpers 5), all NaN-tolerant clause forms
(constructor mirrors, zero-or-nonzero canonical forms, reflect
degenerate-normal implication, refract presence mirrors, angle bands,
clamped-parameter guard for vec3_lerp, clamp-length mirror-or-overflow,
Hamilton/quaternion mirrors, Euler -2..2 bands, scalar angle mirrors).
Fix-first: `quat_from_euler` wrote its literal w,x,y,z (declaration order
x,y,z,w) and the compiler stores literal fields positionally, so every
Euler-derived rotation was scrambled; reordered. New finding:
`p_struct_literal_field_order.xi` (compiler, both pins). Probe
`p_wave54_shapes.xi` (209th, 99 checks, green on both pins); smoke_geom.xi
grew to 49 KATs (module-smoke 3,332 -> 3,377 fns); floors91; geom 65.7% ->
76.8%, global 36.3% -> 37.0%. Next: geom batch 7 (quaternion tail 15 +
Mat2 8 + Mat3 12 + Mat4 core 10 = 45), then Mat4 tail + Aabb + Sphere +
Ray + Plane (51), then the low dirs.

Update 2026-10-02 (wave 55 landed): geom aggregate batch 2 -- quaternion
tail (15: from_axis_angle, mul_vec3, inverse, dot, length, is_unit, slerp,
nlerp, from_mat4, to_mat4, to_mat3, roll, pitch, yaw, angle_between), Mat2
(8) and Mat3 (12) full mirrors/presence claims, and the Mat4 core (10:
identity, mul, translate, scale, rotate_x/y/z, perspective, look_at,
transform_vec3); all NaN-tolerant (mat2/mat3 transposes caught during
probe validation and fixed). No fix-first. Probe `p_wave55_shapes.xi`
(210th, 69 checks, green on both pins); smoke_geom.xi grew to 90 KATs
(module-smoke 3,377 -> 3,421 fns); floors92; geom 76.8% -> 87.7%
(363/414), global 37.0% -> 37.7%. Next: geom batch 8 (Mat4 tail 17 + Aabb
14 + Sphere 8 + Ray 8 + Plane 4 = 51, the last aggregate batch), then the
low dirs.

State 2026-09-29 (handoff snapshot 3, main 2a06a90): floors85 global 32.8%,
math 38.8%, num 37.4%; probes 202; smoke 951; modules 509/509; barename
0/509; doc 100%; module-smoke ratchet 497/517 modules, 3332/6200 pub fns.
stdlib 0.62.0 released (tag stdlib-v0.62.0 = 0e63101, assets published,
registry publish owned by that lane). Next unit: wave 49 = geom
(batch-split primitives -> curves -> transforms, 40-60 pub per wave), then
the low dirs; smoke-growth runs alongside every wave. Full continuation
prompt is in docs/stdlib_session.md (HANDOFF 2026-09-29 block).

Remaining-to-100% snapshot (answer to the packages relay, 2026-09-27):
the release gate is per-directory 100% pub-with-clause + doc 100% + all
gates green. Current floors77: global 29.7%; math 31.0%; lowest dirs
async 4.5, net 5.4, serialize 5.4, hash 8.9, reflect 9.1, num 9.6, iter
9.8, geom 10.6, convert 11.5, format 13, time 13, misc 13.9, os 15.3,
rand 16, crypto 17, bench 18.8, log 19.1, compress 21.1, encoding 23.7,
debug 24.4, simd 24.4, stats/thread 25, core 26.7, then sync 29.1 up to
mem 100. Queue units after the waves: C geom dedup (needs the compiler-lane
api_freeze snapshot regen), D tzdata phase 2 (first unit that lands NEW
module namespaces -- check `docs/PACKAGE-NAMESPACES.txt` first), E
untested-surface generator classes, F release cut + tag handover at 100%.
Pin-gated cleanups: ptr.is_null workaround (m142+ pin), tcp_connect
refused-port -> Err (m146), concrete ErrorInfo/ErrorKind with its first
consumer. Package-wishlist items are growth features, not on the 100%
path.

Readiness outlook (2026-09-28, floors78): 6,499 pub fns total, 1,954
covered (30.1%). Uncovered 4,545; largest gaps math 660, num 442, geom 370,
os 310, net 281, convert 270, format 201, collect 190, iter 165, string
164, crypto 151, time 120, stats 105, core 96, serialize 88, sync 83. At
the recent per-wave scope (19-27 pub covered, ~25 avg) that is ~180 waves;
about 70% of the remainder is safely coverable (the rest is
higher-order/generic/nested-shape SKIP territory), so ~125 waves at the
current scope, or ~70-80 if whole families are batched at 40-60 pub per
wave. Units C/D/E add fixed-size work on top; adopting wishlist modules
grows the denominator and pushes 100% further out.

Module smoke coverage (owner requirement, 2026-09-29): every stdlib module
must be exercised by at least one smoke file, tracked as a monotone gate.
Baseline `tools/module_smoke_floors.json` (from
`tools/module_smoke_scan.ps1`): 497/517 source modules (96.1%) covered
(509 manifest modules + 8 transitive submodules), 3,332/6,200 public
functions (53.7%) referenced by a qualified smoke call. The ratchet is
wired into ci/heavy/release and fails if the covered module or function
counts drop; the remaining 20 modules and 2,868 unreferenced functions are
targets for the smoke-growth waves that accompany the coverage waves.

Packages growth wishlist (external channel): `xiom-packages` repo,
`docs/STDLIB-WISHLIST.md` (namespace snapshot:
`docs/PACKAGE-NAMESPACES.txt`, 342 package names / 366 module namespaces).
Top hand-rolled items requested by packages: checksum (crc32/8/7/24,
internet checksum, adler32), bitstream (MSB/LSB reader+writer), varint
(LEB128+zigzag), bytes.cursor (bounds-checked reader), encoding.base64,
string.utf8 (strict UTF-8 validation -> safe Str), text.scan, date.civil,
net.addr, bcd, math.int, buf.writer; wave-36 additions: encoding.hex,
string.cstr, encoding.le, bits.u32, hash.sha256, l10n.iso4217, string.bytes,
err.at (requesters extended on bitstream, bytes.cursor, math.int, text.scan,
time.civil, buf.writer, result, test.bytes). Two-way rule: before landing a
NEW module namespace, check PACKAGE-NAMESPACES.txt; their
scripts/namespace-check.ps1 scans this repo before dispatch. First affected
unit: D (tzdata phase 2, `xiom/time/zone`). When a wishlist item ships, tick
its Status row or announce it in the session handoff. These are growth
features and are NOT part of the 100% coverage path.

The compiler lane's mixed-bracket/arity lists have since arrived (item 6); wave 31
(factorial family, floors68) is also DONE -- see the session doc evening
block; next are wave 32 (combinatorics) and wave 33 (number_theory).
Relay note: the exact PIN list arrived in the evening relay; 13 main-side
mixed-bracket sites were fixed in `0823433` (item 6). `xiom.cell`'s
`ptr.is_null()` (`xiom/ptr/ptr.xi` free-fn declaration, method-style
calls) is the compiler lane's offset-bug case; the arity list is still
outstanding.

Every coverage wave follows the same protocol (see 0A PART 9 for ~8 worked
examples): recon (agent or direct read) -> new-shape probe(s) in
`tools/probes/` -> clauses -> `coverage_scan.ps1 -DumpFloors
tools/coverage_floors<N>.json` -> wire floors into ci.yml/heavy.yml/
release.yml + tools/README.md + docs/STDLIB_READINESS_PLAN.md in the SAME
commit -> `check_modules.ps1` + full `run_smokes.ps1 -RetryFailed` + probe
corpus + `barename_scan.ps1` + both ratchets. One wave per commit.

---

## A. Wave 30+: remaining coverage targets

### A1. `xiom/math/signal.xi` (~40 pub, safest — pure length invariants)
Candidates verified by reading the module: result-length equalities guarded
by input sizes (convolution `n + kernel - 1`; correlation lags;
power-spectrum `n/2 + 1`; upsampling `2n`; downsampling `n/2`; mel filterbank
`<= n_filters`; MFCC `<= 24`), plus `x.len() == 0 => result.len() == 0`
guards where the body early-returns. Check every loop bound before landing.

### A2. `xiom/math/exponential.xi` (~16)
`exp(x) >= 0.0`, `expm1(x) >= -1.0`, `ln(x)`: `x > 0.0 => result >= 0.0 ||
result != result` (NaN-tolerant), `x > 1.0 => result > 0.0`, empty guards for
vector variants. All values are Float64; never assert equality.

### A3. `xiom/math/number_theory.xi` (~32 pub) and tails
Re-run a read-only recon agent with the standard prompt shape (exact
signature + proposed clause + justification per fn; do-not-touch list);
expected families: `gcd/lcm >= 0` and `gcd(a,b) <= min(|a|,|b|)` guarded,
`abs` mirrors, primality Boolean mirrors (`result == false || n >= 2`),
digit-sum `>= 0`, modular bounds, exact small-input identities. Watch
overflow: guard identities with input-size antecedents.

### A4. `xiom/math/factorial.xi`, `xiom/math/combinatorics.xi`
`factorial(n)`: `n < 0 => result == 0` (check actual), `n >= 0 => result
>= 1`; `combinations(n,k)`: `k < 0 || k > n => result == 0`,
`0 <= k <= n => result >= 1 && result <= 2^n` style only if the
implementation cannot overflow for the guarded range; otherwise bound by `n`
antecedents. Re-derive per function from the source; do not trust family
generalizations.

### A5. Smaller tails if wanted
`xiom/geom` (mostly 3D helpers), `xiom/math` remaining <15% files, `xiom/net`
pure helpers. No correctness impact — coverage only.

---

## B. `control_theory` observability/controllability + `lp_simplex`

Signatures are frozen; every new body must carry at least one clause
(math floor 8.3% is exactly at the current value).
Working recipe: repair a by-ref nested `Vec[Vec[Float64]]` into a NEW local
matrix (`rows.push(m[i])` for all rows) and index the local; row-local
`var r = m[i]` is NOT enough for Float64 (verified 2026-09-25).

Helpers to add in `xiom/math/control_theory.xi` (math layer cannot import
`xiom.geom`; copy the gate-green bodies as private `_ct_*`):
`_ct_copy` (deep copy of a repaired matrix), `_ct_mul`, `_ct_transpose`,
`_ct_rank` (Gaussian elimination, pivot threshold 1e-12).

- `observability(a, c) -> Bool`: repair A/C; require A square n×n and C p×n;
  build `O = [C; CA; ...; CA^(n-1)]` by push; return `_ct_rank(&O) == n`.
  Guards -> false: empty A or C, non-square A, ragged widths, mult failure.
  Clause: `ensures: !result || a.len() > 0`.
- `controllability(a, b) -> Bool`: rank of `[B, AB, ...]` equals rank of its
  transpose `[B^T; B^T A^T; ...]`; build stacked rows, same guards
  (B must be n×m, m > 0). Same clause.
- `state_space(a,b,c,d)`: DEFER (4-tuple of aggregates has documented
  ABI risk); keep the stub, sharpen its doc comment.

`xiom/math/optimization.xi`:
- `lp_simplex(c, a, b) -> Vec[Float64]`: dense tableau (m+1)×(n+m+1),
  slacks basis, Bland entering + Bland leaving tie-break, Gauss-Jordan
  pivots, 10000-iteration cap. Return conventions: empty vec for empty c,
  no constraints, `b.len() != a.len()`, ragged A, any `b[i] < 0` (no
  Phase I), unbounded, cap hit; otherwise argmin x of length n.
  Clause: `ensures: result.len() == 0 || result.len() == c.len()`.
- `linear_programming(c,a,b,bounds)`: repair bounds too; empty bounds =
  `x >= 0`; per-variable modes (lo-only, hi-only, both -> add `z <= 1`,
  free -> split `z+ - z-`); shift/scale A,b,c; delegate to `lp_simplex`;
  map back (free: `z+ - z-`). Same clause. Documented limitation: shifted
  `b2 < 0` returns empty (no Phase I).

Verification (add to `tests/smoke/smoke_math_optimization.xi`, float `near`
1e-9): observability true/false cases (A=[[0,1],[-2,-3]],C=[[1,0]] true;
A=I,C=[[1,0]] false), controllability (B=[[0],[1]] true; B=[[1],[1]] false;
multi-input true), guards; `lp_simplex(c=[-3,-2],A=[[1,1],[1,0],[0,1]],
b=[4,2,3]) == [2,2]`; unbounded/guards; `linear_programming` delegation
identity; bound modes ([0,1],[0,inf]) -> [1,3]; free variable case.
First step: a single probe binary exercising observability + lp_simplex
before touching the smokes.

---

## C. Geom dedup unit (dequeued 2026-09-24)

`xiom/geom/{vec,mat,quat}.xi` vs `{vector,matrix,quaternion}.xi` is NOT a
pure rename: short-name modules are dynamic APIs, long-name modules carry
the typed Mat2/3/4/Vec domain; `quat.xi` already partly delegates to
`geom.xi`. Consumers: `smoke_geom_vec/mat/quat/3d/2d/geom` + the aggregate
`geom.xi` (imports all six). Needs its own audited API-translation unit:
name map, consumer migration, then removal with the api_freeze snapshot
regen (compiler lane). Do not blind-shim.

---

## D. tzdata phase 2

Recommended design (from the 2026-09-24 recon): vendor a pinned IANA tzdb
release tarball under `tools/tzdata/` (public domain; provenance header per
generated file; no GPL tooling). Generate region tables as gzip+base64
payloads in `xiom/time/zone/data/{africa,antarctica,asia,australasia,europe,
northamerica,southamerica,etcetera}.xi` (private base64 chunks + one pub
`data_<region>() -> Result[Vec[UInt8], Str]` per region with `ensures`),
plus a hand-written `xiom/time/zone.xi` engine (~15 KB): format decoder,
lazy one-time region init into module-level `var Vec[UInt8]`
(whole-value assignment), public API `zone_offset_at`, `zone_is_dst_at`,
`zone_abbrev_at`, `zone_to_local`, `zone_local_candidates`,
`zone_local_to_utc` (Err "nonexistent"/"ambiguous"), `zone_exists`,
`zone_list`, `zone_canonical_name`, `zone_data_version`.
KAT smoke `smoke_time_zone.xi` with pre-verified instants (Europe/Athens,
America/New_York, Australia/Sydney, Pacific/Apia date-line, Europe/Amsterdam
sub-minute LMT, Dublin negative-SAVE, Kathmandu +5:45, Lord_Howe 30-min DST,
Chatham +12:45; NY ambiguous/nonexistent local times; link US/Eastern).
POSIX TZ footer expanded to 2100 at generation time; post-2100 = last known
offset (documented). Register in `tools/modlist_all.txt` +
`docs/STDLIB_MANIFEST.md`; new pub fns need clauses to hold the time floor.
Commit order: probe (encoding/size measure) -> spec -> generator + tarball
-> data modules -> engine -> KAT smoke -> docs. Offline prerequisite: the
pinned tzdb tarball must be fetched once (network) or supplied.

---

## E. Untested-surface generator classes

`tools/gen_call_probes.ps1` already has scalar/refs/structs/fns/wrapped
classes (126 modules / 751 calls compile-only). Remaining, in order:
1. **fn-param non-scalar shapes (53 fns)**: extend the helper emitter to
   accept one container level in inner params/returns
   (`fn(&Vec[Float64]) -> Float64`, `fn(Str) -> Str`, `fn(&Int) ->
   Option[Int]`, ...); emit helper bodies returning synthetic values.
2. **generic fns (80)**: substitute each type param with `Int`
   (bounds `Ord/Eq/Clone/Serialize/Deserialize/Any` -> Int), emit
   `mod.fn[Int](...)`; skip `&Slice[T]`, `*const/*mut T`, `dyn Any`,
   `const N` array shapes.
3. **struct params without ctor (28)**: widen the ctor search to an index
   by exact type spelling (same-leaf collision risk) or struct-literal
   `T{...}` construction (probe support first); skip no-public-field structs.
All compile-only (never execute): generated args are unsafe
(file I/O, null FFI, @pre aborts); `-Timeout 0` for net/num groups; run
from the repo root. Matrix run at the end:
`-MinParams 1 -MaxParams 4 -IncludeRefs -IncludeStructs -IncludeFns
-IncludeWrappedCtors` + new switches; keep per-class runs for triage.
Rescans: `profile_untested.ps1` / `profile_struct_params.ps1` /
`profile_fn_params.ps1` (temp copies existed 2026-09-24; re-derive if gone).

---

## F. Release cut and handover

Follow `docs/RELEASE_CHECKLIST.md`: bump `package.xi` to the tag suffix
(recommended 0.62.0), keep `COMPILER_VERSION` at an EXISTING tag (currently
v0.61.3; the combined compiler release happens after our cut), keep the
2-highlight notes fragment, move CHANGELOG Unreleased, run the local
battery, verify author, tag `stdlib-vX.Y.Z` + push ONLY when the release
lane says so, then dispatch the registry publish (the workflow now passes
`--compiler` from COMPILER_VERSION) and canary. After the release, the
compiler lane bumps `STDLIB_VERSION`, runs
`XIOM_STRICT_CLAUSES=1 cargo test -p xiom-check catalog_corpus_is_clean`
(green here), flips the strict default, re-gates, and cuts v0.62.0.

---

## Environment and gotchas (learned the hard way)

- Compiler binaries: `%TEMP%\kilo\stdlib_ws\xiom_v0613.exe` (pin build);
  local compiler main with R66-R72 was `xiom_main_r72.exe` (may be gone).
- No `pwsh` in this shell: `powershell -NoProfile -File tools\<x>.ps1`.
- The local corpus is 951 files, ~22-60 min depending on machine load; check
  per-worker CSVs for liveness; do not assume a hang.
- One fix = one probe = one verified rerun; no repo edits while a sweep runs.
- Edit-tool gotchas: mixed bracket styles (`Result<X, Y>` vs `Result[X, Y]`)
  in legacy files; multi-line matches can fail on mixed CRLF/LF (use a
  single-line anchor and put newlines only in the newString); verify each
  edit with a grep; one `edit` invoke per message.
- Contract gotchas: `A == B > C` parses left-associatively
  (`(A == B) > C`) -- always parenthesize; payload reads in CATALOG clauses
  are unsafe (see `tools/known_failures/README.md`: Ok-Str reads violate or
  crash, a nested-Vec payload clause poisons user codegen); Err-payload
  `.len()` and Option payload mirrors are OK; prefer payload-free guards.
- Import gotchas: only ONE sibling module per family when bare names overlap
  (`xiom.test.*`, `xiom.regex.regex` vs `syntax`); cross-module types by
  unqualified leaf (`Vec[TestResult]`), qualified `mod.Type` silently
  becomes `Vec[Int]`.
- Probe corpus currently 181 files; smoke corpus 951; floors64-66 wired.

## Open compiler findings (relay status)

1. Cross-type generic callback returns (`fn(&T)->U` with U != T) wrong --
   in the compiler lane's Sprint C acceptance matrix.
2. E001 borrow-conservatism -- queued with our probe as the lock.
3. Result-Ok Str payload reads in catalog clauses (false violation / AV) --
   relayed 2026-09-25, filed in known_failures.
4. Nested-Vec payload clause poisons user codegen -- relayed 2026-09-25,
   filed with evidence probe.
5. Same-leaf private type collision (Timer) and clause Bool/Int coercion --
   fixed in the compiler lane's m134/m135/m136; our tree carries the
   workarounds; re-verify on the next pin.
6. Strict-parser prep (relay 2026-09-25): the mixed-bracket/arity error
   lists were relayed without their file/site enumerations. This repo's
   `io/fs.xi` has no angle-bracket generics; ~100 legacy-angle sites live
   in 15 other files, so no bracket sweep until the compiler lane sends
   the exact list. `xiom.cell`'s `ptr.is_null()` (`xiom/ptr/ptr.xi:36`
   free-fn declaration; `xiom/cell/cell.xi:155,181` method-style calls) is
   the compiler lane's offset-bug case: compiler fix, not a stdlib arity
   edit.
   UPDATE 2026-09-25: the compiler lane sent the exact PIN list (18 mixed
   type spellings, 7 files). On main, 13 remained and were normalized to
   all-square in `fix(lang)`: core/contracts 231 (`Option<Vec[...>>`),
   io/console 47, io/fs 50/80/110/124/138/162 (line-shifted) and 215/230/
   299/338, io/pipe 185 -- all `Result[T, Str>` closers. The other 5
   (test/harness 34/99, test/test 196/212, math/approximation 502) were
   already canonical on main (arrows inside square brackets are fine).
   The four touched modules check clean through the check_modules probe
   shape. Strict flip waits on the compiler lane's XIOM_STRICT_BRACKETS=1
   diagnostics + pin bump; the arity list is still outstanding.

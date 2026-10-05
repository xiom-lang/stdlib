# Production-readiness remaining queue (handoff 2026-09-25)

**75.2% -- 7 of 10 gates complete; gate 8 at 52.1% (partial credit) and
gates 9-10 discrete.** (Compiler pin: **v0.64.0**.)
**Gates: corpus 953/953 full (C001 carve-outs retired on v0.63.1; new
TcpStream loopback smoke added), modules 509/509, probes 242/242,
barename 0/509.**

Readiness gates (the meter above counts these; each is backed by the battery
recorded in the updates below). Update the two lines above and this list as
gates flip:
1. Modules type-check clean -- MET (509/509).
2. Smoke corpus green -- MET on the v0.64.0 pin: release gate 953/953
   full, no carve-outs (C001 fixed by 4bf8cf1e; 20/20 + 20/20 stress).
   lz4 is fixed by m190 and stayed in the gate; the new TcpStream loopback
   smoke locks m196.
3. Probe corpus green -- MET (242/242 on v0.64.0, incl. the promoted
   regression probes, the pin locks, the v0.64.0 m193-m196 probe and the
   wave-77 stats probe).
4. Strict bare-name scan clean -- MET (0/509).
5. Coverage ratchet green -- MET (floors114).
6. Documentation ratchet 100% -- MET.
7. Module-smoke ratchet green -- MET (497/517 modules, 3475/6200 fns).
8. Contract coverage 100% (every public fn carries clauses) -- OPEN (52.1%).
9. Zero open findings (`tools/known_failures/README.md` Current section) --
   OPEN (10: 9 compiler, 1 stdlib algorithm).
10. Beta-exit release cut green (`docs/RELEASE_CHECKLIST.md`) -- OPEN.

Meter formula: MET gates count 1.0; gate 8 counts its current
pub-with-clause fraction (52.1% -> 0.521); gates 9 and 10 get no partial
credit (discrete). Update the percentage and the gate-8 fraction in the
same commit as each floors dump so the meter moves smoothly toward 80%.

Authoritative order: the gates above, then the updates below newest-first.
Current state: compiler pin v0.64.0; coverage 52.1%, meter 75.2%; handoff
in `docs/stdlib_session.md` snapshot 16 (block 46).

## Project Pulse relay (web-framework lane) -- 2026-10-05

Consumer lane `E:\xiom-projects\xiom-pulse` (`docs/STDLIB-WISHLIST-PULSE.md`,
pin v0.63.1 / stdlib 15cb889, `XIOM_RUNTIME_DIR=...\stdlib\runtime`). All
items verified against our tree:

- **Confirmed stubs needing real implementations (stdlib, Pulse-hardening
  wave):** `socket_set_timeout`/`socket_set_nonblocking`/`socket_reuse_addr`
  at `xiom/net/socket.xi:287/302/360` (documented Err); the Windows
  `xiom_socket_bind` path lacks `setsockopt(SO_REUSEADDR)` while POSIX sets
  it (`runtime/xiom_runtime.c:4737` vs `:4816`). Fix: runtime C externs
  (`xiom_socket_set_timeout/nonblocking/reuse_addr`) plus real wrappers and
  a deadline-capable recv. Caveat: the compiler archives bundle the older
  runtime, so consumers need `XIOM_RUNTIME_DIR` (or the next compiler pin)
  until the updated runtime ships.
- **TcpStream.write partial-send:** `xiom/net/net.xi:124-144` is a single
  `xiom_socket_send` returning `Ok(n)`; add `write_all` (loop) + probe and
  document the single-send semantics of `write`.
- **Server request-head parser:** `xiom/net/server.xi` exposes only
  `server_parse_request_line`; add `server_parse_request(bytes)` with header
  list, `Content-Length` framing and a body span.
- **`str_bytes`: already exists** at `xiom/string/slice.xi:135`
  (`ensures: result.len() == s.len()`); Pulse missed it because the root
  `xiom.string` does not re-export submodule fns -- use
  `xiom.string.slice`. **Adopted by Pulse 2026-10-05.**
- **`flush_stdout` is a no-op** (`xiom/io/io.xi:903`, empty body): implement
  a real flush through a runtime extern; probe explicit-flush visibility
  (abnormal-exit durability stays runtime/CRT-dependent). Pulse confirms
  this finding is the root cause of their lagging/truncated redirected
  logs (log evidence now attributed to io.xi:903).
- **`hmac_sha256_hex` absent:** add a convenience wrapper (+ probe).
- **Executable test registry: compiler-owned** (`xiom/test/harness.xi`
  header: module-scope fn-pointer reassignment unsupported); relay to the
  compiler lane.
- **`TcpStream.read` dead (C-PULSE-01): compiler-owned.** Add a
  `tcp_listen`/`tcp_connect` loopback fixture in `tests/` with read/write
  to lock the fix and the new write semantics together.
- **Positives to keep (no action):** raw-fd socket path (145/145 soak,
  64/64 concurrent), `xiom.serialize.json`, `xiom.env.var_or`, contracts,
  and crypto KAT with `XIOM_RUNTIME_DIR` set (the default runtime's missing
  `xiom_sha256_hash` is a compiler-archive/pin issue, not ours).
- Pulse reply 2026-10-05: `str_bytes` adopted; the empty-body
  `flush_stdout` finding is confirmed as the cause of their lagging and
  truncated redirected logs; runtime-backed items accepted with the
  `XIOM_RUNTIME_DIR` caveat; new loopback smoke noted as the read/write
  lock.

## Systems track (bare-metal / GPU / driver-adjacent) -- relayed 2026-10-05

Not a readiness gate yet; do not displace coverage waves before gate 10
(beta-exit cut) unless the owner re-prioritizes.

- Compiler asks (relay to the compiler lane): (1) `--freestanding`/
  no-runtime target with linker script, allocator hooks and panic/abort
  paths; (2) `repr(C)`/packed struct layout plus by-value ABI guarantees
  with regression tests; (3) volatile load/store, memory fences and
  ordered atomics (CAS variants); (4) compile-time contract-check
  disable for hard-real-time paths; (5) later: device-code (SPIR-V)
  target with memory-space/barrier types.
- Stdlib assets today: `xiom.ffi` (dl/SafePtr/FFIBuffer/marshal; its
  header names vulkan/imgui/glfw as the consumers), `simd` 90 pub fns,
  `thread`/`sync` + `AtomicInt`, epoll/kqueue async runtime, mmap/ioctl/
  os-event modules, guard-page/mprotect machinery in the runtime.
- Stdlib work on unlock (probe-first, one surface at a time): GPU compute
  loader skeleton (Vulkan instance/device/compute path, SPIR-V blobs,
  runtime skip when no loader DLL), mmio/volatile shims via C helpers
  until volatile lands, RAII/Drop for FFI handles (ffi Phase 2), and a
  deterministic CPU physics package on math/geom/simd.
- Cheap prerequisites already in the coverage path (`ffi`, `mem`, `ptr`,
  `io`, `thread`, `sync`) keep landing as normal waves.
- Compiler relay 2026-10-05: plan recorded at compiler
  `docs/SYSTEMS_TRACK_PLAN.md` (commit 6f4173cd); the order was accepted
  as asked. Ask (4) is already satisfied (`--no-contracts` exists and
  release defaults checks off; an IR lock is being added). First unlock
  pair = S1 freestanding + S2 `repr(C)`, slotted after the current
  v0.64.0 bug batch (m192/R65/m193/m194/UX landed and fully gated);
  freestanding sits behind a profile so selfhost parity stays
  byte-stable. S1 run-lock will be a Linux CI fixture with an asm
  `_start`; Windows is build-only. Freestanding caveat to carry into the
  gpu/mmio skeletons: without the OS-backed guard page/trampoline,
  confined `unsafe` cannot trap hardware faults in that mode -- design
  those surfaces for explicit checking. Nothing is needed from stdlib
  until S1/S2 land.

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

Update 2026-10-02 (compiler relay / next pin): `COMPILER_BUGS.md` m169
(same-leaf qualified Vec results) and m170 (fn-typed param Vec returns +
erased Option/Result literal payload slots) close
`p_geom_vector_result_bits.xi` and `p_curve_thunk_zero.xi`; both verified
rc=0 on the local v0.62.2 dev binary (pre-fix rc=2). Keep both in
known_failures until the gate pin carries m169/m170, then promote to
tools/probes/ and un-mediate the wave-51 reads. Still open on the v0.62.2
dev binary: `p_geom_matrix_result_infer.xi` (run=4),
`p_clause_float_vec_index.xi` (run=1), `p_polyhedra_nested_hull.xi`
(run=1).

Update 2026-10-02 (wave 56 landed): geom aggregate batch 3/final -- Mat4
tail (17), Aabb (14), Sphere (8), Ray (8), Plane (4), 51 clauses
(NaN-tolerant mirrors, presence claims, containment/overlap implications,
reciprocal/shape claims). No fix-first. Probe `p_wave56_shapes.xi` (211th,
77 checks, green on v0.61.3 and the v0.62.2 dev binary); smoke_geom.xi grew
to 128 KATs (module-smoke 3,421 -> 3,471 fns); floors93. `geom.xi` is now
186/186 and the geom directory 414/414 = 100%; global 37.7% -> 38.5%.
Next: the low dirs (net 5.4%, serialize 5.4%, hash 8.9%, reflect 9.1%, iter
9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%, rand 16%,
crypto 17%, log 19.1%, compress 21.1%), then C, D, E, F.

Update 2026-10-02 (packages wishlist relay, evening): five more rows land
(`docs/STDLIB-WISHLIST.md` rows 33-41): the `crypto` linkability defect
(fix-first once the packages lane supplies the exact symbols/repro), FNV-1a
over `Str` + masked combine, ASCII byte classifiers, delimiter helpers,
graph closure/depth, plus extended requester lists on `vec.str`, `Vec`
truncation, `serialize.json` and `graph.topo`. Growth rows are not part of
the 100% coverage path; row 33 is the only fix-first candidate.

Update 2026-10-03 (wave 57 landed + crypto relay): net batch 1 -- the
address family (address 5, ip 15, ip4 10, ip6 8, url 8 = 46 clauses).
Fix-firsts: `ipv4_to_string` now uses the first four octets per its doc;
`url_join`'s "//" branch now normalizes per its doc. New finding
`p_wave57_probe_ir.xi` (context-dependent alloca-dominance invalid IR;
non-monotonic under bisection). Probe `p_wave57_shapes.xi` (212th, 141
checks, green on v0.61.3 and v0.62.2 dev); `smoke_net_address.xi` grew
(module-smoke 3,471 -> 3,475); floors94; net 5.4% -> 20.9%, global 38.5%
-> 39.2%.

Crypto link packet (packages `docs/repro/crypto-link` @ 8eb7944f): NOT
reproduced on stdlib main -- `crypto.sha256_hex` (NIST "abc") and
`encoding.base64_encode` ("YWJj") link and run green on v0.61.3 and the
v0.62.2 dev binary, with and without XIOM_STDLIB. The symbol
`xiom_sha256_hash` is defined in `runtime/sha256_sw.c` (present in
`stdlib-v0.62.0`, `stdlib-perf1` and main) and the driver's build-runtime
source list includes it; the undefined-symbol shape points at a stale
installed runtime library -- hand to the compiler/install lane with the
packages KATs. In the same relay, `fn` as a reserved identifier and the
Result-type mismatch laxness are compiler-side; the stdlib-relevant
additions are wishlist rows 42-46 (glob/regex, Str->Str map, span/
byte-slice API, strict int parsing with offsets, base32 + percent-encoder).

Update 2026-10-02 (compiler lane ack + JSON note): v0.62.3 can pin the
already-tagged `stdlib-perf2` (`f011efe`) -- no new pin is needed for the
release; wave 57 is local and is not part of the release pin (push/tag at
the next release boundary or on request). The compiler-log check and the
crypto packet are resolved correctly (`m169`/`m170` verified fixed;
`xiom_sha256_hash` is an install/deploy stale-runtime issue, not compiler
or stdlib). JSON legacy bugs (0.05 -> 0.5 parse, `stringify_frac`,
exponent hang) are folded into the next serialize.json hardening wave, not
the coverage waves. Wave-58 recon (HTTP family, 55 uncovered pub: http 21,
header 6, cookie 10, mime 18) flags fix-first candidates for the executor:
`accept_q_value` returns up to 1999 while RFC 7231 caps q at 1.0
(`parse_q` accepts `1.999`); `charset_normalize` accepts `iso-8859-1`
despite its UTF-8/ASCII doc; the cookie matcher/expiry helpers call
`time.unix_timestamp()` while the module header says "pure" (by design --
keep probe KATs time-relative or expiry=0).

Update 2026-10-03 (wave 58 landed + push): net batch 2 -- the HTTP family
(http 21, header 6, cookie 10, mime 18 = 55 clauses). Fix-first:
`parse_q`/`accept_q_value` now cap q at 1000 per RFC 7231 (`1.999`
previously scored 1999). Probe `p_wave58_shapes.xi` (213th, 119 checks,
green on v0.61.3 and v0.62.2 dev); floors95; net 20.9% -> 39.4%, global
39.2% -> 40.1% (crosses 40%). Main was pushed through `c11b66c` (waves
54-57 + docs) so the website meter is current; wave 58 is local until the
next push point. Next: net batches 3+ (transport ~53, then protocols),
then serialize 5.4%.

Update 2026-10-03 (m178 closure + net.xi fix-first): the compiler lane's
m178 checker validation (pattern-vs-type on match arms) landed at compiler
main `659f6ec1`; our wave-57 invalid-IR finding is FIXED and
`p_wave57_probe_ir.xi` is retired (the diagnostic is now a clean T001). It
exposed a real pre-existing stdlib bug in the `xiom.net` aggregate body:
`str_slice` (`xiom/net/net.xi`) matched `Str::from_utf8(buf)` as `Ok/Err`
although it returns Str -- replaced with `return Str::from_utf8(buf);`.
Verified with the m178 binary: `check_modules` 509/509 type-check clean
(303s) and `smoke_net_address` compiles clean; gate-pin batteries re-run
green. Findings count 12 -> 11 (10 compiler, 1 stdlib). This unblocks the
compiler lane's api-freeze and the v0.62.3 tag. Also found while checking
the m178 build pre-tag: `p_never_called_zeroarg` AVs at call 3
(`xiom.contracts.any_contracts()`) and `p_sync_sizeof` returns 1
(`Arc.strong_count() != 1`) -- both green on v0.61.3; filed as
`p_contracts_any_av.xi` and `p_sync_arc_count.xi` (dev-build-only compiler
findings; count 11 -> 13) and relayed to the compiler lane before the tag.

Update 2026-10-03 (wave 59 landed: serialize.json hardening): the JSON
legacy bugs are fixed -- number grammar (leading zeros rejected;
integer-digit and exponent-digit requirements), the exponent hang
(accumulation capped at 1000, at most 400 scaling steps; `1e4000000000`
now errors fast), and non-finite stringify (`"null"` instead of invalid
`"inf"`; `json_parse` errors on inf/NaN results). The recorded
`0.05 -> 0.5` symptom does not reproduce on current sources (replayed
pre-fix: `0.05` parses correctly); `stringify_frac` has no symbol (the
surviving 15-vs-17-digit precision defect is recorded as a follow-up).
Probe `p_wave59_json.xi` (214th) RED pre-fix / GREEN post-fix on v0.61.3
and the m178 dev binary; serialize smokes 24/24, json smokes 17/17.
Compiler lane note: the sync Arc/strong_count finding is compiler-side
(m166 inlined unsafe path, 8-byte alloc for a 16-byte ArcInner); KEEP the
`#[unsafe_direct]` annotations on `xiom/sync/sync.xi` (Gate P depends on
them); sync-probe noise is expected until the compiler fix. Next: net
batches 3+ (transport ~53, then protocols), then the remaining low dirs.

Update 2026-10-03 (wave 60 landed): net batch 3 -- the transport family
(socket 18, tcp 4, udp 4, unix 10, tls 5, tls_helper 12 = 53 clauses).
Validation-guard implications on every socket entry point, documented
always-Err stubs, port bands, endpoint format/parse claims, TLS name-table
implications, DER/PEM presence bands, fingerprint length claims. Probe
`p_wave60_shapes.xi` (215th, 80 checks, green on v0.61.3 and the m178 dev
binary); floors96; net 39.4% -> 57.2%, global 40.9%. Next: net protocols
(proto/smtp/ftp/ntp/ping/sse/websocket/ws), then the remaining low dirs
(hash 8.9%, reflect 9.1%, iter 9.8%, convert 11.5%, format 13%, time 13%,
misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%, compress 21.1%),
then C, D, E, F.

Update 2026-10-03 (wave 61 landed): net batch 4 -- the protocol family
(proto 10, smtp 13, ftp 9, ntp 9, ping 7 = 48 clauses). Exact
command/format mirrors and length bands, JSON-RPC/SSE skeleton bands,
header parse/get presence, auth mirrors, reply-parser presence bands, NTP
structural/encode/decode claims plus exact offset/roundtrip mirrors, the
ICMP empty-input claim, and the nine documented Err stubs. Probe
`p_wave61_shapes.xi` (216th, 72 checks, green on v0.61.3 and the m178 dev
binary); floors97; net 57.2% -> 73.4%, global 41.6%. Gate P:
`stdlib-perf3` tagged at `2429ac3` and pushed. Next: net batch 5 (sse,
websocket, ws, dns, multipart, server, jwt, net.xi -- split into
40-60-pub batches), then the remaining low dirs (hash 8.9%, reflect 9.1%,
iter 9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%,
rand 16%, crypto 17%, log 19.1%, compress 21.1%), then C, D, E, F.

Update 2026-10-03 (release): compiler **v0.62.3 is PUBLISHED** with official
SHA256SUMS and the nine-tool archives (windows-x64/linux-x64/macos-arm64/
macos-x64) plus VSIX 0.12.2 and wasm. The shipped pin is `stdlib-perf3`
(`2429ac3`); no stdlib action needed. Gate P is closed on both sides.

Update 2026-10-03 (official v0.62.3 baseline): the windows-x64 archive
(SHA256 `011af7dd...` verified against the release SHA256SUMS and the
GitHub API digest) is installed at
`%TEMP%\kilo\stdlib_ws\v0623\x\bin\xiom.exe` (reports v0.62.3) and the
full battery ran on it: check_modules 509/509 (170.4s); corpus 947/951 --
filed failures: `smoke_iter_range` C001 and `smoke_compress_lz4_snappy`
(compiler-side, context-dependent, green on v0.61.3, minimal forms pass);
the two cell smokes were stdlib-side (missing `Ref.release`) and are fixed
2026-10-03; probes 219/219 (the m169/m170/m178-fixed
repros were promoted from known_failures to `tools/probes/` as
`p_regress_*`); barename 0/509; floors97/doc/module-smoke ratchets OK. Two
stale smokes were fixed at the pin move (bomb-guard's gzip Vec API;
`sprintf_i1` arity). Findings Current is now 10 (9 compiler, 1 stdlib):
`p_generic_typechanging_fnptr` now passes; `p_curve_thunk_zero`,
`p_geom_vector_result_bits` and `p_struct_literal_field_order` are
retired as fixed.

Update 2026-10-03 (wave 62 landed): net batch 5 -- sse (8), websocket
(14), ws (5), dns (8), multipart (6) = 41 clauses. Fix-first:
`ws_handshake_verify` now scans the CRLF after the accept value (canonical
101 responses verified false before). New finding:
`p_multipart_parse_name.xi` (multipart_parse result Part field reads are
corrupt on both v0.61.3 and v0.62.3; probe presence-only). Probe
`p_wave62_shapes.xi` (220th, green on v0.62.3 and v0.61.3); floors98; net
73.4% -> 87.2%, global 41.6% -> 42.2%. Next: net batch 6 (net.xi 15,
server 6, jwt 9), then the remaining low dirs (hash 8.9%, reflect 9.1%,
iter 9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%,
rand 16%, crypto 17%, log 19.1%, compress 21.1%), then C, D, E, F.

Update 2026-10-03 (relay resolutions): the 2026-10-02 "missing arguments
accepted silently" arity row is STALE -- on v0.62.2 `T001: expects N
argument(s), found M` rejects missing and extra args, exact-arity control
green; the registry row is retired and no local row existed to update.
`Vec[Float64]` push/compare/arith are green; the bitcast half is still
compiler-pending: `xiom.num.float.float_bits`/`bits_to_float` remain the
documented fallback stubs (`ensures: result == 0` / `0.0`, TODO(compiler),
probe prints `float_bits(1.5) == 0`), so packages keep raw-octet encodings
until the bitcast intrinsic lands. Relayed to the compiler lane: the
intrinsic is the remaining item, no stdlib change wanted.

Update 2026-10-03 (Gate P pin + trap-10): the compiler lane needs a fresh
stdlib tag >= `8b23b79` for Gate P; tagged `stdlib-perf3` at `5037262`
(waves 54-60: geom 100%, net 57.2%, global 40.9%; m178 + JSON hardening;
`#[unsafe_direct]` annotations stay; compiler then bumps STDLIB_VERSION,
regens api-freeze, t2 `185342f4`, tags v0.62.3). The packages'
`Vec[StructType]` trap-10 row is a retirement candidate (not reproducible
on both sides); no local row existed.

Update 2026-10-05 (v0.64.0 pin wave landed): re-pinned COMPILER_VERSION/
package.xi to v0.64.0 (tag c68d91de). Consumed the m193-m196 batch:
m195 resolves reflect.all_types (probe exits 0; clause added, reflect
100%); m196 restores TcpStream.read, locked by the new
tests/smoke/smoke_net_tcp_stream.xi loopback (corpus 953/953); m194 makes
num.float.float_bits/bits_to_float exact (fallback docs and clauses
replaced with roundtrips); m193 retires the guard-alloc probe shim in
smoke_guard_alloc_wrap.xi. New probe p_pin0640_shapes.xi (241st) locks
m194/m195. Findings 10 -> 9 (all_types RESOLVED); multipart stays
compiler-owned for v0.64.1; Box stays section C. floors113 (global
51.4%, reflect 100%); meter 75.1%. Battery on v0.64.0: corpus 953/953,
probes 241/241, modules 509/509, barename 0/509, floors113 +
module-smoke ratchets OK.

Update 2026-10-05 (wave 77 landed): stats --
93 clauses / 48 new pub (dist 15, histogram 9 -- histogram_add is void
with a discarded by-value mutation and stays clause-free, moments 13,
test 11). Guard-branch NaN mirrors, [0,1] distribution bands, exact
x == 0 chi-squared branch values, histogram struct field/length mirrors
and degenerate-histogram guards, even-k non-negative moment bands,
p-value/interval bands. Fix-first (probe-caught): moments.quantile
returned raw bits for q == 0.0 / q == 1.0 -- rvalue indexing of a
returned Vec[Float64] (`_sorted(data)[0]`) misreads; new compiler finding
p_rvalue_float_vec_index.xi (rc 1 on v0.64.0), bound copies used instead;
stddev/geometric_mean now guard NaN before math.sqrt/math.ln requires.
stats 25% -> 59.3%, global 51.4% -> 52.1%; meter 75.2%; floors114.
Probe p_wave77_shapes.xi (242nd, 167 checks) green on v0.64.0 pre/post;
targeted smoke smoke_stats 1/1. Findings 9 -> 10 (9 compiler, 1 stdlib).
Battery on the commit (v0.64.0): corpus 953/953 full (804.9s), probes
242/242 (395.1s), modules 509/509 (261.3s), barename 0/509 (745.9s),
floors114 + module-smoke ratchets OK.
Readiness next: thread 25% / convert 25.6%; then the iter clause retry
(block 27) and the Pulse hardening wave.

Update 2026-10-05 (wave 76 landed): simd --
49 clauses / 49 new pub (gather 5, mask 14, vec4 17, vec8 13); simd
24.4% -> 78.9%, global 50.6% -> 51.3%; meter 75.1%; floors112. Probe
p_wave76_shapes.xi (240th, 66 checks) green on v0.63.1; targeted smokes
simd 1/1. Clause forms: exact lane mirrors on vec4/vec8 structs
(field-read clauses verified working on the pin), min/max lane
disjunctions, mask bit-pattern mirrors and guarded set/clr, gather
length identities. Deliberate omits: div (NaN), dot/sum self-mirrors,
f32x4_load/store (pointer), vec8 array-param constructors (array element
reads in clauses), gather_load4 (default-T tuple). Probe landmine
recorded: explicit type args on module-qualified generic calls
(`gather_load[Int](...)`) miscompile with an LLVM Vec/ptr error on
v0.63.1 -- use inference. Readiness next: stats 25%, then thread 25% /
convert 25.6%.

Update 2026-10-05 (compiler help relay -- scrypt/shuffle/choice/BUG-18/Box):
- The compiler lane asked for failing snippets for scrypt, shuffle/choice
  and BUG 18, plus a Box decision. Verified on v0.63.1: all three are
  GREEN and now regression-locked -- tools/probes/p_regress_scrypt.xi
  (N=4/r=2/p=1/dkLen=32 then RFC-7914-sized 1024/8/1/64 twice),
  p_regress_shuffle_choice.xi (T=Int and T=Str, both fns in one program),
  p_regress_bug18_combo.xi (io+string+text.similarity+time with
  rot13/translate/jaccard/strftime/strptime). Stale "blocked" comments in
  smoke_crypto_kdf/smoke_str2/smoke_time2 updated. The `%Q` strptime face
  cannot be re-tested because that path no longer exists in time.xi;
  restoring it is a small follow-up if the compiler needs it.
- Box answer: rides queue section C (geom dedup + rename), gated on the
  compiler-lane api_freeze regen; no special compiler fix is required if
  the rename lands. A compiler-side shadowing/alias fix would also clear
  it, but the lane's C plan is the confirmed path.
- Probe corpus 236 -> 239 (probes-only run 239/239 on v0.63.1).

Update 2026-10-05 (wave 75 landed): encoding remainder + debug --
50 clauses / 50 new pub (ascii85 6, punycode 7, idna 8, disasm 7,
heap_report 11, trace 11; debug.hexdump's placeholder replaced).
encoding 72.4% -> 100%, debug 24.4% -> 95.1% (only the void trace_print/
trace_log remain uncovered), global 49.8% -> 50.6%; meter 75.1%;
floors111. Probe p_wave75_shapes.xi (236th, 84 checks) green on v0.63.1;
targeted smokes ascii85 2/2, punycode 3/3, debug 2/2. Notable clause
forms: punycode_adapt requires (numpoints > 0, delta >= 0) + result >= 0;
disasm stub mirrors (all Err/false/None); heap counters mirror module
vars and reset re-establishes the peak invariant; trace mirrors
enablement/depth and enter/exit are monotone with @pre. Readiness next:
simd 24.4%, stats 25%, thread 25%, convert 25.6%, core 26.7%.

Update 2026-10-05 (wave 74 landed): encoding + three fix-first --
55 clauses / 37 new pub (encoding.xi 24 touched, base64 8, base32 6,
hex 9, percent 8); encoding 23.7% -> 72.4%, global 49.3% -> 49.8%; meter
75.0%; floors110. Fix-first: utf8_decode's `requires: data.len() > 0`
removed (utf8_decode(empty) -> Ok("") and utf8_valid(empty) -> true; the
old clause aborted callers with `contract violated: requires at 501:13`);
both base64url_decode copies now return Err for a dangling final char
(len%4==1, silently dropped before); the percent '+' divergence is pinned
by probe and documented (root percent_decode is form-style, the percent
module keeps '+' literal) -- no behavior change. Probe p_wave74_shapes.xi
(235th, 95 checks) green pre/post on v0.63.1; targeted smokes encoding
16/16, base 12/12, utf8 6/6, percent 2/2. Remaining encoding: ascii85 6,
idna 8, punycode 7. Readiness next: debug 24.4%, simd 24.4%, stats 25%,
thread 25%, convert 25.6%; tuple-component clauses are now allowed by
v0.63.1.

Update 2026-10-05 (v0.63.1 pin wave landed): re-pinned COMPILER_VERSION/
package.xi to v0.63.1 (release commit 1b972478; tag c0fa3a2d; handoff
5666d092; STDLIB_VERSION stayed cd61062). C001 trigger fired: 4bf8cf1e is
an ancestor of the release, both iter carve-outs dropped from
gate-exclusions.txt after 20/20 + 20/20 stress (registry lane
independently 20/20 + 20/20) -- the release corpus is now FULL 952/952,
no exclusions. Instant fix: Instant.now()/elapsed() read the monotonic
runtime clock (monotonic_ms()/1000); SystemTime stays wall clock; probe
p_pin0631_shapes.xi (234th) locks it plus the bare-lz4 leaf resolution;
the wave-68 lz4 rename is kept as an optional no-op per the compiler lane.
Contract-evaluator false aborts (tuple/payload clauses) and duplicate
index warnings are gone on the pin. floors109 wired. Fix-first exposed by the pin: io.write_file_bytes' Err
clause `result.value.len() > 0` (a Result[Unit, IOError] payload read,
bogus `.len()` on IOError) was lowered strictly by v0.63.1 into
str_len(IOError), so any caller of the gzip file wrappers failed clang
(the sweep probe caught it); the same clause was retired from move_file,
write_file_lines and append_line. The gzip wrappers compile again and are
runtime-locked by p_pin0631_shapes.xi (empty-path Err). Repo-wide
`result.value` clause audit (wave 74): the four io.xi IOError `.len()`
sites were the only bogus ones -- io/pipe.xi, io/fs.xi and io/console.xi
Err payloads are Str (valid) and stay. Relay from the compiler/benchmark lane: perf residual
is runtime syscalls (Windows VirtualProtect ablation 438.5 -> 92.5 ms on
262k entries; POSIX adds sigaction/mprotect per trampoline); fast-path
design tracked in the compiler COMPILER_BUGS entry, container t3 target
25-29 ms once the pin moves -- no stdlib action.
Battery on v0.63.1 (re-run after the io fix): corpus 952/952,
probes 234/234, modules 509/509, barename 0/509, floors109 +
module-smoke ratchets OK.

Update 2026-10-05 (wave 72 landed): compress formats --
39 clauses / 39 new pub (gzip 6, deflate 5, brotli 4, zlib 6, snappy 8,
lz4 10); 4 skipped by design (io wrappers gzip_compress_file/
gzip_decompress_file and FFI streams deflate_compress_stream/
brotli_decompress_stream have no parameter-derivable claim). compress
21.1% -> 64.4%, global 48.7% -> 49.3%; floors108; meter 74.9%. Probe
p_wave72_shapes.xi (233rd, 71 checks) green on v0.63.0; targeted smokes
compress 26/26, crc 1/1. Deliberate omits carried from recon: deflate
capped has no `max_out < 0 => Err` (EOB-only fixed stream returns Ok
empty), lz4 capped has no `<= max_out` (one-block overshoot), dynamic
repeat codes stay Err (wishlist row 124 is feature work), no element
reads anywhere. lz77 (6) and huffman (12) remain clause-free for a
follow-up. Readiness next: encoding 23.7% (fix-first ledger above), then
debug 24.4%, simd 24.4%, stats 25%.

Update 2026-10-05 (wave 71 recon + packages relay):
- Packages wishlist source-of-record advanced to 126 rows (waves 47-55;
  local mirror docs/STDLIB-WISHLIST.md still holds the 46 relayed rows).
  Actionable intersections: row 124 deflate dynamic-Huffman read path is
  feature work (the current decoder deliberately Errs on repeat codes
  16/17/18 -- wave-72 clauses must match that limitation); row 127
  `_u64_lshr` n=63 defect is a crypto fix-first candidate; row 150
  is_finite/is_nan + reciprocal is clause-authoring leverage; row 152
  strict percent_decode (offsets + NUL rejection) aligns with the percent
  findings below; rows 87/96 are sb_push_int INT_MIN and parse_int 2^63
  defects. Stale rows to close at next sync: 34 (encoding.base64 shipped),
  139 (duplicates local row 33). Full 80-row mirror refresh rides a
  dedicated intake.
- Wave-72/73 recon findings (verified on v0.63.0, temp evidence):
  (1) `encoding.utf8_valid(empty)` aborts with a contract violation at
  encoding.xi:501 (utf8_decode requires data.len() > 0; its len == 0 Ok
  branch is dead) -- fix-first for the encoding wave; (2)
  `encoding.base64url_decode("AAAAA")` silently drops the dangling char
  (len%4==1) in both copies -- fix-first; (3) same-named percent_decode
  diverges: encoding.percent_decode("a+b") == "a b" vs
  percent.percent_decode("a+b") == "a+b". Reported only: idna_uts46 cp
  range, huffman length guards, snappy > 2^24 literal truncation, brotli
  stream missing got<0, deflate dead got<0 / unchecked fwrite. Compress
  over-claim traps for wave 72: deflate capped max_out<0 returns Ok on an
  EOB-only stream, lz4 capped overshoots by one block, no element reads.

Update 2026-10-05 (wave 71 landed): log levels/color/sinks/json/core --
60 clauses / 49 new pub (levels 12, color 8, sinks 8, json 4, log core
28); log 19.1% -> 91.2%, global 47.9% -> 48.7%; floors107. Probe
p_wave71_shapes.xi (232nd, 88 checks) green on v0.63.0; targeted smokes
log 9/9, json 17/17. Pin quirks: qualified JsonLogEntry construction
(same-leaf type family) worked around via log_json_parse payload; Map
field .len() codegen symbol avoided (map-length claim dropped). Readiness
next: compress 21.1%, encoding 23.7%, debug 24.4%, simd 24.4%.

Update 2026-10-05 (wave 70 landed): crypto mac/kdf/keyx/rng/sign/poly --
41 clauses / 41 pub (mac 12, kdf 9, keyx 9, rng_crypto 5, sign 5,
poly1305_mac 1); crypto 17% -> 39.6%, global 47.3% -> 47.9%; floors106.
Probe p_wave70_shapes.xi (231st, 79 checks) green on v0.63.0; targeted
smokes crypto 36/36, poly 2/2, hash 39/39. Fix-first: hkdf_extract/
hkdf_expand's Int parameter `hash` shadowed the `use xiom.crypto.hash;`
alias, so every hash == 2 call AV'd; calls now fully qualified and the
hash-2 paths verified. Skipped by design: scrypt (ROMix heap corruption),
crypto_random_shuffle/choice (generic lowering blocked), the unsigned
word returns and tuple helpers. Readiness next: log 19.1%, compress
21.1%, encoding 23.7%.

Update 2026-10-05 (wave 69 landed): os path/filetype + rand family --
76 clauses / 76 pub covered (path 18, filetype 22, rand 20, pcg 5,
mt19937 6, chacha 5); os 15.3% -> 26.2%, rand 16% -> 88%, global 46.1%
-> 47.3%; floors105. Probe p_wave69_shapes.xi (230th, 167 checks) green
on v0.63.0; targeted smokes rand 42/42, path 18/18, filetype 1/1.
Clause forms: empty-input Option/Str identities, presence bands,
length/range claims, seed and state-shape mirrors, bounded-next ranges
(hi <= 0 => 0). Readiness next: crypto 17%, log 19.1%, compress 21.1%,
encoding 23.7%; os continues with the FFI/event families (err, event,
fs, file, dir, sysinfo, terminal).

Update 2026-10-05 (wave 68 landed): misc glob/soundex/natural/
levenshtein -- 36 clauses / 29 pub; misc 13.9% -> 50.6%, global 45.7% ->
46.1%; floors104. Probe p_wave68_shapes.xi (229th, 54 checks) green on
v0.63.0 and v0.61.3; smoke_misc 3/3. Duplicate-leaf fix: the stale
`xiom.misc.misc.soundex` copy (returned "0000" for empty) now delegates
to the canonical shim, so bare `soundex("")` returns "" (evidence
bare=[0000] before); remaining soundex string/similarity shim leaves go
to the same-leaf audit / compiler parity work. Readiness next: os 15.3%,
rand 16%, crypto 17%, log 19.1%, compress 21.1%, encoding 23.7%.

Update 2026-10-05 (lz4 duplicate-leaf unblock): the umbrella wrappers
were renamed to `lz4_compress_checked` / `lz4_decompress_checked`, so a
bare `lz4_compress` now uniquely resolves to the Vec variant; verified
against v0.63.0 (stress smoke rc 0, snappy smoke OK, bare-call scratch
rc 0). Compiler parity fix queued as defense.

Update 2026-10-05 (wave 67 landed): format dump/number/relative/table --
33 clauses / 33 pub; format 13.0% -> 27.3%, global 45.1% -> 45.7%;
floors103. Probe p_wave67_shapes.xi (228th, 59 checks) green on v0.63.0
and v0.61.3; targeted smoke_format 8/8. Readiness toward 100%, next low
dirs: misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%, compress
21.1%, encoding 23.7%, then the larger surfaces. The iter surface still
waits on the first compiler archive containing 4bf8cf1e (then drop the
two C001 gate exclusions and rerun the 20-run stress retest).

Update 2026-10-05 (publish complete + C001 fix relay): staging canaries
for 0.62.3/0.62.4/0.63.0 all green on staging.registry.xiom-lang.org and
the production publishes all succeeded on registry.xiom-lang.org after
environment approvals (sha256/signature/provenance verified); the
registry now carries xiom-std 0.62.3, 0.62.4 and 0.63.0. C001 is fixed on
compiler main (4bf8cf1e); v0.63.0 predates it, so the two C001 smokes
stay excluded on this pin -- drop both on the first archive containing
the fix and run the 20-run stress retest (expect deterministic green)
before promoting the lock.

Update 2026-10-04 (v0.63.0 re-pin + release prep): SHA256-verified
official v0.63.0; COMPILER_VERSION/package.xi -> 0.63.0. Gate carve-out
shrinks to the two C001 iter smokes -- m190 fixes lz4 and the smoke is
green on the archive, so it left gate-exclusions.txt; release notes
disclose C001 only. Findings: lz4 RETIRED (count 12 -> 11 = 10 compiler +
1 stdlib); all_types still crashes (v0.63.0, rc -1073740940); multipart
still rc=1; C001 still flaky (excluded); iter collect call side green.
Battery on v0.63.0: release corpus 950/950 (2 excluded of 952), probes
227/227, modules 509/509, barename 0/509, ratchets OK; t2 15/15.
Caveat: the compiler's own v0.63.0 archive bundles a pre-bound-check
stdlib runtime; stdlib-v0.63.0 carries the check. The external-extern
guard-alloc hang is filed on the compiler side. Publish retries for
0.62.3/0.62.4 continue under the registry lane's db39144 fix (asset-name
sha256 match); tags re-triggered 17:08Z, publish environment approvals
pending.

Update 2026-10-04 (wave 66 landed): time core -- 39 clauses / 39 pub
(duration 15, instant 6, date 12, iso8601 6); time 13.0% -> 41.3%,
global 44.5% -> 45.1%; floors102. Probe p_wave66_shapes.xi (227th, 61
checks) green on v0.62.4 and v0.61.3; targeted smoke_time 19/19. Skipped
by design: the three clock functions and the tuple-returning iso8601
helpers. No runtime/ or iter changes, so the v0.63.0 pin candidate
(cd61062) is untouched. Also since the v0.62.4 re-pin: the guard-alloc
wrapping-size bound check + fault-injection lock (cd61062) and macos-14
in the weekly heavy matrix (release-matrix promotion after a green heavy
run).

Update 2026-10-04 (v0.62.4 re-pin + stdlib 0.62.3/0.62.4 release prep):
COMPILER_VERSION moved to the SHA256-verified official v0.62.4 archive.
Release-gate carve-out per the owner decision: run_smokes.ps1
-ExcludeFile + tools/known_failures/gate-exclusions.txt
(smoke_iter_range, smoke_iter_find_all_any, smoke_compress_lz4_snappy;
exclusions printed and counted in the JSON); release.yml wired, ci/heavy
stay full-corpus. New finding p_iter_range_contains_c001.xi: the C001
classifier is run-to-run nondeterministic on v0.62.3 AND v0.62.4 (6-run
3/3 here; registry stress 8/20 + 12/20 and 8/20 + 10/20). Promotions:
p_regress_uint32_compare.xi (m186 fix, entry retired) and
p_regress_iter_collect.xi (collect call side fixed on v0.62.4; clause
side persists, entry kept); probe corpus 226. t2 (kat_) 15/15 on v0.62.4.
stdlib 0.62.3 (commit 12a3a1b, tag stdlib-v0.62.3): release battery with
exclusions 948/948, modules 509/509, barename 0/509, ratchets OK.
stdlib 0.62.4 (this commit, tag stdlib-v0.62.4): package.xi 0.62.4,
release notes + CHANGELOG; both notes disclose the C001 flake and the
lz4 empty block. Publish is staging-first (release.yml canary-dispatch)
then production via the tag push with registry-publish environment
approval. Packages repo already carries its own v0.62.4 re-pin
(c477528a/281db5de) not interleaved here.

Update 2026-10-04 (wave 65x landed): convert shims -- 43 clauses / 43
pub: convert.bytes 6, endian 6, checked 9, base64 4, exact 3, swap 3,
tostring 5, wrapping 7. convert 11.5% -> 25.6%, global 43.9% -> 44.5%;
floors101. Re-derived and rejected `hex_to_bytes`'s odd-length -> Err
claim (the canonical decoder REQUIRES even length and aborts); the
wrapper now carries that precondition and its doc is corrected.
bytes.from_bytes stays compile-checked only (documented invalid-IR call
collision). Probe p_wave65x_shapes.xi (224th, 60 checks): green on
v0.62.3, v0.61.3 and m189; targeted smokes convert 37/37, cross 9/9.
iter remains deferred (wave 65 blocked; see the entry below). Enum-payload
minimization materials for the compiler lane: the bundle lives in the
packages repo (E:\xiom-packages\packages\docs\repro\enum-payload-str\
{README.md,probe_enum_payload_str.xi}); in-situ context
packages\xiom-graphql\graphql.xi validate_operation, failing case
tests\test_conformance.xi "validate valid operation" (9/10) -- packages
lane owns the slice.

Update 2026-10-04 (wave 65 BLOCKED, nothing landed): every drafted
xiom.iter clause set was reverted -- with the Range core set (7 clauses
incl. Range.collect) 12 iter-consuming smokes fail with closure
use-before-def ("use of undefined value" in a __closure_N); removing the
collect clause restores them but flips smoke_iter_range back to the old
C001 contains-classifier error. No subset keeps the iter family green on
the v0.62.3 pin. Filed
tools/known_failures/p_iter_range_collect_forwardref.xi (Range.collect
call fails clang "instruction forward referenced with type 'ptr'"; any
clause on Range.count/find breaks smoke_iter). Coverage unchanged:
floors100 (global 43.9%, iter 18.6%); the wave-65 floor dump was
withdrawn. Kept: the finding + tools/probes/p_wave65_shapes.xi (223rd,
13 checks) as a behavioral Range-core API lock, green on v0.62.3,
v0.61.3 and m189. Findings Current 12 (11 compiler, 1 stdlib). Resume
the iter surface after the compiler closure-lowering and C001 classifier
fixes.

Update 2026-10-04 (wave 64 landed): reflect + iter adapters -- 55
clauses / 55 pub covered: reflect.fields 10 + reflect.typeinfo 11 (exact
placeholder constants), reflect 18 (TypeId.of id==0, size/align/total
>= 0, downcasts is_none, reflect_type shape, type_info_by_name
empty-name None band, classifier constants), iter.map 5, iter.range 6,
iter.zip 5 (exact length arithmetic and empty bands). New finding
p_reflect_all_types_crash.xi: `reflect.all_types()` heap-corrupts
(0xC0000374) on v0.62.3, v0.61.3 and the m187 dev build; the identical
build loop replicates green in a user module and type_info_by_name's
single-TypeInfo return works, so it is catalog-return-path specific --
all_types is the only reflect pub fn left clause-free. Probe
p_wave64_shapes.xi (222nd, 47 checks, reflect+iter combined; the
fields/typeinfo clauses ride smoke_reflect at runtime): green on
v0.62.3, v0.61.3 and m187. reflect 9.1% -> 97.7%, iter 9.8% -> 18.6%,
global 43.0% -> 43.9%. floors100. Findings Current 11 (10 compiler, 1
stdlib). Compiler-lane relay: m186 fixes the wave-63
p_uint32_high_bit_compare (verified rc 0 on m187; retire + promote at
the next pin); m184/m185 fix nested test-module import and uninit local
struct; the iter-range C001 is CLOSED (smoke_iter_range rc 0 on the
v0.62.3 tree; promote the smoke lock when v0.62.4 ships on
stdlib-perf3); the packages-lane enum-payload Str in-situ case still
fails on m189 too (local v0.62.4 candidate 355c69d0/HEAD 32ea20f0:
graphql conformance 9/10, same validate-valid-operation failure,
standalone control green) -- a FRESH finding per the compiler lane;
porter rules (nested-module workaround, initialize-locals) can drop
once the packages pin is v0.62.4. No package.xi bump/tag needed now.

Update 2026-10-04 (wave 63 landed): net batch 6 + hash batch 1 -- 53
clauses / 52 pub covered: net.xi 15 (handle-close Ok claims, empty-URL
Err implications, udp_bind port-guard bands, parse_url/url_parse_*
presence bands, alias preconditions), server 6 (default port,
request-line Option bounds, status-line/response length bands with exact
200/404/500 mirrors, status-text table mirrors), jwt 9 (base64url length
bands, alg mirror, decode/verify/expired/claims min-length bands), hash
22 (adler empty-input claim with the 65521-byte b-wrap case locked by
the probe, checksum 16-bit bands, CRC empty seeds
and checksum rows, FNV offset-basis empties, jenkins/murmur Vec length
claims, superfast mask bound). Probe p_wave63_shapes.xi (221st, 123
checks, no network I/O; early-error paths + synthetic -1 handles): green
on v0.62.3 and v0.61.3. New finding p_uint32_high_bit_compare.xi:
inline module-qualified UInt32 call compares misread high-bit values
(0xFFFFFFFF reports unequal) on BOTH v0.62.3 and the m178 dev build;
binding the call to a local is the documented workaround, extended from
UInt16/UInt8. floors99; net 87.2% -> 97.3%, hash 8.9% -> 33.3%, global
42.2% -> 43.0%. Findings Current 10 (9 compiler, 1 stdlib). Next: the
remaining low dirs (reflect 9.1%, iter 9.8%, convert 11.5%, format 13%,
time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%,
compress 21.1%), then C, D, E, F.

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

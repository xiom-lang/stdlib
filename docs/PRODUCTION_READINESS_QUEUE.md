# Production-readiness remaining queue (handoff 2026-09-25)

**76.4% -- 7 of 10 gates complete; gate 8 at 63.6% (partial credit) and
gates 9-10 discrete.** (Compiler pin: **v0.64.2**.)
**Gates: corpus 954/954 full (C001 carve-outs retired on v0.63.1; new
TcpStream loopback and uuencode roundtrip smokes added), modules 509/509,
probes 273/273, barename 0/509.**

Readiness gates (the meter above counts these; each is backed by the battery
recorded in the updates below). Update the two lines above and this list as
gates flip:
1. Modules type-check clean -- MET (509/509).
2. Smoke corpus green -- MET on the v0.64.0 pin: release gate 954/954
   full, no carve-outs (C001 fixed by 4bf8cf1e; 20/20 + 20/20 stress).
   lz4 is fixed by m190 and stayed in the gate; the new TcpStream loopback
   smoke locks m196.
3. Probe corpus green -- MET (273/273 on v0.64.2, incl. the promoted
   regression locks (rvalue float Vec index, multipart parse name, iter
   forwardref), the v0.64.1 pin probe p_pin0641_iter_shapes.xi, the
   wave-77 stats probe, the Pulse hardening probe, the wave-78..100
   coverage probes (the wave-97 probe was remerged after m242, plus the
   wave-98/99/100 probes), the io byte-fidelity/CRLF lock and the
   fs_remove lock).
4. Strict bare-name scan clean -- MET (0/509).
5. Coverage ratchet green -- MET (floors129).
6. Documentation ratchet 100% -- MET.
7. Module-smoke ratchet green -- MET (497/517 modules, 3477/6202 fns).
8. Contract coverage 100% (every public fn carries clauses) -- OPEN (63.6%).
9. Zero open findings (`tools/known_failures/README.md` Current section) --
   OPEN (14: 13 compiler, 1 stdlib algorithm).
10. Beta-exit release cut green (`docs/RELEASE_CHECKLIST.md`) -- OPEN.

Meter formula: MET gates count 1.0; gate 8 counts its current
pub-with-clause fraction (63.6% -> 0.636); gates 9 and 10 get no partial
credit (discrete). Update the percentage and the gate-8 fraction in the
same commit as each floors dump so the meter moves smoothly toward 80%.

Authoritative order: the gates above, then the updates below newest-first.
Current state: compiler pin **v0.64.2** (combined release, tag c51170a6);
**stdlib-v0.64.3 RELEASED 2026-10-09** (release run 37962367989 full
success; assets xiom-std-0.64.3.tar.gz + SHA256SUMS) and the **REGISTRY IS
LIVE** (xiom-std 0.64.3 signed, sha256
775496c094d2a1703307313c9139c8cdc959d7687fc7a5b42b57657efa596b17,
compiler v0.64.2); the compiler lane confirmed the **candidate-tag pin
protocol** (relay 2026-10-09: tag candidate -> compiler verifies -> then
registry publish; one-version steady state allowed) and will verify
stdlib-v0.64.3 during its v0.64.3 candidate gates. Open follow-ups: the
STDLIB_VERSION pin PR needs a manual open (branch
`chore/pin-stdlib-v0.64.3`), the staging canary (37968157641) still waits
for approval, package.xi needs `categories` + `stage` for the next cut,
and the repaired heavy matrix passes ubuntu/windows but the macos-14
corpus leg is red (PULSE macOS runtime-C blockers suspected). Wave 98
landed post-tag (M7 closure rewrite; read_file_lines/to_string_char
contract fixes; new tostring-import finding); wave 99 added crypto hash
sizes, xxhash/city empty pins and math constants; wave 100 added the
finance/information-theory guard surfaces; wave 101 added graph_theory
(32/32) + machine_learning (31/32) and caught two fix-firsts
(floyd_warshall's 2n-row defect; metric_auc's corrupted tuple scores --
filed as the new compiler finding `p_tuple_elem_vec_read.xi`; findings
15 Current). Coverage 63.6%, meter 76.4%; handoff in
`docs/stdlib_session.md` snapshot 25 (block 88), wave record block 89.
BINARY NOTE: the shared local build path
`E:\xiom-lang\xiom\target\release\xiom.exe` was rebuilt past the pin
(compiler main da7798da m252) and fails four corpus smokes; use the
official archive binary `%TEMP%\kilo\stdlib_ws\v0.64.2\bin\xiom.exe`.

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
- **TcpStream.write partial-send: DONE (2026-10-05).** `write_all` added
  (`xiom/net/net.xi`: 64 KiB staging-buffer loop, advances by the
  kernel-reported partial count, empty => Ok(0) clause); `write` keeps
  its documented single-send semantics. Locked by p_pulse_shapes.xi
  (100000-byte loopback) and the extended smoke_net_tcp_stream.xi.
- **Server request-head parser: DONE (2026-10-05).**
  `server_parse_request(bytes)` + `ServerRequest` added to
  `xiom/net/server.xi`: method/target/version, lowercased (name, value)
  header list, Content-Length framing and the body span; None on a
  malformed request line, unterminated head, header without colon or a
  bad/negative Content-Length. Reuses `server_parse_request_line`.
- **`str_bytes`: already exists** at `xiom/string/slice.xi:135`
  (`ensures: result.len() == s.len()`); Pulse missed it because the root
  `xiom.string` does not re-export submodule fns -- use
  `xiom.string.slice`. **Adopted by Pulse 2026-10-05.**
- **`flush_stdout` is a no-op** (`xiom/io/io.xi:903`, empty body): implement
  a real flush through a runtime extern; probe explicit-flush visibility
  (abnormal-exit durability stays runtime/CRT-dependent). Pulse confirms
  this finding is the root cause of their lagging/truncated redirected
  logs (log evidence now attributed to io.xi:903).
- **`hmac_sha256_hex`: DONE (2026-10-05).** `crypto.hmac_sha256_hex`
  (flat module; `hex_encode(hmac_sha256(...))`, 64-char ensure) locked
  against RFC 4231 case 1 by p_pulse_shapes.xi.
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
- Pulse hardening wave landed 2026-10-05: `TcpStream.write_all`,
  `server_parse_request` + `ServerRequest`, `crypto.hmac_sha256_hex`
  (probe p_pulse_shapes.xi, 243rd; smoke_net_tcp_stream.xi extended).
  Remaining runtime-backed items (`socket_set_timeout`/`nonblocking`/
  `reuse_addr` + real `flush_stdout`) wait for the runtime bundle or
  `XIOM_RUNTIME_DIR`.
- Pulse wishlist fetch 2026-10-07 (their file updated 2026-10-05 21:39
  against stdlib 15cb889 / pin v0.63.1, i.e. just before our ec64dec
  hardening):
  * Production evidence for `write_all`: serving the 270 KB app icon
    through one `socket_send` returned a short write and the client got
    nothing; PULSE chunks+loops locally (`send_all`). The stdlib version
    landed at ec64dec (chunked, partial-send aware) and is locked by the
    100000-byte loopback probe.
  * `server_parse_request` landed as `Option[ServerRequest]` (PULSE
    suggested `Result[ServerRequest, Str]`); flagged for PULSE re-verify
    -- an error-carrying variant can follow if the failure reason is
    needed.
  * `hmac_sha256_hex` landed; `mac.xi` already carries
    `constant_time_eq`/`hmac_verify`, so the constant-time-compare half
    needs no new code.
  * NEW durable-append ask (fsync/flush; `io.fsync(handle)`,
    `flush_stdout`): no `fsync`/`FlushFileBuffers`/`_commit` exists in
    `runtime/*.c`, so it is runtime-backed and queued for the next
    compiler runtime bundle; the packages sheet filed the same ask on
    2026-10-05 as its "highest-value storage ask" (two-lane demand).
  * v0.64.0 positives: runtime + crypto link env-free (`XIOM_RUNTIME_DIR`
    retired in PULSE's dev-env; doctor reports the installed
    `lib\runtime`); `TcpStream.read` probes green (C-PULSE-01 closed).
  * `PACKAGE-WISHLIST-PULSE.md` checked: packages-lane items only
    (`xiom.http` 0.1.1, `xiom.jwt` 0.2.0 and `xiom.router` 0.1.0 adopted;
    proposed `xiom.session`/`static`/`metrics`/`middleware`/`kv`); the
    stdlib asset to keep for `xiom.static` is `xiom.net.mime`;
    C-PULSE-02 (installed packages not mapped into the compiler module
    catalog) is compiler-side.
  * Submodule note: root modules do not re-export submodule fns; a doc
    line per root README is a low-priority docs item.

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

Update 2026-10-08 (string quadratic defects fixed; PULSE signal stubs;
registry live): ORBITDB's re-sweep found `str_split` O(n^2) (slice per scan
position; 5 MB / 20k-line WAL replay ~44 s vs 2 ms read). Fixed with a
byte-compare scan; same class: `str_repeat` now doubles (was quadratic
accumulation), `str_pad_left`/`str_pad_right` allocate once (were
quadratic and leaked one malloc per pad byte). Locked by
`tools/probes/p_str_split_scale.xi` (120 KB scale + edge cases) plus the
string smokes. PULSE's signal-handler ask is addressed stdlib-side as
documented-Err `signal_handle`/`signal_pending` stubs in `xiom/os/signal.xi`
(signal-safe runtime trampoline queued). XVECTOR, bindings and packages
reports show no new rows. REGISTRY CONFIRMED LIVE: xiom-std 0.64.2 is
published (signed, sha256 f5375c03ad88) -- the 0.63.0 -> 0.64.2 registry
lineage is complete.

Update 2026-10-08 (stdlib 0.64.2 RELEASED): per the owner decision, one
release was cut at the new pin. Tag stdlib-v0.64.2 on commit 4dd8844
(package.xi 0.64.2 + release-notes/v0.64.2.md + CHANGELOG [0.64.2]); the
full gate suite ran green on that commit (corpus 954/954, probes
263/263, modules 509/509, barename 0/509, floors129 + doc ratchets) and
release.yml run 37786796498 completed SUCCESS with the GitHub Release
(stdlib-v0.64.2: xiom-std-0.64.2.tar.gz + SHA256SUMS). No 0.64.0/0.64.1
stdlib tags were cut; lineage 0.63.0 -> 0.64.2. REGISTRY: publish runs
37786796626 (tag-triggered) and 37793330331 (dispatch) are WAITING on
the protected registry-publish environment -- approve ONE, then verify
with `xiom pkg info xiom-std` (expect 0.64.2 signed). Compiler side:
STDLIB_VERSION = stdlib-v0.64.2 for the v0.64.2 combined release.

Update 2026-10-08 (v0.64.1 PIN BUMP): pin moved to official v0.64.1 (tag
3c6f3bb5; binary at %TEMP%\kilo\stdlib_ws\v0.64.1). Verified green on the
pin: m200 rvalue Vec[Float64] index (rc 0), m201 multipart parse name
(rc 0) and m203 iter closure-thunk clause leak (Range.count clause +
smoke_iter 21/21 including at -Workers 8; the forward-ref repro rc 0).
Landed the retried iter set (13 clauses / 12 pub: contains x2, sum,
product, collect, count-empty, max, min, find, all, any, nth, last) with
pin probe p_pin0641_iter_shapes.xi green pre/post; promoted three
resolved repros to tools/probes/ (rvalue, multipart, iter forwardref).
STILL OPEN on v0.64.1 (relay corrections recorded): geom-matrix tuple
inference PARTIAL (checks 1-3 pass, `var l2 = lu.0` check 4 rc=4),
polyhedra nested hull unchanged (rc=1), p_ensures_isok_guard unchanged,
p_clause_float_vec_index unchanged, p_geom_box_unnameable unchanged, the
cross-module type-path/foreign-call findings unchanged. iter 18.6% ->
25.1%, global 57.5% -> 57.7%, meter 75.8%; floors129. NOTE for the
release lane: the archive at v0.64.1 bundles stdlib 6e60e958 (old
wave-74 pin); the v0.64.2 pin decision + release notes are pending in
the session blocks.

Update 2026-10-09 (wave 98 landed): M7 stdlib-side fix + consumer contract
fixes + array extension -- 7 clauses, +3 pub covered. M7: the four
adapters (step_by/take_while/skip_while/inspect) rewritten to the
closure-based shape and constructed from Range; the Iterator[T] receivers
are gone (the 5x "unknown type 'Iterator'" warnings stop);
p_iter_iterator_type_unresolved.xi exits 0; constructor claims landed
(Range.step_by step/first mirrors, take_while done==false, skip_while
skipped==false); iter 45.4% -> 46.4%. Consumer contract rows:
read_file_lines now returns Ok with ZERO lines for a zero-byte file
(guarded) and the false `len>=1` ensures was replaced by
`requires: path.len() > 0` + doc (packages row 168, xiom.wal);
to_string_char rewritten over Str::from_utf8 (removes a per-call malloc
leak) with clauses `(c != '\0') => (result.len() >= 1)` and
`(c == '\0') => (result.len() == 0)` documenting the NUL truncation
(packages row 169, xiom.http). array_zip gained the M<=N direction clause
and array.fold the empty identity (zero-length `[0]T` by value, m238).
NEW FINDING: p_tostring_import_breaks_adapters.xi -- importing
xiom.convert.tostring corrupts closure predicate dispatch for
Range.filter/take_while (any alias; inline lambdas too; step_by
unaffected; no corpus smoke mixes them); the wave-98 probe is split
(p_wave98_shapes.xi + p_wave98_tostring_shapes.xi) as the workaround
(findings stay 14 Current: M7 moved to history, the new entry added).
Probes 272. Targeted smokes smoke_iter 21/21, smoke_io 20/20,
smoke_convert 38/38, smoke_array 17/17 (no smoke_fs family exists).
Coverage global 61.8% (pubCovered 4022, clauses 5309); floors135. Battery
on v0.64.2: corpus 954/954 (853.2s, no exclusions), probes 272/272
(262.3s), modules 509/509 (205.2s), barename 0/509 (285s), floors135 +
doc + module-smoke (497/517, 3476/6204) ratchets OK. Readiness next:
relay the tostring-import finding; resume coverage (os/hash/num/math/
crypto); queued feature candidates (Vec[UInt8].with_len, address-aware
bind, socket_recv_into).

Pin protocol agreed 2026-10-09 (relay `COMPILER-RELAY-2026-10-09-pin-protocol.md`,
block 86): stdlib tags a CANDIDATE `stdlib-vX.Y.Z` (no registry publish
yet) and relays tag + hash + wave report; the compiler lane verifies the
candidate against compiler main (vendored sync + STDLIB_VERSION + e2e
without XIOM_STDLIB + feature + checker corpus + the wave smokes) and
replies OK; only then does stdlib publish to the registry and the
compiler pins it at its next cut. Waves keep flowing on main throughout;
one-version steady state is expected; security-urgent publishes may skip
verification with an explicit note. Current cycle: the compiler lane will
verify stdlib-v0.64.3 (d052a3c5) during its v0.64.3 candidate gates.
Housekeeping in the same relay: the wave-97 sibling-alias split-probe
workaround was DROPPED -- p_wave97_bitwise_shapes.xi was merged back into
p_wave97_shapes.xi and re-run green on v0.64.2 (probe corpus stays 272).

Update 2026-10-10 (wave 101 landed): graph_theory + machine_learning --
121 clauses, +63 pub covered. graph_theory 32/32 (100%): the
empty-constructor field mirror, negative guards on the add/remove
surface, the remove_edge post-state has_edge mirror, degree/traversal/
shortest-path/spanning/SCC/ordering shape and presence claims, the
connected/cyclic/bipartite/isomorphic pins and the flow/cut/hamiltonian/
tsp identities. machine_learning 31/32 (96.9%; normalization_batch
stays the frozen nested-float stub): activation branch bands,
loss/metric mismatch-NaN guards, empty identities and [0,1] bands, the
auc NaN-or-band form, regularization zero pins, normalization/dropout
length guards, kernel/distance/similarity pins. TWO FIX-FIRSTS
(probe-caught pre-clause): graph_floyd_warshall pushed n zero rows
before the n distance rows (2n total -- the dead loop was dropped);
metric_auc built (score, label) pairs with inline vector element reads
inside the tuple literal, corrupting every Float64 score on v0.64.2 --
binding the elements first is the workaround, FILED as the new compiler
finding p_tuple_elem_vec_read.xi (findings 14 -> 15 Current). Probe
p_wave101_shapes.xi (274th, 145 checks) green pre/post on the official
v0.64.2 archive; targeted smokes smoke_math_finance 1/1, smoke_math
53/53; both modules --check clean. Coverage global 62.6% -> 63.6%
(clauses 5370 -> 5491, pubCovered 4075 -> 4138); math 42.0% -> 48.3%;
meter 76.4%; floors138. Battery on the official v0.64.2 archive binary:
corpus 954/954 (661.4s, no exclusions), probes 274/274 (258.7s),
modules 509/509 (173.4s), barename 0/509 (239.6s), floors138 + doc +
module-smoke (497/517, 3476/6204) ratchets OK. COMPILER-BINARY DRIFT:
the shared local build path `E:\xiom-lang\xiom\target\release\xiom.exe`
was rebuilt 2026-10-10 00:56 from compiler main (da7798da, m252 -- past
the v0.64.2 tag c51170a6) and fails four corpus smokes the pin passes
(smoke_cell_narrow rc 2, smoke_collections_btree_map rc 7,
smoke_rand_weighted rc 1, smoke_stress_regex_find AV); the official
archive binary `%TEMP%\kilo\stdlib_ws\v0.64.2\bin\xiom.exe` is the wave
pin and is 954/954. Readiness next: the remaining math remainder
(decompose/fuzzy/game_theory/chaos), os 26.6%, the queued feature
candidates and the runtime-C guards.

Update 2026-10-10 (wave 100 landed): finance + information theory -- 35
clauses, +29 pub covered. finance 20 (the r==0 closed forms pv/fv/pmt/
nper; NaN guards on mirr, pmt nper==0, ipmt/ppmt per<1, nper pmt==0,
rate<=0 perpetuity, cagr, sharpe/sortino/calmar, bond_price invalid face/
freq, VaR/CVaR bad alpha, beta/alpha length-or-sample guards, treynor
beta<=0; empty-series npv==0 and drawdown len 0; exact perpetuity pmt/
rate pin) -- finance contributes to math 39.1% -> 42.0% together with
information_theory 9 (entropy empty==0, perplexity empty==1,
data_compression_bound empty==0, huffman empty len 0, arithmetic_coding
empty seq==0.5, kl/js/cross length-mismatch NaN, self_information p<=0
-> +inf). Note: math/calculus.xi was inspected and SKIPPED -- the whole
vector-calculus/limit surface is a documented frozen stub set (BUG 20
AVX-512 / BUG 12 Vec[Float64] reads); no stub self-mirror clauses per
protocol. Probe p_wave100_shapes.xi (273rd, 41 checks) green pre/post;
targeted smokes smoke_math_finance 1/1 and smoke_math 53/53 (no
information-theory smoke exists; the probe is the lock). Global 62.2% ->
62.6% (clauses 5335 -> 5370, pubCovered 4046 -> 4075); meter 76.3%;
floors137. Battery on v0.64.2: corpus 954/954 (698.3s, no exclusions),
probes 273/273 (319s), modules 509/509 (213.1s), barename 0/509
(312.9s), floors137 + doc + module-smoke (497/517, 3476/6204) ratchets
OK. Readiness next: math remainder (graph_theory, machine_learning,
decompose, fuzzy, game_theory), os 26.6%, the queued feature candidates,
and the macOS runtime-C guards.

Update 2026-10-09 (wave 99 landed): crypto hash + xxhash/city + math
constants -- 26 clauses, +24 pub covered. crypto.hash 10 (exact digest/
hex sizes on sha256/sha512/md5 and the sha256/sha512/md5 HMAC variants;
pbkdf2 `iterations<1 || len<1 -> empty` and derived -> `len`, hkdf
`len<1 || len>255*32 -> empty` and derived -> `len`), crypto flat 3
(sha256 32, sha256_hex 64, blake3 32) -- crypto 39.9% -> 47.0%. hash 8
(xxh64/xxh32/xxh3_64 empty pins 0xEF46DB3751D8E999 / 0x02CC5D05 /
0x2D06800538D394C2, xxh3_64_with_seed(seed 0) and the xxh3_128 pair
low64 0x6001C324468D497F / high64 0x99AA06D3014798D8 -- the first probe
had the 128-bit pair swapped and was corrected from the measured
implementation, city64 empty 0x9AE16A3B2F90404F, city128 empty pair
length 2) -- hash 42.2% -> 51.1%. math.constants 3 (infinity > 1,
neg_infinity < -1, nan != nan) -- math 38.8% -> 39.1%. Probe
p_wave99_shapes.xi (272nd, 28 checks) green pre/post; targeted smokes
smoke_crypto 7/7, smoke_hash 25/25, smoke_math 53/53. Global 61.8% ->
62.2% (clauses 5309 -> 5335, pubCovered 4022 -> 4046); meter 76.2%;
floors136. Battery on v0.64.2: corpus 954/954 (794.6s, no exclusions),
probes 272/272 (285.6s), modules 509/509 (192.4s), barename 0/509
(257.5s), floors136 + doc + module-smoke (497/517, 3476/6204) ratchets
OK. Readiness next: os 26.6% and math remainder (finance/calculus/
graph_theory/machine_learning surfaces), the queued feature candidates
(Vec[UInt8].with_len, address-aware bind, socket_recv_into), and the
macOS runtime-C guards (PULSE).

Wishlist scoop 2026-10-09 (five lanes; full delta in
`docs/STDLIB-WISHLIST.md`): NEW fix-first defects -- `read_file_lines`
empty-file ensures (io.xi:1076, packages row 168, requester xiom.wal) and
`to_string_char(Char(0))` violating its own len>=1 ensures (packages row
169, xiom.http 0.1.4); NEW asks -- address-aware socket bind +
`socket_recv_into` (PULSE), `Vec[UInt8].with_len` (bindings W-5,
re-checked on 0.64.3), macOS runtime-C guards (`_SC_AVPHYS_PAGES`,
fp128 x86 asm). Status: packages `io.list_dir` RESOLVED (m211);
ORBITDB str_split/CRLF confirmed fixed (20k-record WAL replay 61.6 s ->
9.9 s) with the storage cluster still open; XVECTOR six rows open;
bindings 19-suite matrix green on v0.64.2; `xiom.wal` 0.1.0 gated on the
durable-write row.

Compiler relays consumed 2026-10-09 (block 83): v0.64.2 batch facts
(m222..m241; m237 array_zip, m238 `[0]T` by value, m239 deep container
equality, m240 verifier SMT, m241 OOB write trap; m242 sibling alias is
in the tag c51170a6 -> 516ea33b); compiler main has moved past the pin
(d9f146cb m244 null guards, not in v0.64.2). TWO actionable handoffs
accepted: (a) M7 `Iterator[T]` is STDLIB-SIDE per the compiler-lane
diagnosis -- declare the opaque handle or move the four adapters to the
closure shape (wave-98 first item; `--check` passes, `--run` C001); (b)
B-05 guard-heap spin is RUNTIME-SIDE in this repo (`runtime/xiom_runtime.c`
guard arena; repro under
`E:\xiom-packages\packages\docs\repro\bindings-pilot\alloc-guard-spin`) --
runtime-lane item after the release. Findings 14 Current (13 compiler,
1 stdlib); the two v0.64.2 clears (array_zip, sibling alias) are marked
RESOLVED in the known_failures README with the re-run evidence.

Release cut 2026-10-09 (stdlib-v0.64.3; pin v0.64.2; findings cleared;
heavy.yml repaired): `COMPILER_VERSION` -> v0.64.2 (tag c51170a6; binary
verified "XIOM Compiler v0.64.2"), `package.xi` -> 0.64.3,
release-notes/v0.64.3.md (2 schema-clean highlights) and the CHANGELOG
section. The known-failure sweep was re-run on the pin: array_zip
truncates in EVERY direction now (M<N, M==0 both sides, N<=M all
return min(N,M); the wave-96 repro exits 0) and triplicate sibling
submodule imports resolve again (m242; p_sibling_dup_fn_alias.xi exits 0;
the split wave-97 probes stay green and the single-file combination now
works too) -- findings 16 -> 14 (13 compiler, 1 stdlib). The M7
Iterator[T] receiver remains open (check passes, run C001). Also fixed
`heavy.yml`: the job matrix was nested OUTSIDE `strategy`, so every push
run since the matrix was introduced died in 0s with "workflow file
issue" (no heavy run has ever succeeded); the matrix now nests under
strategy and a manual dispatch (run 37962605725, in progress) actually
starts the ubuntu/windows/macos job matrix. Cloud runs for this cut:
release.yml 37962367989 (validate OK, Win/Linux gates running),
publish-registry.yml 37962367935 (waiting at the protected
`registry-publish` environment for the owner approval).
Battery on v0.64.2 (release commit): corpus 954/954 (2098.7s, no
exclusions), probes 270/270 (401.8s), modules 509/509 (221.3s), barename
0/509 (464.2s), floors134 + doc + module-smoke (497/517, 3477/6205)
ratchets OK. RELEASE: tag stdlib-v0.64.3 pushed -> release.yml
(validate -> Windows/Linux gates -> tarball + SHA256SUMS -> attested
GitHub Release -> STDLIB_VERSION pin PR) and publish-registry.yml
(waits for the same-tag asset, then the protected `registry-publish`
environment) both dispatched; the registry publish is PENDING OWNER
APPROVAL (approve ONE run). Release-note fragment merges into the next
combined compiler cut (compiler v0.64.3 bundles stdlib-v0.64.3).

Update 2026-10-09 (wave 97 landed): bits submodules + hash + fraction --
57 clauses, +40 pub covered. bits 22 (bitfield: width/offset no-op guards
on set/clear/insert, sign_extend width<=0 and >=64 identities, and the
`result >= 0` placeholders on get/mask/extract replaced with real
guard/edge pins; rotation: k==0/k==64 identities including the aliases
and masked mask==0; popcount: next/prev_pow2 boundaries and rotations;
bitwise: zero pins on bit_reverse/byte_swap, bit_reverse_byte(1)->128,
byte_swap(256)->1<<48, pow2 boundaries) -- bits 52.5% -> 74.3%. hash 8
(empty-input offset pins on fnv1a32/fnv1a64, crc32_ieee empty -> 0,
hash_bytes_to_hex empty, combine_hashes zero pin -> 0x9e3779b9,
string_hash/djb2 empty -> 5381, murmur3_32(empty, seed 0) -> 0,
xxhash64(empty, seed 0) -> 0xEF46DB3751D8E999) -- hash 33.3% -> 42.2%.
num.fraction 10 (from_float zero/NaN -> 0/1; add/sub/mul den>0 invariant;
sub equal operands -> num 0; mul a.num==0 -> num 0; div b.num==0 -> None;
reduce zero -> 0/1; to_float zero -> 0.0; to_str 0/1 pin; is_zero
branches; compare [-1,1] + zero/positive-sign pins) -- num 35.6% ->
37.6%. NEW FINDING (15 -> 16): p_sibling_dup_fn_alias.xi -- importing
three sibling submodules that export the same function name
(rotate_left/rotate_right in bits.rotation/popcount/bitwise) breaks
alias-qualified resolution; the wave-97 probe was split into
p_wave97_shapes.xi + p_wave97_bitwise_shapes.xi as the workaround. Probes
green on v0.64.1 pre/post (67 + 11 checks); targeted smokes smoke_hash
25/25, smoke_num_fraction 1/1, smoke_bit 3/3, smoke_num_rotate_bits 1/1.
Global 61.2% -> 61.8% (clauses 5245 -> 5302); meter 76.2%; floors134.
Battery on v0.64.1: corpus 954/954 (659.5s, no exclusions), probes
270/270 (248.6s), modules 509/509 (154.8s), barename 0/509 (232.9s),
floors134 + doc + module-smoke (497/517, 3477/6205) ratchets OK.
Readiness next: os 26.6% (runtime-backed surfaces inspected per item),
num 37.6% (convert/base/float/fraction remain), math 38.8%, crypto 39.9%,
hash 42.2% (city/metro/farm/xxh3/siphash empty pins), the remaining
bitarray/endianness surfaces, and the queued feature candidates (ORBITDB
append_line_sync pure half, bindings W-2/W-5). Release note: the next
stdlib cut picks up blocks 75/77/78/79/80/81.

Update 2026-10-09 (wave 96 landed): array + sort + bits -- 53 clauses, +40
pub covered. array 19 (the N==0 identities on len/is_empty/array_sum/
array_max/array_min/array_count/array_find/array_equal; fixed.xi
array_len/get/first/last, the array_slice empty and bounded-length
claims, the array_zip N<=M direction; dynamic.xi array_pop's None=>empty
post-form, array_resize post-length, array_concat length-sum,
array_search empty guard, array_is_empty branch pins) -- array 35.6% ->
77.8%. sort 5 (the len<=1 is_sorted identities on sort.xi and
sort.intro.xi, is_sorted_by variants and the nth_element bounds guard) --
sort 31.9% -> 42.6%. bits 16 (out-of-range no-op guards on
bit_set/clear/toggle, k==0 rotation identity, zero pins on bit_reverse/
byte_swap16/32/64, the len<=0 identity on get/set_bit_range, is_pow2
boundary pins, and the pack_u16/u32 little/big-endian bit-position pins)
-- bits 36.6% -> 52.5%. NEW FINDING (14 -> 15):
`p_array_zip_no_truncate.xi` -- array_zip does not truncate for M < N
(emits N pairs, reads b[M] out of bounds; the `if M < count` branch is
never taken), so the clause covers the N <= M direction only. Also
dropped array.fold from the wave: passing a zero-length `[0]Int` by value
miscompiles at clang ('[0 x i64]' vs 'i64'); the probe is p_wave96_shapes
.xi (268th, 87 checks) green on v0.64.1 pre/post; targeted smokes
smoke_array 17/17, smoke_sort 2/2, smoke_bit 3/3. Global 60.6% -> 61.2%
(clauses 5192 -> 5245); meter 76.1%; floors133. Battery on v0.64.1:
corpus 954/954 (709.6s, no exclusions), probes 268/268 (585.2s), modules
509/509 (225.8s), barename 0/509 (291.1s), floors133 + doc + module-smoke
(497/517, 3477/6205) ratchets OK. Readiness next: os 26.6% (runtime-backed
surfaces inspected per item), hash 33.3%, num 35.6%, math 38.8%, crypto
39.9%, the remaining bits submodules (bitarray/bitfield/rotation/popcount/
bitwise/endianness), and the queued feature candidates (ORBITDB
append_line_sync pure half, bindings W-2/W-5). Release note: the next
stdlib cut picks up blocks 75/77/78/79/80.

Update 2026-10-08 (wave 95 landed): format remainder -- 82 clauses, +68
pub covered. markup 13 (wrapper length claims: bold/italic/code/strike
len+2, link text+url+4; escape empty/expansion bands; parse empty-Ok and
unclosed-Err pins; empty render/strip identities; parse_inline empty).
textual 24 (box exact byte lengths 2w+1 plain / 6w+1 rounded-double for
empty content; border widths by style; separator widths incl. the 3-byte
double rule; header/title/section exact lengths; toc/toc_indent; list/
columns/wrap/justify empty identities). fmt 31 (Int/Float64/Bool/Str
to_str pins; format1/2/3 no-placeholder identity; table/columns/wrap/
indent/hexdump/join guards; pad-number + repeat width bands; float_fixed
pin; bool/line/align claims; the eight sprintf and three sscanf
empty-spec Ok pins plus the sscanf mismatch Err) -- format 59.3% ->
88.7%. Also the Formatter.write_str `ensures: true` placeholder replaced
with `result.is_ok`. Note: receiver `self == literal` comparisons are
rejected in catalog clauses (`Bool.to_str`/`Str.to_str` rewritten to
disjunction/length forms; a candidate finding, not filed). Probe
p_wave95_shapes.xi (267th, 92 checks) green on v0.64.1 pre/post; targeted
smokes smoke_format_markup 1/1, smoke_fmt 18/18,
smoke_string_printf_scanf_template 1/1 (no smoke exercises the textual
surface; the probe is the lock). Global 59.5% -> 60.6% (clauses 5110 ->
5192); meter 76.1%; floors132. Battery on v0.64.1: corpus 954/954
(769.6s, no exclusions), probes 267/267 (570.2s), modules 509/509
(379.3s), barename 0/509 (243.2s), floors132 + doc + module-smoke
(497/517, 3477/6205) ratchets OK. Readiness next: os 26.6% (runtime-backed
surfaces inspected per item), sort 31.9%, hash 33.3%, num 35.6%, array
35.6%, bits 36.6%, math 38.8%, crypto 39.9%, and the queued feature
candidates (ORBITDB append_line_sync pure half, bindings W-2/W-5).

Update 2026-10-08 (wave 94 landed): cmp + core + sync + terminal -- 86
clauses, +62 pub covered. cmp 16 (then_with self-mirror; min_by/max_by
value disjunctions; max_int/min_int ordering bands; max/min_float
disjunctions; clamp_float three-way branch; Reverse.new field mirror;
min3/max3/median3 disjunctions; is_between guarded results; compare_ints
-1/0/1 pins; min_of_vec/max_of_vec empty -> None) -- cmp now 100%.
core.xi 12 (to_string zero pin; the int/float/bool parser empty/valid
guards; min_of/max_of disjunction + ordering band; abs_int non-negative
mirror; clamp_int three-way branch; bool_to_int/int_to_bool branch pins;
int_to_char_safe bounds; result_unwrap_or Err -> default). sync 8
(sem_new field mirrors; sem_try_acquire/sem_acquire false -> count <= 0;
sem_release requires count <= max; sem_available mirror; barrier_new
requires n > 0 + count mirror; cdl_new mirror; cdl_is_zero pins).
format.terminal 29 (the 24 exact ANSI escape pins; progress_new clamp/
done/width mirrors; progress_finish; progress_percent total <= 0 -> 100;
spinner_new index/frames; spinner_frame mirror). THREE NEW FINDINGS filed
(12 -> 14): `p_mut_param_field_pre.xi` (`@pre` on `&mut` param scalar
fields aliases the post-mutation value -- the sync clauses were rewritten
to @pre-free forms), `p_generic_byref_option.xi` (`&Option[T]`/
`&Result[T, E]` standalone queries silently misread),
`p_slice_bound_generic_c001.xi` (bounded `&Slice[T]` calls fail C001; the
Slice helper set stays clause-free). Probe p_wave94_shapes.xi (266th, 113
checks) green on v0.64.1 pre/post; targeted smokes smoke_cmp 17/17,
smoke_sync 22/22, smoke_core 20/20, smoke_fmt 18/18,
smoke_format_terminal + smoke_format_ansi 1/1. sync 29.1% -> 35.9%, core
26.7% -> 45.8%, format 46.8% -> 59.3%, global 58.6% -> 59.5% (clauses
5024 -> 5110); meter 76.0%; floors131. Battery on v0.64.1: corpus 954/954
(703s, no exclusions), probes 266/266 (289.7s), modules 509/509 (197.6s),
barename 0/509 (299.7s), floors131 + doc + module-smoke (497/517,
3477/6205) ratchets OK. Readiness next: os 26.6% (runtime-backed surfaces
inspected per item), sort 31.9%, hash 33.3%, num/array/bits low dirs, the
format remainder (markup/textual/fmt), and the queued feature candidates
(ORBITDB append_line_sync pure half, bindings W-2/W-5).

Update 2026-10-08 (wave 93 landed): iter remainder + format text -- 55 pub /
71 clauses. iter.chain 14 (fold/fold_right empty -> init; reduce/sum/product/
any/all empty identities; nth OOB -> None; last/position/max/min empty ->
None; partition exact len-sum; group_by empty -> len 0), iter.fold 8
(find/find_map/contains/position_of empty identities; chunks/windows exact
count bounds; cmp [-1,1] + empty-side pins; eq len-mismatch/empty-equal
pins), iter adapters 14 new pub (RangeInclusive.next done-state pins;
Range/MapIter/FilterIter/EnumerateIter/ChainIter take/skip/enumerate field
mirrors; TakeIter.next remaining@pre guard; range_step ceil band; repeat_n
n band) plus the Range.next `ensures: true` placeholder replaced with
start/end@pre pins, format.text 18 (alignment delegation bounds; justify/
wrap/flow/paragraph/reflow/measure empty identities; indent no-op and len
bands; columns row counts; ellipsis branches; overline/underline/
strikethrough/quote exact lengths; blockquote bands). NEW FINDING filed:
`p_iter_iterator_type_unresolved.xi` -- the M7 `Iterator[T]` receiver type
does not exist (`unknown type 'Iterator' -- defaulting to i64` warnings on
every xiom.iter consumer; `r.step_by(2)` fails C001 unresolved
`Iterator.step_by`), so the four M7 adapters stay clause-free (findings
11 -> 12). Probe p_wave93_shapes.xi (265th, 139 checks) green on v0.64.1
pre/post; targeted smokes smoke_iter 21/21, smoke_fmt 18/18,
smoke_format_ 8/8, smoke_format_text + smoke_text2 1/1. iter 25.1% ->
45.4%, format 39.0% -> 46.8%, global 57.7% -> 58.6% (clauses 4953 ->
5024); meter 75.9%; floors130. Battery on v0.64.1: corpus 954/954 (606.2s,
no exclusions), probes 265/265 (316.7s), modules 509/509 (419.5s),
barename 0/509 (437.5s), floors130 + module-smoke (497/517, 3477/6205)
ratchets OK. Release side: nothing pending -- the next cut picks up the
block-75 post-tag fixes + this wave. Readiness next: async 4.5%
(runtime-backed), os 26.6%, core 26.7%, sync 29.1%, format remainder
(markup/terminal/fmt), and the queued feature candidates (ORBITDB
append_line_sync pure half, bindings W-2/W-5).

Update 2026-10-08 (wave 91 landed): bench + format (numbering/units) --
85 clauses / 38 new pub, plus a defect fix. bench 13 new (run_bench
iteration/name/total==mean/stddev pins; run_bench_n zero-iteration
all-zero branch; compare band; analytics zero branches and empty-result
zeros; human-ns pins; black-box identity; run_avg pins; report empty len
124); **defect fixed: bench_time_fn called `run_bench("", f)`, violating
run_bench's own `requires: name.len() > 0` at runtime -- now passes
"bench_time_fn" (found by the wave probe; bench_time_fn stays
clause-free)**. format.numbering 11 (word/milliard/ordinal/CJK/Indian/
money exact pins), format.units 16 (bytes/bits/percent/ratio/scientific/
engineering/SI/binary/temperature/currency/durations/hertz exact pins).
bench 18.8% -> 87.5%, format 27.3% -> 39.0%, global 56.9% -> 57.5%;
meter 75.8%; floors128. Probe p_wave91_shapes.xi (259th, 89 checks) green
on v0.64.0 pre/post; targeted smokes smoke_bench, smoke_format_numbering
and smoke_format_units 1/1. Readiness next: the remaining low dirs
(async 4.5% -- runtime-backed, iter 18.6% -- clause-side blocked, os
26.2%, core 26.7%, sync 29.1%, sort 31.9%, format remainder) and the
queued feature candidates (ORBITDB append_line_sync pure half, bindings
W-2/W-5).

Update 2026-10-08 (wave 90 landed): serialize batch 3 -- toml + yaml_lite,
23 clauses / 16 new pub. toml 11 (toml_parse empty -> Ok, "a = 1" -> Ok,
"[a" -> Err; toml_get + the six typed getters empty-table -> None;
toml_has empty -> false; toml_keys len mirror; toml_write empty -> "" +
result >= keys band), yaml_lite 5 (yaml_parse/yaml_parse_document empty
-> Err + "a: 1" -> Ok; yaml_emit_scalar empty -> `""` + >= len band;
yaml_emit_sequence empty -> "" + >= items band; yaml_emit_mapping any
empty side -> ""). Clause-free by design: yaml_stringify/yaml_get (enum
match). serialize 73.1% -> 90.3% (only clause-free-by-design surfaces
remain), global 56.7% -> 56.9%; meter 75.7%; floors127. Probe
p_wave90_shapes.xi (258th, 35 checks) green on v0.64.0 pre/post;
targeted smokes smoke_serialize (+csv/toml/toml_write) 1/1.
Readiness next: the remaining low dirs (async 4.5% -- runtime-backed, iter
18.6% -- clause-side blocked, bench 18.8%, os 26.2%, core 26.7%, format
27.3%, sync 29.1%, sort 31.9%), plus the queued feature candidates
(ORBITDB append_line_sync pure half; bindings W-2 out-param slots; W-5
Vec[UInt8].with_len).

Update 2026-10-08 (io fidelity defect fixed + ORBITDB/XVECTOR intake): the
ORBITDB relay's CRLF row is a real defect cluster -- `io.read_file_lines`
kept the trailing CR on CRLF files, and the CRLF files themselves came
from `io.write_file` / `io.append_file` / `io.write_file_bytes` opening
in TEXT mode (Windows `fwrite` silently turned every LF into CRLF; the
"bytes" writer was not byte-exact). Fixed: line reads strip one trailing
CR per line; all three writers open binary (`wb`/`ab`). Probe lock
`p_read_file_lines_crlf.xi` (18 checks: byte-exact write/append roundtrips
+ CRLF/LF line reads). ORBITDB + XVECTOR durability rows (fsync,
fd write path, append_file_bytes, truncate/ftruncate, tail check,
flush_stdout, f32 bitcast) are recorded in docs/STDLIB-WISHLIST.md with
the confirmed surface shape (complete the existing fd-level + path-level
stubs; no new names) and stay queued with the compiler runtime bundle.
Bindings-lane relay 2026-10-08 (W-1..W-5) recorded too: W-1 fixed
(`fs_remove` + `p_fs_remove.xi`), W-4 fixed (smoke_ffi2 note now records
the verified typed-call cast idiom), W-3 addressed stdlib-side (xiom.ffi
confinement caution; compiler finding B-05 owns the real fix), W-2
(out-param slots) and W-5 (Vec[UInt8].with_len) are scheduled
candidates.

Update 2026-10-08 (wave 89 landed): serialize + json modules -- 50
clauses / 36 new pub. serialize.xi 26 (format_error band + zero-error
exact pin; is_valid_json/is_valid_bytes empty -> false; json_string /
json_array / json_object empty pins + result >= len+2 / 2n / 4n bands;
json_number nan/zero pins; json_bool/json_null mirrors; json_parse empty
-> Err + "null" -> Ok replacing the `requires: data.len() >= 0` and twin
`ensures: true` placeholders; parse_json empty -> Err; JsonValue.index
negative -> None; little_endian/big_endian constants;
json_escape/unescape/minify/pretty empty identities and bands;
json_get_path empty-json -> None; json_type_of empty/object/bool pins;
varint_encode band + zero/300 pins; varint_decode(_at) pos-OOB -> Err;
varint_encoded_len pos-OOB -> 0; bytes_to_hex_str == 2n + empty;
hex_str_to_bytes empty -> Ok), serialize.json 12 (json_parse empty/null
pins; json_get_path empty path -> Some; constructor type pins via
json_type(result) on set/array_push/object_new/array_new/number/string/
bool/null; json_type >= 4 band; json_escape band). Two compiler findings
filed with minimal repros (p_alias_module_type_path, T001 on
`ser.SerializeError`; p_foreign_method_call, C001 on
`v.json_get_path(...)`; cross-ref C-PULSE-12) plus the PULSE 2026-10-08
relay recorded in docs/STDLIB-WISHLIST.md (write_all/server_parse_request
adopted; import-aliasing ask cross-filed; socket_set_timeout/flush_stdout
stay runtime-backed). serialize 34.4% -> 73.1%, global 56.1% -> 56.7%;
meter 75.7%; floors126. Probe p_wave89_shapes.xi (255th, 67 checks) green
on v0.64.0 pre/post; targeted smokes serialize/json/stress/fuzz/KAT 13
files 1/1. Readiness next: serialize batch 3 (toml 11, yaml_lite 7) then
the other low dirs (async 4.5% -- runtime-backed, iter clause-side
blocked, bench 18.8%, os 26.2%, core 26.7%).

Update 2026-10-08 (wave 88 landed): serialize batch 1 -- 37 clauses / 27
new pub. endian 16 (write_u16/u32/u64_le+be, write_i64_le and
write_f64_le claim appends via out.len() == out.len()@pre + 2/4/8; the
eight read_* carry the OOB identity guards pos < 0 || pos + N >
data.len() => result == 0 / 0.0), varint 9 (varint_encode/varint_size
1..10 bands + zero/300 pins; varint_decode empty -> Err; zigzag
encode/decode exact body mirrors; uvarint_encode band + zero pin;
uvarint_decode empty -> Err; varint_encode_slice empty -> empty and
result >= values; varint_decode_slice empty -> Ok), csv 4 (empty -> Ok
on parse/parse_with, empty -> "" on write_row/write; write_row >=
fields-1 and write >= 2 * rows length bands). The @pre append claims
held at runtime first pass (incl. the double-append case). serialize
5.4% -> 34.4%, global 55.7% -> 56.1%; meter 75.6%; floors125. Probe
p_wave88_shapes.xi (254th, 57 checks) green on v0.64.0 pre/post;
targeted smokes smoke_serialize (+toml), smoke_serialize_csv and
smoke_convert_endian 1/1 each. Readiness next: the serialize remainder
(serialize 31, json 15, toml 11, yaml_lite 7) then the other low dirs
(async 4.5% -- runtime-backed surfaces, check each; iter clause-side
blocked; bench 18.8%; os 26.2%; core 26.7%).

Update 2026-10-07 (wave 87 landed): convert tails -- 52 clauses / 33 new
pub. Root convert 6 (int_to_float/float_to_int/int_to_string zero pins,
fixed/sci string pins + the nan branch mirror, bool mirrors) plus the
int_to_char placeholder `ensures: true` replaced by the OOR-None /
65-some pins; cstring 2 (null-pointer identities; to_cstring/cstring_copy
stay clause-free, pointers); float 6 (nan/zero pins, empty -> Err parse
guard, fixed/sci pins, zero pins on the int<->float legs); json 5 (empty
identities, `""` quote pin, escape result >= input band); punycode/idna 8
(empty -> Ok identities on encode/decode/domains/idna and
idna_is_valid(empty) -> false); strftime 2 (empty/percent/ISO pins);
strptime 2 (empty -> false, <10 -> false, the full layout pin incl.
result.date fields); tryfrom 3 (NaN/2^63 Err guards, empty -> Err,
zero -> Ok). First-pass green at runtime (incl. the nested result.date
clause). convert 83.3% -> 94.1%, global 55.2% -> 55.7%; meter 75.6%;
floors124. Probe p_wave87_shapes.xi (253rd, 57 checks) green on v0.64.0
pre/post; targeted smokes convert float/json/punycode/strftime/try +
all_directions/identity/narrow 1/1 each. Readiness next: the low dirs
(async 4.5%, serialize 5.4%, iter 18.6% -- clause-side blocked -- bench
18.8%, os 26.2%, core 26.7%, format 27.3%); convert leftovers stay
clause-free by design (overflow compiler-blocked, toint char-casts,
pointer/generic surfaces).

Update 2026-10-07 (wave 86 landed): convert locals + shims -- 58 clauses
/ 39 new pub. date 5 (date_new field mirror; date_iso8601 10-byte band;
date_from_iso8601 layout guard + epoch some-pin; date_weekday [0,6] band
+ epoch == 4; date_day_of_year 1..366 band + 2026-08-12 == 224),
datetime 3 (datetime_new field mirrors; datetime_iso8601 >= 19 band +
epoch string pin; datetime_from_iso8601 layout guard), duration 6
(zero/negative normalization pins on seconds/millis/micros/nanos;
as_secs/as_ms accessor mirrors), time 3 (time_now [0,86399] band;
timestamp_to_date epoch/86400/-1 pins; date_to_timestamp epoch pin;
timestamp_now clause-free), wstring 2 (null-pointer identities; to_wstring
clause-free), from 3 / into 2 (zero pins + from_bool mirrors; from_char
and into_str clause-free), roundtrip 4 (empty/invalid/zero pins incl.
roundtrip_base invalid-base false and n == 0 true), uuid 4 (len 36/16
claims, layout guards), mac 4 (len 17 claims, layout guards), iri 3
(empty -> Err, non-empty -> Ok presences). Clauses held at runtime on the
first pass (field mirrors, band claims, presence implications). convert
70.5% -> 83.3%, global 54.6% -> 55.2%; meter 75.5%; floors123. Probe
p_wave86_shapes.xi (252nd, 72 checks) green on v0.64.0 pre/post; targeted
smokes smoke_convert_time, smoke_convert_traits, smoke_convert_checked,
smoke_convert_ip and smoke_convert_url 1/1 each. Readiness next: convert
tails (float/json/punycode/cstring, strftime/strptime, tryfrom/tostring/
bytes/validate) then the low dirs (async 4.5%, serialize 5.4%, iter 18.6%
-- clause-side blocked -- bench 18.8%, os 26.2%, core 26.7%).

Update 2026-10-07 (wave 85 landed): convert ip/lossy/network/timestamp
families -- 31 clauses / 20 new pub. ip 6 (is_valid_ipv4 < 7 / > 15 and
is_valid_ipv6 < 2 => false; empty-input None identities on
string_to_ipv4/ip_parse/ip_to_bytes; ipv4_to_string empty -> "" and the
4-octet 7..15 length band), lossy 4 (empty and sign-only zero pins;
NaN/2^63 clamp mirrors of lossy_from_float; zero pins on
lossy_to_float/lossy_char), network 6 (exact byte-swap mirrors, incl. the
64-bit closed form verified with the sign-bit case), timestamp 4
(epoch/86400/-1 pins on timestamp_to_date/timestamp_to_datetime and the
epoch-day band on timestamp_from_datetime; timestamp_now stays
clause-free, system clock). convert 63.9% -> 70.5%, global 54.3% ->
54.6%; meter 75.5%; floors122. Probe p_wave85_shapes.xi (251st, 63
checks) green on v0.64.0 pre/post; targeted smokes smoke_convert_ip,
smoke_convert_time and smoke_convert_checked 1/1 each. Readiness next:
convert remaining locals (date/datetime/duration/time, wstring/from/into/
roundtrip) then the low dirs (async 4.5%, serialize 5.4%, iter 18.6% --
clause-side blocked -- bench 18.8%, os 26.2%, core 26.7%, format 27.3%).

Update 2026-10-07 (wave 84 landed): convert uri/url/urn families --
8 clauses / 8 new pub (uri_parse, uri_normalize, url_parse, url_encode,
url_decode, urn_parse, urn_is_valid, urn_build). convert 61.3% -> 63.9%,
global 54.2% -> 54.3%; meter 75.4%; floors121. Clause forms: empty-input
Err identities, percent-encode >= n / <= 3n bands, the canonical
url_decode `result is Ok => result.len() <= s.len()` + empty-Ok mirrors,
urn_parse/urn_is_valid < 7 guards, urn_build exact length
(nid.len() + nss.len() + 5). Compiler relay: filed
p_ensures_isok_guard.xi (findings 10 -> 11). Probe p_wave84_shapes.xi
(250th, 16 checks) green on v0.64.0 pre/post; targeted smokes
smoke_convert_url + smoke_net_url 1/1 each. Readiness next: ip family +
lossy/network/timestamp in wave 85.

Update 2026-10-07 (wave 83 landed): convert codec tails + UU trim fix --
7 clauses / 7 new pub (uuencode, uudecode, uuencode_line, xxencode,
xxdecode, base58check_encode, base58check_decode). Fix-first
(probe-caught): `_trim` in xiom/convert/uuencode.xi stripped trailing
spaces, but UU trailing spaces are data (value 0 = ' '), so uudecode
rejected every line whose final group ended in zero bytes (e.g. any
1-byte payload: `uuencode([65])` = "!00  " -> Err "truncated line");
`_trim` now strips only CR/LF on the right. New smoke
tests/smoke/smoke_convert_uuencode.xi locks 1/3/45/100-byte and XX
roundtrips (corpus 953 -> 954). convert 59% -> 61.3%, global 54.1% ->
54.2%; meter 75.4%; floors120. Clause forms: empty-input identities
("" / Ok(empty) / length-1 line / base58check Err-on-empty; base58check
encode >= 1). Probe p_wave83_shapes.xi (249th, 15 checks) green on
v0.64.0 pre/post; targeted smokes uuencode + base58_62 1/1 each.
Readiness next: uri/url/urn/ip families + lossy/network/timestamp in
wave 84.

Update 2026-10-07 (wave 82 landed): convert codec guards --
11 clauses / 11 new pub (ascii85 4, quotedprintable 4, base58_decode,
base62_decode, uudecode_line). convert 55.4% -> 59%, global 53.9% ->
54.1%; meter 75.4%; floors119. Clause forms: empty-input identities
("" on the encode legs, Ok(empty) on the decode legs, Err on
uudecode_line). Push incident: three GitHub 500s 15:07-15:09Z logged in
docs/failed_attempts.md, resolved on the 4th attempt 15:22Z
(origin/main caught up). Probe p_wave82_shapes.xi (248th, 15 checks)
green on v0.64.0 pre/post; targeted smokes ascii85 + percent-ascii85 +
base58_62 1/1 each. Readiness next: remaining codec legs (uuencode 5,
base58check 2) plus uri/url/urn/ip families in wave 83.

Update 2026-10-07 (wave 81 landed): convert unicode family --
38 clauses / 26 new pub (utf8 4, utf16 4, utf32 4, utf 14). convert 46.9%
-> 55.4%, global 53.5% -> 53.9%; meter 75.4%; floors118. Clause forms:
empty-input identities (Vec/Str/units empty), BOM-only byte lengths
(UTF-16 -> 2, UTF-32 -> 4), even/quad byte-count parity, odd-length Err
guards on the LE/BE decoders, empty-Ok decode paths, utf8 encode 1..4
range, valid_sequences <= s.len(), is_valid empty -> true, surrogate
arithmetic claims (code_point_to_utf16: invalid => equal components,
valid => unequal; surrogate_pair_to_code_point: -1 or >= 0x10000).
Probe p_wave81_shapes.xi (247th, 36 checks) green on v0.64.0 pre/post;
targeted smokes smoke_convert_utf + utf8 encoder/decoder KATs 1/1 each.
Readiness next: convert local codec bodies (ascii85 4, uuencode 6,
quotedprintable 4, base58 byte/check legs 3, base62 byte leg 1) plus the
uri/url/urn/ip families, then lossy/network/timestamp.

Update 2026-10-07 (wave 80 landed): convert base-codec shims --
40 clauses / 25 new pub (base16 4, base32 4, base64url 4, percent 4,
base58 3: to_base58/from_base58/base58_encode, base62 3: to_base62/
from_base62/base62_encode, uuencode 1: uu_encoded_length, quotedprintable
2: qp_is_binary/qp_escape_byte). convert 38.7% -> 46.9%, global 53.1% ->
53.5%; meter 75.3%; floors117. Clause forms: canonical length identities
mirrored through the shims (hex 2n; base32 ((n+4)/5)*8; base64url
modulo-3 trio; percent bands), empty-string Ok/""/Err guards, base58
zero -> "1" and INT_MIN -> "-NQm6nKp8qFD" pins, base62 zero -> "0",
uu_encoded_length block math (% 61), QP helpers. Protocol finding:
`(result.is_ok == true) => result.len()` does not protect payload reads
at runtime; the canonical `result is Ok => result.len()` guard form is
required (6 clauses fixed). Split for wave 81: the local codec bodies
(ascii85 4, uuencode 6 remaining, quotedprintable 4, base58 byte/check
legs 3, base62 byte legs 1) plus the utf family. Probe p_wave80_shapes.xi
(246th, 45 checks) green on v0.64.0 pre/post; targeted smokes
base16/base32/base64/percent/base58_62 1/1 each.

Update 2026-10-07 (wave 79 landed): convert numeric shims --
57 clauses / 40 new pub (parse 5, int 8, toint 2, itos 3, atoi 3,
fromstr 3, ftos 3, tofloat 3, unchecked 5, saturating 5). convert 25.6%
-> 38.7%, global 52.5% -> 53.1%; meter 75.3%; floors116. Clause forms:
empty-string Err/None guards through the parse/delegate stack,
zero/negative formatting mirrors, invalid-radix empty/zero claims,
toint NaN/range clamps (f != f => 0; >= 2^63 => INT_MAX; checked is_none
guards + is_some range), itos width >= guard at n == 0, atoi C-style
zero-on-empty, ftos nan/inf/-inf branch mirrors plus len >= 1, unchecked
`b == 0/1` and `n == 0` identities, saturating b == 0/1, abs mirror and
pow e <= 0 / a == 1. Skips: to_int (undefined for NaN/out-of-range),
to_int_from_char (char-cast clause avoided), overflow.xi
(compiler-blocked tuple+Bool codegen, must not be called). Probe
p_wave79_shapes.xi (245th, 95 checks) green on v0.64.0 pre/post;
targeted smokes smoke_convert_int_str / float_str / bool_str 1/1 each.
Readiness next: convert remainder -- base-codec shims (base16/base32/
base58/base62/base64url/ascii85/uuencode/quotedprintable/percent,
43 pub), then the utf16/utf32/utf/lossy families.

Update 2026-10-07 (wave 78 landed): thread --
27 clauses / 24 new pub (thread 8, spawn 5, pool 8, park 1, local 5;
void/unclaimable surfaces skipped: scope, thread_yield,
thread_parallel_for, detach, sleep_ms, is_main_thread, tp_submit/join/
shutdown, park_token_wait, park, park_timeout, unpark, unpark_all,
tls_set/clear/key_get/key_set). thread 25% -> 67.9%, global 52.1% ->
52.5%; meter 75.2%; floors115. Fix-first (contract/doc consistency):
xiom.thread.sleep_ms documented "negative values return immediately"
while `requires: ms >= 0` aborts; doc corrected and `sleep` gained the
same delegation precondition. Clause forms: Thread.id field mirror and
Thread.name/thread_name_current is_none mirrors, spawn/spawn_with
`result.id > 0`, join/spawn_scoped `result.is_ok == true`, pool
new/submit_with/size/idle/busy cross-module field claims
(closed => false / !closed => true), thread_local_new/tls_get/
tls_replace/tls_take initialized-state claims, park_token_new non-null
flag, alias delegation ranges (hardware_threads/thread_count >= 1,
sleep/thread_sleep_us preconditions). Probe p_wave78_shapes.xi (244th,
39 checks) green on v0.64.0 pre/post; targeted smokes smoke_thread 1/1,
smoke_collect_threadpool 1/1. Readiness next: convert 25.6% (multiple
waves), then the remaining low dirs.

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
7. Compiler relay 2026-10-07 (dev builds m200-m203): four findings fixed --
   promote out of known_failures at the next pin: p_rvalue_float_vec_index
   (m200), p_multipart_parse_name (m201), p_geom_matrix_result_infer and
   p_polyhedra_nested_hull (m201). The iter clause-side closure leak is
   fixed on m203 (`ensures: result >= 0` on Range.count + smoke_iter
   verified OK/exit 0): at the next pin, re-add that clause and retry the
   deferred set (Range core 7 + chain 14 + fold 8 + iter_collect)
   probe-first. Relay to packages: grpc publish can proceed once the
   official pin carries m202 (their 36/36 x2 is on the candidate);
   graphql conformance is 10/10 with m206.

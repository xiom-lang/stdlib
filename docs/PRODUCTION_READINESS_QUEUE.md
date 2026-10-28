# Production-readiness remaining queue (handoff 2026-09-25)

**90% -- 9 of 10 gates complete; gate 9 discrete.** (Main pin:
**v0.64.8**; stdlib-v0.65.2 tag `7d4d48f`, GitHub Release live
(`xiom-std-0.65.2.tar.gz` + `SHA256SUMS`, run 40523878342); registry live
(xiom-std 0.65.2, sha256 `9638b576...`, compiler field v0.64.8, run
40523878370); staging canary green. Compiler v0.65.2 (tag `fe1994b1`)
pins stdlib-v0.65.2 but is **not accepted for durable/vector lanes**
(Struct{Vec} push regression fixed on compiler main `bb8eccf5a`, v0.65.3
awaits owner GO); PULSE is on v0.65.1. Main pin stays v0.64.8.)
**Gates: merged corpus 963/963 (0 compilefail / 0 runfail), modules
533/533, probes 417/417, barename 0/533, floors197. Wave pin: v0.64.8
(block 298).**

Readiness gates (the meter above counts these; each is backed by the battery
recorded in the updates below). Update the two lines above and this list as
gates flip:
1. Modules type-check clean -- MET (533/533).
2. Smoke corpus green -- MET: merged 963/963 on v0.64.8 (0/0),
   including the directory-rename regression; plus 963/963 on both
   Windows and Ubuntu release gates, no carve-outs.
3. Probe corpus green -- MET (417/417; the gate-9 set plus
   p_http_parse_alloc, p_wave298_sse_wire, p_wave298_h2_conn_mux and the
   earlier waves are included and individually green).
4. Strict bare-name scan clean -- MET (0/533).
5. Coverage ratchet green -- MET (floors197).
6. Documentation ratchet 100% -- MET.
7. Module-smoke ratchet green -- MET (499/542 modules, 3501/6575 fns).
8. Contract coverage 100% outside the documented no-clause tail -- MET
   (wave 208, 2026-10-25, refreshed 2026-10-28: every non-tail public fn
   carries a clause; non-tail 100%, global 95.9%, 6688/6973; clauses/fns
   97.9%, 9213 clauses; floors197). The remaining 285 public fns are the
   documented no-clause tail: iter 70.5%, os 71.5%, math 90.7%, thread
   91.1%, ffi 94.5%, serialize 94.7%, format 95.2% (no non-tautological
   clauses left; no clause waves in the tail).
9. Zero open findings (`tools/known_failures/README.md` Current section) --
   OPEN pending the compiler OK (gate 9 is discrete). Evidence on the
   official v0.65.2 windows-x64 archive (zip sha256 `0a328560...`, verified
   against SHA256SUMS `c08eeadf...`):
   - the 10-probe gate-9 set is **10/10 green** (52.7 s); 1609
     (`p_result_payload_index_concat`) is fixed (compile rc 0, run rc 0)
     and `p_iter_enumerate_tuple` is green;
   - a full sweep of all 27 `tools/known_failures` repros is 26 pass + 1
     intended negative (`p_vec_shape_arg_mismatch_av` correctly reports
     T001 at the call site), so no repro is red;
   - 1704's 10k target stays met (PULSE v0.65.2: JSON obj 2,006 B/iter)
     with the linear drop residual still compiler-side (m375);
   - 1955 (`server_parse_request` ~8 KB/req) is fixed on main `a696fb6`
     (857 B/iter Windows, 1,138 B/iter Linux/WSL) and awaits the next pin.
   Why it stays OPEN: the compiler-side JsonValue drop residual (1704) and
   the v0.65.2 durable-lane regression (Struct{Vec} push, fixed on compiler
   main `bb8eccf5a`, v0.65.3 awaiting owner GO) are still open findings; the
   gate flips when the compiler OK arrives and the next archive is swept.
   Historical: v0.65.1 was 9/10 (only 1609); v0.64.8 results are in the
   updates below.
10. Beta-exit release cut green (`docs/RELEASE_CHECKLIST.md`) -- MET
    (stdlib-v0.65.2 released 2026-10-27; tag object `e041aae` -> commit
    `7d4d48f`; release run 40523878342; assets + SHA256SUMS published;
    registry xiom-std 0.65.2 live via run 40523878370; compiler v0.65.2
    pins STDLIB_VERSION; tags frozen. stdlib-v0.65.1 `9dc69b3` and 0.65.0
    remain released/immutable.)

Meter formula: MET gates count 1.0; gate 9 gets no partial credit
(discrete). 9 / 10 = 90%. Gate 8 is MET via the non-tail 100% rule
above; the documented no-clause tail does not count against the meter.

Authoritative order: the gates above, then the updates below newest-first.

Current state 2026-10-28: **wave 298 + gate-9 evidence complete on v0.65.2.**
- stdlib-v0.65.2 released from `7d4d48f` (annotated tag `e041aae`);
  release run 40523878342 green (Ubuntu 24m13s, Windows 51m56s);
  registry xiom-std 0.65.2 live (sha256 `9638b576...`, compiler v0.64.8,
  run 40523878370); staging canary 40532608142 green; branch merged to
  main `--no-ff` at `6899cb5`.
- Compiler v0.65.2 (tag `fe1994b1`) pins stdlib-v0.65.2 and its 10-probe
  gate-9 set is 10/10 green (1609 fixed). It is NOT accepted for
  durable/vector lanes (Struct{Vec} push regression); the fix is on
  compiler main `bb8eccf5a`, v0.65.3 awaits owner GO. PULSE stays on
  v0.65.1.
- Full 27-repro `tools/known_failures` sweep on the official v0.65.2
  archive: 26 pass + 1 intended negative (T001 on
  `p_vec_shape_arg_mismatch_av`); no red repro.
- Wave 297 fixed `server_parse_request` allocation on main `a696fb6`
  (8,954 -> 857 B/iter Windows; 1,138 B/iter Linux/WSL; new
  `p_http_parse_alloc`). REL-20261027-1955-pulse-2 fixed; 1549-pulse-5
  fixed (1609 cleared).
- Wave 298 (`63ab0e1`) delivered the SSE server half (encode/write/
  comment/heartbeat over TcpStream) and the h2 connection multiplexer
  (H2Connection + h2_conn_*: concurrency cap, local ids, received/local
  GOAWAY drain); probes `p_wave298_sse_wire` + `p_wave298_h2_conn_mux`.
  **The h2 primitive layer is complete** (frame I/O stays with the
  caller). File-watch parity is already in (Windows ReadDirectoryChangesW,
  Linux inotify); only macOS/BSD kqueue remains a documented Err.
- Gates on the official v0.64.8 archive: modules 533/533, probes 417/417,
  smokes 963/963, barename 0/533, coverage floors197 OK (6688/6973,
  9213 clauses), doc 100% (7547/7547), module-smoke ratchet OK.
- Readiness stays 90% (gate 9 discrete). Remaining 2202 residuals: RFC
  7932 brotli / zstd, macOS/BSD kqueue, thread arg/closure channel
  (compiler). No tag; `COMPILER_VERSION` stays v0.64.8.

Current state 2026-10-26: **gate 9 is down to one red.** On the released
v0.65.0 Windows archive (sha256 `ff4abb4a...`), the gate-9 set is green
except 1609: 1626/2343/2100-W1/1456/1451/1326/2249/2249-2/1550 all rc 0
(`p_iter_enumerate_tuple` len=3, em[1].0=7; `p_nested_generic_ptr_read`
nested=42 local=42). 1609 (`p_result_payload_index_concat`) is still
rc 1. The stdlib rows in
`release-checks/compiler-compiler-v0.65.0.md` carry the verdicts; relay
2343/2100/1410/1414 are verified/closed, 1550 stays acked pending the
compiler's fixed move, 1609 is BOUNCED to acked. 1704 parse-side
retention remains m375. Linux leg pending. Readiness stays 90% (gate 9
discrete); gate 8 MET. **floors197** now locks the non-tail 100%
(Global 95.9) and is wired into the three workflows. Wishlist 2202 item
9: HPACK dynamic-table primitives landed (`H2HpackDynamicTable` +
new/len/size/add/get/set_max/clear; probe `p_wave283_hpack_dynamic`) and
the RFC 7541 Huffman codec landed (257-entry table, H=1 string
decode/encode; probe `p_wave285_hpack_huffman`), and HEADERS +
CONTINUATION reassembly landed (`H2HeaderBlock`; probe
`p_wave286_h2_cont`) and h2 SETTINGS/flow windows
(`p_wave290_h2_settings_flow`) and per-stream state transitions
(`p_wave291_h2_stream_state`) and connection-control payloads
(`p_wave292_h2_conn`), so the probe corpus is 413/413. **stdlib-v0.65.1
released** from `9dc69b3` (owns_return prep): release run 40375774931
green, GitHub Release live, compiler main pins stdlib-v0.65.1 (PR #8
closed as superseded); registry live (sha256
`3bb9b850...`, compiler v0.64.8); staging canary green. Compiler v0.65.1
is production and pins stdlib-v0.65.1; the full v0.65.1 compatibility
battery is green (modules 533/533, probes 413/413, smokes 963/963,
barename 0/533, floors197, doc 100%), gate-9 is 9/10 (only 1609), and
the 1704 memory matrix meets the 10k target (23.6 MB) with a linear
residual. Main `COMPILER_VERSION` stays v0.64.8; the next candidate is
the owner/compiler decision. Vec slot REL-20261026-2142 is fixed on
branch `feat/vec-elem-stride` (`863248f`); the compiler combined tree is
green; the next stdlib tag is pending owner GO. Gate-9 report
`REL-20261026-2247-stdlib` sent to compiler.

Current state 2026-10-25: **clause wave 208 closes gate 8 (non-tail).**
Every non-tail public fn now carries a clause (66 functions across 30
modules); the tail (iter/os/math/thread/ffi/serialize/format, 285 fns)
remains the documented no-clause tail. Global pub-with-clause is 95.9%
(6635/6920; 9149 clauses, 97.8% clauses/fns). Battery on the official
v0.64.8 archive: modules 533/533 (1579.6s), smokes 963/963 (the first
run caught one over-strong `test_register` @pre-on-global contract,
replaced with an explicit no-precondition clause; the rerun is clean),
probes 407/407 (681.4s), barename 0/533 (458.9s), floors197 OK, doc_scan
100%. Post-wave SHA/convert clauses: 2/2 modules, SHA smokes 11/11,
convert smokes 66/66, barename 0/533.
REL-20261020-1704 follow-up: the reference-taking entry points
(`json_stringify_ref`, `json_pretty_ref`, `json_type_ref`,
`json_get_ref`) landed; the render cores take `&JsonValue` and the
by-value names are thin wrappers. Probe `p_json_ref_api` locks byte
parity; PULSE should re-run its capped probe. Parse-side retention
remains compiler m375.
Readiness is 90% (9/10); gate 9 (zero open findings) is the remaining
gate and stays with the compiler-side findings
(1609/1626/2343/2100-W1/1704). Compiler pin stays v0.64.8; v0.65.0 is
released but not pinned per owner direction. The v0.65.0 Windows
archive re-check already passes `p_nested_generic_ptr_read`
(nested=42 local=42) and `p_iter_enumerate_tuple` (enumerate tuple ok);
the Linux leg is not yet re-run.

Current state 2026-10-20: **stdlib-v0.64.8 RELEASED and PUBLISHED; main
pin v0.64.8** (tag object `0bf5b75` -> commit `112c5b6` with tag-time
`COMPILER_VERSION=candidate-v0.64.8-r2`; compiler v0.64.8 tag
`4d040604b`; release run 39289746856; registry run 39298965606 green,
`xiom-std 0.64.8` sha256 `c4ab5c61...`). Assets:
`xiom-std-0.64.8.tar.gz` sha256 `6ea77968...`. Main carries waves
188-204: num/num.xi 100%, string 100%, collect 99.8%, time 96.4%,
async 92.5%, os 71.5%, thread 91.1%, compress 100%, math 87.7%,
bits 100%, iter 70.5%, core 99.2%, simd 97.8%, ffi 93.2%; collections/
array/cell and many smaller modules at 100%. Gates: modules 533/533,
smokes 963/963, probes 396/396, barename 0/533, floors196. Also fixed
this cycle: runtime `__udivti3`, `fraction_add`, `io.rename` directory
postcondition, Routh-Hurwitz, weekday convention, `AsyncExecutor.run`
receiver drain, Vec4f lane pointer arithmetic, the caller-buffer
`io.read_at_into` page reader, in-place JSON builders, and runtime-owned
`list_dir` names. New open items: 1704 JSON retention (partial builder
mitigation; compiler drop elaboration remains) and 0918 macOS list_dir
(fixed, witness pending). Gate 8 is 95.2%; readiness is 89.5%; gate 9
reds are 1626/2343/2100-W1 plus 1609. Historical state below is
retained.

Historical state (2026-10-11): compiler pin **v0.64.4** (released
2026-10-12, tag f76fd47c on df493530; the lane battery runs the official
windows-x64 release archive; COMPILER_VERSION = v0.64.4);
**stdlib-v0.64.4 CUT
2026-10-11** (tag object f8fb7a88 on 3df0843; package.xi 0.64.4; battery
+ witness green; the compiler pins STDLIB_VERSION and ships it);
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
for approval, package.xi now carries the registry metadata for the next
cut -- `categories: ["core", "systems", "data"]` + `stage: "stable"`
(registry vocabulary: max 3 categories; stages incubating|stable|
deprecated; xiom.std is exempt from display-stage overrides so the
manifest value governs; owner review welcome at the cut),
and the repaired heavy matrix passes ubuntu/windows but the macos-14
corpus leg is red (PULSE macOS runtime-C blockers suspected). Wave 98
landed post-tag (M7 closure rewrite; read_file_lines/to_string_char
contract fixes; new tostring-import finding); wave 99 added crypto hash
sizes, xxhash/city empty pins and math constants; wave 100 added the
finance/information-theory guard surfaces; wave 101 added graph_theory
(32/32) + machine_learning (31/32) and caught two fix-firsts
(floyd_warshall's 2n-row defect; metric_auc's corrupted tuple scores --
filed as the new compiler finding `p_tuple_elem_vec_read.xi`). The
2026-10-10 five-lane wishlist fetch added one row: XVECTOR's
`json_parse` recursion-depth cap (verified natively: depth 300+ dies,
0xC000001D; filed as finding #16, repro
`p_json_parse_depth_cap.xi`) -- first wave-102 item; the other four
lanes had no deltas. Wave 102 FIXED it stdlib-side (`_JSON_MAX_DEPTH =
128`; the repro was promoted to tools/probes, findings 16 -> 15 Current)
and covered the math remainder (decompose 100%, fuzzy 85.7%,
game_theory 46.2%, chaos 100%; 46 pub, 97 clauses) plus the W-5
`Vec[UInt8].with_len(n)` wishlist feature. Wave 103 fixed the relay
pulse-6 sleep bug and covered os batch 1 (fs/file/dir/platform/err/args;
42 pub, 46 clauses), adding the payload-index and path-println findings
   (16 Current). Wave 104 fixed the relay benchmark-2 Instant millisecond
   resolution and benchmark-3 buffered-stdin normalization (probe 278th;
   coverage flat, fix wave). Wave 105 fixed the signal_raise/raise_signal
   `raise_sig` link defect (libc raise + Windows guard) and covered the
   os batch 2 remainder (env/sysinfo/term/proc/signal + dir/fs/args/
   process/os tails; 64 clauses, +64 pub; probe 279th). Wave 106 covered
   the hash modules (probe-first catch: private-symbol collision filed as
   REL-20261011-1052-stdlib high, metro's consts renamed; builtin .hash()
   shadow filed as -1053-stdlib; 41 clauses, +39 pub; probe 280th). Wave
   107 covered crypto batch 1 (chacha/aead/curves/des/rng/sign/rsa; 41
   clauses, +41 pub; probe 281st) and fixed the RSA short-key OOB read in
   _rsa_parse_key. Wave 108 covered crypto batch 2 (cipher/crypto tail/
   ecc; 49 fns, +46 pub; probe 282nd) and fixed THREE defects the probe
   exposed: cipher.xi's _gf_mul11/_gf_mul13 swap (every cipher.xi decrypt
   path was wrong; encrypt was FIPS-correct; untested by any smoke), the
   argon2 iterations guard (tripped pbkdf2's requires), and the
   educational ed25519 short-key/signature OOB reads. Wave 109 covered
   the misc dir (misc.xi + semver.xi; 38 fns, +38 pub; probe 284th) and
   ran the compiler resolver/isolation coordination: reversed-order 1052
   lock added on main and the rename-reverted witness branch pushed.
   Math 53.0%, os 55.4%, hash 94.4%, crypto 94.5%, misc 98.7%, global
   68.5%, meter 76.9%; handoff in `docs/stdlib_session.md` snapshot 29
   (block 113 refresh; compiler v0.64.3 released pinning ab894b47;
   resolver/isolation batch in flight with the 1052 witness armed), wave
   records blocks 89-116. Wave 110 covered the sync dir (sync.xi tail +
   atomics/mutex/rwlock/barrier/channel/condvar tails; 70 fns, +70 pub;
   sync 35.9% -> 94.9%, global 69.5%, meter 77.0%; probe 285th) and filed
   the compiler Mutex builtin-shadow finding (REL-20261011-1456-stdlib).
   Sync clauses are runtime-checked; the parent Mutex.new/Mutex.lock
   surface stays clause-free, and cdl_count_down / channel try paths stay
   clause-free (documented reasons in block 115). Correction: the wave-110
   record's pubCovered/clause figures counted cdl_count_down's reverted
   @pre clauses; the landed pair is pubCovered 4454 -> 4523 and clauses
   5923 -> 6029. Wave 111 fixed the xvector json quadratic
   (REL-20261011-1453): the json parser scans cached raw bytes (one
   `s.len()`, pointer offsets) instead of `string.char_at`/`str_slice`
   (runtime strnlen per call), `slice.str_bytes` and `string.str_slice`
   copy bytes through cached (base, len) views, and the `\u` escape
   no longer swallows the byte after its 4 hex digits ("a\u0042c" now
   parses as "aBc"). Evidence: xvector's pinned probes exit 0
   (repro_json_quad 20000 numbers 498 ms vs ~18 s pre-fix, linear;
   repro_strbytes 400 KB 366 ms vs ~3.7 s, linear), probe 286th
   (p_json_parse_scale.xi) green pre/post, battery corpus 954/954 full
   (795.3s), probes 286/286 (291.6s), modules 509/509 (187.5s), barename
   0/509 (264.6s), all ratchets OK (no floors bump; no pub-coverage
   change). Also this round: REL-20261011-1442-compiler fixed at ad9169e,
   REL-20261011-1453-xvector landed (acked -> fixed), REL-20261011-1513-
   engine flake acked (save_write transient, tracking), and the new
   checker finding REL-20261011-1626-stdlib (trailing bare match after a
   Vec.push; findings 18 Current). Next candidate items: the cut
   mechanics (package.xi categories + stage, pin decision) and the
   compiler release-check verdicts. RC round 2026-10-11 (block 118): the
   OFFICIAL v0.64.3 windows-x64 archive was downloaded + digest-verified
   (sha256 5140b863...), all 27 known_failures repros were re-run on it,
   and the 15 stdlib rows of the compiler-v0.64.3 release check were
   filled (bus commit fdb9e4b). Headline: REL-20261010-1548-stdlib-5
   (generic by-ref Option/Result/Slice) is VERIFIED FIXED on v0.64.3 --
   `p_generic_byref_option.xi` and `p_slice_bound_generic_c001.xi` both
   3x rc 0 -- so findings drop to 17 Current (16 compiler, 1 stdlib) and
   the held-back Option/Result queries + Slice-param helpers can take
   clauses in the next coverage wave. All other open findings remain red
   on v0.64.3 (repro rcs in the check file); -1548-stdlib-2 awaits the
   next batch (m254). Wave 112 (block 119) covered the Option/Result
   standalone queries and the Slice-param helper set, unblocked by the
   v0.64.3 generic by-reference fix (16 fns, +24 clauses; core 45.8% ->
   58.0%, global 69.8%; probe 287th) with the battery green on v0.64.3:
   corpus 954/954 (673.6s), probes 287/287 (222.1s), modules 509/509,
   barename 0/509, floors148 + ratchets OK. Wave 113 (block 120) finished
   the str-family linearization: `str_chars`/`str_code_points` now decode
   over a cached (base, len) view with byte-exact semantics (masking
   decode for code points, leading-byte rule for malformed sequences),
   probe 288th; local 400 KB: chars 2472 -> 389 ms, code points 4221 ->
   370 ms (linear, under the 500 ms gate); battery: corpus 954/954
   (1377.6s), probes 288/288 (221.2s), modules 509/509 (250.3s),
   barename 0/509 (596.6s), ratchets OK. Next for the cut: the
   version/pin/CHANGELOG mechanics on the compiler's go (1731-compiler-2
   pin protocol) and the wave-106 revert at the v0.64.4 archive. Compiler
   pin decision (REL-20261011-1812-compiler, acked): HOLD the cut; after
   their doorbell push lands m263-m271, build the v0.64.4 dry-run archive
   via the XIOM Release workflow_dispatch, run the witness branch, land
   the metro revert, then tag. Follow-up wave after async: the string
    dir's remaining strnlen-family call sites (191 across 34 files:
    builder/case/casefold/collate/compare/unicode/normalize/... ) need the
    same cached (base, len) treatment; scoped per-file with smokes.
    WAVE 125 (block 150) converted batch 1 -- compare / trim / escape.xi
    (cached (base, len) byte loops; escape builders rewritten to Vecs
    after the old concat-per-byte loop allocated ~n^2/2 and died at
    512 KB). Remaining: string.xi first (~15 per-position xiom_char_at
    sites incl. the public str_escape/str_unescape, the json-escape
    path), then case/collate/indent/truncate/reverse/replace/segment/
    sentencebreak/unescape/unicode/wordbreak/shuffle + slice remnants
    (~34 .byte_at sites).
   CUT 2026-10-11: **stdlib-v0.64.4 tagged at 3df0843** (annotated tag
   f8fb7a88; package.xi 0.64.4 + registry metadata; COMPILER_VERSION ->
   v0.64.3; CHANGELOG [0.64.4]; release-notes/v0.64.4.md clean). Evidence:
   witness branch both import-order locks rc 0 on the v0.64.4 archive
   (metro revert landed 4e8b696); the compiler's m275 (4c42fc0a) fixed
   the one regression the battery found (cross-module fn-arg inttoptr);
   refreshed-archive battery FULL GREEN -- corpus 954/954 (552.1s),
   probes 288/288 (195.3s), modules 509/509, barename 0/509, floors148 +
   doc + module-smoke ratchets; release-gate set on v0.64.3 post-revert
   green. Bus: 1812 -> fixed (pin + ship requested); 2045 verified +
    closed. Next: the v0.64.4 release-check verify on our side at the
    compiler ship; registry publish per the candidate-tag protocol.
    RELEASED 2026-10-12: **compiler v0.64.4 shipped** (tag f76fd47c on
    df493530; run 38256358845 green, assets live) pinning stdlib-v0.64.4
    (3df0843). Release-check round (block 124): the OFFICIAL
    xiom-0.64.4-windows-x64 asset was downloaded to
    %TEMP%\kilo\stdlib_ws\v0.64.4-rel and all 27 known_failures repros
    were swept on it -- tuple elem read rc 0 (1548-stdlib-2 verified +
    closed; m254), 1052 + 1709 closed (witness green / pin consumed);
    the batch-targeted rows stay RED (table in REL-20261012-1342-stdlib)
    and the stdlib-6 payload-poisoning discriminator re-confirms red on
    v0.64.4 (REL-20261012-1852-stdlib); findings 16 Current (15 compiler
    + 1 stdlib). Findings plan (block 125): (1) pin bump to the v0.64.4
    release archive + battery + promote p_tuple_elem_vec_read.xi to
    tools/probes (289th lock), then (2) the compiler next-batch brief
    (T1 silent-wrong/trap rows, T2 compile-fail ergonomics, T3 guards),
    (3) stdlib-side polygon + the runtime/wishlist bundle, (4) the
    post-batch re-verify sweep cycle. Handoff in
    `docs/stdlib_session.md` snapshot 32 (block 143 refresh, head
    869ff72), wave
    records blocks 89-150. WAVE 114 step 0 (block 128): battery pin moved
    to the official v0.64.4 release archive
    (%TEMP%\kilo\stdlib_ws\v0.64.4-rel\bin\xiom.exe, sha256 DB8A2EF0...;
    COMPILER_VERSION -> v0.64.4): corpus 954/954 (589.5s), probes 289/289
    (277.7s; p_tuple_elem_vec_read.xi promoted, lock 289), modules
    509/509 (190.4s), barename 0/509 (322.3s), floors148 + doc +
    module-smoke ratchets OK. WAVE 114 part 1 (block 129): async coverage
    -- 29 clauses (channel 10, executor 4, timer 7, io 8; payload-free
    guards, no @pre on &mut fields; probe 290th p_wave114_shapes.xi green
    pre/post; smoke_async trio green); async 4.5% -> 47.8%, global 70.2%
    (pubCovered 4539 -> 4568, clauses 6056 -> 6102); floors149 wired
    (ci/heavy/release + tools/README + plan). Parent xiom.async surface
    stays for part 2. RELAY ROUND 2026-10-12 19:45-19:46Z (block 130):
    three new asks acked -- orbitdb durable-IO bundle (P1 fsync + P2 byte
    IO first), xvector mmap family, pulse wave-2 server primitives
    (deadlines first; websocket/chunked helpers stdlib-side; json_parse
    numeric already linear; gzip ships). All runtime-backed rows queue
    with the runtime bundle (effective at the next re-vendoring compiler
    pin, or XIOM_RUNTIME_DIR on v0.64.4). Bus commit 92b6941; two to-all
    notices read. WAVE 115 (block 131): the durability + byte-level IO
    first drop -- runtime fsync/fdatasync/_commit + sync_file +
    fflush_stdout + fsync_dir + open_append/open_read + read_at/write_at/
    append_bytes/truncate_path shims; fs_ffi.fsync/fdatasync, sync_io
    read_exact/write_all/sync_fd/fsync_dir/open_append/open_read/
    close_fd, io.flush_stdout/fsync(FILE*)/read_at/write_at/
    append_file_bytes/truncate_file real. Probe p_wave115_shapes.xi
    (291st) red pre / green post; smoke_os_sync + smoke_os_ffi rewritten
    to the new semantics; smoke_os* 8/8 + smoke_io* 20/20 green.
    Coverage: pubCovered 4568 -> 4580 / pubFns 6513 (global 70.3%);
    floors150 wired. Battery on v0.64.4-rel: corpus 954/954, probes
    291/291, modules 509/509, barename 0/509, ratchets OK. Landed rows
    move acked -> fixed on the bus with the re-vendor caveat; partials
    (fd ftruncate, remove_dir, locking, mmap, tail/append_line sugar)
    stay acked. OWNER DIRECTIVE (block 131): on the next compiler
    candidate/release, process the compiler's relay items (release checks
    + pin coordination), run the 27-repro re-verify sweep on the
    candidate archive (fixed -> verified -> closed), bump the pin per the
    candidate-tag protocol, fix the stdlib-side bugs it exposes, and keep
    the classic waves (coverage dirs, durability P3/P4/P5 remnants,
    string-dir follow-up) running in parallel. WAVE 116 (block 133):
    polygon_difference disjoint-case fix -- empty intersection returns
    Some(a) exactly (both orders); empty-a/b and a-inside-b stay exact;
    overlap stays documented-approximate (the full clipper with holes/
    slits remains a follow-up). Probe p_wave116_shapes.xi (292nd) red pre
    / green post; repro promoted to tools/probes (293rd); known_failures
    Current now 15, all compiler. Battery on v0.64.4-rel: corpus 954/954,
    probes 293/293, modules 509/509, barename 0/509, floors150 + ratchets
    OK. WAVE 117 (block 134): durability P5 pairs -- io.append_line_sync
    (torn-tail repair + fsync), io.file_last_byte / io.ends_with_newline,
    io.remove_dir, sync_io.truncate_fd + the xiom_remove_dir /
    xiom_ftruncate_fd runtime shims; probe p_wave117_shapes.xi (294th)
    red pre / green post; smoke_io* 20/20 + smoke_os* 8/8; coverage
    pubCovered 4585 / pubFns 6518 (70.3%), floors151 wired; battery on
    v0.64.4-rel: corpus 954/954, probes 294/294, modules 509/509,
    barename 0/509, ratchets OK. Orbitdb closed -3..-6 and pulse closed
    -5/-6 verified on the lane runtime (XIOM_RUNTIME_DIR, Win+WSL); the
    wave-117 landed rows move acked -> fixed next. WAVE 118 (block 135):
    P4 advisory locking real -- runtime xiom_flock_fd (POSIX
    fcntl F_SETLKW/F_SETLK; Windows LockFileEx) + xiom_funlock_fd;
    sync_io file_lock/file_unlock/file_try_lock live; probe
    p_wave118_shapes.xi (295th); smoke_os_sync remerged; floors152 wired
    (pubCovered 4588, clauses 6131, global 70.4%); battery on v0.64.4-rel
    corpus 954/954, probes 295/295, modules 509/509, barename 0/509.
    Platform lore: Windows LockFileEx blocking-reacquire hangs -- never
    re-lock a held range. Deferred: xvector-6 f32 bitcast (compiler
    Float32 batch). WAVE 119 (block 136): socket options + deadline
    receive -- runtime set_timeout/nonblocking/reuse_addr/shutdown, the
    Windows bind SO_REUSEADDR parity fix, socket.xi option wrappers +
    recv_timeout real; ROOT-CAUSE FIX: recv/recvfrom Int->Int32 return
    (a -1 read as 4294967295 caused an access violation on the
    nonblocking/timeout path -- unblocks both). Probe p_wave119_shapes.xi
    (296th); p_wave60_shapes remerged (requires-abort -> early-error
    returns); smoke_net* 11/11; floors153 wired (pubCovered 4589,
    clauses 6136); battery on v0.64.4-rel: corpus 954/954, probes
    296/296, modules 509/509, barename 0/509. Stale rows fixed: pulse-1134
    (fsync_dir), xvector-8 (flush_stdout). Watch: smoke_misc2 flaked once
    (rc 20; solo x2 green). DOORBELL 05:00Z (block 137): the consolidated
    orbitdb bundle (REL-20261012-1945) closed upstream after verifying
    P1-P5; no new asks; remaining non-terminals are compiler-blocked or
    queued (thread pool/2053, f32 Float32 batch, mmap, pulse wave-2
     remnants, engine-3 watch, C-PULSE-17 compiler payload-index family).
     WAVE 120 (block 142): the mmap family real (REL-20261012-1945-xvector-2
     P5) -- runtime xiom_mmap_file/mmap_anon/munmap/msync/madvise/mprotect/
     mlock/munlock/mem_write + xiom_open_rw (POSIX + Windows twins; msync
     flags transported 1=async/else sync for the macOS MS_* differences);
     mmap.xi 12 stubs -> 11 real (anon/file/writeable, unmap/sync/advise/
     protect/lock/unlock, pure-XIOM copy, memcpy write), resize stays a
     documented Err; fs_ffi mmap/munmap/msync/madvise/mlock/munlock real
     (payload-free Ok-side clause -- catalog struct payload reads false-fire
     on v0.64.4); sync_io.open_rw new. FIX-FIRST: the fd-open/read/write
     externs returned C int but were declared i64 -- open_read on a missing
     path returned Ok(4294967295-as-fd) and the downstream cast crashed
     0xC0000409; now Int32 + casts (wave-119 family completion). Probe
     p_wave120_shapes.xi (297th) red pre / green post; smoke_os_ffi remerged
     to the real semantics; targeted smokes os 8/8, io 20/20, ffi 2/2,
     net 11/11. Coverage pubCovered 4589 -> 4606 (clauses 6155, global
     70.6%; os 57.8% -> 62.2%), floors154 wired; battery on v0.64.4-rel:
     corpus 954/954 (617.1s), probes 297/297 (209.3s), modules 509/509
     (179.6s), barename 0/509 (249.7s), coverage + module-smoke (497/517,
     3481/6219) + doc ratchets OK. UCRT lore: _read/_write of a closed/
     out-of-range fd fast-fails the Windows process before returning a
     value (C-verified). Follow-up: async/io.xi + io/pipe.xi copies of the
     xiom_read/xiom_write Int returns need the Int32 treatment.
     WAVE 121 (block 145): websocket I/O fix + server-side helpers +
     chunked-transfer stream helpers (REL-20261012-1946-pulse stdlib-side
     rows). websocket.xi FIX-FIRST: ws_connect closed the socket before
     returning and read the handshake to EOF; ws_recv read every frame to
     EOF (both hang a persistent connection); now head-exact reads with a
     WsConnection.pending buffer, fd stays live, ws_recv is a bounded
     incremental reader (1 MiB cap) on the new pure ws_frame_take (+
     consumed count). New: ws_request_key, ws_handshake_response (101,
     129 bytes), ws_close_code, ws_frame_encode_fin; full-send loop
     ws_send_all fixes partial sends; ping/pong/close return Result;
     client I/O via xiom.net.socket (send shim got the wave-119 Int32
     fix). socket.xi: socket_send_all + socket_chunk_encode /
     socket_chunked_end / socket_stream_chunk / socket_stream_end
     (lowercase-hex; empty = no-op; head written by the caller). Probe
     p_wave121_shapes.xi (298th) red pre / green post (pure protocol
     pieces + loopback wire exchange, chunked bytes byte-exact);
     p_wave62_shapes remerged (pending field); smoke_net_url extended;
     smoke_net 11/11. Coverage pubCovered 4606 -> 4617 (clauses 6169,
     global 70.7%), floors155 wired; battery on v0.64.4-rel: corpus
     954/954 (578.1s), probes 298/298 (211.4s), modules 509/509 (188s),
     barename 0/509 (280.2s), coverage + module-smoke (497/517,
     3490/6230) + doc ratchets OK. Follow-ups: ws_random_key is
     time-seeded; socket create/accept/bind/listen POSIX -1 declarations
     audit.
     WAVE 122 (block 146): poll/select with timeout + SO_REUSEPORT
     (REL-20261012-1946-pulse asks 2 and 3). Runtime:
     xiom_socket_reuseport (POSIX setsockopt; Windows documented Err via
     the wrapper, no-equivalent story) and xiom_poll (poll()/WSAPoll; up
     to 1024 fds, in-place compaction to ready entries in input order;
     0 = immediate, > 0 = wait). ABI CATCH (fix-first): the shim first
     used C `long` (32-bit on Windows) -- the in-place Int array's
     elements were half-written, producing phantom readiness and a ready
     value of 0; fixed with `long long` everywhere in the shim (64-bit);
     lesson recorded: runtime shims must use long long for Int-sized
     values and Int arrays. Stdlib: socket_set_reuseport,
     socket_poll_read, socket_poll_write (shared poll_impl; empty = Ok
     empty; >1024 = Err; negative timeout = Err). Probe
     p_wave122_shapes.xi (299th) red pre / green post (POSIX double-bind
     of one port by two SO_REUSEPORT listeners; Windows documented Err;
     poll timeout-empty / pending-connection / idle-empty / write-ready /
     multi-fd order / post-send roundtrip / Err rows); smoke_net 11/11.
     Coverage pubCovered 4617 -> 4620 (clauses 6174, global 70.7%),
     floors156 wired; battery on v0.64.4-rel: corpus 954/954, probes
     299/299, modules 509/509, barename 0/509, ratchets OK. Remaining
     pulse wave-2 row: signal delivery (next); raw stream send covered
     by socket_send_all (wave 121).
     WAVE 123 (block 147): signal delivery -- the LAST stdlib-side
     wave-2 row. Runtime xiom_signal_install/installed/wait/raise (POSIX
     sigaction + self-pipe waker, coalesced last-wins via the wave-122
     poll; Windows SetConsoleCtrlHandler + auto-reset event, CTRL_C->2 /
     CTRL_BREAK->3 / close/logoff/shutdown->15, raise = latch+wake);
     stdlib xiom.os.signal: signal_install (idempotent), signal_wait
     (bounded; 0 timeout), signal_pending = wait(0), signal_raise real
     on both platforms and Err before install; signal_handle stays a
     documented Err pointing at the poll API. FIX-FIRST: signal_code's
     documented case-insensitive match actually compared exact-case;
     fixed. Probe p_wave123_shapes.xi (300th) red pre / green post;
     smoke_os_folder extended; smoke_os 8/8. Coverage pubCovered 4620 ->
     4622 (clauses 6177, global 70.7%), floors157 wired; battery on
     v0.64.4-rel: corpus 954/954 (479.5s), probes 300/300 (277.6s),
     modules 509/509 (179.8s), barename 0/509 (241.6s), module-smoke
     (498/517, 3496/6235) + doc ratchets OK. BUS: REL-20261012-1946-pulse
     acked -> fixed (all wave-2 rows delivered; pulse verifies next).
     WAVE 124 (block 149): directory watch + the guard-free runtime half.
     Watch (REL-20261012-2012-engine-3, Windows-first): new module
     xiom.os.watch (modlist 510) -- watch_dir (ReadDirectoryChangesW,
     recursive, 8 slots x 4 KiB) + watch_poll (record-per-call, 256/call
     cap, WATCH_OVERFLOW on coalesced loss) + watch_close; POSIX
     (inotify/kqueue) documented Err. Runtime xiom_watch_open/poll/close.
     smoke_os_watch added (corpus 955); probe p_wave124_shapes.xi (301st)
     red pre / green post (Windows create/modify/remove + recursive
     subdir; POSIX Err rows). GUARD-FREE (REL-20261013-1445 part 1, B-05
     runtime half): xiom_guard_free (arena-aware) -- surfaced by this
     wave's runtime rebuild: two guard-family probes had linked only via
     a stale cached runtime object; now green. Part 2 (ffi.free routing)
     landed in ffi.xi but the alloc-guard-spin still reproduces on
     v0.64.4: IR shows ffi.free call sites lowering to `call void @free`
     regardless of the wrapper (--force --no-cache; markers never fire) --
     compiler-side finding relayed; 1445 stays acked. 1423 (thread-spawn
     hoist) acked for the thread wave (needs m282 e2e). Battery on
     v0.64.4-rel: corpus 955/955 (544s), probes 301/301 (224.4s),
     modules 510/510 (224.5s), barename 0/510 (323.6s), floors158 +
     module-smoke (499/518) + doc ratchets OK.
     WAVE 125 (block 150): strnlen-family conversion batch 1 -- compare /
     trim / escape raw-byte loops over cached (base, len) views (the
     wave-111 idiom; per-call strnlen made them quadratic). escape.xi's
     _code_point_at reworked to (base, len, pos) with OOB reads as 0
     (byte-exact); str_escape_ascii/unicode rewritten as single-Vec
     builders after the old concat-per-byte loop allocated ~n^2/2 (the
     512 KB measurement scratch hit allocation failure at ~137 GB of
     leaked strings -- measured defect, fixed). Probe
     p_wave125_shapes.xi (302nd) byte-exact (multibyte folding,
     leading-zero order both ways, trim variants, \xNN/\uNNNN, U+1F600
     -> "\uf600", truncated c0); string smokes 56/56. Local perf (512 KB
     under engine-lane load, upper bounds): compare 1361 ms, natural
     1257 ms, trim 550 ms, escape 567 ms. Coverage fns 8737, clauses
     6184, floors159 wired; battery corpus 955/955 (851.9s), probes
     302/302 (328.7s), modules 510/510 (280.5s), barename 0/510
     (418.4s), ratchets OK. NEXT BATCH: string.xi first (public
     str_escape/str_unescape + ~15 char_at sites, the json-escape path),
     then case/collate/indent/truncate/reverse/replace/segment/
      sentencebreak/unescape/unicode/wordbreak/shuffle + slice remnants.
     WAVE 126 (block 152b): strnlen-family conversion batch 2 -- string.xi
     core (trim / words / char_count / title_case / swap_case / reverse /
     truncate_utf8 + the public str_escape / str_unescape, now single-Vec
     builders over cached (base, len) views via a byte-exact
     _char_at_runtime mirror of slice.xi) and the json escape family
     (convert/json escape+unescape, serialize's json_escape,
     serialize/json's _json_escape_impl, log/json's json_escape).
     str_reverse: the quadratic nested per-character boundary search
     became one boundary pass + reverse emit; a truncated trailing
     sequence whose decoded lead byte encodes longer than the bytes left
     emits its raw remaining bytes, so the len-preserving ensures holds on
     every input (the old walk could not terminate on those). One real
     defect fixed in _json_escape_impl: control bytes < 0x20 went through
     convert.int_to_string, so nibbles >= 10 emitted decimal text (0x0B ->
     "\u00011" -- malformed five-digit escapes); they now render lowercase
     hex (0x0B -> "\u000b"). Probe p_wave126_shapes.xi (303rd): 70 rows
     byte-exact on every converted path, red pre (run=65) / green post;
     string/json/serialize/log smoke families 152/152. Capped 512 KB
     re-measurement (REL-20261013-1638-stdlib; 1.5 GB working-set cap +
     60 s watchdog): rc=0, peak 5.5-27.5 MB across runs -- the wave-125
     allocation-exhaustion class is gone from the converted paths.
     Coverage fns 8742, clauses 6187, floors160 wired; battery corpus
     955/955 (560.9s), probes 303/303 (216.3s), modules 510/510 (165s),
     barename 0/510 (268.6s), coverage/module-smoke/doc ratchets OK.
     NEXT: batch 3 = case/collate/indent/truncate/replace/segment/
     sentencebreak/unescape/unicode/wordbreak/shuffle + slice remnants
     (~34 .byte_at sites); then the thread wave (1423 hoist) / queued
     options.
     WAVE 127 (block 154): strnlen-family conversion batch 3 -- the
     remaining per-position accessors converted to cached raw-pointer
     reads in 13 string-dir files (case / collate / indent / truncate /
     replace / reverse / segment / sentencebreak / unescape / shuffle /
     wordbreak / unicode) plus the string.xi bare-byte_at tail
     (str_compare / str_split / str_contains-starts-ends via _matches_at /
     str_upper / str_lower / str_translate / str_rot47 / str_caesar /
     str_atbash). Two family traps recorded: the earlier grep pattern
     missed BARE `byte_at(` calls (no qualifier), which is how string.xi's
     split/compare/transform hot paths stayed quadratic; and `s.c_str()`
     is a Ptr that supports neither arithmetic nor `as *UInt8` -- the
     idiomatic cached binding is `let base: *UInt8 = s.c_str();` inside
     the unsafe block (or passing c_str() to a *UInt8 parameter). The
     concat-per-item builders on those paths became single-Vec builders
     (case joins + sentence case, indent line builders, replace scans,
     shuffle joins, reverse spans, unescape Vec push, transforms).
     Probe p_wave127_shapes.xi (304th): 127 rows byte-exact on every
     converted path (multibyte/malformed/truncated rows included);
     string smokes 102/102 + shuffle 2/2. Measured (capped 1.5 GB + 280 s
     watchdog): out/dbg127r.xi runs 16 ops on 512 KB, rc=0, 157.1 s, peak
     4.2 MB -- the per-position rescans are gone; the residual cost is
     str_slice's per-call len rescan on per-char/per-part paths
     (clusters/shuffle/split lines), queued as a batch-4 core item.
     Coverage fns 8752, clauses 6205 (floors161 wired); battery corpus
     955/955 (496.7s), probes 304/304 (235.5s), modules 510/510 (209.8s),
     barename 0/510 (344.3s) + coverage/module-smoke/doc ratchets OK.
     NEXT: batch 4 = the remaining qualified `.byte_at` files (casefold /
     builder / combinatorics / block / compat / cosine / ea_width /
     editdistance / emoji / lcp / linebreak / normalize / permute / strip /
     template / interleave) + str_slice's per-call len; then the thread
     wave (1423 hoist) / queued options.
     WAVE 128 (block 155): strnlen-family conversion batch 4 -- the
     remaining qualified byte_at / char_at accessors in 14 files
     (casefold / ea_width / emoji / linebreak / normalize -- five
     decoder-block copies of the same _byte_at body -- plus block /
     compat / cosine / editdistance / lcp / permute / strip / template /
     interleave) now read through cached raw pointers, and the
     concat-per-item builders on those paths became single-Vec builders
     (permute pieces, strip scans, interleave merges). One REAL regression
     caught by the probe: raw Char-returning helpers must mask with
     `& 0xFF` before `as Char` -- `(*(base + i)) as Int` sign-extends
     (BUG 22 #10), which changed len_utf8-driven skip decisions (strip
     swallowed a space after a multibyte char; an old-vs-new inlined
     comparison isolated it, and the mask fixed it in all six
     Char-returning helpers, incl. the wave-127 case/replace/reverse/
     indent ones). Probe p_wave128_shapes.xi (305th): 49 rows byte-exact;
     string smokes 102/102; capped measurement (1.5 GB cap + 240 s
     watchdog): 13 ops on 512 KB + a 4 KB banded DP, rc=0, 18.8 s, peak
     4.9 MB. Coverage fns 8759, clauses 6220 (floors162 wired); battery
     corpus 955/955 (476s), probes 305/305 (197.4s), modules 510/510
     (166.4s), barename 0/510 (236.6s) + ratchets OK.
     NEXT: batch 5 = builder.xi's sb_push_str (the last qualified
     byte_at site in the string dir) + str_slice's per-call len (core;
     per-char/per-part paths pay O(k*n)) + the deferred builder pass
     (template escape/interpolate, combinatorics joins); then the thread
     wave (1423 hoist) / queued options.
     WAVE 129 (block 156): the str_slice fast path (core) -- str_slice
     itself keeps its exact len-clamp semantics (OOB / negative / empty
     rows unchanged), while the hot per-part / per-character call sites
     now use a bounds-guaranteed _slice_fast (raw copy over a cached
     pointer, no str_len rescan): str_split, words, case _split_words,
     segment _split_chars, shuffle _sh_split, sentencebreak/wordbreak
     splits, unicode unicode_combining_sequence, combinatorics
     splits/chunks/windows/reverse-words/joins -- and that commit also
     carries the MISSED wave-128 combinatorics _byte body conversion
     (its scans were still quadratic; the wave-128 edit failure exposed
     it) plus builder.xi's sb_push_str (the last qualified byte_at site
     in the string dir). Evidence: out/dbg127r.xi re-run drops from
     157.1 s to 19.4 s (8.1x) with identical outputs and a 4.9 MB peak.
     Probe p_wave129_shapes.xi (306th): 33 rows (str_slice
     OOB/negative/empty clamps + all touched publics + builder); probes
     127/128 re-run green; string smokes 102/102. Coverage fns 8768,
     clauses 6230 (floors163 wired); battery corpus 955/955 (551.8s),
     probes 306/306 (225.8s), modules 510/510 (271.2s), barename 0/510
     (262.8s) + ratchets OK.
     NEXT: the deferred builder pass (template escape/interpolate,
     combinatorics combination/interleaving joins, normalize tails) +
     str_slice's own per-call str_len for one-shot callers; then the
     thread wave (1423 hoist) / queued options.
     WAVE 130 (block 157): the builder pass -- the last concat-per-item
     leak-class builders in the string dir converted to single-Vec
     builders with cached raw reads: wrap (str_wrap / str_wrap_soft /
     str_wrap_hard + _slice_fast / str_wrap_join), combine
     (str_combinations / str_combination_at), align (str_align_justify),
     permute (str_permutation_at), template (_render / template_escape /
     template_unescape), combinatorics (str_rotate_word / str_interleave
     / str_chunk_bytes / str_unique_chars). Announcement per the 1545
     protocol (REL-20261013-1903-stdlib); capped measurement (1.5 GB +
     240 s watchdog): out/dbg130r.xi, 17 ops on 512 KB, rc=0, 14.9 s,
     peak 4.9 MB. Probe p_wave130_shapes.xi (307th): 26 rows;
     string/template/align/wrap/combine smokes 113/113. Coverage fns
     8776, clauses 6234 (floors164 wired); battery corpus 955/955
     (507.4s), probes 307/307 (197.5s), modules 510/510 (176.4s),
     barename 0/510 (248.3s) + ratchets OK. The wave-125..130 arc has
     now removed the whole observed strnlen / concat-per-item class from
     the string dir; str_slice's own per-call str_len remains for
     one-shot callers only (documented).
     NEXT: the thread wave (1423 hoist + pool/spawn flip); then
     playground-4 / website-2 / engine-6 as queued.
     WAVE 131 (block 158): REL-20261013-1423 hoist -- xiom.thread.spawn's
     result buffer (bufsize + alloc.alloc) moved OUT of the confined
     block, so it is main-heap memory; the guard arena no longer frees it
     at block exit while the spawned thread still writes its result (the
     compiler's proposed fix, acked at 15:00Z; the join/detach deallocs
     are unchanged and now pair with the main-heap alloc). The raw-fn
     handover in the same function still requires compiler m282: the
     spawn[T] e2e (return 42) HANGS on the v0.64.4 pin (out/dbg131s.xi
     prints "spawned" then join never returns; killed by a 20 s
     watchdog), so the probe locks the spawn-independent thread surfaces
     only and the hoist is compile-locked by check_modules. Probe
     p_wave131_shapes.xi (308th): 6 rows; thread smokes 2/2. Coverage
     fns 8776, clauses 6234 (floors165 wired); battery corpus 955/955
     (694.3s), probes 308/308 (353.9s), modules 510/510 (204.1s),
     barename 0/510 (293.2s) + ratchets OK.
     NEXT: on the next compiler pin (m282) flip spawn[T] to the real
     path + the sequential-simulation notes (thread_parallel_for, pool),
     re-run the spawn e2e; then playground-4 / website-2 / engine-6 as
     queued.
     WAVE 132 (block 160): the queued relay asks plus an independent
     audit fix wave. (a) playground-4: io.stdin()/read_line/read_int doc
     callouts (the fd-0 "reads like cin" trap); (b) website-2: confirmed
     already wired -- the publish workflow reads COMPILER_VERSION at the
     tag and passes --compiler to `xiom pkg publish` (9b2d2a2); (c)
     website: docs/ACCELERATED.md per-symbol marker inventory + probe
     132 same-build differential (sha256 vs sha256_accelerated, FIPS
     "abc" vector, ct-compare dispatch, AES-128 FIPS C.1 first-block KAT
     + roundtrip, dispatch-backed str_concat). (d) A read-only audit
     subagent (waves 127-131) found and this wave FIXED two REAL issues:
     str_unescape_ascii dropped the rest of the string after a \x00
     escape (the Vec builder pushed a NUL, which from_utf8 truncates at;
     the old _byte_str(0) skipped it and continued -- restored byte-
     exact, probe rows 15/16), and an orphaned `return true; }` left by
     the wave-127 _matches_at edit (parser-recovered today, latent
     break; removed). Hardening from the same audit: pos >= 0 guards in
     _pm_piece/_piece_from_idx, masked _json_char's Char cast, removed
     the dead _mk_byte. Probe p_wave132_shapes.xi (309th): 16 rows;
     probes 127/128 re-run green; string smokes 102/102. Coverage fns
     8775 (-1 dead helper), clauses 6234 (floors166 wired); battery
     corpus 955/955 (1677.7s under the compiler lanes' worktree sweep),
     probes 309/309 (298.4s), modules 510/510 (342.7s), barename 0/510
     (506.9s) + module-smoke/doc ratchets OK.
     NEXT: the tree-wide quadratic-sweep inventory (independent agent;
     it lists the remaining conversion campaign by module tree, HOT
     clusters: core.to_int_from_str, io pipe/buffer writers, hash
     hashers, encoding codecs, convert escape/validate, serialize
     parsers, net http/ws, format fmt). Wave 133 starts the highest-
     value batch (candidate: core + io + hash) unless a relay item wins.
     WAVE 133 (block 162): the sweep-campaign opener (core + io + hash).
     Converted: core.to_int_from_str / to_float_from_str (cached len +
     masked-raw Char reads; the parser decisions are ASCII-only, so
     byte-exact), hash.DefaultHasher.write_str / djb2 / sdbm (the
     runtime-mirror decode -- the hashers feed the DECODED value into
     their state at every byte position, so hash values stay identical)
     / fnv1_32 / adler32_str, io.parse_int / parse_float / parent_path /
     file_name / extension, io.pipe_write_line, io.buffer.bw_write_str.
     Probe p_wave133_shapes.xi (310th): 46 rows (parser KATs + error
     rows, adler32 "Wikipedia" KAT, write_str == djb2 equality,
     path-helper rows, buffered-writer byte copy); core/hash/io/buffer/
     pipe smokes 200/200. Capped measurement: out/dbg133r.xi, 512 KB
     digits through both parsers + all hashers + a long-path parent
     scan, rc=0, 5.0 s, peak 4.7 MB (each op was quadratic before).
     Coverage fns 8782, clauses 6240 (floors167 wired); battery corpus
     955/955 (1305.1s), probes 310/310 (693.1s), modules 510/510
     (466.9s), barename 0/510 (519.7s) + ratchets OK.
     NEXT: the next sweep batch -- encoding codecs (base64/hex/percent/
     idna) or convert escape/validate/json; the spawn flip + engine
     S-section rows stay pin/relay-gated.
     WAVE 134 (block 163): the escape family (convert/escape.xi) -- all
     16 scanners (html/xml/csv/tsv/regex/glob/shell/cmd escape+unescape)
     plus the entity decoder and the private scanners now read through
     cached pointers and build through single Vec[UInt8] builders (the
     1-byte-slice + concat-per-char loops were both quadratic). Probe
     p_wave134_shapes.xi (311th): 33 rows (entity KATs incl. numeric,
     unknown-entity and no-semicolon fallbacks, CSV quoting/doubling,
     TSV/glob/shell/cmd rows, multibyte passthrough); escape/convert/csv
     smoke filters 71/71. Capped measurement: out/dbg134r.xi, 512 KB
     special-heavy input through every scanner + roundtrips, rc=0,
     10.5 s, peak 4.9 MB. Wave also re-merges p_wave113's timing gate to
     best-of-3 (a load flake in the first probes leg; a true quadratic
     regression still trips the 500 ms gate). Coverage fns 8785, clauses
     6242 (floors168 wired); battery corpus 955/955 (1174s), probes
     311/311 (474.2s), modules 510/510 (502.1s), barename 0/510
     (611.7s) + ratchets OK.
     NEXT: FIX-FIRST -- REL-20261014-1208-bindings (B-27 ffi.write_u32/
     u64_at dropped offset; B-28 Vec.reserve cap==0 ordering -> with_len
     heap overflow, ASan-proven) is claimed and is wave 135; then the
     encoding sweep batch; the spawn flip + engine S-rows stay
     pin/relay-gated.
     WAVE 135 (block 165): FIX-FIRST REL-20261014-1208-bindings. B-27:
     ffi.write_u32_at / write_u64_at dropped their byte offset (`let p:
     *UInt8 = dest as *UInt8`, no +offset); both now bind `(dest as
     *UInt8) + offset` like the (already correct) write_f32_at. B-28:
     Vec.reserve seeded the 0->4 minimum AFTER the doubling loop; the
     seed (`if new_cap < 4 { new_cap = 4; }`) now runs BEFORE it, so
     with_len(n) holds n*8 bytes. The two fixes are the lane actor's
     working-tree edits, verified here: out/scratch_b27f.xi via Vec-index
     readback shows u32@16 -> 44 33 22 11, u32@20 -> 88..55, u64@24
     low/high bytes, "Z"@40; the reassembled probe p_b2728_shapes.xi
     (312th) passes. ROOT-CAUSE NOTE: the v0.64.4 archive BUNDLES a
     stale stdlib snapshot (lib/xiom) whose ffi lacks +offset and whose
     reserve seeds after the loop -- so the reported defects were real
     against the bundle; consumers must build with XIOM_STDLIB pointed at
     stdlib main or wait for the next pin that bundles this tree, then
     the bindings workarounds can retire. The probe's guard-free
     alloc/free row was REMOVED: on the pin ffi.free lowers to plain
     @free (1445) and freeing guard-arena memory SPINS (confirmed by a
     hung out/scratch_guard.xi run) -- that lock belongs to the
     compiler-side acceptance on the next pin; a hanging row must never
     ship in a probe. Coverage fns 8785, clauses 6242 (floors169 wired);
     battery corpus 955/955 (828.6s; a first pass flaked three files with
     clang exit -1/empty stderr under load -- all pass alone and in the
     re-run), probes 312/312 (383.9s), modules 510/510 (195.4s),
     barename 0/510 (281.8s) + ratchets OK.
     NEXT: re-probe B-27/B-28 at the next pin (bindings); then the
     encoding sweep batch; the spawn flip + engine S-rows stay
     pin/relay-gated.
     WAVE 136 (block 166): the encoding core (encoding.xi) -- base64 /
     base64url / hex / base32 decoders, url_encode / url_decode, the
     percent delegates, utf8_encode, hex_to_int and base64_encode_str
     now decode through the cached runtime-mirror `_char_at_runtime`
     (xiom_char_at strnlens per call, so the per-position codec loops
     were quadratic). One trap found live: an INLINE
     `unsafe { *(base + pos) }` EXPRESSION used as a VALUE misbehaved
     (the decoder acted on the raw lead byte for multibyte input);
     rewriting the helper around a function-shaped `_raw_byte(base, i)`
     fixed it -- use the function form, never a value-position unsafe
     block. Probe p_wave136_shapes.xi (313th): 36 rows (round-trips,
     padding variants, invalid-character errors, multibyte percent rows,
     the RFC 4648 base32 vector, the base64_encode_str low-byte-cast
     quirk); encoding/base64/base32/hex/percent/url/utf8 smoke filters
     41/41. Capped measurement: out/dbg136r.xi, 512 KB through both
     directions of url/base64/hex/base32 + the wrappers, rc=0, peak
     4.9 MB, every round-trip byte-exact. Coverage fns 8787, clauses
     6243 (floors170 wired); battery corpus 955/955 (1001s), probes
     313/313 (299.9s), modules 510/510 (244.2s), barename 0/510 (534s)
     + ratchets OK.
     NEXT: wave 137 = FIX-FIRST REL-20261014-1427-engine (binary-safe
     copy_file / byte-exact file IO roundtrip); then the encoding
     submodules (base64/base32/hex/percent/punycode/idna/ascii85) batch.
     WAVE 137 (block 167): FIX-FIRST REL-20261014-1427-engine --
     copy_file now goes through read_file_bytes / write_file_bytes
     (byte-exact, length-carrying) instead of read_file/write_file (Str
     is NUL-terminated by design, so a binary source truncated at the
     first NUL: a PE DLL became 3 bytes MZ\x90). Probe
     p_wave137_shapes.xi (314th): 24 rows -- the NUL/0xFF byte roundtrip,
     the PE-magic copy_file byte-equality + size, append parity at the
     byte level, the unchanged text path, and fixture cleanup;
     file/copy/binary smoke filters 20/20. Coverage fns 8787, clauses
     6243 (floors171 wired -- counts unchanged, the rewrite swapped
     calls only); battery corpus 955/955 (617.7s), probes 314/314
     (367.9s), modules 510/510 (267.3s), barename 0/510 (392.3s) +
     ratchets OK. The engine's PowerShell Copy-Item workaround can
     retire on the next archive (or now against stdlib main via
     XIOM_STDLIB); verify the NUL roundtrip + PE-magic copy at the
     candidate.
     NEXT: the encoding submodules (base64/base32/hex/percent/punycode/
     idna/ascii85) sweep batch; the candidate-queue engine/bindings rows
     as the archive lands.
     WAVE 138 (block 169): the encoding submodules converted (the sweep
     campaign) -- every per-position string.byte_at / s.char_at loop in
     base64/base32/hex/percent/punycode/idna/ascii85 now reads through
     per-module copies of the wave-136 function-shaped helpers (raw byte
     + runtime-mirror decode) over a cached (base, len) view; the idna
     _byte/_decode_cp/_char_len chain threads the cached base. 15 new
     private helpers (per-module prefixes). FINDING (live, from the
     capped scratch): the ascii85 encoder delegate
     xiom.convert.ascii85.to_ascii85 grew its result with str_concat PER
     GROUP -- quadratic time and leaked intermediate strings; the first
     512 KB scratch run hit the 1.5 GB memcap at 10.8 s (peak 1567 MB)
     inside a85_enc, and the builder rewrite (+ from_ascii85 cached
     reads) turned it into rc=0, 14.6 s, 48.5 MB peak, all 21 rows
     byte-exact. Probe p_wave138_shapes.xi (315th): 132 rows green pre
     and post (RFC base64/base32 vectors, padding + Err rows, multibyte
     encode_str rows, punycode/idna domain + uts46 + bidi rows, ascii85
     delimiters); encoding smoke filters 16/16 + convert-family 60/60;
     residue grep clean (no per-position accessors in xiom/encoding).
     Coverage fns 8802, clauses 6252 (floors172 wired); battery corpus
     955/955 (806.6s), probes 315/315 (310.2s), modules 510/510
     (232.7s), barename 0/510 (501.8s) + module-smoke/doc ratchets OK.
     NEXT: the rest of the ranked sweep inventory (convert/validate +
     convert/json; serialize toml/csv/json string-val; net http/ws/dns;
     format fmt/numbering; text similarity/diff; misc/regex/search/
     collect; num parse/itoa; log; crypto rng/curves; os path/fs;
     error/debug/test builders); the candidate queue jumps the moment
     the next archive lands (m312/m313 still gate the spawn flip + the
     guard-spin acceptance).
     WAVE 139 (block 170d): FIX-FIRST the v0.64.5 release gate
     REL-20261013-1423 -- the RUNTIME half (the 17:00Z doorbell item).
     xiom_task_trampoline stored the i64 result as C long (sizeof(long)
     == 4 on Windows), so only the low half landed at result_buf + 8 and
     JoinHandle.join readbacks were garbage (low32 == the worker value;
     compiler m312 bc1d821b had landed the read-path half). The payload
     fn type, the result local and BOTH stores in the trampoline, plus
     the spawn fn cast, now use long long (8 bytes on every ABI).
     Acceptance with the compiler lane's live m312+ build
     (E:\xiom-lang\xiom\target\debug\xiom.exe, XIOM_STDLIB=this tree):
     dbg131s.xi x5 -> spawned + joined 42 rc=0; the new two-thread
     out/dbg139w.xi x5 -> joined 42 + joined 7 rc=0; smoke_thread +
     smoke_collect_threadpool 2/2; p_wave131_shapes green. The compiler
     now verifies and requests the v0.64.5 pin (expected pin = stdlib
     main carrying this fix); the spawn flip is unblocked at the next
     archive (m312 landed); the guard-spin acceptance still waits on
     m313; thread gate 2053/1627/1402 flips with the pin per the
     candidate queue. (Numbering: the actor's doorbell block 170 sits
     above; the wave block is 170d.) Battery (pin v0.64.4, after the
     fix): corpus 955/955 (792.3s), probes 315/315 (466.3s), modules
     510/510 (295.8s), barename 0/510 (414.6s) + module-smoke/doc
     ratchets OK.
     PIN PREP v0.64.5 (block 171b, from the REL-20261014-1739 ack): the
     tag set is ready -- release-notes/v0.64.5.md (converter-validated,
     2 highlights, merged cap 6 with the compiler draft's 4), package.xi
     0.64.5, CHANGELOG [0.64.5]; COMPILER_VERSION stays v0.64.4. The
     compiler lane holds the tag signal; on it, cut the annotated
     stdlib-v0.64.5 at the frozen sha and run the candidate-processing
     checklist (full battery + the 27-repro sweep + the pending post-pin
     re-verifications).
     PIN HOLD (block 172, 2026-10-14 21:00Z): the tag signal arrived
     (relays 06d0a7c; release-wave push 1e4a444e; dry-run 38626737822,
     artifact sha256 67e57dfe...). Candidate checks found TWO
     DETERMINISTIC corpus regressions (953/955: smoke_cell_narrow rc 2 --
     Cell[Int8] set/get reads pointer-shaped garbage; smoke_stress_crypto_
     aes_gcm 0xC0000005 -- aes pair lengths read 0xFFFFFFFF, decrypt AVs;
     both 5/5 green on v0.64.4 in the same env). Filed as
     REL-20261014-2123-stdlib with minimal repros; the stdlib-v0.64.5 tag
     is HELD. Notes cleanup c8d713a (m313 stale line dropped, converter
     rc=0) is the tag target once the next candidate is green. Full
     candidate profile: corpus 953/955, probes 310/315 (3 compilefails:
     zext-float IR in p_sweep_single_param; duplicate
     LinkedList.invariant_check in p_wave7/p_wave8 -- 2 runfails:
     p_wave107/p_wave108 crypto pair lengths = the aes-gcm signature),
     modules 510/510, barename 0/510, ratchets OK.
     RELEASED (block 181, 2026-10-15): the fresh candidate (run
     38731274663, sha256 9b391ef4...) is fully green -- corpus 955/955,
     probes 315/315, modules 510/510, barename 0/510, floors172 +
     module-smoke + doc ratchets OK; the 27-repro sweep matches the
     recorded expectations; the thread acceptance is 5/5 on dbg131s and
     5/5 on the two-thread dbg139w; p_polyhedra_nested_hull is
     bonus-resolved (5/5 rc 0; pin control 3/3 rc 1). The annotated
     stdlib-v0.64.5 (tag object ecc3549 -> commit e082623) is pushed;
     the compiler pins + re-gates + tags v0.64.5. Post-tag: promote the
     polyhedra repro to tools/probes (probe count 316), re-add the
     1549-stdlib-6 payload clauses, resume the ranked sweep.
     RETAG (block 183, 2026-10-15): the first tag push (e082623) went RED
     on the ubuntu release gates -- smoke_os_sync SIGABRT, glibc heap
     corruption, root-caused to the pin-era m296 class (a fresh
     Vec[UInt8] ctor allocates 16 bytes while with_len(8) zero-fills
     n*8=64; the pinned compiler predates the m296 slot floor). The
     smoke's buffers are now a pin-portable zeros(n) push loop; verified
     in WSL (ASan clean + normal rc 0) and on Windows (pin + candidate
     rc 0). The tag was re-cut at the fix commit; release.yml re-runs on
     the moved tag; the compiler pins the moved tag.
     WAVE 140 (block 192, 2026-10-16): FIX-FIRST REL-20261015-1942-packages
     (HIGH) -- xiom.crypto.md5 produced wrong digests silently (RFC 1321
     mismatch). Root cause, both surfaces: the facade round applied a
     plain masked shift where MD5 needs a left rotate (no rotl helper
     existed; added _u32_rotl), and the deprecated legacy module rotated
     RIGHT on an unmasked 64-bit accumulation (now rotl_32 with an input
     mask). Locks: tools/probes/p_wave140_md5.xi (RFC 1321 A.5 suite x8
     + fox variants; red rc 1 pre, green post) + p_wave140b_md5_legacy.xi
     (legacy surface) + the extended RFC suite in
     smoke_stress_crypto_md5_basic.xi. Battery (v0.64.4-rel, heavy
     shared-box load; slices verified solo where flaked): corpus 956/956,
     probes 317/317, modules 510/510, barename 0/510, floors173 (fns
     8803, clauses 6252) + module-smoke + doc ratchets OK. md5 item now
     fixed; socket_connect (1948) is the next net-wave fix; the
     __fixdfti win64 finding (from 2011) is queued. NOTE: the wave pin
     moved to the official v0.64.5 archive (block 191) -- the next
     battery uses v0.64.5-rel.
     NEXT: the ranked sweep inventory as before; candidate processing
     when the v0.64.5 archive lands (release-check rows + known-failures
     sweep + the m313 guard-spin acceptance).
     WAVE 155 (block 207b, 2026-10-16): FIX-FIRST REL-20261016-1404-compiler
     (HIGH, C-PULSE-16) -- socket_bind ignored the address and
     socket_local_addr was an Err stub. Runtime (both platform blocks):
     xiom_socket_bind_addr (inet_pton/InetPtonA; -2 = parse failure;
     "" / 0.0.0.0 = wildcard) + xiom_socket_local_addr (getsockname +
     inet_ntop/InetNtopA); xiom_socket_bind stays as the wildcard
     delegation. socket.xi: bind marshals the host and maps -2 to the
     typed "invalid address" Err; socket_local_addr returns (ip, port).
     Locks: p_wave155_bind.xi RED 6 (pre-155 stub, detached-worktree
     witness) -> GREEN 0 -- 127.0.0.1 roundtrip, wildcard, invalid -> Err,
     non-local -> Err, unbound port-0, client-loopback; netstat witness
     TCP 127.0.0.1:45741 LISTENING (pre-155: 0.0.0.0). Battery on the
     OFFICIAL v0.64.5 pin (bd71e2d3): corpus 962/962 (956 tracked + 6
     untracked diag smokes), probes 327/327, floors178 ratchet, modules
     510/510, barename 0/510, module-smoke + doc OK. First POST-TAG tail:
     stdlib-v0.64.6 stays at b81430b (does not carry this fix); notes on
     1404/1452 for the next pin.
     FOLLOW-UP (from the REL-20261014-1453-packages ack): add the
     `copy_file_bytes` convenience alias with the next io-touching wave
     (copy_file itself is already byte-exact since wave 137; the alias
     is discoverability only). Trivial, but it needs a battery cycle,
     so it rides the next io change rather than a wave of its own.
     FOLLOW-UP (wave-145 candidate, from REL-20261015-2343-stdlib): the
     bare-inline i32-extern annotation tails + two ABI findings.
     Classification done 2026-10-16 (extern declaration vs the runtime's
     C return, source-of-truth = runtime/xiom_runtime.c):
     - pipe.xi xiom_read/xiom_write are declared `-> Int` while the
       runtime returns C int (sync_io.xi's copies are already Int32).
       PIN-TODAY BUG: on the bare form a -1 read is zero-extended to
       0xFFFFFFFF (positive), so pipe_read / pipe_write / pipe_read_
       timeout treat a failed syscall as success with garbage bytes.
       Fix (the wave-143 convention): retype the extern to Int32 +
       declared-form bindings `let n32: Int32; unsafe { n32 = ...; };
       let n = n32 as Int;`. Sites: pipe.xi 31, 47, 71, 116, 152, 159,
       185, 208.
     - async/io.xi 154/173 (the accept/connect copies declared
       `-> Int`): retype to Int32 + declared bindings, mirroring
       net/socket.xi.
     - ecc.xi 360: the extern is already Int32 -> annotate the binding
       only.
     - http.xi: 588 connect (Int32 declared) annotate; 604/613
       send/recv (declared `-> Int`, C int) retype + annotate; the
       create/accept sites keep Int (SOCKET is pointer-sized).
     - sysinfo.xi 28 / spawn.xi 157: cpu_count is Int32 -> annotate.
       thread_id is Int with a C long long -> fine as-is.
     - RUNTIME TAILS (needs a runtime-touching wave AFTER the actor's
       in-flight runtime edit lands): xiom_getpid / xiom_total_memory /
       xiom_free_memory return C `long` (32-bit on Windows) while the
       externs declare Int64/UInt64 -- memory totals truncate on
       greater-than-4GB boxes. Retype the C to long long (the wave-139
       lesson).
     - Context: the compiler's general fix (2343-stdlib, acked) makes
       bare forms correct on the next pin; the annotations are the
       belt-and-braces route plus THE pin-today error-path fix. The
       pipe error rows are probe material (red pre-fix on v0.64.4).
     CANDIDATE QUEUE (the open v0.64.4 release-check,
     release-checks/compiler-compiler-v0.64.4.md on the bus; compiler
     fixer wave m276-m313 in flight as of 2026-10-14T14:15Z): when the
     next compiler archive lands --
     (1) run the known-failures sweep (25 repros under
     tools/known_failures) on the candidate and diff the observed rcs
     against the recorded ones;
     (2) verify the stdlib rows queued in the release check:
     1548-stdlib-3/4/5/6/7, 1549-stdlib-2/3/4/5 and 1615-stdlib (all
     marked "stdlib lane re-verifies at the next archive");
     (3) re-add the 1549-stdlib-6 catalog payload clauses (Ok-side
     payload reads) once the pin carries m283+;
     (4) flip the spawn e2e + thread pool ONLY after m312 (the join
     readback defect): on m310 the hang is gone (m282 + wave-131 hoist;
     the worker runs, done=1 written) but the JoinHandle readback is
     still pointer-shaped garbage; thread gate 2053/1627/1402 stays
     OPEN;
     (5) retest the alloc-guard-spin acceptance only after m313
     (ffi.free call-site lowering): the spin still reproduces on m310,
     IR shows `call void @free` at the user call site while the wrapper
     body calls @xiom_guard_free; keep the alloc/free workarounds until
     the fix + a pin carrying both halves ship;
     (6) bindings re-probe context: the candidate carrying stdlib
     85acf16 + compiler m296 (vec_slot_size with_len overflow) should
     clear B-27/B-28 end to end (REL-20261014-1401-stdlib);
     (7) engine rows: REL-20261014-1427-engine (binary-safe copy_file --
     fixed stdlib-side in wave 137; verify the NUL roundtrip + the
     PE-magic copy_file probe on the candidate), engine-6 (thread
     pool/Send-Sync) rides the m312 spawn gate, 1513-engine (probe_save
     flake) stays under watch, engine-3 (directory watch) awaits the
     engine lane's verify. 1158-engine (identifier `spawn` drops catalog
     exports) and 1213-engine (layout-sensitive AV) are
     compiler-addressed, not stdlib rows.
BINARY NOTE: the shared local build path
`E:\xiom-lang\xiom\target\release\xiom.exe` was rebuilt past the pin
(compiler main da7798da m252) and fails four corpus smokes; waves now run
on the official v0.64.4 release archive
`%TEMP%\kilo\stdlib_ws\v0.64.4-rel\bin\xiom.exe` (sha256 DB8A2EF0...),
with the v0.64.3/v0.64.2 archives kept for comparison.

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

Pin protocol agreed 2026-10-09 (bus item REL-20261010-1559-stdlib; the
old relay drop is retired, block 86): stdlib tags a CANDIDATE `stdlib-vX.Y.Z` (no registry publish
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

Update 2026-10-11 (wave 109 landed): misc dir 98.7% + 1052 witness round.
Misc coverage: 38 fns, +38 pub (misc.xi 25: glob/natural/palindrome,
damerau/jaro/jaro-winkler/hamming/LCS, roman, case converters,
ordinal/pluralize/anagram, unit conversions, human_size; semver.xi 13:
parse/valid/compare/matches/satisfies/inc/to_string/prerelease/build/
caret/tilde/gt/lt). misc 50.6% -> 98.7%, global 67.9% -> 68.5%
(pubCovered 4416 -> 4454, clauses 5875 -> 5923); meter 76.9%; floors146.
Relay round: compiler resolver/isolation batch (1052) coordination
delivered -- forward-order lock already in p_wave106_shapes.xi, NEW
reversed-order lock on main (p_witness_1052_rev.xi, commit 67d66c9) and
the witness branch witness/1052-metro-rename-reverted (1566c26) with the
rename reverted + both locks (RED today by contract abort; must run rc 0
post-fix). The rename will be reverted on main once isolation is
verified; both probes stay as permanent e2e locks and the registry ships
natural names. Acked REL-20261011-1342-compiler-2. Battery: corpus
954/954 full (757.8s), probes 284/284 (377.8s), modules 509/509 (196s),
barename 0/509 (244.6s), floors146 + doc + module-smoke (497/517,
3476/6204) ratchets OK. Next: sync coverage (sync.xi tail +
atomics/mutex/rwlock); async later.

Update 2026-10-11 (wave 108 landed): FIX-FIRST crypto defects (3) +
crypto batch 2. cipher.xi's `_gf_mul11`/`_gf_mul13` were SWAPPED -- every
cipher.xi decrypt path (aes_block_decrypt / ECB / CBC) computed wrong
plaintext while its encrypt was FIPS-correct; NO smoke covered the
decrypt (the wave probe caught it by comparing the block roundtrip
against the FIPS-verified runtime AES). Fixed. `argon2` could pass
iterations <= 0 into pbkdf2 (whose requires trap) -- guarded to the
family's validate-and-return-empty convention. The educational ecc
ed25519_sign/verify indexed 32 bytes blindly (OOB reads for short keys/
signatures) -- bounds-guarded with zero-fill; open note: the toy's
keygen->sign->verify roundtrip is false by construction (sign binds
sha256(sk); verify binds the passed key), no smoke covers it. Crypto
coverage: 49 fns, +46 pub (cipher 22, crypto tail 15, ecc 12); crypto
69.4% -> 94.5%, global 67.2% -> 67.9% (pubCovered 4370 -> 4416, clauses
5790 -> 5875); meter 76.8%; floors145. Probe p_wave108_shapes.xi (282nd,
60 checks) RED on the AES decrypt + argon2 trap / GREEN post-fix, green
post-clauses. Battery: corpus 954/954 full (607.9s), probes 282/282
(246.5s), modules 509/509 (156.2s), barename 0/509 (234.4s), floors145
+ doc + module-smoke (497/517, 3476/6204) ratchets OK. Next: misc/sync
coverage; runtime asks when the compiler runtime bundle moves.

Update 2026-10-11 (wave 107 landed): FIX-FIRST RSA short-key OOB read +
crypto batch 1. `_rsa_parse_key` (crypto.xi) indexed key[0..8]
unconditionally, so any key shorter than 8 bytes read out of bounds and
made the RSA guards nondeterministic -- caught by the wave probe's
contract run (the empty-key rsa_sign clause failed on garbage memory).
The read is now bounds-guarded (short keys zero-pad; empty key -> n=0 ->
deterministic Err). Crypto coverage: 41 clauses, +41 pub (chacha 4, aead
10, curves 9, des 4, rng 2, sign 6, rsa 6); crypto 47.0% -> 69.4%,
global 66.5% -> 67.2% (pubCovered 4329 -> 4370, clauses 5739 -> 5790);
meter 76.7%; floors144. Probe p_wave107_shapes.xi (281st, 55 checks)
green pre/post after the fix. Battery: corpus 954/954 full (698.4s),
probes 281/281 (299.4s), modules 509/509 (203.3s), barename 0/509
(216.6s), floors144 + doc + module-smoke (497/517, 3476/6204) ratchets
OK. Bus: acked the pulse keep-alive/deadlines design note (the three
interface points are adopted as the acceptance shape for the queued
socket-timeout wave). Next: crypto batch 2 (cipher + crypto.xi tail +
ecc); misc/sync coverage.

Update 2026-10-11 (wave 106 landed): hash modules + two compiler findings.
FIX-FIRST private-symbol collision (probe-first catch): with
xiom.hash.farm + xiom.hash.metro co-imported, metro's module-private
_K0/_K1/_K2 resolved to farm's values -- metrohash64(empty,0) returned
15427970114922222902 instead of 1424585646250073642 (exact numeric
match; farm wins in both import orders). Filed REL-20261011-1052-stdlib
(high): module-level privates must be per-module mangled (same mechanism
covers same-named private fns; a full-stdlib scan found no other live
divergent const). Stdlib-side: metro's consts renamed _METRO_K0..K3
(city/farm agree). Second finding: REL-20261011-1053-stdlib (medium):
zero-arg `.hash()` on scalars lowers to a compiler builtin identity that
shadows Int.hash/Bool.hash (methods unreachable; explicit receiver does
not type-check; hash_value(0) == 0). Hash coverage: 41 clauses, +39 pub
(hash.xi 11, farm 9, highway 4, metro 5, murmur 2, spooky 4, t1ha 6);
hash 51.1% -> 94.4%, global 65.9% -> 66.5% (pubCovered 4290 -> 4329,
clauses 5698 -> 5739); meter 76.7%; floors143. Probe p_wave106_shapes.xi
(280th, 50 checks) RED on the collision / GREEN after the rename, pre
and post clauses. Battery: corpus 954/954 full (788.5s), probes 280/280
(301.6s), modules 509/509 (221.5s), barename 0/509 (259.3s), floors143
+ doc + module-smoke (497/517, 3476/6204) ratchets OK. Bus round: pulse-3
(server_parse_request) and pulse-4 (write_all) acked -> fixed as
already-delivered at ec64dec (doorbell's "wave-106 candidates" framing
superseded). Next: crypto/misc/sync coverage; runtime-backed asks when
the compiler runtime bundle moves.

Update 2026-10-10 (relay website-10 fixed: no-NASM crypto fallbacks):
security triage confirmed the hole shape but not through stdlib public
API -- the stdlib AES path uses the NASM-independent xiom_aesni_*
intrinsics and crypto.mac.constant_time_eq is pure XIOM; the broken
pieces were the runtime's exported dispatch primitives
(xiom_ct_compare_dispatch always "equal", xiom_aes128_*_dispatch writing
zeros). The pin's driver here compiles with -DXIOM_NO_ASM (verified: the
cached runtime object carries the fallback symbols; no NASM objects are
linked), so the fallback is the operative path. Fixed with real portable
FIPS-197 AES-128 (key expand, encrypt, decrypt) and branch-free XOR
compares (0 = equal) in the no-asm block; KAT-verified standalone and
end-to-end through the driver (throwaway out harness, rc 0); post-edit
smokes green (kat_ 15/15, crypto 7/7, stress_crypto 24/24, mem 6/6, ffi
2/2). Bus item moved acked -> fixed. NEW open runtime finding: aarch64
xiom_aesni_encrypt_block is a single round and xiom_aesni_decrypt_block
is an empty stub while xiom_crypto_aesni_available() returns 1 -- stdlib
AES-128 on Apple ARM produces wrong ciphertext (candidate contributor to
the red macos-14 corpus leg); fix needs an ARM runner (use the verified
portable AES or the full vaeseq/vaesmc schedule).

Update 2026-10-10 (wave 105 landed): FIX-FIRST signal_raise link defect
+ os batch 2 -- 64 clauses, +64 pub. FIX-FIRST: `xiom.os.signal.
signal_raise` and `xiom.os.raise_signal` referenced a `raise_sig` extern
that no runtime (archive, vendored, or repo) ever defined -- the first
link reference (the wave probe) exposed the never-linkable surface. Both
now call libc `raise` with a documented-Err Windows guard (the ucrt
raise fail-fasts on unsupported numbers); locked by the probe. Coverage:
env 28/28, sysinfo 12/12, term 11/11 pub (is_tty/width stay the
documented stub delegations), proc 5/5, signal 8/8, dir 11/11, args 6/6,
process 11/11, fs 10/10, plus the flat-os tails; os 38.0% -> 55.4%,
global 65.0% -> 65.9% (pubCovered 4226 -> 4290, clauses 5634 -> 5698);
meter 76.6%; floors142. Probe p_wave105_shapes.xi (279th, 91 checks) RED
pre-fix (undefined raise_sig) / GREEN post-fix and post-clauses.
Battery on the official v0.64.2 archive: corpus 954/954 full (1002.7s;
first pass had 5 transient clang -1 crashes, -RetryFailed clean), probes
279/279 (304.7s), modules 509/509 (184.4s), barename 0/509 (263.1s),
floors142 + doc + module-smoke (497/517, 3476/6204) ratchets OK.
Readiness next: the website-10 no-NASM crypto triage (security), then
the runtime-backed wishlist asks.

Update 2026-10-10 (wave 104 landed): Instant millisecond resolution +
buffered-stdin normalization -- two relay fixes, probe 278th; coverage
flat (fix wave). benchmark-2: Instant.t is now milliseconds;
elapsed()/duration_since()/add/sub/sleep_until and the xiom.time.instant
wrappers switched; elapsed().as_millis() reports real millisecond
deltas (the wave-66 lock was remerged to the new semantics).
benchmark-3: buf_reader_new(0)/buf_writer_new(1) resolve stdin/stdout
through the runtime; piped stdin reads GOT:hello; FILE* handles
unchanged. floors141. Battery on the official v0.64.2 archive: corpus
954/954 (975.5s), probes 278/278 (323.2s), modules 509/509 (255.7s),
barename 0/509 (460.9s), floors141 + doc + module-smoke ratchets OK.
Readiness next (wave 105): the os batch 2 claimable remainder, the
website-10 no-NASM crypto triage, and the runtime-backed wishlist asks.

Update 2026-10-10 (wave 103 landed): sleep fix-first + os batch 1 --
46 clauses, +42 pub. pulse-6 (C-PULSE-18) FIXED: time.sleep_ms/sleep
(Duration) now call the runtime xiom_thread_sleep_ms (the old
`ms / MILLIS_PER_SEC` integer division made sub-second sleeps no-ops);
locked by a monotonic_ms timing check. pulse-5 (C-PULSE-17) RE-TRIAGED:
io.list_dir is correct (from_c_str emits the m211 copy); the break is
the consumer-side inline Result.value[i] payload index -- filed as
p_result_payload_index_concat.xi + REL-20261010-1609-stdlib. NEW
finding: the Path.exists + trailing-println sequence dies with exit
-1073741795 (context-dependent codegen; p_path_println_context_crash.xi,
REL-20261010-1615-stdlib). Coverage: fs 9/10, file 12/12, dir 8/11,
platform 7/10, err 3/11, args 3/6; os 26.6% -> 38.0%; global 64.3% ->
65.0% (pubCovered 4184 -> 4226, clauses 5588 -> 5634); meter 76.5%;
floors140. Findings 16 Current (15 compiler + 1 stdlib). The remaining
os gap is largely stub-gated (event/terminal/mmap/sync_io/unix/win/
ioctl/fs_ffi/proc_ffi documented stubs stay clause-free). Battery on the
official v0.64.2 archive: corpus 954/954 (790.2s), probes 277/277
(265.6s), modules 509/509 (200.2s), barename 0/509 (295.9s), floors140
+ doc + module-smoke ratchets OK. Readiness next (wave 104): os batch 2
(claimable remainder), the relay queue (website-10 no-NASM crypto
triage), then the runtime-backed asks.

Update 2026-10-10 (relay bus onboarding + first processing round): the
stdlib lane is on `xiom-lang/xiom-relays` (working instructions in
AGENTS.md + session section 0B; a 2h doorbell cron is live). The 14 open
compiler-finding entries were migrated one-per-entry (ids in the
known_failures README Current header) plus the shared-build drift item.
First inbound round: 5 items fixed with refs -- bindings-9
(Vec.with_len, 5b7bf8f), bindings-10 (dl out-param recipe, c146cc1),
xvector-7 (json depth cap, 5b7bf8f), packages-2/3 (wave-98 contract
fixes, 2e55b13); 23 acked with plans (runtime-bundle queue plus two
wave-103 quick wins: pulse-6 sleep_ms root-caused to the integer
division, website-10 no-NASM crypto triage); one ops tool bug filed
(REL-20261010-1553-stdlib; the resolver's exact-id collision blocks ack
on two items). The owner-authorized darwin one-off 48850df (macOS
runtime-C guards) was reviewed and accepted. Bus commit: 62d48e3.

Update 2026-10-10 (wave 102 landed): json depth cap FIXED + math
remainder covered + W-5 delivered -- 97 clauses, +46 pub. json:
`_JSON_MAX_DEPTH = 128` threaded through the parser; Err beyond;
boundary 128 Ok / 129+60000 Err locked by p_wave102_shapes.xi and the
promoted tools/probes/p_json_parse_depth_cap.xi; finding #16 resolved
(findings 16 -> 15 Current: 14 compiler, 1 stdlib). Math: decompose
15/15 (100%), fuzzy 12/14 (85.7%; the two nested-float relation stubs
stay), game_theory 6/13 (46.2%; the stubs and alpha_beta stay), chaos
13/13 (100%); math 48.3% -> 53.0%; global 63.6% -> 64.3% (pubCovered
4138 -> 4184, clauses 5491 -> 5588); meter 76.4%; floors139. Wishlist
W-5 `Vec[UInt8].with_len(n)` delivered as `fn Vec.with_len[T]`
(byte-zeroed element area; the mem.zeroed/mem_set generic calls did not
resolve under C001, so the zeroing is an in-module byte loop);
collections smokes 21/21. Compiler relay:
`docs/STDLIB-RELAY-2026-10-10.md` dropped in the compiler repo
(untracked) with the two stdlib findings plus the B-11/B-10/B-05/
XVC-C-13/macOS blockers from the five-lane fetch. Battery on the
official v0.64.2 archive: corpus 954/954 (831.6s), probes 276/276
(298.3s), modules 509/509 (265.5s), barename 0/509 (265.3s), floors139
+ doc + module-smoke ratchets OK. Readiness next (wave 103): os 26.6%
(inspect each runtime-backed surface before claiming), then the queued
runtime-backed asks (address-aware bind, socket_recv_into, the fsync
family) with the compiler runtime bundle.

Update 2026-10-10 (five-lane stdlib-wishlist fetch): sources re-read
directly on the lanes' working trees (packages, bindings, PULSE,
ORBITDB, XVECTOR; the remaining lanes were swept for asks too). ONE new
row ecosystem-wide: XVECTOR's bounded-depth `json_parse` recursion
guard -- `xiom.serialize.json.json_parse` recurses without a cap and a
deep `[` run kills the process before any error path; verified natively
on the official v0.64.2 archive (Windows x64): depths 100/150/200
return the graceful Err, depth 300+ dies with exit -1073741795
(0xC000001D), depth 60000 likewise. Recommended cap ~128 (serde_json
default; the observed floor is ~300 on Windows). Filed as finding #16
with repro `tools/known_failures/p_json_parse_depth_cap.xi` (dies
pre-fix; expected rc 0 = Err) and queued as the FIRST wave-102 item.
Packages/bindings/PULSE/ORBITDB rows are unchanged (no new asks since
2026-10-09; bindings' new B-11 plus the re-verified B-10/B-05 are
compiler-lane items, no stdlib action). Full delta in
`docs/STDLIB-WISHLIST.md` ("Relay status 2026-10-10") and session
block 90. Findings now 16 Current (14 compiler, 2 stdlib).

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

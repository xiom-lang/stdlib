# Stdlib wishlist (packages/consumers -> stdlib lane)

Intake record for feature and defect requests relayed by the packages lane.
Source of record: the packages lane's `docs/STDLIB-WISHLIST.md` sheet; this
file mirrors the rows relayed on 2026-10-01 so they survive lane handoffs.
Rows are informational until a stdlib wave picks them up; defects are
fix-first.

Status legend: **open** = not started; **fixed** = landed with a probe lock
(commit noted); **declined** = with reason.

| # | Item | Kind | Notes | Status |
|---|------|------|-------|--------|
| 1 | `str_contains` / `index_of` empty-needle contract violation | defect | `string.index_of` carried `requires: substr.len() > 0` while its body returned `Some(0)` for an empty needle and `str_contains` delegates to it; same contradiction on `string.str_index_of` (doc promises `Some(0)`) and `str_replace_all` (doc promises `s` unchanged; `replace` handles it). Fixed by removing the three preconditions and adding empty-needle `ensures` (`p_empty_needle_contracts.xi`). `string.str_split`'s delimiter precondition is genuine (no empty-delimiter promise) and stays. | **fixed** (2026-10-01) |
| 2 | Allocation-free line accessors | enhancement | Iterate lines without allocating a new `Str` per line (byte-range or cursor view), for line scanners on large inputs. | open |
| 3 | Keyed FIFO / mailboxes | feature | FIFO queues addressable by key (multiple logical mailboxes over one structure), with the same non-blocking semantics as the existing queue helpers. | open |
| 4 | Stable argmax | feature | Index of the maximum with first-wins stability and documented NaN policy (match the stats module's conventions). | open |
| 5 | Event-log cursors | feature | Opaque cursor over an append-only event log: read-new-since-cursor without copying the whole log. | open |
| 6 | Composite-key lookups | feature | Map/set lookups on multi-field keys (struct keys or tuple keys) without manual string packing. | open |
| 7 | Non-aborting assertion catalog | feature | Test-assertion helpers that report failures and continue (collect-all mode) instead of aborting on the first failure, for packages' conformance suites. | open |
| 8 | Fixed-point MSE | feature | Mean squared error for the fixed-point numeric types, matching the float stats MSE semantics. | open |
| 9 | Saturating `Int` arithmetic | feature | `add`/`sub`/`mul` clamping at MIN/MAX on the module face. Requesters: `defi`, `geom3d`, `svm`, `mechanics`, `materials`, `chaincrypto`. | open |
| 10 | Pinned rounding helpers | feature | `div_round` (half away from zero) and `div_ceil` (toward zero) over signed ints. Requesters: `geom3d`, `svm`, `defi`, `materials`, `boosting`. | open |
| 11 | Fixed-point scale-once multiply kernels | feature | `mul(a, b, scale)` plus guarded sums, to avoid intermediate overflow. Requesters: `geom3d`, `materials`, `mechanics`, `boosting`. | open |
| 12 | Fixed-point trigonometry + standalone `isqrt` | feature | `sin`/`cos` with range reduction; Newton `isqrt` usable without importing the `xiom.math` barrel. Requesters: `geom3d`, `defi`. | open |
| 13 | Typed-vector copy helper | feature | `Vec[Int]` clone (and the same shape for other element types). Requesters: `exchanger`, `chaincrypto`, `actor`, `itest`. | open |
| 14 | Table interpolation | feature | Linear interpolation over an ordered (tick, value) table. Requesters: `materials`, `discovery`. | open |
| 15 | Group-by-key fold with running aggregate | feature | Bucketed folds (OHLCV buckets, top-N depth). Requesters: `exchanger`, `stats-ml`. | open |
| 16 | `xiom.math.fixed` transcendentals | feature | `exp`/`log`/`pow`-class functions for the fixed-point type (overlaps row 12's sin/cos; a broader fixed transcendental surface). | open |
| 17 | Exact-sum softmax | feature | Softmax with exact-sum accumulation so the denominator does not drift across long inputs. | open |
| 18 | Bit-set dataflow primitives | feature | Worklist/bit-set primitives for dataflow passes (set union/intersection/iteration over bit sets). | open |
| 19 | Borrowed `Str` views | feature | Non-owning string slice views (offset+len) to scan without copying. | open |
| 20 | Dependency-free `Vec[UInt8]` -> `Str` builder | feature | Build a `Str` from a byte vector without importing other modules (allocation-light path). | open |
| 21 | `Vec.pop` ergonomics | feature | Pop returning an `Option`-shaped result (or a checked variant) instead of the raw representation. | open |
| 22 | `compress.zip` | feature | ZIP container read/write support in `xiom.compress`. | open |
| 23 | Deflate dynamic-Huffman reads + public tables | enhancement | Decoder support for dynamic Huffman blocks; expose the Huffman tables. | open |
| 24 | Neutral CRC32 | feature | CRC32 helper without format/policy dependencies (shared by zip/deflate-class consumers). | open |
| 25 | Keccak-256 | feature | Keccak-256 hash primitive. | open |
| 26 | `_u64_lshr` defect | defect | The private u64 logical right shift is defective; fix plus a probe lock. | open |
| 27 | Fixed-point `log2` + integer stats | feature | `log2` for the fixed-point type and integer-domain stats helpers. | open |
| 28 | Strict `str_to_int` | feature | Strict integer parsing (reject junk; `Option`-shaped result). | open |
| 29 | XML tokenizer | feature | Streaming XML tokenizer. | open |
| 30 | UTF-8 code-point helpers | feature | Decode/encode Unicode code points on UTF-8 strings. | open |
| 31 | `rand.state` | feature | Explicit RNG state save/restore (requester list extended 2026-10-02). | open |
| 32 | `encoding.le` | feature | Little-endian encode/decode helpers (requester list extended 2026-10-02). | open |
| 33 | `crypto` linkability defect | defect | Packages packet `docs/repro/crypto-link` @ 8eb7944f (Windows x64, v0.62.2 installed, stdlib-perf1): `lld-link: undefined symbol: xiom_sha256_hash` from `xiom.crypto.sha256_hex(&Vec[UInt8])` / `xiom.crypto.hash.crypto_hash_sha256(&Vec[UInt8])`; --emit-ir passes. NOT reproduced on stdlib main: both KATs (NIST "abc"; base64 "YWJj") link and run green on v0.61.3 and v0.62.2 dev, with/without XIOM_STDLIB; the symbol is in `runtime/sha256_sw.c` in all tags and in the driver's build-runtime list -- suspect a stale installed runtime library; handed to the compiler/install lane with the packages KATs. | open (compiler/install lane) |
| 34 | `xiom.hash` FNV-1a over `Str` + masked combine | feature | FNV-1a hashing for `Str` inputs and a masked/truncated combine variant. | open |
| 35 | ASCII byte classifiers | feature | Byte-domain ASCII digit/alpha/alnum-class predicates. | open |
| 36 | Delimiter helpers | feature | Multi-delimiter scan/split helpers. | open |
| 37 | Graph closure/depth | feature | Transitive closure and depth computation over graph structures. | open |
| 38 | `vec.str` helpers | feature | Requester list extended 2026-10-02 (packages relay); concrete surface follows their sheet. | open |
| 39 | `Vec` truncation | feature | In-place truncate/resize-down helper; requester list extended 2026-10-02. | open |
| 40 | `serialize.json` | feature | Requester list extended 2026-10-02 (JSON surface on the module face). | open |
| 41 | `graph.topo` | feature | Topological sort helper; requester list extended 2026-10-02. | open |
| 42 | glob/regex helpers | feature | Glob matching (and/or a small regex surface) for path and text filters; relay 2026-10-02 night. | open |
| 43 | `Str` -> `Str` map | feature | String-keyed map ergonomics on the module face (no manual hashing); relay 2026-10-02 night. | open |
| 44 | Span/byte-slice API | feature | Non-owning byte-span views over `Str`/`Vec[UInt8]` for zero-copy parsing; relay 2026-10-02 night. | open |
| 45 | Strict int parsing with offsets | feature | Reject-junk integer parsing that also reports the consumed byte offset (extends row 28); relay 2026-10-02 night. | open |
| 46 | base32 + percent-encoder | feature | Public base32 encode/decode and a standalone percent-encoder on the encoding face; relay 2026-10-02 night. | open |

Relay status 2026-10-03 (fetched 2026-10-05): the packages source-of-record
has advanced to 126 rows (waves 47-55); this mirror still carries rows
1-46. New actionable rows: 124 (deflate dynamic-Huffman read path --
feature), 127 (`_u64_lshr` n=63 defect -- stdlib fix-first candidate), 150
(contract-usable is_finite/is_nan + reciprocal), 152 (strict percent_decode
with relocatable offsets + NUL rejection), 87 (`sb_push_int` INT_MIN),
96 (`parse_int` 2^63 -> INT64_MIN). Stale: 34 (encoding.base64 shipped),
139 (duplicates row 33). Full 80-row mirror refresh pending a dedicated
intake; the packages sheet at
`E:\xiom-packages\packages\docs\STDLIB-WISHLIST.md` is the source of
record.

Five relays from the packages lane: the initial batch named 8 rows
(rows 1-8), the wave-46 batch added rows 9-15 with requester lists, the
2026-10-02 morning batch added rows 16-21, the 2026-10-02 afternoon batch
adds rows 22-32 (compress.zip, deflate dynamic-Huffman reads + public
tables, neutral CRC32, Keccak-256, the `_u64_lshr` defect, fixed-point
log2 + integer stats, strict `str_to_int`, XML tokenizer, UTF-8
code-point helpers, and the extended requester lists for `rand.state` and
`encoding.le`), and the 2026-10-02 evening batch adds rows 33-41 (the
`crypto` linkability defect -- fix-first once reproduced -- plus FNV-1a
over `Str` + masked combine, ASCII byte classifiers, delimiter helpers,
graph closure/depth, and the extended requester lists on `vec.str`, `Vec`
truncation, `serialize.json` and `graph.topo`); the 2026-10-02 night batch
adds rows 42-46 (glob/regex helpers, `Str` -> `Str` map, span/byte-slice
API, strict int parsing with offsets, base32 + percent-encoder). Defects
are fix-first: row 33's packet is in hand and does not reproduce on stdlib
main (defined in `runtime/sha256_sw.c`; handed to the compiler/install lane
with the packages KATs). The full sheet (wave 43-46 rows and
requester lists) lives in `xiom-packages/packages` at commit `66f26e1`;
the packages lane offered to forward the whole file. The empty-needle
defect (row 1) is acknowledged FIXED in the packages sheet; their
`compliance` package keeps its short-circuit workaround until the next
stdlib release. The packages lane's other notes (catalog bugs obs-fold
trimming and `max-age=abc` were package-side; `str_replace_all` proved
useful for policy rewriting; avoid `==` on Result values in tests -- no
guaranteed `Eq`) need no stdlib action beyond row 1.

Relay status 2026-10-07 (fetched online; sheet now 134 rows): the
2026-10-05 batch adds 8 rows, all stdlib-relevant:
- HTTP-date pair: RFC 1123/7231 formatter from epoch + public
  IMF-fixdate parser (`strftime` hardcodes `%H/%M/%S` to "00" and lacks
  `%a/%b`; the parser is private in `cookie.xi`) -- requesters
  `xiom.static`, PULSE.
- Path safety: cross-platform lexical `path_within(root, child)`,
  Windows-aware `is_absolute`, both-separator join (`io.join_paths` /
  `io.is_absolute` are `/`-only) -- `xiom.static` traversal guard.
- `xiom.io.fs` remove parity: `fs_remove` / `fs_remove_dir` (`fs` has
  write/read but no remove; only `io.remove_file`).
- Concrete stdio `Read` implementation of `read_exact` (streaming;
  `io.xi:481` is interface-only, `fs_read_range` returns whole buffers
  with Int32 offsets).
- Durable write path: real `io.fsync(handle)` / flush (`fsync` /
  `fdatasync` / `flush_fd` / `sync_fd` / `fsync_dir` are Err stubs and
  `flush_stdout` is a no-op) -- flagged "highest-value storage ask";
  also filed by PULSE (STDLIB-WISHLIST-PULSE row 25), so two-lane
  demand. Runtime-backed: no `fsync`/`FlushFileBuffers`/`_commit` in
  `runtime/*.c`; queued for the next compiler runtime bundle.
- Byte-level append parity: `append_file_bytes(path, &Vec[UInt8])`.
- `truncate(path, len)` + `remove_dir(path)` (`os/fs_ffi.xi:151` is a
  stub; `io` has `remove_file` only).
- File locking (`file_lock` is an Err stub; `xiom.kv` single-writer is
  unenforced).
Defects unchanged: `sb_push_int` INT_MIN (87), `parse_int` 2^63 ->
INT64_MIN (96) and `_u64_lshr` n=63 (127) stay open (fix-first
candidates); row 33 crypto linkability stays compiler/install-lane (not
reproducible on stdlib main); the empty-needle row is fixed. Stale: 34
(encoding.base64 shipped), 139 (duplicates 33).

Relay status 2026-10-08 (PULSE delta, fetched from
`E:\xiom-projects\xiom-pulse\docs\STDLIB-WISHLIST-PULSE.md`):
`TcpStream.write_all` and `xiom.net.server.server_parse_request` are
ADOPTED by PULSE (the 270 KB favicon path is green on both platforms;
the parser is pinned by their 12-check
`probe_stdlib_server_parse.xi`). New ask: import aliasing -- a consumer
module whose last segment collides with a stdlib module shadows the alias
(C-PULSE-12); cross-filed here as the cross-module type-path /
foreign-method-call finding with repros
`tools/known_failures/p_alias_module_type_path.xi` and
`tools/known_failures/p_foreign_method_call.xi`. `socket_set_timeout`
re-confirmed as a documented-Err stub (runtime-backed; stays queued with
the socket-option row). `io.flush_stdout` is still a no-op
(runtime-backed; queued). Positive: v0.64.0 runtime + crypto are
env-free; `TcpStream.read` works (C-PULSE-01 fixed); the stdlib loopback
fixture request is satisfied by `smoke_net_tcp_stream.xi`.

Relay status 2026-10-08 (ORBITDB + XVECTOR lanes; sources
`E:\xiom-projects\xiom-orbitdb\docs\RELAY-STDLIB-ORBITDB.md` and
`E:\xiom-projects\xiom-xvector\docs\STDLIB-WISHLIST-XVECTOR.md`, both on
pin v0.64.0).

Storage/durability cluster (three lanes now agree -- PULSE, ORBITDB,
XVECTOR), all runtime-backed and queued for the compiler runtime bundle;
the stdlib-side surface shape is confirmed as follows (asked by XVECTOR):
complete the existing documented stubs as designed instead of adding new
names -- fd-level primitives in `xiom.os.sync_io` (`write_all`,
`read_exact`, `sync_fd`/fsync, `fsync_dir`) plus path-level wrappers in
`xiom.os.fs_ffi` (`fsync`, `fdatasync`, `truncate`, `ftruncate`) and
`io` conveniences (`append_file_bytes(path, &Vec[UInt8])`,
`sync_file(path)`, real `flush_stdout`); needs
`fsync`/`FlushFileBuffers`/`_commit` and a write-capable fd in the
runtime. Until then consumers keep the documented not-durable limit.

- ORBITDB row 1 / XVECTOR row 1: `fsync`/`fdatasync` -- runtime-backed,
  queued (PULSE row + two more requesters).
- ORBITDB row 2: **`io.read_file_lines` CRLF normalization -- FIXED
  2026-10-08** (strip one trailing CR per line; probe lock
  `tools/probes/p_read_file_lines_crlf.xi`). Root cause fixed too: the
  ORBITDB CRLF files came from `io.write_file` / `io.append_file` /
  `io.write_file_bytes` opening in TEXT mode, so Windows `fwrite`
  silently turned LF into CRLF (and `write_file_bytes` was not
  byte-exact). All three now open binary (`wb`/`ab`); byte fidelity is
  locked by the same probe. This also unblocks XVECTOR's byte-framing
  expectations for the existing `read_file_bytes` / `write_file_bytes`.
- ORBITDB row 3: append-with-tail-repair + flush -- the repair half is
  pure XIOM (new `append_line_sync` surface to be scheduled); the durable
  flush half is runtime-backed.
- ORBITDB row 4 / XVECTOR row 5: `truncate`/`ftruncate` -- runtime-backed
  stubs (WAL checkpoint/segmentation).
- ORBITDB row 5 / XVECTOR row 3: byte-level append
  (`io.append_file_bytes`) -- runtime-backed (append-capable fd write);
  the whole-file byte APIs exist and are now byte-exact.
- ORBITDB row 6: tail check without a full read
  (`io.file_last_byte`/`ends_with_newline`) -- needs a seek/stat
  primitive; runtime-backed.
- XVECTOR row 4: `f32_bits`/`bits_to_f32` -- compiler-lane ask (bitcast
  lowering for Float32; the Float64 pair is compiler-lowered); the
  `as Float64` round-trip workaround is exact.
- XVECTOR row 6 / PULSE: durable `flush_stdout` -- runtime-backed;
  XVECTOR added as requester.
- ORBITDB note: `xiom.test` `assert` returns `TestResult` (the old
  `TestCase` type is gone) -- doc note queued.
- Positives: `io.sleep(ms)`, `io.append_line`/`read_file_lines`,
  `env.var_or`, `crc32c` framing, whole-file byte IO and the Float64
  bitcast pair are adopted and working; ORBITDB's crash test is offered
  as the acceptance fixture for the fsync/append-repair/replay rows.

Relay status 2026-10-08 (bindings lane; source
`E:\xiom-packages\bindings\docs\BINDINGS-STDLIB-WISHLIST.md`, rows
W-1..W-5, pilot `xiom.sqlite` on v0.64.0):
- W-1 `xiom.io.fs` file delete/remove -- **FIXED 2026-10-08**:
  `fs_remove(path)` added to `xiom/io/fs.xi` (delegates to
  `io.remove_file`; Ok -> `!file_exists`; probe lock `p_fs_remove.xi`).
  `io.remove_file` already existed but was not on the fs module face.
- W-2 `xiom.ffi` out-param slot helper (`OutSlot`, or `out_slot(n)` +
  typed `read_i64`/`write_i64`) -- open; scheduled candidate (pure XIOM
  over an `FFIBuffer`/`Vec[UInt8]` slot + `as_mut_ptr`).
- W-3 guard-aware `ffi.free` -- compiler finding B-05 (guard-alloc vs
  libc free mismatch spins the guard heap in confined blocks); the
  stdlib side is addressed by the new CONFINEMENT CAUTION in the
  `xiom.ffi` module header and the `free` doc (2026-10-08). The compiler
  lane owns the real fix; bindings keep the outside-confinement pattern.
- W-4 stale Int-to-pointer-cast warning -- **FIXED 2026-10-08**: the
  `smoke_ffi2.xi` note now records the bindings-verified typed-call idiom
  (`let f = addr as fn(..) -> T;` inside `unsafe`) on v0.64.0; a dl
  typed-call smoke is queued so the idiom is locked.
- W-5 `Vec[UInt8].with_len(n)` zeroed constructor -- open; scheduled
  candidate (collections change + probe; removes the per-slot push loop).
- Companion defects file: `docs/BINDINGS-COMPILER-FINDINGS.md` (B-05
  above) lives with the bindings lane; the stdlib repro intake stays
  `tools/known_failures/`.

Relay status 2026-10-08 (second sweep; sources re-fetched 17:40):
- PULSE (`STDLIB-WISHLIST-PULSE.md`, 17:11), new asks: **signal-handler
  installation** (`signal_handle`/`signal_pending`) -- ADDRESSED stdlib-side
  as documented-Err stubs in `xiom/os/signal.xi` (signal-safe trampoline is
  runtime-backed; SIGTERM graceful shutdown stays queued for the runtime
  bundle); import aliasing (already cross-filed as the compiler finding);
  socket options and `flush_stdout` unchanged (runtime-backed). PULSE
  verified the adopted items on Linux v0.64.1 against lane checkout 4dd8844
  (server-parse 12 checks, 270 KB favicon, soaks) -- no behavior delta.
- ORBITDB (`RELAY-STDLIB-ORBITDB.md`, 16:15), sharp finding: **`str_split`
  was O(n^2)** because it sliced a substring per scan position; 5 MB / 20k
  line WAL replays took ~44 s (`read_file` alone 2 ms). **FIXED 2026-10-08**:
  byte-compare scan, O(|s| * |delimiter|), no per-position slices; probe
  lock `p_str_split_scale.xi` (120 KB scale + edge cases). Same-class fixes
  in the sweep: `str_repeat` now doubles (was quadratic accumulation) and
  `str_pad_left`/`str_pad_right` allocate once (were quadratic AND leaked
  one malloc per pad byte). Row 2 (CRLF) already fixed earlier today; the
  append-handle ask (`io.open_append` -> write/sync/close) stays open and
  scheduled (throughput 626 -> 2,061 ops/s in-lane; the sync half is
  runtime-backed).
- XVECTOR (`STDLIB-WISHLIST-XVECTOR.md`, 13:05): no new rows; the
  durability cluster (fsync, fd write path, append_file_bytes, f32 bitcast,
  truncate, flush_stdout) is unchanged and queued.
- Bindings (`BINDINGS-STDLIB-WISHLIST.md`, 13:30): no new rows; W-1/W-4
  already fixed earlier today, W-2/W-3/W-5 unchanged (W-3 has the stdlib
  confinement caution; compiler B-05 owns the fix).
- Packages lane (`E:\xiom-packages\packages\docs\STDLIB-WISHLIST.md`): the
  2026-10-05 eight-row intake stands; no new rows.

Relay status 2026-10-09 (five-lane scoop, gathered by an agent; the agent
sandbox denies shell, so file mtimes are unavailable and dates below are
content-derived):

Packages source-of-record (`E:\xiom-packages\packages\docs\STDLIB-WISHLIST.md`,
370 lines, 138 data rows = +4 vs the mirrored 134):
- row 162 (`io.list_dir` broken): **RESOLVED** on the v0.64.1 archive
  (m211), re-verified natively on v0.64.2 (2026-10-09; 23 distinct entries).
- row 164 durable write path: UPDATE 2026-10-09 -- `xiom.wal` 0.1.0
  (extracted 2026-10-09) ships the documented no-op `wal_flush` with the
  call site kept, waiting on this row; still the highest-value storage ask.
- row 163 DateTime.weekday 0=Monday vs `date_day_of_week` 0=Sunday --
  open (API inconsistency).
- **NEW row 168 (2026-10-09, requester xiom.wal): `io.read_file_lines`'s
  `ensures: result is Ok => result.len() >= 1` (io.xi:1076) is FALSE for
  an empty file (Ok with zero lines)**; the consumer stays 6/6 green only
  because callers pre-check. This is our clause; fix-first candidate.
- **NEW row 169 (2026-10-09, requester xiom.http 0.1.4, repro
  `tstring-char-nul.xi`): `to_string_char(Char(0))` returns "" (C-string
  truncation) and violates its own `ensures: result.len() >= 1`**; emit
  the NUL byte or weaken the contract -- stdlib lane's call; fix-first.
- rows 165-167 (`append_file_bytes`, `truncate`/`remove_dir`, `file_lock`
  stub) still open and may account for the remaining count delta.

Bindings (`E:\xiom-packages\bindings\docs\BINDINGS-STDLIB-WISHLIST.md`,
45 lines; "stdlib response check" dated 2026-10-09):
- W-1 `fs_remove` DELIVERED (0.64.2; xiom.sqlite adoption queued).
- W-2 out-param slot helper RE-SCOPED: `SafePtr`/`FFIBuffer` already
  exist; the remaining gap is documentation plus the B-07 alias-shadowing
  caveat (open on v0.64.2).
- W-3 guard-aware `ffi.free` open; B-05 re-verified on v0.64.2 (6.9 CPU-s
  in 8 s, flat ~4.5 MB); the compiler relay confirms runtime/stdlib side.
- W-4 stale cast note DELIVERED (0.64.2).
- W-5 `Vec[UInt8].with_len(n)` open; re-checked 2026-10-09 on stdlib
  0.64.3: `xiom.mem.zeroed[T]` exists but is a zero-memory value, not a
  sized buffer; no `with_len`/`filled` anywhere. Scheduled candidate.
- Pin matrix: 19 suites green on v0.64.2, no stdlib regressions. The
  sibling copy at
  `E:\xiom-packages\packages\docs\BINDINGS-STDLIB-WISHLIST.md` is the
  older 35-line variant (v0.64.2 repin: B-01 m231 and B-08 m228 FIXED,
  workarounds droppable); the `bindings\docs` copy is newer.

PULSE (`E:\xiom-projects\xiom-pulse\docs\STDLIB-WISHLIST-PULSE.md`,
179 lines):
- **NEW ASK (wrap 8, 2026-10-09): address-aware socket bind** --
  `PULSE_BIND=127.0.0.1` currently binds `0.0.0.0` because `socket_bind`
  is wildcard-only; ask for `xiom_socket_bind_addr(sock, host: *UInt8,
  port)` or an extended `socket_bind` that parses IPv4/IPv6; "not in
  v0.64.2; still awaited" (runtime-backed primitive + stdlib wrapper).
- **NEW (wrap 8b, 2026-10-09): macOS runtime-C build blockers** --
  `runtime/xiom_runtime.c:4222` uses `_SC_AVPHYS_PAGES` (Linux-only; needs
  `#ifdef __APPLE__`) and `runtime/fp128_helpers.c` compiles x86 inline
  asm (`leaq`/`movq`) on arm64 (needs a `__x86_64__` guard). Runtime-C
  fix-first (macOS lane).
- **NEW ASK (wrap 4b, 2026-10-08): `socket_recv_into(fd, &mut
  Vec[UInt8], max)`** for reusable caller buffers.
- Defect (wrap 4b): `read_file_lines("/proc/self/status")` trips its own
  `ensures: result.len() >= 1` because /proc files stat as size 0 -- read
  until EOF for the non-regular case or document regular-files-only (same
  family as packages row 168).
- `signal_handle`/`signal_pending` still shown open on the PULSE list (no
  PULSE-side confirmation yet of the stdlib Err-stub landing recorded
  2026-10-08); `socket_set_timeout`/`socket_reuse_addr` remain
  documented-Err stubs; `flush_stdout` still empty (io.xi:903).

ORBITDB (relay 64 lines stops at the 2026-10-08 update; full table
`STDLIB-WISHLIST-ORBITDB.md` 69 lines pinned 2026-10-09, compiler v0.64.2,
stdlib 82ac2f3):
- **RESOLVED: `str_split`/`read_file_lines` O(n^2)** -- WAL replay of 20k
  records 61.6 s -> 9.9 s on v0.64.2 ("every line-oriented consumer is
  linear now"). **RESOLVED: CRLF handling.**
- Open (no new rows): real `fsync` (stub surface at fs_ffi.xi:238 and
  sync_io.xi:80), `io.open_append` (append still open/close-bound;
  3,524 ops/s), `truncate_file`, byte read/write/append-bytes,
  `append_line_sync`, `file_last_byte`/`ends_with_newline`.
- Acknowledges our 82ac2f3 sweep; tracks the three new rows (empty-read
  clause, `to_string_char(Char(0))`, whole-body cast miscompile) as
  non-blockers for ORBITDB today.

XVECTOR (`STDLIB-WISHLIST-XVECTOR.md` 45 lines + `RELAY-STDLIB.md`
addendum, re-checked 2026-10-09 on stdlib 0.64.3 / compiler v0.64.2): all
six rows STILL OPEN -- `fsync`/`fdatasync` stubs (fs_ffi.xi:238/:246), the
whole `sync_io` fd path stubbed (write_all:28, sync_fd:80, fsync_dir:88),
no `append_file_bytes`, `truncate`/`ftruncate` stubs (:151/:160), no
`f32_bits`/`bits_to_f32` (Float64 pair only, float.xi:43/:52),
`flush_stdout` empty (io.xi:906). Critical pair narrowed to fsync +
append-bytes; "one primitive unblocks three consumers" (`xiom.wal` gated
too); `io.rename` covers atomic checkpoints meanwhile. Status change:
XVC-C-11/C-12 (read_file Str-content + tiny-read) were compiler-lowering
bugs FIXED in compiler v0.64.2 -- no stdlib action; byte-file APIs are
byte-exact/CRLF-clean since 0.64.2.

Consolidated new actionables from this sweep: stdlib features -- address-
aware socket bind, `socket_recv_into`, `Vec[UInt8].with_len`; runtime-C --
macOS guards (`_SC_AVPHYS_PAGES`, fp128 asm), B-05 guard-heap spin,
fsync/append-bytes; defects (fix-first, wave 98) -- `read_file_lines`
empty-file ensures (io.xi:1076), `to_string_char(Char(0))` (packages row
169). The compiler-relay drops (x5 lane dirs) carry the same B-05
runtime-side and triplicate-sibling notes recorded in block 83.

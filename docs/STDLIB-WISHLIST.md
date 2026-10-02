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

Four relays from the packages lane: the initial batch named 8 rows
(rows 1-8), the wave-46 batch added rows 9-15 with requester lists, the
2026-10-02 morning batch added rows 16-21, and the 2026-10-02 afternoon
batch adds rows 22-32 (compress.zip, deflate dynamic-Huffman reads +
public tables, neutral CRC32, Keccak-256, the `_u64_lshr` defect,
fixed-point log2 + integer stats, strict `str_to_int`, XML tokenizer,
UTF-8 code-point helpers, and the extended requester lists for
`rand.state` and `encoding.le`). The full sheet (wave 43-46 rows and
requester lists) lives in `xiom-packages/packages` at commit `66f26e1`;
the packages lane offered to forward the whole file. The empty-needle
defect (row 1) is acknowledged FIXED in the packages sheet; their
`compliance` package keeps its short-circuit workaround until the next
stdlib release. The packages lane's other notes (catalog bugs obs-fold
trimming and `max-age=abc` were package-side; `str_replace_all` proved
useful for policy rewriting; avoid `==` on Result values in tests -- no
guaranteed `Eq`) need no stdlib action beyond row 1.

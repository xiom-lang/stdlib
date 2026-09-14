# STDLIB Dedup Inventory -- Twin Module Consolidation Plan

**Status:** UNBLOCKED (compiler round-22 m62 delegation fix, 71fcf6f5);
execution STARTED 2026-09-10. Progress log below.
**Source:** stdlib audit 5.1/5.4 + this session's verification pass.
**Rule:** keep the RICHER implementation canonical when the table's
direction disagrees with reality; every shim ships with a parity smoke.

## Progress log (2026-09-10)

DONE:
- `memory/rc.xi` -> `rc/rc.xi` (d15f5390): directory==module fix; rc
  family smokes (6) green.
- `misc/soundex.xi` -> delegating shim over `text.similarity.soundex`
  (d15f5390). Full 6-fn surface preserved; pre-1.0 empty-string alignment
  ("0000" -> canonical "") documented; locked by
  smoke_misc_soundex_parity. NOTE: the table's direction (canonical =
  string.soundex) was stale -- string/soundex was ALREADY a shim for
  text.similarity; the 150-line misc duplicate was the remaining twin.
- `string/glob.xi` -> delegating shim over `misc/glob.xi` (dd174986).
  Canonical is misc.glob (9 fns incl. escape/translate/compile), not
  string.glob as the table said; 15-vector parity probe identical; locked
  by smoke_string_glob (extended with the class-literal vectors).
  HARDENED 1e099b84: the shim originally omitted `use xiom.misc.glob;`
  (the only shim without it) and crashed deps of any consumer that
  imported only the shim (0xC0000409) -- see R9. All shims now import
  their target. The dual-path parity smoke was retired (dual-module
  full-path calls are unsafe while R9 is open; parity style = twin vs
  vectors, per kat_convert_base64_parity).
- LEGACY QUARANTINE (2026-09-12): `crypto/{des,md5,sha}.xi` ->
  `crypto/legacy/` with physical-location headers. Module names FROZEN for
  the api_freeze gate (`xiom.des` / `xiom.crypto.md5` / `xiom.crypto.sha`),
  so imports are unchanged; docs/STDLIB_MANIFEST.md paths synced. Verified
  by p_legacy_modules + the 41-file crypto battery (all green).
- NAMESPACE WAVE 1 (2026-09-12): the 61 `xiom.collect.*` modules moved from
  `stdlib/xiom/collections/` to `stdlib/xiom/collect/` (directory==module);
  the `xiom.collections` aggregate stays at `collections/collections.xi`.
  Manifest + NAMING_CONVENTIONS/SCALING_ARCHITECTURE synced; 100/100
  container smokes green. Memory quartet (alloc/cell/mem/ptr) still queued.
- ENDIAN TRIO UNIT (2026-09-12): `xiom.convert.endian` converted to a thin
  delegating shim over `xiom.serialize.endian` (writers/readers) +
  `xiom.bits.byte_swap64` (swap primitive). The 8-byte Int forms stay as
  the frozen legacy surface; parity pinned twin-vs-vectors by
  smoke_convert_endian (short 1..7-byte reads, >8-byte/empty -> 0,
  negative two's-complement, round-trips added). `xiom.bits.endianness`
  stays the primitive module (not a twin of the public conversion API).
- IP4/IP6 AUDIT (2026-09-12): NOT a blind shim. `net/ip4` and `net/ip6`
  expose Result + Vec[UInt8] surfaces; canonical `net/ip` is Option-based
  (Vec[UInt8] v4 / Vec[UInt16] v6 + IpAddr + masking/subnet). Delegation
  needs an API translation pass; queued as its own unit with a
  twin-vs-vectors lock.
- ASCII85 DIRECTION CORRECTED (2026-09-12): the pair is ALREADY layered --
  `xiom.encoding.ascii85` imports `xiom.convert.ascii85.to_ascii85/
  from_ascii85` (different names, so no R15 collision) and adds the
  str/delimiter wrappers. Canonical = convert.ascii85; encoding is the
  public wrapper layer. No action needed; inventory table direction was
  stale (4th stale direction after soundex, glob, endian).
- ENCODING FAMILY R15-GATED (2026-09-12): convert.base32 vs
  encoding.base32, convert.percent vs encoding.percent, and
  convert.punycode vs encoding.punycode share BOTH the module leaf and
  the fn names, which trips R15 (leaf-qualified codegen key collision).
  Round-56 re-test: the crash became a SILENT EMPTY return for the
  same-name fns (differently-named legs like base32hex_* work), so the
  gate stands -- probes p_b32_s5a/s5b + reverted shim recorded in
  COMPILER_BUGS R15. Round-58 re-test (a07507c4, target_r40):
  Str-returning legs now correct, but Result-returning legs still yield
  an empty-payload Err to the shim consumer (unstable across program
  shapes) and the smoke AVs -- recorded as COMPILER_BUGS R20. The gate
  therefore stands for base32/percent/punycode (all expose Results).

PARITY-SMOKE CONVENTION (hardened by R9): a shim's lock compares the twin
against official/expected vectors with the twin imported + alias calls;
do NOT write side-by-side calls to two modules in one smoke until R9 is
fixed.

ALREADY DONE before this session (verified):
- `string/levenshtein.xi` delegates to `misc.levenshtein_distance`
  (canonical = misc.levenshtein, table direction stale).
- `string/soundex.xi` delegates to `text.similarity.soundex`.
- `convert/duration.xi` delegates to xiom.time (function-name mapping).
- `convert/endian.xi` delegates swap primitives to bits.byte_swap64.

DEFERRED / CORRECTED:
- `convert/json.xi`: inventory said "json heap cluster must land first" --
  confirmed: json heap Part 1 (298ba5af) fixed
  smoke_stress_serialize_json_parse_valid only; the other json smokes
  (nested/parse_nested/jsonvalue_get/kat_minimal) still AV. Shim AFTER
  Part 2. NOTE: convert/json's header still names BUG 25 #1 (same-name
  delegation miscompiles) as the reason it was copied -- that note is
  obsolete; update when shimming.
- geom mat/matrix, vec/vector, quat/quaternion: NOT pure rename pairs --
  the short-name modules are distinct APIs (mat_* / vec_* / quat_* over
  Vec[Vec[Float64]], 554+204+144 lines) while the long-name modules carry
  the Mat2/3/4 typed domain. Consolidation needs an API translation pass;
  plan as its own unit (do not blind-shim).
- `bits/endian + convert/endian + serialize/endian`: three-way merge onto
  serialize.endian still open (convert side partially delegated).
- `net/ip4+ip6`, base32/ascii85/percent/punycode twins, io/console vs
  os/terminal/os/term, core/platform vs os/platform: future units --
  audit surfaces first (reality has disagreed with the table 3/3 times so
  far; verify before choosing a canonical).

## Convention for consolidation

For each pair: keep ONE canonical module (best surface + test coverage),
move the twin to a thin re-export shim (`pub use`-equivalent delegation)
marked DEPRECATED, keep both import paths working until 1.0. Every shim
needs a smoke asserting parity on shared surface (see
kat_convert_base64_parity.xi as the template).

## Inventory

| Pair (twin A / twin B) | Canonical | Rationale | Shim notes |
|---|---|---|---|
| encoding/base64 / convert/base64 | encoding.base64 | 8+ fns incl url/padded vs 4 | convert shim keeps 4-fn surface |
| convert/base32 / encoding/base32 | encoding.base32 | hex variant present | verify fn-name diff first |
| convert/ascii85 / encoding twin | encoding side | same pattern | audit count |
| convert/percent / net/percent | net.percent | transport-adjacent | confirm both surfaces |
| encoding/punycode / convert twin | encoding.punycode | RFC vectors green there | - |
| serialize/json / convert/json | serialize.json | richer surface | json heap cluster must land first |
| bits/endian, convert/endian, serialize/endian | serialize.endian | newest | three-way merge |
| string glob / misc/glob | string.glob | co-locate with text tools | - |
| string soundex / misc/soundex | string.soundex | same | - |
| string levenshtein / misc twin | string.levenshtein | same | - |
| net/ip4+ip6+ip | net.ip | one family module | ip4/ip6 re-export |
| net/url twins | net.url | - | confirm which is canonical |
| time/duration / convert/duration | time.duration | domain owner | - |
| time/date / convert/date | time.date | same | - |
| io/fs / os/fs / os/fs_ffi | io.fs | public facade; os/fs_ffi stays private impl | fs_ffi NOT deprecated (impl detail) |
| io/console / os/terminal / os/term | os.terminal | richest surface | audit before choosing |
| core/platform / os/platform | os.platform | runtime-backed | - |
| geom mat/matrix vec/vector quat/quaternion | *long names* | match user expectations from other langs | pure rename pair |
| memory/rc (declares xiom.rc!) / callers using xiom.rc | xiom.rc name | existing smokes bind it | fix directory==module violation by MOVING file to rc/ |

## Verified-diverged pairs (fix content BEFORE shimming)

- base64: convert twin lacks url alphabet + unpadded forms (4 vs 8+ fns) --
  parity locked by kat_encoding_base64_rfc4648 + kat_convert_base64_parity.
- rc: memory/rc.xi works via method-call shapes only; prefix-call generic
  methods garble receivers (compiler bug 3b.5). Consolidation must preserve
  the method-call surface.
- deflate bare-name binding hazard: after consolidation, ALL internal calls
  must be module-prefixed (bare names have bound wrong overloads).

## Execution checklist (per pair)

1. Confirm both twins' full public surfaces are represented in smokes/KATs.
2. Fix content drift against the canonical.
3. Land compiler delegation fix (their side).
4. Convert twin to shim; run FULL sweep; expect zero deltas beyond shim
   smoke additions.
5. Mark shim headers DEPRECATED with migration note.

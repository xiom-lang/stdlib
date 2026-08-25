# STDLIB Dedup Inventory -- Twin Module Consolidation Plan

**Status:** prepared; execution BLOCKED on the compiler's same-name
delegation crash (see REPORT_TO_COMPILER_SESSION.md section 1).
**Source:** stdlib audit 5.1/5.4 + this session's verification pass.
**Rule:** do NOT execute any rename/re-export here until the crash is fixed;
renames hit the identical crash family.

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

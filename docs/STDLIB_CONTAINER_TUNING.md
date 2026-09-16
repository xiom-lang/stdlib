<!--
Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# STDLIB Container Tuning -- Documented Guarantees

**Status:** factual documentation of current behavior (phase E4) -
**Created:** 2026-08-25
Sources: collections/collections.xi (Vec family), collections/map.xi
(IntMap). Where behavior is currently UNSPECIFIED this doc says so
explicitly rather than promising.

## Vec[T] (collections.xi raw-buffer family)

- Initial capacity 4; growth DOUBLES (`new_cap = cap * 2`, floor 4).
- Reserve-style growth rounds up to the next power-of-two >= needed.
- Amortized O(1) push; O(n) insert/remove middle.
- Backing via realloc; pointers into the vector are INVALIDATED by any
  growth -- do not hold `data` across pushes.
- No shrink-to-fit today; capacity is monotonic.

## IntMap / hash maps (map.xi)

- Open addressing, LINEAR probing, tombstone deletion (state array:
  0 empty / 1 occupied / 2 tombstone).
- Initial capacity **16**; doubles when load factor exceeds **0.75**
  (`needs_grow`); grow re-inserts live entries, clears tombstones.
- Lookup cost degrades linearly with tombstone density between grows;
  heavy delete+insert workloads may need an explicit rehash API
  (TODO: map_rehash) -- not present yet.

## Iteration order -- UNSPECIFIED BY DESIGN (until further notice)

- Hash-map iteration order is implementation-defined: it depends on the
  hash function, table capacity history, and deletion pattern. Code MUST
  NOT depend on it. Sorted output requires explicit sorting.
- As of 2026-09-12 StringMap (xiom.collect.stringmap) uses a per-process
  OS-ENTROPY-SEEDED SipHash key, so its bucket assignment -- and therefore
  iteration order -- VARIES run-to-run by design. Do not rely on run
  determinism anywhere; seed randomization (hash-DoS hardening, audit
  phase E4) is now the default for Str-keyed maps.
- Vec/lz77/token streams are ordered by construction.

## Hash-DoS posture (DELIVERED 2026-09-12)

`xiom.collect.stringmap` now defaults to seeded SipHash-2-4:
- `xiom.hash.siphash.siphash24_str_seeded` lazily draws a 16-byte key from
  the runtime OS entropy source (`xiom_os_entropy`: ProcessPrng /
  RtlGenRandom / /dev/urandom) once per process.
- Degraded fallback (no OS entropy source answering): a time-derived key --
  still per-process variable, but PREDICTABLE; treat untrusted-key maps as
  theoretical-targets in that environment.
- The core hashes Str inputs with zero copies (pointer+len signature;
  reference vectors re-verified byte-exact: key 00..0f ->
  0x726FDB47DD0E0E31 / 0x2BA3E8E9A71148CA).
- `siphash24`/`siphash13`/`siphash24_zerokey` remain available with
  explicit keys for MAC-style use.
- Open (separate unit): the generic `HashMap[K,V]` in collections.xi still
  hashes via the legacy free `hash` helpers -- its Str-key support and a
  seed rollout there are future work.

## Guidance for new container code

1. Double-with-floor-4 for capacity growth unless measurements say
   otherwise; document deviations at the type.
2. Every container exposing iteration must state ordering semantics in its
   header comment.
3. Every decoder/builder must bound output (see compress caps convention).

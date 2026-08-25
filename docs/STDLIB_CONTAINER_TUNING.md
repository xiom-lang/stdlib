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
- There is NO keyed/hash-seed randomization in the default hasher today,
  so iteration order is currently DETERMINISTIC across runs -- do not rely
  on that either; seed randomization (hash-DoS hardening, audit phase E4)
  will deliberately change order run-to-run when it lands.
- Vec/lz77/token streams are ordered by construction.

## Hash-DoS posture (planned)

The hash package contains a keyed siphash candidate. Plan: make a seeded
siphash the DEFAULT Map hasher for Str keys (per-process random key),
keeping the fast identity hash opt-in for trusted workloads. Until then,
untrusted-key hash maps are theoretically collidable by design.

## Guidance for new container code

1. Double-with-floor-4 for capacity growth unless measurements say
   otherwise; document deviations at the type.
2. Every container exposing iteration must state ordering semantics in its
   header comment.
3. Every decoder/builder must bound output (see compress caps convention).

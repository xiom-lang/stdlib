# Same-leaf public type conflicts (R44 class)

Public-type leaves are declared with **different shapes** in two or more
stdlib modules. Codegen injects `%struct.<Leaf>` / enum tags by bare leaf, so
different shapes under one leaf can clobber each other's fields. This is
exactly how `net.net.HttpResponse` (2 fields) vs `net.http.HttpResponse`
(3 fields) broke `http_parse_response`.

**STATUS 2026-09-18: 0 conflicts.** All 16 original groups are resolved
stdlib-side (renames in `tools/same_leaf_audit.ps1` batches 1-5) or
reclassified by the audit parser fix for inline bodies:

| Leaf | Resolution |
|---|---|
| `HttpResponse` | `net.net` renamed `NetHttpResponse` (2026-09-17) |
| `PHeap` | `collect/priority.xi` renamed `IntMaxHeap` |
| `SpscRing` | `collect/ring.xi` renamed `RingBuffer` |
| `IntervalTree` | `collect/range.xi` renamed `IntervalSet` |
| `UnionFind` | `collect/graph.xi` renamed `GraphUnionFind` |
| `IntMap` | `collect/map.xi` renamed `HashIntMap` |
| `StringMap` | `collect/intmap.xi` renamed `OrderedStringMap` |
| `Graph` | `math/graph_theory.xi` renamed `WeightedGraph` |
| `Executor` | `async/async.xi` renamed `AsyncExecutor` |
| `Future` | `async/timer.xi` renamed `TimerFuture` |
| `FloatScan` | `format/fmt.xi` renamed `FormatFloatScan` |
| `Aabb`/`Sphere`/`Ray` | `geom/collision.xi` renamed `CollisionAabb`/`CollisionSphere`/`CollisionRay`; `geom/geom.xi` keeps the Vec3 core types |
| `Sphere`/`Plane` | `geom/geometry_3d.xi` renamed `Sphere3d`/`Plane3d` (smoke_geom_3d.xi now constructs them directly instead of working around the shadowing) |
| `Regex`/`Match` | `regex/engine.xi` vs `regex/regex.xi` were shape-identical; the old audit counted the one-line body as a single field. Parser fixed: `Split-BodyItems` splits on `;`/newline and top-level commas with bracket depth tracking |

- Generated evidence: `docs/baselines/same-leaf-conflicts.md`
  (reproduce with `tools/same_leaf_audit.ps1`; conflicts list is now empty).
- Compiler-side context and the failed wholesale-qualification experiment:
  `docs/COMPILER_BUGS.md` R44 in the compiler repo.
- The remaining multi-declaration leaves are **shape-identical** after syntax
  normalization (`Vec<...>` vs `Vec[...]` etc.) -- benign for codegen, but
  still dedup candidates (e.g. `JsonValue` is the same enum in
  `serialize/json.xi` and `serialize/serialize.xi`).

## Rules for the slice (kept for future regressions)

1. **Do not blind-rename**: some leaves are semantically distinct types that
   happen to share a name; each group's owner module decides rename vs merge.
2. Every change is a public-API change: batch it with the compiler
   `api_freeze` snapshot regen (the freeze test is already red on other
   items).
3. After each batch: `tools/same_leaf_audit.ps1` must show the group count
   dropping, `tools/check_modules.ps1` must stay 509/509, and the corpus
   battery must stay green (the R44 experiment showed qualification alone
   breaks smokes until the conflicts are dedup'd).

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

## Same-leaf *function* annotations (2026-11-03)

A distinct collision was found in the gate-9 / 1704 ownership-contract work:
the annotation maps (`owns_return`, `consumes_agg`, `borrows_vec`,
`borrows_str`, `owns_str`) are keyed by **leaf function name**, not by a
module-qualified declaration. `json_parse` is declared in both
`xiom/serialize/json.xi` (`Result[JsonValue, Str]`) and
`xiom/serialize/serialize.xi` (`Result[JsonValue, SerializeError]`). With
both carrying `#[owns_return]`, the compiler applies one declaration's
return layout to calls of the other.

Evidence (compiler main WIP, single-tree install roots):

- Both annotated: the gate probe looks "flat" (5.6 / 5.6 / 9.3 MB at
  10k / 20k / 100k) but a nested-scope `json_parse` binding fails to
  compile with `Instruction does not dominate all uses!`.
- `serialize.serialize.json_parse` unannotated: the nested repro compiles
  and runs, and the gate is 25.3 / 44.7 / 205.4 MB (2.0 KB/iter, parse
  tree). The "flat" number was therefore the collision, not a reclaim.
- `serialize.serialize.json_parse` with `#[owns_return]` only: the nested
  repro fails again and the gate is flat (5.8 / 6.1 / 12.3).

Same class: `json_escape` (`#[owns_str]` in `serialize/json.xi`,
`serialize/serialize.xi`, `convert/json.xi`, `log/json.xi`) and `build`
(`JsonObjectBuilder.build` / `JsonArrayBuilder.build`, both
`#[consumes_agg]`).

This is compiler-side annotation resolution, not a type-shape conflict, so
the type-level conflict count above stays at 0. Item:
REL-20261103-1557-stdlib (correction to 1551).

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

# Same-leaf public type conflicts (R44 class)

Public-type leaves are declared with **different shapes** in two or more
stdlib modules. Codegen injects `%struct.<Leaf>` / enum tags by bare leaf, so
different shapes under one leaf can clobber each other's fields. This is
exactly how `net.net.HttpResponse` (2 fields) vs `net.http.HttpResponse`
(3 fields) broke `http_parse_response`; the legacy net.net type was renamed
`NetHttpResponse` on 2026-09-17 and the priority-queue `PHeap` twin was
renamed `IntMaxHeap` on 2026-09-18, leaving **15 conflicts**. The generated
audit (`docs/baselines/same-leaf-conflicts.md`) is the count of record.

- Generated evidence: `docs/baselines/same-leaf-conflicts.md`
  (reproduce with `tools/same_leaf_audit.ps1`).
- Compiler-side context and the failed wholesale-qualification experiment:
  `docs/COMPILER_BUGS.md` R44 in the compiler repo.

## Groups

| Leaf | Modules (declaring) | Suggested disposition |
|---|---|---|
| `Executor` | `async/async.xi`, `async/executor.xi` | dedup executor family (pick one owner) |
| `Future` | `async/io.xi`, `async/timer.xi` | keep both; rename one leaf (domain-specific) |
| `Graph` | `collect/graph.xi`, `math/graph_theory.xi` | dedup graph family |
| `UnionFind` | `collect/graph.xi`, `collect/unionfind.xi` | dedup (one owner) |
| `PHeap` | `collect/priority.xi`, `collect/heap.xi` | **RESOLVED 2026-09-18:** `priority.xi` renamed its type `IntMaxHeap` (binary max-heap queue); `heap.xi` keeps the production pairing-heap `PHeap` that `bheap.xi`/`pairingheap.xi` delegate to |
| `IntervalTree` | `collect/range.xi`, `collect/interval.xi` | dedup interval family |
| `IntMap` | `collect/map.xi`, `collect/intmap.xi` | dedup map family |
| `StringMap` | `collect/stringmap.xi`, `collect/intmap.xi` | dedup map family |
| `SpscRing` | `collect/ring.xi`, `collect/queue.xi` | dedup ring twin |
| `FloatScan` | `format/fmt.xi`, `string/scanf.xi` | rename one leaf (scanner twins) |
| `Aabb` | `geom/collision.xi`, `geom/geom.xi`, `geom/geometry_3d.xi` | dedup into the geom core |
| `Sphere` | `geom/collision.xi`, `geom/geom.xi`, `geom/geometry_3d.xi` | dedup into the geom core |
| `Ray` | `geom/collision.xi`, `geom/geom.xi`, `geom/geometry_3d.xi` | dedup into the geom core |
| `Plane` | `geom/geom.xi`, `geom/geometry_3d.xi` | dedup into the geom core |
| `Regex` | `regex/engine.xi`, `regex/regex.xi` | dedup regex family |
| `Match` | `regex/engine.xi`, `regex/regex.xi` | dedup regex family |

24 further multi-declaration leaves are **shape-identical** after syntax
normalization (`Vec<...>` vs `Vec[...]` etc.) -- benign for codegen, but
still dedup candidates (e.g. `JsonValue` is the same enum in
`serialize/json.xi` and `serialize/serialize.xi`). The audit separates the
two sets: run `tools/same_leaf_audit.ps1`.

## Rules for the slice

1. **Do not blind-rename**: some leaves are semantically distinct types that
   happen to share a name; each group's owner module decides rename vs merge.
2. Every change is a public-API change: batch it with the compiler
   `api_freeze` snapshot regen (the freeze test is already red on other
   items).
3. After each batch: `tools/same_leaf_audit.ps1` must show the group count
   dropping, `tools/check_modules.ps1` must stay 509/509, and the corpus
   battery must stay green (the R44 experiment showed qualification alone
   breaks smokes until the conflicts are dedup'd).

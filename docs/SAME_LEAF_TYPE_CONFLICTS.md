# Same-leaf public type conflicts (R44 class)

Public-type leaves are declared with **different shapes** in two or more
stdlib modules. Codegen injects `%struct.<Leaf>` / enum tags by bare leaf, so
different shapes under one leaf can clobber each other's fields. This is
exactly how `net.net.HttpResponse` (2 fields) vs `net.http.HttpResponse`
(3 fields) broke `http_parse_response`.

**STATUS 2026-11-07: 0 conflicts.** The clean state regressed when
`thread/pool.xi` added a 10-field `ThreadPool` alongside the 7-field
`collect/threadpool.xi` type. The collect type is renamed
`CollectThreadPool`; `thread.pool.ThreadPool` remains canonical (richer).
Re-audit: 355 declarations, 23 multi-declaration leaves, 0 shape conflicts.

**STATUS 2026-09-18 (historical): 0 conflicts.** All 16 original groups are
resolved stdlib-side (renames in `tools/same_leaf_audit.ps1` batches 1-5) or
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
| `ThreadPool` | `collect/threadpool.xi` renamed `CollectThreadPool` (2026-11-07); `thread.pool.ThreadPool` (10 fields) is canonical |
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

The gate-9 / 1704 ownership-contract work exposed two separate interactions
between same-leaf functions and annotations. Only one is a defect.

1. **Defect (compiler codegen):** when the `#[owns_return]` contract is
   active, a Result bound inside a **nested block** gets its drop `alloca`
   after its GEP uses -> `Instruction does not dominate all uses!`.
   Top-level bindings and `match` compile; nested `let`/`var` fail.
   Repro: `let s = "{\"a\":1}"; if s.len() > 0 { let r = json_parse(s);
   if r.is_ok { return 0; } }`. The reclaim itself works (gate flat at
   5.5 / 5.0 / 9.4 MB at 10k / 20k / 100k). Item REL-20261103-1626-stdlib.
2. **Masking rule (not a defect):** `collect_fresh_enum_tree_returns`
   groups by leaf and rejects the whole leaf if any same-named declaration
   lacks `#[owns_return]`. `json_parse` is declared in both
   `xiom/serialize/json.xi` (annotated, `Result[JsonValue, Str]`) and
   `xiom/serialize/serialize.xi` (annotated, `Result[JsonValue,
   SerializeError]`); making the latter unannotated disables the contract,
   which makes the nested repro compile again and the gate leak
   2.0 KB/iter. Renaming the duplicate does **not** fix (1), so qualified
   annotation keys are not the fix.

Same-leaf `#[owns_str]` functions (`json_escape` in four modules) and
`#[consumes_agg]` builders (`build` in both JSON builder types) follow the
same conservative group rule; no defect has been attributed to them.

This is compiler-side annotation codegen, not a type-shape conflict, so the
type-level conflict count above stays at 0.

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

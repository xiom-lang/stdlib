// p_polyhedra_nested_hull.xi -- KNOWN FAILURE (compiler v0.61.3 + v0.62.1, 2026-10-02)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// xiom.geom.polyhedra.convex_hull_2d and convex_hull_3d collapse on the
// current pins: the hull of a 4-point square is 2 rows (expected 4) and the
// hull of a non-coplanar tetrahedron is 0 rows (expected 4), while the
// empty-input paths correctly return 0. The bodies already use the
// documented local-copy workaround for by-ref nested float Vec reads
// (BUG 26 #1), so the workaround is insufficient for these reads on
// v0.61.3 and v0.62.1; caller- and callee-side length reads agree (2/2, 0),
// i.e. the result itself is collapsed, not just misread.
// Expected: convex_hull_2d(square) == 4 and convex_hull_3d(tetra) == 4, so
// the program returns 0. Observed: returns 1 (and would return 2 for the
// 3D case).
// Found while landing the wave-53 geom clauses (2026-10-02); the wave-53
// probe keeps only the empty-input hull checks. geometry_2d.convex_hull
// (Point2 rows, no nested float Vecs) is correct and covered by wave 52.
//
// Stdlib impact: callers must not use polyhedra.convex_hull_2d/3d for
// nonempty inputs until the nested-read class is fixed.

module p_polyhedra_nested_hull

use xiom.geom.polyhedra;

fn mkvec(a: Float64, b: Float64, c: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  out.push(a);
  out.push(b);
  out.push(c);
  return out;
}

fn main() -> Int {
  var sq = Vec[Vec[Float64]].new();
  sq.push(mkvec(0.0, 0.0, 0.0));
  sq.push(mkvec(2.0, 0.0, 0.0));
  sq.push(mkvec(2.0, 2.0, 0.0));
  sq.push(mkvec(0.0, 2.0, 0.0));
  if polyhedra.convex_hull_2d(&sq).len() != 4 { return 1; }
  var t3 = Vec[Vec[Float64]].new();
  t3.push(mkvec(0.0, 0.0, 0.0));
  t3.push(mkvec(1.0, 0.0, 0.0));
  t3.push(mkvec(0.0, 1.0, 0.0));
  t3.push(mkvec(0.0, 0.0, 1.0));
  if polyhedra.convex_hull_3d(&t3).len() != 4 { return 2; }
  return 0;
}

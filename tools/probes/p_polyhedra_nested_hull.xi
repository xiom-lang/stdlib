// p_polyhedra_nested_hull.xi -- regression lock: polyhedra nonempty-hull reads
// (REL-20261010-1549-stdlib; promoted from tools/known_failures 2026-10-16)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the class fixed by the m276-m327 batch (no single commit claims it):
// convex_hull_2d/3d collapsed on nonempty inputs -- the hull of a 4-point
// square was 2 rows (expected 4) and a non-coplanar tetrahedron 0 rows
// (expected 4) -- while the empty-input paths were always correct. The
// bodies already used the documented local-copy workaround for by-ref
// nested float Vec reads, so the workaround was insufficient; the result
// itself was collapsed (caller/callee length reads agreed).
// Expected: convex_hull_2d(square) == 4 and convex_hull_3d(tetra) == 4, so
// the program returns 0. Green 5/5 on the official v0.64.5 release archive
// (v0.64.4-rel control 5/5 rc 1). The wave-53 probe keeps only the
// empty-input hull checks; this lock carries the nonempty rows.
// Historical context: found while landing the wave-53 geom clauses
// (2026-10-02); geometry_2d.convex_hull (Point2 rows, no nested float Vecs)
// was correct and covered by wave 52.

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

// p_polygon_difference_halfplanes.xi -- KNOWN FAILURE (stdlib algorithm bug,
// 2026-10-01) -- RESOLVED 2026-10-12 (wave 116) and PROMOTED to tools/probes.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// xiom.geom.geometry_2d.polygon_difference clipped the subject against the
// OUTSIDE of every edge of b, which intersects b's outside half-planes
// instead of taking the union of them: for any closed b the intersection is
// usually empty, so a minus b returned None even when a and b are disjoint.
// Found by the wave-52 probe; the existing smoke never exercised the
// polygon booleans.
// Expected: polygon_difference(a, b) is Some for disjoint a and b.
// RESOLVED 2026-10-12 (wave 116): the difference now routes through the
// intersection test first -- an empty intersection returns Some(a) exactly
// (both orders); empty-a (None), empty-b (Some(a)) and a-inside-b (None)
// stay exact; overlapping/containment inputs keep the documented
// conservative approximation (a real polygon-clipping implementation with
// holes/slits remains a queue follow-up). rc 0 on the v0.64.4-rel pin; the
// disjoint/edge/inside cases are additionally locked by
// tools/probes/p_wave116_shapes.xi.

module p_polygon_difference_halfplanes

use xiom.geom.geometry_2d;
use xiom.geom.geometry_2d.Point2;
use xiom.geom.geometry_2d.Polygon2;

fn p2(x: Float64, y: Float64) -> Point2 {
  return Point2{ x: x; y: y; };
}

fn main() -> Int {
  var av = Vec[Point2].new();
  av.push(p2(0.0, 0.0));
  av.push(p2(2.0, 0.0));
  av.push(p2(2.0, 2.0));
  av.push(p2(0.0, 2.0));
  var a = Polygon2{ vertices: av; };
  var bv = Vec[Point2].new();
  bv.push(p2(5.0, 5.0));
  bv.push(p2(6.0, 5.0));
  bv.push(p2(6.0, 6.0));
  bv.push(p2(5.0, 6.0));
  var b = Polygon2{ vertices: bv; };
  // Disjoint: a minus b is a (Some) - observed None on the pin.
  if !geometry_2d.polygon_difference(a, b).is_some { return 1; }
  return 0;
}

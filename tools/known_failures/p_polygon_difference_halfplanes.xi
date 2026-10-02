// p_polygon_difference_halfplanes.xi -- KNOWN FAILURE (stdlib algorithm bug, 2026-10-01)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// xiom.geom.geometry_2d.polygon_difference clips the subject against the
// OUTSIDE of every edge of b, which intersects b's outside half-planes
// instead of taking the union of them: for any closed b the intersection is
// usually empty, so a minus b returns None even when a and b are disjoint
// (where the documented behavior is a conservative approximation of a\b,
// i.e. Some(a)). Found by the wave-52 probe; the existing smoke never
// exercised the polygon booleans.
// Expected: polygon_difference(a, b) is Some for disjoint a and b (and the
// function needs a real polygon-clipping implementation for overlap cases).
// Observed on v0.61.3: the disjoint case returns None (this program returns
// 1); the empty-a / empty-b edges behave as documented.
// Stdlib impact: consumers must not rely on polygon_difference until the
// algorithm is replaced (queue: geom follow-up); the doc comment now states
// the limitation.

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

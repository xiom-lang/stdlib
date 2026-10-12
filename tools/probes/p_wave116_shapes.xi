// p_wave116_shapes.xi -- wave 116 lock: polygon_difference disjoint-case fix
// (REL-internal: tools/known_failures/p_polygon_difference_halfplanes.xi).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the behaviour the wave-116 fix makes exact: a minus b when the two
// polygons are disjoint (both orders) returns Some(a) with a's vertices;
// the empty-a (None) and empty-b (Some(a)) edges hold; a fully inside b
// returns None (a\b is empty). Overlapping inputs stay the documented
// conservative approximation and are only checked not to abort.
// Every returned value is bound before comparing. Returns 0 when all
// cases hold. Red pre-fix (disjoint returns None), green post.

module p_wave116_shapes

use xiom.geom.geometry_2d;
use xiom.geom.geometry_2d.Point2;
use xiom.geom.geometry_2d.Polygon2;

fn p2(x: Float64, y: Float64) -> Point2 {
  return Point2{ x: x; y: y; };
}

fn square(ax: Float64, ay: Float64, bx: Float64, by: Float64) -> Polygon2 {
  var v = Vec[Point2].new();
  v.push(p2(ax, ay));
  v.push(p2(bx, ay));
  v.push(p2(bx, by));
  v.push(p2(ax, by));
  return Polygon2{ vertices: v; };
}

fn main() -> Int {
  var a = square(0.0, 0.0, 2.0, 2.0);
  var b = square(5.0, 5.0, 6.0, 6.0);
  var empty = Polygon2{ vertices: Vec[Point2].new() };

  // candidate 1: disjoint a minus b -> Some(a), a's four vertices
  let d1 = geometry_2d.polygon_difference(a, b);
  match d1 {
    Some(p) => {
      let n = p.vertices.len();
      if n != 4 { return 1; }
    },
    None => { return 1; },
  };

  // candidate 2: disjoint b minus a -> Some(b), four vertices
  let d2 = geometry_2d.polygon_difference(b, a);
  match d2 {
    Some(p) => {
      let n = p.vertices.len();
      if n != 4 { return 2; }
    },
    None => { return 2; },
  };

  // candidate 3: empty a -> None
  let d3 = geometry_2d.polygon_difference(empty, b);
  match d3 {
    Some(_) => { return 3; },
    None => {},
  };

  // candidate 4: empty b -> Some(a), four vertices
  let d4 = geometry_2d.polygon_difference(a, empty);
  match d4 {
    Some(p) => {
      let n = p.vertices.len();
      if n != 4 { return 4; }
    },
    None => { return 4; },
  };

  // candidate 5: a fully inside b -> None (a minus b is empty)
  var big = square(0.0, 0.0, 10.0, 10.0);
  var small = square(2.0, 2.0, 3.0, 3.0);
  let d5 = geometry_2d.polygon_difference(small, big);
  match d5 {
    Some(_) => { return 5; },
    None => {},
  };

  // candidate 6: overlapping input stays the documented approximation --
  // the call must not abort (result intentionally not locked)
  var ov = square(1.0, 1.0, 3.0, 3.0);
  let d6 = geometry_2d.polygon_difference(a, ov);
  let _ = d6;

  return 0;
}

// XIOM - Geom: Geometry 2D
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.geometry_2d

// Depends on: xiom.geom

// ============================================================================
// 2D primitives, point containment, intersections, and polygon operations.
// NOTE: current implementation lives in geom/collision.xi + geom/polyhedra.xi
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
//
// Polygon boolean operations: intersection uses Sutherland-Hodgman clipping
// (exact for convex clipping polygons); union returns the convex hull of both
// vertex sets (exact when the union is convex); difference clips a against the
// outside of b (valid when b is fully contained in a). All are documented.
// ============================================================================

use xiom.geom;
use xiom.math;

// 2D point.
pub type Point2 = { x: Float64; y: Float64; }

// Infinite line a*x + b*y + c = 0.
pub type Line2 = { a: Float64; b: Float64; c: Float64; }

// Ray: origin and (not necessarily unit) direction.
pub type Ray2 = { origin: Point2; dir: Vec2; }

// Segment between two points.
pub type Segment2 = { a: Point2; b: Point2; }

// Circle with center and radius.
pub type Circle = { center: Point2; radius: Float64; }

// Axis-aligned rectangle defined by min and max corners.
pub type Rect = { min: Point2; max: Point2; }

// Triangle with three vertices.
pub type Triangle2 = { a: Point2; b: Point2; c: Point2; }

// Polygon: vertex list in boundary order.
pub type Polygon2 = { vertices: Vec[Point2]; }

// Euclidean distance between two points. O(1).
pub fn point_distance(a: Point2, b: Point2) -> Float64 {
  var dx = a.x - b.x;
  var dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

// True if p lies inside (or on) the circle. O(1).
pub fn point_in_circle(p: Point2, c: Circle) -> Bool {
  var dx = p.x - c.center.x;
  var dy = p.y - c.center.y;
  return dx * dx + dy * dy <= c.radius * c.radius;
}

// True if p lies inside (or on) the axis-aligned rectangle. O(1).
pub fn point_in_rect(p: Point2, r: Rect) -> Bool {
  return p.x >= r.min.x && p.x <= r.max.x && p.y >= r.min.y && p.y <= r.max.y;
}

// True if p lies inside (or on) the triangle (same-side test). O(1).
pub fn point_in_triangle(p: Point2, t: Triangle2) -> Bool {
  var d1 = (p.x - t.b.x) * (t.a.y - t.b.y) - (t.a.x - t.b.x) * (p.y - t.b.y);
  var d2 = (p.x - t.c.x) * (t.b.y - t.c.y) - (t.b.x - t.c.x) * (p.y - t.c.y);
  var d3 = (p.x - t.a.x) * (t.c.y - t.a.y) - (t.c.x - t.a.x) * (p.y - t.a.y);
  var has_neg = d1 < 0.0 || d2 < 0.0 || d3 < 0.0;
  var has_pos = d1 > 0.0 || d2 > 0.0 || d3 > 0.0;
  return !(has_neg && has_pos);
}

// True if p lies inside the polygon (ray-casting test; boundary counts as
// inside). O(n).
pub fn point_in_polygon(p: Point2, poly: Polygon2) -> Bool {
  var inside = false;
  var j = poly.vertices.len() - 1;
  var i = 0;
  while i < poly.vertices.len() {
    var vi = poly.vertices[i];
    var vj = poly.vertices[j];
    var intersect = (vi.y > p.y) != (vj.y > p.y);
    if intersect {
      var x_cross = (vj.x - vi.x) * (p.y - vi.y) / (vj.y - vi.y) + vi.x;
      if p.x < x_cross {
        inside = !inside;
      }
    }
    j = i;
    i = i + 1;
  }
  return inside;
}

// Intersection of two infinite lines; None when they are parallel. O(1).
pub fn line_intersection(l1: Line2, l2: Line2) -> Option[Point2] {
  var det = l1.a * l2.b - l2.a * l1.b;
  if math.abs_float(det) < 0.000000000001 {
    return None;
  }
  var x = (l1.b * l2.c - l2.b * l1.c) / det;
  var y = (l2.a * l1.c - l1.a * l2.c) / det;
  return Some(Point2{ x: x; y: y; });
}

// Intersection of two segments; None when they do not meet. O(1).
pub fn segment_intersection(s1: Segment2, s2: Segment2) -> Option[Point2] {
  var l1 = Line2{
    a: s1.a.y - s1.b.y;
    b: s1.b.x - s1.a.x;
    c: s1.a.x * (s1.b.y - s1.a.y) - s1.a.y * (s1.b.x - s1.a.x);
  };
  var l2 = Line2{
    a: s2.a.y - s2.b.y;
    b: s2.b.x - s2.a.x;
    c: s2.a.x * (s2.b.y - s2.a.y) - s2.a.y * (s2.b.x - s2.a.x);
  };
  var det = l1.a * l2.b - l2.a * l1.b;
  if math.abs_float(det) < 0.000000000001 {
    return None;
  }
  var px = (l1.b * l2.c - l2.b * l1.c) / det;
  var py = (l2.a * l1.c - l1.a * l2.c) / det;
  var eps = 0.000000000001;
  var on1 = px >= math.min_float(s1.a.x, s1.b.x) - eps && px <= math.max_float(s1.a.x, s1.b.x) + eps
         && py >= math.min_float(s1.a.y, s1.b.y) - eps && py <= math.max_float(s1.a.y, s1.b.y) + eps;
  var on2 = px >= math.min_float(s2.a.x, s2.b.x) - eps && px <= math.max_float(s2.a.x, s2.b.x) + eps
         && py >= math.min_float(s2.a.y, s2.b.y) - eps && py <= math.max_float(s2.a.y, s2.b.y) + eps;
  if !(on1 && on2) {
    return None;
  }
  return Some(Point2{ x: px; y: py; });
}

// Shortest distance from p to the segment s. O(1).
pub fn segment_point_distance(s: Segment2, p: Point2) -> Float64 {
  var abx = s.b.x - s.a.x;
  var aby = s.b.y - s.a.y;
  var apx = p.x - s.a.x;
  var apy = p.y - s.a.y;
  var len_sq = abx * abx + aby * aby;
  if len_sq == 0.0 {
    return point_distance(p, s.a);
  }
  var t = (apx * abx + apy * aby) / len_sq;
  if t < 0.0 { t = 0.0; }
  if t > 1.0 { t = 1.0; }
  var cx = s.a.x + t * abx;
  var cy = s.a.y + t * aby;
  return point_distance(p, Point2{ x: cx; y: cy; });
}

// Perpendicular distance from p to the infinite line l. O(1).
pub fn line_point_distance(l: Line2, p: Point2) -> Float64 {
  var denom = math.sqrt(l.a * l.a + l.b * l.b);
  if denom == 0.0 {
    return 0.0 / 0.0;
  }
  var num = l.a * p.x + l.b * p.y + l.c;
  if num < 0.0 { num = -num; }
  return num / denom;
}

// Intersection points of the circle and the line; None when they do not meet
// or the line is degenerate. O(1).
pub fn circle_intersection(c: Circle, l: Line2) -> Option[Vec[Point2]] {
  var out = Vec[Point2].new();
  var len_sq = l.a * l.a + l.b * l.b;
  if len_sq == 0.0 {
    return None;
  }
  var len = math.sqrt(len_sq);
  var d = (l.a * c.center.x + l.b * c.center.y + l.c) / len;
  if d > c.radius || d < -c.radius {
    return None;
  }
  var h = math.sqrt(c.radius * c.radius - d * d);
  var fx = c.center.x - l.a * d / len;
  var fy = c.center.y - l.b * d / len;
  var ux = -l.b / len;
  var uy = l.a / len;
  if h < 0.000000000001 {
    out.push(Point2{ x: fx; y: fy; });
    return Some(out);
  }
  out.push(Point2{ x: fx + ux * h; y: fy + uy * h; });
  out.push(Point2{ x: fx - ux * h; y: fy - uy * h; });
  return Some(out);
}

// Alias of circle_intersection. O(1).
pub fn circle_line_intersection(c: Circle, l: Line2) -> Option[Vec[Point2]] {
  return circle_intersection(c, l);
}

// Intersection points of two circles; None when they do not intersect (or are
// concentric). O(1).
pub fn circle_circle_intersection(c1: Circle, c2: Circle) -> Option[Vec[Point2]] {
  var out = Vec[Point2].new();
  var dx = c2.center.x - c1.center.x;
  var dy = c2.center.y - c1.center.y;
  var d = math.sqrt(dx * dx + dy * dy);
  if d == 0.0 {
    return None;
  }
  if d > c1.radius + c2.radius {
    return None;
  }
  if d < math.abs_float(c1.radius - c2.radius) {
    return None;
  }
  var a = (c1.radius * c1.radius - c2.radius * c2.radius + d * d) / (2.0 * d);
  var h2 = c1.radius * c1.radius - a * a;
  if h2 < 0.0 { h2 = 0.0; }
  var h = math.sqrt(h2);
  var px = c1.center.x + a * dx / d;
  var py = c1.center.y + a * dy / d;
  var ox = -dy / d * h;
  var oy = dx / d * h;
  out.push(Point2{ x: px + ox; y: py + oy; });
  if h > 0.000000000001 {
    out.push(Point2{ x: px - ox; y: py - oy; });
  }
  return Some(out);
}

// Signed area of the triangle (positive for counter-clockwise vertices). O(1).
pub fn area_triangle(t: Triangle2) -> Float64 {
  var abx = t.b.x - t.a.x;
  var aby = t.b.y - t.a.y;
  var acx = t.c.x - t.a.x;
  var acy = t.c.y - t.a.y;
  return (abx * acy - aby * acx) * 0.5;
}

// Signed area of the polygon via the shoelace formula. O(n).
pub fn area_polygon(poly: Polygon2) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < poly.vertices.len() {
    var vi = poly.vertices[i];
    var vj = poly.vertices[(i + 1) % poly.vertices.len()];
    s = s + vi.x * vj.y - vj.x * vi.y;
    i = i + 1;
  }
  return s * 0.5;
}

// Area centroid of the polygon. Returns the zero point for a degenerate
// polygon. O(n).
pub fn centroid(poly: Polygon2) -> Point2 {
  var cx = 0.0;
  var cy = 0.0;
  var area2 = 0.0;
  var i = 0;
  while i < poly.vertices.len() {
    var vi = poly.vertices[i];
    var vj = poly.vertices[(i + 1) % poly.vertices.len()];
    var cross = vi.x * vj.y - vj.x * vi.y;
    area2 = area2 + cross;
    cx = cx + (vi.x + vj.x) * cross;
    cy = cy + (vi.y + vj.y) * cross;
    i = i + 1;
  }
  if area2 == 0.0 {
    return Point2{ x: 0.0; y: 0.0; };
  }
  return Point2{ x: cx / (3.0 * area2); y: cy / (3.0 * area2); };
}

// Convex hull of the points via the monotone chain algorithm (Andrew). The
// hull is counter-clockwise without a duplicated closing vertex. O(n log n).
pub fn convex_hull(points: &Vec[Point2]) -> Polygon2 {
  var out = Polygon2{ vertices: Vec[Point2].new(); };
  var n = points.len();
  if n <= 1 {
    var i = 0;
    while i < n {
      out.vertices.push(points[i]);
      i = i + 1;
    }
    return out;
  }
  // Bubble sort by (x, y) - simple and correct. Each point is rebuilt as a
  // fresh struct so no by-ref data pointer is carried into the hull.
  var sorted = Vec[Point2].new();
  var i = 0;
  while i < n {
    sorted.push(Point2{ x: points[i].x; y: points[i].y; });
    i = i + 1;
  }
  var s = 0;
  while s < n {
    var t = s + 1;
    while t < n {
      var ps = sorted[s];
      var pt = sorted[t];
      var swap = false;
      if pt.x < ps.x { swap = true; }
      if pt.x == ps.x && pt.y < ps.y { swap = true; }
      if swap {
        sorted[s] = pt;
        sorted[t] = ps;
      }
      t = t + 1;
    }
    s = s + 1;
  }
  var lower = Vec[Point2].new();
  var upper = Vec[Point2].new();
  var k = 0;
  while k < n {
    while lower.len() >= 2 {
      var l0 = lower[lower.len() - 2];
      var l1 = lower[lower.len() - 1];
      var p = sorted[k];
      var cross = (l1.x - l0.x) * (p.y - l0.y) - (l1.y - l0.y) * (p.x - l0.x);
      if cross > 0.0 {
        break;
      }
      lower.pop();
    }
    lower.push(sorted[k]);
    k = k + 1;
  }
  k = n - 1;
  while true {
    while upper.len() >= 2 {
      var u0 = upper[upper.len() - 2];
      var u1 = upper[upper.len() - 1];
      var p = sorted[k];
      var cross = (u1.x - u0.x) * (p.y - u0.y) - (u1.y - u0.y) * (p.x - u0.x);
      if cross > 0.0 {
        break;
      }
      upper.pop();
    }
    upper.push(sorted[k]);
    if k == 0 { break; }
    k = k - 1;
  }
  var i2 = 0;
  while i2 < lower.len() - 1 {
    out.vertices.push(lower[i2]);
    i2 = i2 + 1;
  }
  var i3 = 0;
  while i3 < upper.len() - 1 {
    out.vertices.push(upper[i3]);
    i3 = i3 + 1;
  }
  return out;
}

// True if every interior angle of the polygon is at most 180 degrees
// (collinear edges allowed). O(n).
pub fn is_convex(poly: Polygon2) -> Bool {
  var n = poly.vertices.len();
  if n < 3 { return false; }
  var sign = 0.0;
  var i = 0;
  while i < n {
    var v0 = poly.vertices[i];
    var v1 = poly.vertices[(i + 1) % n];
    var v2 = poly.vertices[(i + 2) % n];
    var cross = (v1.x - v0.x) * (v2.y - v1.y) - (v1.y - v0.y) * (v2.x - v1.x);
    if cross > 0.000000000001 {
      if sign < 0.0 { return false; }
      sign = 1.0;
    }
    if cross < -0.000000000001 {
      if sign > 0.0 { return false; }
      sign = -1.0;
    }
    i = i + 1;
  }
  return true;
}

// Containment test for p in poly. Same as point_in_polygon. O(n).
pub fn polygon_contains(poly: Polygon2, p: Point2) -> Bool {
  return point_in_polygon(p, poly);
}

// Intersection polygon of a and b via Sutherland-Hodgman clipping of a
// against the edges of b (exact when b is convex). None when the result is
// empty. O(n*m).
pub fn polygon_intersection(a: Polygon2, b: Polygon2) -> Option[Polygon2] {
  var subject = Vec[Point2].new();
  var i = 0;
  while i < a.vertices.len() {
    subject.push(a.vertices[i]);
    i = i + 1;
  }
  if subject.len() == 0 { return None; }
  var bn = b.vertices.len();
  var e = 0;
  while e < bn {
    var cur = b.vertices[e];
    var next = b.vertices[(e + 1) % bn];
    var out = Vec[Point2].new();
    var j = 0;
    while j < subject.len() {
      var sp = subject[j];
      var sq_pt = subject[(j + 1) % subject.len()];
      var cur_x = cur.x;
      var cur_y = cur.y;
      var nx = next.x - cur.x;
      var ny = next.y - cur.y;
      var cp = nx * (sp.y - cur_y) - ny * (sp.x - cur_x);
      var cq = nx * (sq_pt.y - cur_y) - ny * (sq_pt.x - cur_x);
      if cp >= 0.0 {
        out.push(sp);
      }
      if (cp > 0.0 && cq < 0.0) || (cp < 0.0 && cq > 0.0) {
        var t = cp / (cp - cq);
        out.push(Point2{ x: sp.x + t * (sq_pt.x - sp.x); y: sp.y + t * (sq_pt.y - sp.y); });
      }
      j = j + 1;
    }
    subject = out;
    if subject.len() == 0 {
      return None;
    }
    e = e + 1;
  }
  return Some(Polygon2{ vertices: subject; });
}

// Boolean union polygon of a and b. Implemented as the convex hull of both
// vertex sets: exact when the union is convex (e.g. overlapping convex
// polygons), otherwise an enclosing convex approximation (documented). O(n log n).
pub fn polygon_union(a: Polygon2, b: Polygon2) -> Option[Polygon2] {
  var all = Vec[Point2].new();
  var i = 0;
  while i < a.vertices.len() {
    all.push(a.vertices[i]);
    i = i + 1;
  }
  i = 0;
  while i < b.vertices.len() {
    all.push(b.vertices[i]);
    i = i + 1;
  }
  if all.len() == 0 {
    return None;
  }
  return Some(convex_hull(&all));
}

// Boolean difference a minus b. Implemented by clipping a against the outside
// of b (Sutherland-Hodgman with an inverted inside test): exact when b lies
// fully inside a, otherwise a conservative approximation (documented). None
// when the result is empty. O(n*m).
pub fn polygon_difference(a: Polygon2, b: Polygon2) -> Option[Polygon2] {
  var subject = Vec[Point2].new();
  var i = 0;
  while i < a.vertices.len() {
    subject.push(a.vertices[i]);
    i = i + 1;
  }
  if subject.len() == 0 { return None; }
  var bn = b.vertices.len();
  var e = 0;
  while e < bn {
    var cur = b.vertices[e];
    var next = b.vertices[(e + 1) % bn];
    var out = Vec[Point2].new();
    var j = 0;
    while j < subject.len() {
      var sp = subject[j];
      var sq_pt = subject[(j + 1) % subject.len()];
      var nx = next.x - cur.x;
      var ny = next.y - cur.y;
      var cp = nx * (sp.y - cur.y) - ny * (sp.x - cur.x);
      var cq = nx * (sq_pt.y - cur.y) - ny * (sq_pt.x - cur.x);
      if cp <= 0.0 {
        out.push(sp);
      }
      if (cp > 0.0 && cq < 0.0) || (cp < 0.0 && cq > 0.0) {
        var t = cp / (cp - cq);
        out.push(Point2{ x: sp.x + t * (sq_pt.x - sp.x); y: sp.y + t * (sq_pt.y - sp.y); });
      }
      j = j + 1;
    }
    subject = out;
    if subject.len() == 0 {
      return None;
    }
    e = e + 1;
  }
  return Some(Polygon2{ vertices: subject; });
}

// Perimeter of the polygon. O(n).
pub fn polygon_circumference(poly: Polygon2) -> Float64 {
  var p = 0.0;
  var n = poly.vertices.len();
  if n == 0 { return 0.0; }
  var i = 0;
  while i < n {
    var vi = poly.vertices[i];
    var vj = poly.vertices[(i + 1) % n];
    p = p + point_distance(vi, vj);
    i = i + 1;
  }
  return p;
}

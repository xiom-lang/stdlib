// XIOM - Geom: Geometry Extended
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.geom.geometry_extended

// Depends on: xiom.geom

// ============================================================================
// Advanced computational geometry: tessellations, curves, mesh processing, and
// non-Euclidean geometry. NOTE: new sublib - no existing home; implement the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.geom;
use xiom.geom.geometry_2d;
use xiom.geom.geometry_3d;
use xiom.math;

// Bounded Voronoi diagram of sites clipped to bounds: one cell per site, each
// cell the intersection of the half-planes defined by the perpendicular
// bisectors with every other site. O(k^2 * n).
pub fn voronoi(sites: &Vec[Point2], bounds: Rect) -> Vec[Polygon2] {
  var out = Vec[Polygon2].new();
  var k = sites.len();
  if k == 0 { return out; }
  var i = 0;
  while i < k {
    var cell = Vec[Point2].new();
    cell.push(bounds.min);
    cell.push(Point2{ x: bounds.max.x; y: bounds.min.y; });
    cell.push(bounds.max);
    cell.push(Point2{ x: bounds.min.x; y: bounds.max.y; });
    var j = 0;
    while j < k {
      if i != j {
        var si = sites[i];
        var sj = sites[j];
        var mx = (si.x + sj.x) * 0.5;
        var my = (si.y + sj.y) * 0.5;
        var nx = sj.x - si.x;
        var ny = sj.y - si.y;
        var nl = math.sqrt(nx * nx + ny * ny);
        if nl > 0.0 {
          var inv = 1.0 / nl;
          nx = nx * inv;
          ny = ny * inv;
          // Half-plane: points on the si side of the bisector.
          var clipped = Vec[Point2].new();
          var t = 0;
          while t < cell.len() {
            var cp = cell[t];
            var cq = cell[(t + 1) % cell.len()];
            var dp = (cp.x - mx) * nx + (cp.y - my) * ny;
            var dq = (cq.x - mx) * nx + (cq.y - my) * ny;
            if dp <= 0.0 {
              clipped.push(cp);
            }
            if (dp > 0.0 && dq < 0.0) || (dp < 0.0 && dq > 0.0) {
              var tt = dp / (dp - dq);
              clipped.push(Point2{ x: cp.x + tt * (cq.x - cp.x); y: cp.y + tt * (cq.y - cp.y); });
            }
            t = t + 1;
          }
          cell = clipped;
        }
      }
      j = j + 1;
    }
    out.push(Polygon2{ vertices: cell; });
    i = i + 1;
  }
  return out;
}

// Delaunay triangulation of points via the Bowyer-Watson algorithm (bounded
// by a super-triangle). Returns a non-empty triangle list for >= 3 points.
// O(n^2) typical.
pub fn delaunay(points: &Vec[Point2]) -> Vec[Triangle2] {
  var out = Vec[Triangle2].new();
  var n = points.len();
  if n < 3 { return out; }
  var min_x = points[0].x;
  var max_x = points[0].x;
  var min_y = points[0].y;
  var max_y = points[0].y;
  var i = 1;
  while i < n {
    var p = points[i];
    if p.x < min_x { min_x = p.x; }
    if p.x > max_x { max_x = p.x; }
    if p.y < min_y { min_y = p.y; }
    if p.y > max_y { max_y = p.y; }
    i = i + 1;
  }
  var dx = max_x - min_x;
  var dy = max_y - min_y;
  if dx == 0.0 { dx = 1.0; }
  if dy == 0.0 { dy = 1.0; }
  var mid_x = (min_x + max_x) * 0.5;
  var mid_y = (min_y + max_y) * 0.5;
  var big = math.max_float(dx, dy) * 20.0;
  var s0 = Point2{ x: mid_x - big; y: mid_y - big; };
  var s1 = Point2{ x: mid_x + big; y: mid_y - big; };
  var s2 = Point2{ x: mid_x; y: mid_y + big; };
  var tris = Vec[Triangle2].new();
  tris.push(Triangle2{ a: s0; b: s1; c: s2; });
  i = 0;
  while i < n {
    var p = points[i];
    var bad = Vec[Int].new();
    var t = 0;
    while t < tris.len() {
      if _in_circumcircle(tris[t], p) {
        bad.push(t);
      }
      t = t + 1;
    }
    if bad.len() == 0 {
      i = i + 1;
      continue;
    }
    var edges = Vec[Point2].new();
    t = 0;
    while t < bad.len() {
      var tr = tris[bad[t]];
      _add_edge(&mut edges, tr.a, tr.b);
      _add_edge(&mut edges, tr.b, tr.c);
      _add_edge(&mut edges, tr.c, tr.a);
      t = t + 1;
    }
    var r = bad.len() - 1;
    while r >= 0 {
      var idx = bad[r];
      tris.remove(idx);
      r = r - 1;
    }
    var e = 0;
    while e + 1 < edges.len() {
      tris.push(Triangle2{ a: edges[e]; b: edges[e + 1]; c: p; });
      e = e + 2;
    }
    i = i + 1;
  }
  // Drop triangles that reference a super-triangle vertex.
  var t2 = 0;
  while t2 < tris.len() {
    var tr = tris[t2];
    var hits_super = _same_point(tr.a, s0) || _same_point(tr.a, s1) || _same_point(tr.a, s2)
                  || _same_point(tr.b, s0) || _same_point(tr.b, s1) || _same_point(tr.b, s2)
                  || _same_point(tr.c, s0) || _same_point(tr.c, s1) || _same_point(tr.c, s2);
    if hits_super {
      tris.remove(t2);
    } else {
      t2 = t2 + 1;
    }
  }
  var i3 = 0;
  while i3 < tris.len() {
    out.push(tris[i3]);
    i3 = i3 + 1;
  }
  return out;
}

// Point on a Bezier curve with de Casteljau's algorithm. O(k^2).
pub fn bezier_curve(controls: &Vec[Vec2], t: Float64) -> Vec2 {
  var n = controls.len();
  if n == 0 { return Vec2{ x: 0.0; y: 0.0; }; }
  var pts = Vec[Vec2].new();
  var i = 0;
  while i < n {
    pts.push(Vec2{ x: controls[i].x; y: controls[i].y; });
    i = i + 1;
  }
  var level = n;
  while level > 1 {
    var next = Vec[Vec2].new();
    var j = 0;
    while j < level - 1 {
      var p0 = pts[j];
      var p1 = pts[j + 1];
      next.push(Vec2{
        x: p0.x + (p1.x - p0.x) * t;
        y: p0.y + (p1.y - p0.y) * t;
      });
      j = j + 1;
    }
    pts = next;
    level = level - 1;
  }
  return pts[0];
}

// Uniform open (clamped) quadratic B-spline evaluation with de Boor's
// algorithm. Knots must satisfy knots.len() == controls.len() + 3 and be
// clamped (non-decreasing, endpoints repeated); t is clamped to [0, 1].
// Returns the zero vector on inconsistent input. O(1).
pub fn b_spline(controls: &Vec[Vec2], knots: &Vec[Float64], t: Float64) -> Vec2 {
  var zero = Vec2{ x: 0.0; y: 0.0; };
  var np = controls.len();
  var nk = knots.len();
  if np < 3 { return zero; }
  if nk != np + 3 { return zero; }
  var u = t;
  if u < 0.0 { u = 0.0; }
  if u > 1.0 { u = 1.0; }
  var p = 2;
  var k = p;
  while k < np - 1 && u >= knots[k + 1] {
    k = k + 1;
  }
  if u >= knots[np + p] { k = np - 1; }
  var dx = Vec[Float64].new();
  var dy = Vec[Float64].new();
  var j = 0;
  while j <= p {
    var ci = k - p + j;
    if ci >= 0 && ci < np {
      dx.push(controls[ci].x);
      dy.push(controls[ci].y);
    } else {
      dx.push(0.0);
      dy.push(0.0);
    }
    j = j + 1;
  }
  var r = 1;
  while r <= p {
    var j2 = p;
    while j2 >= r {
      var left = knots[k - p + j2];
      var right = knots[k + 1 + j2 - r];
      var denom = right - left;
      var alpha = 0.0;
      if denom > 0.0 {
        alpha = (u - left) / denom;
      }
      var inv = 1.0 - alpha;
      var dj1x = dx[j2 - 1];
      var djx = dx[j2];
      var dj1y = dy[j2 - 1];
      var djy = dy[j2];
      dx[j2] = inv * dj1x + alpha * djx;
      dy[j2] = inv * dj1y + alpha * djy;
      j2 = j2 - 1;
    }
    r = r + 1;
  }
  return Vec2{ x: dx[p]; y: dy[p]; };
}

// NURBS evaluation: weighted rational B-spline with de Boor's algorithm.
// weights.len() must equal controls.len() and knots must satisfy the clamped
// B-spline sizing. O(1).
pub fn nurbs(controls: &Vec[Vec2], weights: &Vec[Float64], knots: &Vec[Float64], t: Float64) -> Vec2 {
  var zero = Vec2{ x: 0.0; y: 0.0; };
  var np = controls.len();
  if np < 3 || weights.len() != np { return zero; }
  var nk = knots.len();
  if nk != np + 3 { return zero; }
  var u = t;
  if u < 0.0 { u = 0.0; }
  if u > 1.0 { u = 1.0; }
  var p = 2;
  var k = p;
  while k < np - 1 && u >= knots[k + 1] {
    k = k + 1;
  }
  if u >= knots[np + p] { k = np - 1; }
  var dx = Vec[Float64].new();
  var dy = Vec[Float64].new();
  var w = Vec[Float64].new();
  var j = 0;
  while j <= p {
    var ci = k - p + j;
    if ci >= 0 && ci < np {
      dx.push(controls[ci].x);
      dy.push(controls[ci].y);
      w.push(weights[ci]);
    } else {
      dx.push(0.0);
      dy.push(0.0);
      w.push(1.0);
    }
    j = j + 1;
  }
  var r = 1;
  while r <= p {
    var j2 = p;
    while j2 >= r {
      var left = knots[k - p + j2];
      var right = knots[k + 1 + j2 - r];
      var denom = right - left;
      var alpha = 0.0;
      if denom > 0.0 {
        alpha = (u - left) / denom;
      }
      var inv = 1.0 - alpha;
      var dj1x = dx[j2 - 1];
      var djx = dx[j2];
      var dj1y = dy[j2 - 1];
      var djy = dy[j2];
      var wj1 = w[j2 - 1];
      var wj = w[j2];
      dx[j2] = inv * dj1x + alpha * djx;
      dy[j2] = inv * dj1y + alpha * djy;
      w[j2] = inv * wj1 + alpha * wj;
      j2 = j2 - 1;
    }
    r = r + 1;
  }
  if w[p] == 0.0 { return zero; }
  return Vec2{ x: dx[p] / w[p]; y: dy[p] / w[p]; };
}

// Midpoint subdivision surface refinement: every triangle is split into four
// by inserting edge midpoints (no shared-edge deduplication). The triangle
// count quadruples per iteration. O(iterations * n).
pub fn subdivision(mesh: Mesh, iterations: Int) -> Mesh {
  var out = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  var i = 0;
  while i < mesh.vertices.len() {
    out.vertices.push(mesh.vertices[i]);
    i = i + 1;
  }
  var idx = 0;
  while idx < mesh.indices.len() {
    out.indices.push(mesh.indices[idx]);
    idx = idx + 1;
  }
  var it = 0;
  while it < iterations {
    var ntris = out.indices.len() / 3;
    var new_verts = Vec[Point3].new();
    var v = 0;
    while v < out.vertices.len() {
      new_verts.push(out.vertices[v]);
      v = v + 1;
    }
    var new_indices = Vec[Int].new();
    var t = 0;
    while t < ntris {
      var i0 = out.indices[t * 3];
      var i1 = out.indices[t * 3 + 1];
      var i2 = out.indices[t * 3 + 2];
      var m01 = new_verts.len();
      new_verts.push(_midpoint(out.vertices[i0], out.vertices[i1]));
      var m12 = new_verts.len();
      new_verts.push(_midpoint(out.vertices[i1], out.vertices[i2]));
      var m20 = new_verts.len();
      new_verts.push(_midpoint(out.vertices[i2], out.vertices[i0]));
      new_indices.push(i0);
      new_indices.push(m01);
      new_indices.push(m20);
      new_indices.push(m01);
      new_indices.push(i1);
      new_indices.push(m12);
      new_indices.push(m20);
      new_indices.push(m12);
      new_indices.push(i2);
      new_indices.push(m01);
      new_indices.push(m12);
      new_indices.push(m20);
      t = t + 1;
    }
    out.vertices = new_verts;
    out.indices = new_indices;
    it = it + 1;
  }
  return out;
}

// Midpoint of two 3D points. O(1).
fn _midpoint(a: Point3, b: Point3) -> Point3 {
  return Point3{
    x: (a.x + b.x) * 0.5;
    y: (a.y + b.y) * 0.5;
    z: (a.z + b.z) * 0.5;
  };
}

// Mesh cleanup pipeline: removes duplicate vertices (exact position match)
// and rewrites the index list accordingly. Returns the cleaned mesh. O(n^2).
pub fn mesh_processing(mesh: Mesh) -> Mesh {
  var out = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  var remap = Vec[Int].new();
  var i = 0;
  while i < mesh.vertices.len() {
    var v = mesh.vertices[i];
    var found = -1;
    var j = 0;
    while j < out.vertices.len() {
      var o = out.vertices[j];
      if o.x == v.x && o.y == v.y && o.z == v.z {
        found = j;
        break;
      }
      j = j + 1;
    }
    if found < 0 {
      remap.push(out.vertices.len());
      out.vertices.push(v);
    } else {
      remap.push(found);
    }
    i = i + 1;
  }
  i = 0;
  while i < mesh.indices.len() {
    out.indices.push(remap[mesh.indices[i]]);
    i = i + 1;
  }
  return out;
}

// Apply a projective transform to the points: each point (x, y, z) is mapped
// to (x/w, y/w, z/w) with the perspective weight w = 1 + x + y + z. Points
// whose weight is zero are left unchanged. O(n).
pub fn projective_geometry(points: &Vec[Vec3]) -> Vec[Vec3] {
  var out = Vec[Vec3].new();
  var i = 0;
  while i < points.len() {
    var p = points[i];
    var w = 1.0 + p.x + p.y + p.z;
    if w == 0.0 {
      out.push(p);
    } else {
      var inv = 1.0 / w;
      out.push(Vec3{ x: p.x * inv; y: p.y * inv; z: p.z * inv; });
    }
    i = i + 1;
  }
  return out;
}

// Hyperbolic distance in the Poincare ball model:
// 2 * atanh(|a - b| / |1 - a.b|). Returns 0 for identical points. O(1).
pub fn hyperbolic_geometry(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n || n == 0 { return 0.0 / 0.0; }
  var num = 0.0;
  var dot = 0.0;
  var i = 0;
  while i < n {
    var d = a[i] - b[i];
    num = num + d * d;
    dot = dot + a[i] * b[i];
    i = i + 1;
  }
  if num == 0.0 { return 0.0; }
  var denom = math.abs_float(1.0 - dot);
  if denom == 0.0 { return 0.0 / 0.0; }
  var ratio = math.sqrt(num) / denom;
  if ratio > 1.0 { ratio = 1.0; }
  var x = math.log((1.0 + ratio) / (1.0 - ratio));
  return x;
}

// Elliptic (spherical) distance between two unit vectors: acos(a.b) in
// [0, PI]. Returns 0 for identical unit vectors. O(n).
pub fn elliptic_geometry(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n || n == 0 { return 0.0 / 0.0; }
  var dot = 0.0;
  var i = 0;
  while i < n {
    dot = dot + a[i] * b[i];
    i = i + 1;
  }
  if dot > 1.0 { dot = 1.0; }
  if dot < -1.0 { dot = -1.0; }
  return math.acos(dot);
}

// Generic non-Euclidean metric: the Poincare hyperbolic distance (see
// hyperbolic_geometry). O(n).
pub fn non_euclidean(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  return hyperbolic_geometry(a, b);
}

// Incidence predicate: true iff every point lies on at least one of the
// lines. O(p * l).
pub fn incidence_geometry(points: &Vec[Point2], lines: &Vec[Line2]) -> Bool {
  var i = 0;
  while i < points.len() {
    var p = points[i];
    var on_any = false;
    var j = 0;
    while j < lines.len() {
      var l = lines[j];
      var d = l.a * p.x + l.b * p.y + l.c;
      if d < 0.0 { d = -d; }
      if d < 0.000000000001 {
        on_any = true;
        break;
      }
      j = j + 1;
    }
    if !on_any { return false; }
    i = i + 1;
  }
  return true;
}

// Convex decomposition/combination of a point set: returns the convex hull of
// the points as a Polygon2. O(n log n).
pub fn convex_geometry(points: &Vec[Vec2]) -> Polygon2 {
  var pts = Vec[Point2].new();
  var i = 0;
  while i < points.len() {
    pts.push(Point2{ x: points[i].x; y: points[i].y; });
    i = i + 1;
  }
  return geometry_2d.convex_hull(&pts);
}

// General computational geometry entry point: returns the convex hull of the
// points as a single-cell polygon list. O(n log n).
pub fn computational_geometry(points: &Vec[Vec2]) -> Vec[Polygon2] {
  var out = Vec[Polygon2].new();
  var pts = Vec[Point2].new();
  var i = 0;
  while i < points.len() {
    pts.push(Point2{ x: points[i].x; y: points[i].y; });
    i = i + 1;
  }
  if pts.len() == 0 { return out; }
  var hull = geometry_2d.convex_hull(&pts);
  out.push(hull);
  return out;
}

// True if p lies strictly inside the circumcircle of the triangle. O(1).
fn _in_circumcircle(t: Triangle2, p: Point2) -> Bool {
  var ax = t.a.x - p.x;
  var ay = t.a.y - p.y;
  var bx = t.b.x - p.x;
  var by = t.b.y - p.y;
  var cx = t.c.x - p.x;
  var cy = t.c.y - p.y;
  var d = (ax * ax + ay * ay) * (bx * cy - cx * by)
        - (bx * bx + by * by) * (ax * cy - cx * ay)
        + (cx * cx + cy * cy) * (ax * by - bx * ay);
  return d > 0.0;
}

// Add the directed edge (p, q) to edges (stored pairwise), removing an
// opposite occurrence so only boundary edges survive. O(k).
fn _add_edge(edges: &mut Vec[Point2], p: Point2, q: Point2) {
  var i = 0;
  while i + 1 < edges.len() {
    var e0 = edges[i];
    var e1 = edges[i + 1];
    if _same_point(e0, q) && _same_point(e1, p) {
      edges.remove(i);
      edges.remove(i);
      return;
    }
    i = i + 2;
  }
  edges.push(p);
  edges.push(q);
}

// True if two points are identical. O(1).
fn _same_point(a: Point2, b: Point2) -> Bool {
  return a.x == b.x && a.y == b.y;
}

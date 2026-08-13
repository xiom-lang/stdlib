// XIOM - Geom: Polyhedra
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the mesh-generation and hull domain.

module xiom.geom.polyhedra

// Depends on: xiom.geom

// ============================================================================
// Polyhedron mesh generation and convex hull algorithms split from geom.xi.
// TODO(compiler): implement.
//
// All results are dynamic Vec[Vec[Float64]] meshes; the smoke verifies them
// through length counts and scalar invariants (BUG: by-ref nested reads and
// module-returned nested Vec element reads are corrupt). Input points are
// copied into a local matrix before element access (BUG 26 #1).
// ============================================================================

use xiom.math;

// Vertices of a cube centered at the origin with the given side length.
// Returns 8 vertices, each (x, y, z). O(1).
pub fn cube_vertices(size: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var h = size * 0.5;
  var i = 0;
  while i < 8 {
    var x = -h;
    var y = -h;
    var z = -h;
    if i % 2 == 1 { x = h; }
    if (i / 2) % 2 == 1 { y = h; }
    if (i / 4) % 2 == 1 { z = h; }
    var v = Vec[Float64].new();
    v.push(x);
    v.push(y);
    v.push(z);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Face index list for cube_vertices: 12 triangles (3 indices each). O(1).
pub fn cube_faces() -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var quads = Vec[Int].new();
  quads.push(0); quads.push(1); quads.push(3); quads.push(2);
  quads.push(4); quads.push(5); quads.push(7); quads.push(6);
  quads.push(0); quads.push(1); quads.push(5); quads.push(4);
  quads.push(2); quads.push(3); quads.push(7); quads.push(6);
  quads.push(0); quads.push(2); quads.push(6); quads.push(4);
  quads.push(1); quads.push(3); quads.push(7); quads.push(5);
  var q = 0;
  while q < quads.len() / 4 {
    var a = quads[q * 4];
    var b = quads[q * 4 + 1];
    var c = quads[q * 4 + 2];
    var d = quads[q * 4 + 3];
    var t1 = Vec[Int].new();
    t1.push(a); t1.push(b); t1.push(c);
    out.push(t1);
    var t2 = Vec[Int].new();
    t2.push(a); t2.push(c); t2.push(d);
    out.push(t2);
    q = q + 1;
  }
  return out;
}

// UV-sphere vertex grid: (slices + 1) x (stacks + 1) vertices of the form
// (x, y, z). O(slices * stacks).
pub fn sphere_vertices(radius: Float64, slices: Int, stacks: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if slices < 1 || stacks < 1 { return out; }
  var s = 0;
  while s <= stacks {
    var phi = math.PI * s / stacks;
    var sp = math.sin(phi);
    var cp = math.cos(phi);
    var sl = 0;
    while sl <= slices {
      var theta = 2.0 * math.PI * sl / slices;
      var v = Vec[Float64].new();
      v.push(radius * sp * math.cos(theta));
      v.push(radius * cp);
      v.push(radius * sp * math.sin(theta));
      out.push(v);
      sl = sl + 1;
    }
    s = s + 1;
  }
  return out;
}

// Unit icosahedron vertices (12) in the standard layout:
// (+-1, +-phi, 0), (0, +-1, +-phi), (+-phi, 0, +-1). O(1).
pub fn icosahedron_vertices() -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var phi = (1.0 + math.sqrt(5.0)) * 0.5;
  var pts = Vec[Float64].new();
  pts.push(-1.0); pts.push(phi); pts.push(0.0);
  pts.push(1.0); pts.push(phi); pts.push(0.0);
  pts.push(-1.0); pts.push(-phi); pts.push(0.0);
  pts.push(1.0); pts.push(-phi); pts.push(0.0);
  pts.push(0.0); pts.push(-1.0); pts.push(phi);
  pts.push(0.0); pts.push(1.0); pts.push(phi);
  pts.push(0.0); pts.push(-1.0); pts.push(-phi);
  pts.push(0.0); pts.push(1.0); pts.push(-phi);
  pts.push(phi); pts.push(0.0); pts.push(-1.0);
  pts.push(phi); pts.push(0.0); pts.push(1.0);
  pts.push(-phi); pts.push(0.0); pts.push(-1.0);
  pts.push(-phi); pts.push(0.0); pts.push(1.0);
  var i = 0;
  while i < 12 {
    var v = Vec[Float64].new();
    v.push(pts[i * 3]);
    v.push(pts[i * 3 + 1]);
    v.push(pts[i * 3 + 2]);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Icosahedron faces: 20 triangles referencing icosahedron_vertices. O(1).
pub fn icosahedron_faces() -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var tri = Vec[Int].new();
  tri.push(0); tri.push(11); tri.push(5);
  tri.push(0); tri.push(5); tri.push(1);
  tri.push(0); tri.push(1); tri.push(7);
  tri.push(0); tri.push(7); tri.push(10);
  tri.push(0); tri.push(10); tri.push(11);
  tri.push(1); tri.push(5); tri.push(9);
  tri.push(5); tri.push(11); tri.push(4);
  tri.push(11); tri.push(10); tri.push(2);
  tri.push(10); tri.push(7); tri.push(6);
  tri.push(7); tri.push(1); tri.push(8);
  tri.push(3); tri.push(9); tri.push(4);
  tri.push(3); tri.push(4); tri.push(2);
  tri.push(3); tri.push(2); tri.push(6);
  tri.push(3); tri.push(6); tri.push(8);
  tri.push(3); tri.push(8); tri.push(9);
  tri.push(4); tri.push(9); tri.push(5);
  tri.push(2); tri.push(4); tri.push(11);
  tri.push(6); tri.push(2); tri.push(10);
  tri.push(8); tri.push(6); tri.push(7);
  tri.push(9); tri.push(8); tri.push(1);
  var t = 0;
  while t < tri.len() / 3 {
    var f = Vec[Int].new();
    f.push(tri[t * 3]);
    f.push(tri[t * 3 + 1]);
    f.push(tri[t * 3 + 2]);
    out.push(f);
    t = t + 1;
  }
  return out;
}

// Unit tetrahedron vertices (4). O(1).
pub fn tetrahedron_vertices() -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var pts = Vec[Float64].new();
  pts.push(1.0); pts.push(1.0); pts.push(1.0);
  pts.push(-1.0); pts.push(-1.0); pts.push(1.0);
  pts.push(-1.0); pts.push(1.0); pts.push(-1.0);
  pts.push(1.0); pts.push(-1.0); pts.push(-1.0);
  var i = 0;
  while i < 4 {
    var v = Vec[Float64].new();
    v.push(pts[i * 3]);
    v.push(pts[i * 3 + 1]);
    v.push(pts[i * 3 + 2]);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Unit octahedron vertices (6). O(1).
pub fn octahedron_vertices() -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var pts = Vec[Float64].new();
  pts.push(1.0); pts.push(0.0); pts.push(0.0);
  pts.push(-1.0); pts.push(0.0); pts.push(0.0);
  pts.push(0.0); pts.push(1.0); pts.push(0.0);
  pts.push(0.0); pts.push(-1.0); pts.push(0.0);
  pts.push(0.0); pts.push(0.0); pts.push(1.0);
  pts.push(0.0); pts.push(0.0); pts.push(-1.0);
  var i = 0;
  while i < 6 {
    var v = Vec[Float64].new();
    v.push(pts[i * 3]);
    v.push(pts[i * 3 + 1]);
    v.push(pts[i * 3 + 2]);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Unit dodecahedron vertices (20). O(1).
pub fn dodecahedron_vertices() -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var phi = (1.0 + math.sqrt(5.0)) * 0.5;
  var inv_phi = 1.0 / phi;
  var pts = Vec[Float64].new();
  var s = 0;
  while s < 8 {
    var x = -1.0;
    var y = -1.0;
    var z = -1.0;
    if s % 2 == 1 { x = 1.0; }
    if (s / 2) % 2 == 1 { y = 1.0; }
    if (s / 4) % 2 == 1 { z = 1.0; }
    pts.push(x); pts.push(y); pts.push(z);
    s = s + 1;
  }
  var ring = Vec[Float64].new();
  ring.push(0.0); ring.push(inv_phi); ring.push(phi);
  ring.push(0.0); ring.push(-inv_phi); ring.push(phi);
  ring.push(0.0); ring.push(inv_phi); ring.push(-phi);
  ring.push(0.0); ring.push(-inv_phi); ring.push(-phi);
  var r2 = 0;
  while r2 < 4 {
    pts.push(ring[r2 * 3]);
    pts.push(ring[r2 * 3 + 1]);
    pts.push(ring[r2 * 3 + 2]);
    r2 = r2 + 1;
  }
  ring = Vec[Float64].new();
  ring.push(inv_phi); ring.push(phi); ring.push(0.0);
  ring.push(-inv_phi); ring.push(phi); ring.push(0.0);
  ring.push(inv_phi); ring.push(-phi); ring.push(0.0);
  ring.push(-inv_phi); ring.push(-phi); ring.push(0.0);
  r2 = 0;
  while r2 < 4 {
    pts.push(ring[r2 * 3]);
    pts.push(ring[r2 * 3 + 1]);
    pts.push(ring[r2 * 3 + 2]);
    r2 = r2 + 1;
  }
  ring = Vec[Float64].new();
  ring.push(phi); ring.push(0.0); ring.push(inv_phi);
  ring.push(phi); ring.push(0.0); ring.push(-inv_phi);
  ring.push(-phi); ring.push(0.0); ring.push(inv_phi);
  ring.push(-phi); ring.push(0.0); ring.push(-inv_phi);
  r2 = 0;
  while r2 < 4 {
    pts.push(ring[r2 * 3]);
    pts.push(ring[r2 * 3 + 1]);
    pts.push(ring[r2 * 3 + 2]);
    r2 = r2 + 1;
  }
  var i = 0;
  while i < 20 {
    var v = Vec[Float64].new();
    v.push(pts[i * 3]);
    v.push(pts[i * 3 + 1]);
    v.push(pts[i * 3 + 2]);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Convex hull polygon of 2D points (monotone chain). The hull is returned
// without a duplicated closing vertex. O(n log n).
pub fn convex_hull_2d(points: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var n = points.len();
  if n == 0 { return out; }
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    sc.push(points[i]);
    i = i + 1;
  }
  var pc = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    row.push(sc[i][0]);
    row.push(sc[i][1]);
    pc.push(row);
    i = i + 1;
  }
  if n == 1 {
    out.push(pc[0]);
    return out;
  }
  var s = 0;
  while s < n {
    var t = s + 1;
    while t < n {
      var swap = false;
      if pc[t][0] < pc[s][0] { swap = true; }
      if pc[t][0] == pc[s][0] && pc[t][1] < pc[s][1] { swap = true; }
      if swap {
        var tx = pc[s][0];
        var ty = pc[s][1];
        pc[s][0] = pc[t][0];
        pc[s][1] = pc[t][1];
        pc[t][0] = tx;
        pc[t][1] = ty;
      }
      t = t + 1;
    }
    s = s + 1;
  }
  var lower = Vec[Vec[Float64]].new();
  var upper = Vec[Vec[Float64]].new();
  var k = 0;
  while k < n {
    while lower.len() >= 2 {
      var l0 = lower[lower.len() - 2];
      var l1 = lower[lower.len() - 1];
      var p = pc[k];
      var cross = (l1[0] - l0[0]) * (p[1] - l0[1]) - (l1[1] - l0[1]) * (p[0] - l0[0]);
      if cross > 0.0 {
        break;
      }
      lower.pop();
    }
    lower.push(pc[k]);
    k = k + 1;
  }
  k = n - 1;
  while true {
    while upper.len() >= 2 {
      var u0 = upper[upper.len() - 2];
      var u1 = upper[upper.len() - 1];
      var p = pc[k];
      var cross = (u1[0] - u0[0]) * (p[1] - u0[1]) - (u1[1] - u0[1]) * (p[0] - u0[0]);
      if cross > 0.0 {
        break;
      }
      upper.pop();
    }
    upper.push(pc[k]);
    if k == 0 { break; }
    k = k - 1;
  }
  var i2 = 0;
  while i2 < lower.len() - 1 {
    out.push(lower[i2]);
    i2 = i2 + 1;
  }
  var i3 = 0;
  while i3 < upper.len() - 1 {
    out.push(upper[i3]);
    i3 = i3 + 1;
  }
  return out;
}

// Convex hull vertices of a 3D point cloud. Every oriented triangle (i, j, k)
// with all other points on (or behind) its plane is emitted as a hull face.
// O(n^4); exact for small point sets.
pub fn convex_hull_3d(points: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var n = points.len();
  if n == 0 { return out; }
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    sc.push(points[i]);
    i = i + 1;
  }
  var pc = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    row.push(sc[i][0]);
    row.push(sc[i][1]);
    row.push(sc[i][2]);
    pc.push(row);
    i = i + 1;
  }
  var seen = Vec[Bool].new();
  i = 0;
  while i < n {
    seen.push(false);
    i = i + 1;
  }
  i = 0;
  while i < n {
    var j = i + 1;
    while j < n {
      var k = j + 1;
      while k < n {
        var a = pc[i];
        var b = pc[j];
        var c = pc[k];
        var ex = b[1] * c[2] - b[2] * c[1];
        var ey = b[2] * c[0] - b[0] * c[2];
        var ez = b[0] * c[1] - b[1] * c[0];
        var nx = a[1] * ez - a[2] * ey;
        var ny = a[2] * ex - a[0] * ez;
        var nz = a[0] * ey - a[1] * ex;
        var e1x = b[0] - a[0];
        var e1y = b[1] - a[1];
        var e1z = b[2] - a[2];
        var e2x = c[0] - a[0];
        var e2y = c[1] - a[1];
        var e2z = c[2] - a[2];
        var fx = e1y * e2z - e1z * e2y;
        var fy = e1z * e2x - e1x * e2z;
        var fz = e1x * e2y - e1y * e2x;
        var fl = math.sqrt(fx * fx + fy * fy + fz * fz);
        if fl > 0.000000000001 {
          var d0 = nx * a[0] + ny * a[1] + nz * a[2];
          var pos = false;
          var neg = false;
          var t = 0;
          while t < n {
            if t != i && t != j && t != k {
              var sd = nx * pc[t][0] + ny * pc[t][1] + nz * pc[t][2] - d0;
              if sd > 0.000000000001 { pos = true; }
              if sd < -0.000000000001 { neg = true; }
              if pos && neg { break; }
            }
            t = t + 1;
          }
          if !(pos && neg) {
            seen[i] = true;
            seen[j] = true;
            seen[k] = true;
          }
        }
        k = k + 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  i = 0;
  while i < n {
    if seen[i] {
      out.push(pc[i]);
    }
    i = i + 1;
  }
  return out;
}

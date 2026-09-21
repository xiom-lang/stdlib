// XIOM - Geom: Geometry 3D
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.geom.geometry_3d

// Depends on: xiom.geom

// ============================================================================
// 3D primitives, ray queries, containment tests, and mesh metrics. NOTE:
// current implementation lives in geom/collision.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
//
// Vector arithmetic delegates to the canonical geom.xi Vec3 operations.
// convex_hull_3d uses the all-points-on-one-side face test (O(n^4), exact for
// small point clouds).
// ============================================================================

use xiom.geom;
use xiom.math;

/// 3D point.
pub type Point3 = { x: Float64; y: Float64; z: Float64; }

/// Infinite line: point plus direction.
pub type Line3 = { point: Point3; dir: Vec3; }

/// Ray: origin plus (not necessarily unit) direction.
pub type Ray3 = { origin: Point3; dir: Vec3; }

/// Segment between two points.
pub type Segment3 = { a: Point3; b: Point3; }

/// Plane3d normal . p = d.
pub type Plane3d = { normal: Vec3; d: Float64; }

/// Sphere3d with center and radius.
pub type Sphere3d = { center: Point3; radius: Float64; }

/// Capsule: segment (a, b) with radius.
pub type Capsule = { a: Point3; b: Point3; radius: Float64; }

/// Cylinder: axis segment plus radius.
pub type Cylinder = { axis: Segment3; radius: Float64; }

/// Cone: apex, axis direction, and half angle in radians.
pub type Cone = { apex: Point3; axis: Vec3; half_angle: Float64; }

/// Axis-aligned box defined by min and max corners.
pub type Box = { min: Point3; max: Point3; }

/// Oriented box: center, orthonormal axes, half extents.
pub type OBB = { center: Point3; axes: Vec[Vec3]; half_extents: Vec[Float64]; }

/// Triangle with three vertices.
pub type Triangle3 = { a: Point3; b: Point3; c: Point3; }

/// Polygon: vertex list in boundary order.
pub type Polygon3 = { vertices: Vec[Point3]; }

/// Triangle mesh: vertices plus triangle index list (3 indices per triangle).
pub type Mesh = { vertices: Vec[Point3]; indices: Vec[Int]; }

/// Euclidean distance between two points. O(1).
pub fn point_distance(a: Point3, b: Point3) -> Float64 {
  var dx = a.x - b.x;
  var dy = a.y - b.y;
  var dz = a.z - b.z;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

/// Distance from p to the sphere surface (0 when p is inside). O(1).
pub fn point_sphere_distance(p: Point3, s: Sphere3d) -> Float64 {
  var d = point_distance(p, s.center) - s.radius;
  if d < 0.0 { d = 0.0; }
  return d;
}

/// Signed distance from p to the plane (positive on the normal side). O(1).
pub fn point_plane_distance(p: Point3, pl: Plane3d) -> Float64 {
  var len = geom.vec3_length(pl.normal);
  if len == 0.0 { return 0.0; }
  var dot = geom.vec3_dot(pl.normal, Vec3{ x: p.x; y: p.y; z: p.z; });
  return (dot - pl.d) / len;
}

/// Absolute distance from p to the plane. Alias of point_plane_distance. O(1).
pub fn plane_point_distance(pl: Plane3d, p: Point3) -> Float64 {
  var d = point_plane_distance(p, pl);
  if d < 0.0 { d = -d; }
  return d;
}

/// Shortest distance from p to the infinite line l. O(1).
pub fn line_point_distance(l: Line3, p: Point3) -> Float64 {
  var dl = geom.vec3_length(l.dir);
  if dl == 0.0 { return point_distance(p, l.point); }
  var ap = Vec3{ x: p.x - l.point.x; y: p.y - l.point.y; z: p.z - l.point.z; };
  var cross = geom.vec3_cross(ap, l.dir);
  return geom.vec3_length(cross) / dl;
}

/// Shortest distance from p to the segment s. O(1).
pub fn segment_point_distance(s: Segment3, p: Point3) -> Float64 {
  var abx = s.b.x - s.a.x;
  var aby = s.b.y - s.a.y;
  var abz = s.b.z - s.a.z;
  var apx = p.x - s.a.x;
  var apy = p.y - s.a.y;
  var apz = p.z - s.a.z;
  var len_sq = abx * abx + aby * aby + abz * abz;
  if len_sq == 0.0 { return point_distance(p, s.a); }
  var t = (apx * abx + apy * aby + apz * abz) / len_sq;
  if t < 0.0 { t = 0.0; }
  if t > 1.0 { t = 1.0; }
  return point_distance(p, Point3{ x: s.a.x + t * abx; y: s.a.y + t * aby; z: s.a.z + t * abz; });
}

/// Ray-plane intersection: parameter t along the ray; None when parallel or
/// behind the origin. O(1).
pub fn ray_plane_intersection(r: Ray3, pl: Plane3d) -> Option[Float64] {
  var denom = geom.vec3_dot(r.dir, pl.normal);
  if math.abs_float(denom) < 0.000000000001 {
    return None;
  }
  var t = (pl.d - geom.vec3_dot(Vec3{ x: r.origin.x; y: r.origin.y; z: r.origin.z; }, pl.normal)) / denom;
  if t < 0.0 {
    return None;
  }
  return Some(t);
}

/// Ray-triangle intersection via the Moller-Trumbore algorithm. Returns the
/// nearest positive t; None on miss or behind the origin. O(1).
pub fn ray_triangle_intersection(r: Ray3, t: Triangle3) -> Option[Float64] {
  var e1 = Vec3{ x: t.b.x - t.a.x; y: t.b.y - t.a.y; z: t.b.z - t.a.z; };
  var e2 = Vec3{ x: t.c.x - t.a.x; y: t.c.y - t.a.y; z: t.c.z - t.a.z; };
  var pvec = geom.vec3_cross(r.dir, e2);
  var det = geom.vec3_dot(e1, pvec);
  if math.abs_float(det) < 0.000000000001 {
    return None;
  }
  var inv_det = 1.0 / det;
  var tvec = Vec3{
    x: r.origin.x - t.a.x;
    y: r.origin.y - t.a.y;
    z: r.origin.z - t.a.z;
  };
  var u = geom.vec3_dot(tvec, pvec) * inv_det;
  if u < 0.0 || u > 1.0 { return None; }
  var qvec = geom.vec3_cross(tvec, e1);
  var v = geom.vec3_dot(r.dir, qvec) * inv_det;
  if v < 0.0 || u + v > 1.0 { return None; }
  var tt = geom.vec3_dot(e2, qvec) * inv_det;
  if tt < 0.0 { return None; }
  return Some(tt);
}

/// Ray-sphere intersection: nearest positive t; None on miss. O(1).
pub fn ray_sphere_intersection(r: Ray3, s: Sphere3d) -> Option[Float64] {
  var oc = Vec3{
    x: r.origin.x - s.center.x;
    y: r.origin.y - s.center.y;
    z: r.origin.z - s.center.z;
  };
  var a = geom.vec3_dot(r.dir, r.dir);
  if a == 0.0 { return None; }
  var b = 2.0 * geom.vec3_dot(oc, r.dir);
  var c = geom.vec3_dot(oc, oc) - s.radius * s.radius;
  var disc = b * b - 4.0 * a * c;
  if disc < 0.0 { return None; }
  var sq = math.sqrt(disc);
  var t0 = (-b - sq) / (2.0 * a);
  var t1 = (-b + sq) / (2.0 * a);
  if t0 > 0.0 { return Some(t0); }
  if t1 > 0.0 { return Some(t1); }
  return None;
}

/// Ray-box intersection via the slab method: nearest positive t; None on miss.
/// O(1).
pub fn ray_box_intersection(r: Ray3, b: Box) -> Option[Float64] {
  var tmin = 0.0;
  var tmax = 0.0;
  var dx = r.dir.x;
  if math.abs_float(dx) < 0.000000000001 {
    if r.origin.x < b.min.x || r.origin.x > b.max.x { return None; }
  } else {
    tmin = (b.min.x - r.origin.x) / dx;
    tmax = (b.max.x - r.origin.x) / dx;
    if tmin > tmax {
      var tmp = tmin;
      tmin = tmax;
      tmax = tmp;
    }
  }
  var dy = r.dir.y;
  if math.abs_float(dy) < 0.000000000001 {
    if r.origin.y < b.min.y || r.origin.y > b.max.y { return None; }
  } else {
    var tymin = (b.min.y - r.origin.y) / dy;
    var tymax = (b.max.y - r.origin.y) / dy;
    if tymin > tymax {
      var tmp = tymin;
      tymin = tymax;
      tymax = tmp;
    }
    if tymin > tmax || tymax < tmin { return None; }
    if tymin > tmin { tmin = tymin; }
    if tymax < tmax { tmax = tymax; }
  }
  var dz = r.dir.z;
  if math.abs_float(dz) < 0.000000000001 {
    if r.origin.z < b.min.z || r.origin.z > b.max.z { return None; }
  } else {
    var tzmin = (b.min.z - r.origin.z) / dz;
    var tzmax = (b.max.z - r.origin.z) / dz;
    if tzmin > tzmax {
      var tmp = tzmin;
      tzmin = tzmax;
      tzmax = tmp;
    }
    if tzmin > tmax || tzmax < tmin { return None; }
    if tzmin > tmin { tmin = tzmin; }
    if tzmax < tmax { tmax = tzmax; }
  }
  if tmax < 0.0 { return None; }
  if tmin < 0.0 { tmin = tmax; }
  if tmin < 0.0 { return None; }
  return Some(tmin);
}

/// Line of intersection of two planes; None when parallel. O(1).
pub fn plane_plane_intersection(p1: Plane3d, p2: Plane3d) -> Option[Line3] {
  var dir = geom.vec3_cross(p1.normal, p2.normal);
  var dl = geom.vec3_length(dir);
  if dl < 0.000000000001 {
    return None;
  }
  // A point on both planes: solve the 3x3 system with the cross-product
  // formula (for non-parallel normals).
  var n1 = p1.normal;
  var n2 = p2.normal;
  var n1n1 = geom.vec3_dot(n1, n1);
  var n2n2 = geom.vec3_dot(n2, n2);
  var n1n2 = geom.vec3_dot(n1, n2);
  var det_sys = n1n1 * n2n2 - n1n2 * n1n2;
  if math.abs_float(det_sys) < 0.000000000001 {
    return None;
  }
  var c1 = (p1.d * n2n2 - p2.d * n1n2) / det_sys;
  var c2 = (p2.d * n1n1 - p1.d * n1n2) / det_sys;
  var px = c1 * n1.x + c2 * n2.x;
  var py = c1 * n1.y + c2 * n2.y;
  var pz = c1 * n1.z + c2 * n2.z;
  return Some(Line3{ point: Point3{ x: px; y: py; z: pz; }; dir: dir; });
}

/// True if the two spheres overlap or touch. O(1).
pub fn sphere_sphere_intersection(a: Sphere3d, b: Sphere3d) -> Bool {
  var dx = a.center.x - b.center.x;
  var dy = a.center.y - b.center.y;
  var dz = a.center.z - b.center.z;
  var d2 = dx * dx + dy * dy + dz * dz;
  var r = a.radius + b.radius;
  return d2 <= r * r;
}

/// True if the two axis-aligned boxes overlap or touch. O(1).
pub fn aabb_intersection(a: Box, b: Box) -> Bool {
  if a.max.x < b.min.x || a.min.x > b.max.x { return false; }
  if a.max.y < b.min.y || a.min.y > b.max.y { return false; }
  if a.max.z < b.min.z || a.min.z > b.max.z { return false; }
  return true;
}

/// True if p lies inside (or on) the box. O(1).
pub fn aabb_contains(b: Box, p: Point3) -> Bool {
  return p.x >= b.min.x && p.x <= b.max.x
      && p.y >= b.min.y && p.y <= b.max.y
      && p.z >= b.min.z && p.z <= b.max.z;
}

/// Closest point on the segment s to p. O(1).
pub fn closest_point_on_segment(s: Segment3, p: Point3) -> Point3 {
  var abx = s.b.x - s.a.x;
  var aby = s.b.y - s.a.y;
  var abz = s.b.z - s.a.z;
  var apx = p.x - s.a.x;
  var apy = p.y - s.a.y;
  var apz = p.z - s.a.z;
  var len_sq = abx * abx + aby * aby + abz * abz;
  if len_sq == 0.0 { return s.a; }
  var t = (apx * abx + apy * aby + apz * abz) / len_sq;
  if t < 0.0 { t = 0.0; }
  if t > 1.0 { t = 1.0; }
  return Point3{ x: s.a.x + t * abx; y: s.a.y + t * aby; z: s.a.z + t * abz; };
}

/// Orthogonal projection of p onto the plane. O(1).
pub fn closest_point_on_plane(pl: Plane3d, p: Point3) -> Point3 {
  var len = geom.vec3_length(pl.normal);
  if len == 0.0 { return p; }
  var dot = geom.vec3_dot(pl.normal, Vec3{ x: p.x; y: p.y; z: p.z; });
  var dist = (dot - pl.d) / len;
  var inv = 1.0 / len;
  return Point3{
    x: p.x - pl.normal.x * inv * dist;
    y: p.y - pl.normal.y * inv * dist;
    z: p.z - pl.normal.z * inv * dist;
  };
}

/// Unit normal of the triangle (right-handed, b-a cross c-a). Returns the zero
/// vector for a degenerate triangle. O(1).
pub fn triangle_normal(t: Triangle3) -> Vec3 {
  var e1 = Vec3{ x: t.b.x - t.a.x; y: t.b.y - t.a.y; z: t.b.z - t.a.z; };
  var e2 = Vec3{ x: t.c.x - t.a.x; y: t.c.y - t.a.y; z: t.c.z - t.a.z; };
  var n = geom.vec3_cross(e1, e2);
  var len = geom.vec3_length(n);
  if len == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  var inv = 1.0 / len;
  return Vec3{ x: n.x * inv; y: n.y * inv; z: n.z * inv; };
}

/// Signed volume of a closed mesh via the divergence theorem (sum of signed
/// tetrahedron volumes about the origin). O(n).
pub fn mesh_volume(m: Mesh) -> Float64 {
  var vol = 0.0;
  var i = 0;
  while i + 2 < m.indices.len() {
    var i0 = m.indices[i];
    var i1 = m.indices[i + 1];
    var i2 = m.indices[i + 2];
    var a = m.vertices[i0];
    var b = m.vertices[i1];
    var c = m.vertices[i2];
    var det = a.x * (b.y * c.z - c.y * b.z)
            - a.y * (b.x * c.z - c.x * b.z)
            + a.z * (b.x * c.y - c.x * b.y);
    vol = vol + det;
    i = i + 3;
  }
  return vol / 6.0;
}

/// Total surface area of a mesh (sum of triangle areas). O(n).
pub fn mesh_surface_area(m: Mesh) -> Float64 {
  var area = 0.0;
  var i = 0;
  while i + 2 < m.indices.len() {
    var i0 = m.indices[i];
    var i1 = m.indices[i + 1];
    var i2 = m.indices[i + 2];
    var a = m.vertices[i0];
    var b = m.vertices[i1];
    var c = m.vertices[i2];
    var abx = b.x - a.x;
    var aby = b.y - a.y;
    var abz = b.z - a.z;
    var acx = c.x - a.x;
    var acy = c.y - a.y;
    var acz = c.z - a.z;
    var cx = aby * acz - abz * acy;
    var cy = abz * acx - abx * acz;
    var cz = abx * acy - aby * acx;
    area = area + 0.5 * math.sqrt(cx * cx + cy * cy + cz * cz);
    i = i + 3;
  }
  return area;
}

/// Volume-weighted centroid of a closed mesh. Returns the zero point for a
/// degenerate mesh. O(n).
pub fn mesh_centroid(m: Mesh) -> Point3 {
  var vol = 0.0;
  var cx = 0.0;
  var cy = 0.0;
  var cz = 0.0;
  var i = 0;
  while i + 2 < m.indices.len() {
    var i0 = m.indices[i];
    var i1 = m.indices[i + 1];
    var i2 = m.indices[i + 2];
    var a = m.vertices[i0];
    var b = m.vertices[i1];
    var c = m.vertices[i2];
    var det = a.x * (b.y * c.z - c.y * b.z)
            - a.y * (b.x * c.z - c.x * b.z)
            + a.z * (b.x * c.y - c.x * b.y);
    vol = vol + det;
    cx = cx + det * (a.x + b.x + c.x);
    cy = cy + det * (a.y + b.y + c.y);
    cz = cz + det * (a.z + b.z + c.z);
    i = i + 3;
  }
  if vol == 0.0 {
    return Point3{ x: 0.0; y: 0.0; z: 0.0; };
  }
  return Point3{ x: cx / (4.0 * vol); y: cy / (4.0 * vol); z: cz / (4.0 * vol); };
}

/// Convex hull of a point cloud as a triangle mesh. Every oriented face is a
/// triangle (i, j, k) such that all other points lie on (or behind) the plane
/// of that triangle. O(n^4); exact for small point sets.
pub fn convex_hull_3d(points: &Vec[Point3]) -> Mesh {
  var out = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  var n = points.len();
  var i = 0;
  while i < n {
    out.vertices.push(points[i]);
    i = i + 1;
  }
  if n < 4 { return out; }
  i = 0;
  while i < n {
    var j = i + 1;
    while j < n {
      var k = j + 1;
      while k < n {
        var a = points[i];
        var b = points[j];
        var c = points[k];
        var e1 = Vec3{ x: b.x - a.x; y: b.y - a.y; z: b.z - a.z; };
        var e2 = Vec3{ x: c.x - a.x; y: c.y - a.y; z: c.z - a.z; };
        var nrm = geom.vec3_cross(e1, e2);
        var nl = geom.vec3_length(nrm);
        if nl > 0.000000000001 {
          var d0 = geom.vec3_dot(nrm, Vec3{ x: a.x; y: a.y; z: a.z; });
          var pos = false;
          var neg = false;
          var t = 0;
          while t < n {
            if t != i && t != j && t != k {
              var p = points[t];
              var sd = geom.vec3_dot(nrm, Vec3{ x: p.x; y: p.y; z: p.z; }) - d0;
              if sd > 0.000000000001 { pos = true; }
              if sd < -0.000000000001 { neg = true; }
              if pos && neg { break; }
            }
            t = t + 1;
          }
          if !(pos && neg) {
            out.indices.push(i);
            out.indices.push(j);
            out.indices.push(k);
          }
        }
        k = k + 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return out;
}

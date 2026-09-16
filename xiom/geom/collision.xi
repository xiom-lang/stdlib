// XIOM - Geom: Collision
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
// Home: geom.xi - this sublib splits the intersection/containment domain; the
// canonical Aabb, Sphere, Ray types live in geom.xi.

module xiom.geom.collision

// Depends on: xiom.geom

// ============================================================================
// Collision primitives and queries split from geom.xi: bounding volumes, rays,
// point-in-shape tests, and segment intersection. TODO(compiler): implement.
//
// The primitives here are dynamic-Vec based (the canonical geom.xi types use
// fixed Vec3; same-name types are therefore implemented locally). All scalar
// Options are safely extractable; Vec-payload Options (segment_intersect) are
// verified through is_some/None only (BUG: Vec payload extraction crashes).
// ============================================================================

use xiom.math;

// Axis-aligned bounding box defined by min and max corners.
pub type Aabb = { min: Vec[Float64]; max: Vec[Float64]; }

// Sphere primitive defined by centre point and radius.
pub type Sphere = { center: Vec[Float64]; radius: Float64; }

// Ray primitive: infinite line from origin along dir.
pub type Ray = { origin: Vec[Float64]; dir: Vec[Float64]; }

// Construct an AABB from min and max corners (3 components each). O(1).
pub fn aabb_new(min: &Vec[Float64], max: &Vec[Float64]) -> Aabb {
  return Aabb{ min: min; max: max; };
}

// True iff p lies inside the AABB (inclusive). A point with fewer than 3
// components is not inside. O(1).
pub fn aabb_contains(a: Aabb, p: &Vec[Float64]) -> Bool {
  if p.len() < 3 { return false; }
  if a.min.len() < 3 || a.max.len() < 3 { return false; }
  return p[0] >= a.min[0] && p[0] <= a.max[0]
      && p[1] >= a.min[1] && p[1] <= a.max[1]
      && p[2] >= a.min[2] && p[2] <= a.max[2];
}

// True iff the two AABBs overlap or touch. O(1).
pub fn aabb_intersects(a: Aabb, b: Aabb) -> Bool {
  if a.min.len() < 3 || a.max.len() < 3 { return false; }
  if b.min.len() < 3 || b.max.len() < 3 { return false; }
  if a.max[0] < b.min[0] || a.min[0] > b.max[0] { return false; }
  if a.max[1] < b.min[1] || a.min[1] > b.max[1] { return false; }
  if a.max[2] < b.min[2] || a.min[2] > b.max[2] { return false; }
  return true;
}

// Construct a sphere from center and radius. O(1).
pub fn sphere_new(center: &Vec[Float64], radius: Float64) -> Sphere {
  return Sphere{ center: center; radius: radius; };
}

// True iff p lies inside the sphere (inclusive). O(1).
pub fn sphere_contains(s: Sphere, p: &Vec[Float64]) -> Bool {
  if p.len() < 3 || s.center.len() < 3 { return false; }
  var dx = p[0] - s.center[0];
  var dy = p[1] - s.center[1];
  var dz = p[2] - s.center[2];
  return dx * dx + dy * dy + dz * dz <= s.radius * s.radius;
}

// True iff the two spheres overlap or touch. O(1).
pub fn sphere_intersects(a: Sphere, b: Sphere) -> Bool {
  if a.center.len() < 3 || b.center.len() < 3 { return false; }
  var dx = a.center[0] - b.center[0];
  var dy = a.center[1] - b.center[1];
  var dz = a.center[2] - b.center[2];
  var d2 = dx * dx + dy * dy + dz * dz;
  var r = a.radius + b.radius;
  return d2 <= r * r;
}

// Construct a ray from origin and direction. O(1).
pub fn ray_new(origin: &Vec[Float64], dir: &Vec[Float64]) -> Ray {
  return Ray{ origin: origin; dir: dir; };
}

// Ray-sphere intersection: nearest positive t; None on miss. O(1).
pub fn ray_sphere_intersect(r: Ray, s: Sphere) -> Option[Float64] {
  if r.origin.len() < 3 || r.dir.len() < 3 || s.center.len() < 3 {
    return None;
  }
  var ox = r.origin[0] - s.center[0];
  var oy = r.origin[1] - s.center[1];
  var oz = r.origin[2] - s.center[2];
  var dx = r.dir[0];
  var dy = r.dir[1];
  var dz = r.dir[2];
  var a = dx * dx + dy * dy + dz * dz;
  if a == 0.0 { return None; }
  var b = 2.0 * (ox * dx + oy * dy + oz * dz);
  var c = ox * ox + oy * oy + oz * oz - s.radius * s.radius;
  var disc = b * b - 4.0 * a * c;
  if disc < 0.0 { return None; }
  var sq = math.sqrt(disc);
  var t0 = (-b - sq) / (2.0 * a);
  var t1 = (-b + sq) / (2.0 * a);
  if t0 > 0.0 { return Some(t0); }
  if t1 > 0.0 { return Some(t1); }
  return None;
}

// Ray-AABB intersection via the slab method: nearest positive t; None on miss.
// O(1).
pub fn ray_aabb_intersect(r: Ray, a: Aabb) -> Option[Float64] {
  if r.origin.len() < 3 || r.dir.len() < 3 { return None; }
  if a.min.len() < 3 || a.max.len() < 3 { return None; }
  var tmin = 0.0;
  var tmax = 0.0;
  var dx = r.dir[0];
  if math.abs_float(dx) < 0.000000000001 {
    if r.origin[0] < a.min[0] || r.origin[0] > a.max[0] { return None; }
  } else {
    tmin = (a.min[0] - r.origin[0]) / dx;
    tmax = (a.max[0] - r.origin[0]) / dx;
    if tmin > tmax {
      var tmp = tmin;
      tmin = tmax;
      tmax = tmp;
    }
  }
  var dy = r.dir[1];
  if math.abs_float(dy) < 0.000000000001 {
    if r.origin[1] < a.min[1] || r.origin[1] > a.max[1] { return None; }
  } else {
    var tymin = (a.min[1] - r.origin[1]) / dy;
    var tymax = (a.max[1] - r.origin[1]) / dy;
    if tymin > tymax {
      var tmp = tymin;
      tymin = tymax;
      tymax = tmp;
    }
    if tymin > tmax || tymax < tmin { return None; }
    if tymin > tmin { tmin = tymin; }
    if tymax < tmax { tmax = tymax; }
  }
  var dz = r.dir[2];
  if math.abs_float(dz) < 0.000000000001 {
    if r.origin[2] < a.min[2] || r.origin[2] > a.max[2] { return None; }
  } else {
    var tzmin = (a.min[2] - r.origin[2]) / dz;
    var tzmax = (a.max[2] - r.origin[2]) / dz;
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

// Ray-plane intersection against the plane (n, d) given as the 4-element
// vector [nx, ny, nz, d] with n.p = d. None when parallel or behind. O(1).
pub fn ray_plane_intersect(r: Ray, plane: &Vec[Float64]) -> Option[Float64] {
  if r.origin.len() < 3 || r.dir.len() < 3 { return None; }
  if plane.len() < 4 { return None; }
  var nx = plane[0];
  var ny = plane[1];
  var nz = plane[2];
  var d = plane[3];
  var denom = r.dir[0] * nx + r.dir[1] * ny + r.dir[2] * nz;
  if math.abs_float(denom) < 0.000000000001 {
    return None;
  }
  var t = (d - (r.origin[0] * nx + r.origin[1] * ny + r.origin[2] * nz)) / denom;
  if t < 0.0 {
    return None;
  }
  return Some(t);
}

// True iff p is inside (or on) the triangle (a, b, c) using same-side tests
// on the 2D-projected coordinate with the dominant axis removed. O(1).
pub fn point_in_triangle(p: &Vec[Float64], a: &Vec[Float64], b: &Vec[Float64], c: &Vec[Float64]) -> Bool {
  if p.len() < 3 || a.len() < 3 || b.len() < 3 || c.len() < 3 { return false; }
  // Project to the 2D plane with the largest normal component removed.
  var ux = b[0] - a[0];
  var uy = b[1] - a[1];
  var uz = b[2] - a[2];
  var vx = c[0] - a[0];
  var vy = c[1] - a[1];
  var vz = c[2] - a[2];
  var nx = uy * vz - uz * vy;
  var ny = uz * vx - ux * vz;
  var nz = ux * vy - uy * vx;
  var ax = math.abs_float(nx);
  var ay = math.abs_float(ny);
  var az = math.abs_float(nz);
  var x0 = 0.0;
  var y0 = 0.0;
  var x1 = 0.0;
  var y1 = 0.0;
  var x2 = 0.0;
  var y2 = 0.0;
  var px = 0.0;
  var py = 0.0;
  if ax >= ay && ax >= az {
    x0 = a[1]; y0 = a[2];
    x1 = b[1]; y1 = b[2];
    x2 = c[1]; y2 = c[2];
    px = p[1]; py = p[2];
  } else if ay >= az {
    x0 = a[0]; y0 = a[2];
    x1 = b[0]; y1 = b[2];
    x2 = c[0]; y2 = c[2];
    px = p[0]; py = p[2];
  } else {
    x0 = a[0]; y0 = a[1];
    x1 = b[0]; y1 = b[1];
    x2 = c[0]; y2 = c[1];
    px = p[0]; py = p[1];
  }
  var d1 = (px - x1) * (y0 - y1) - (x0 - x1) * (py - y1);
  var d2 = (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2);
  var d3 = (px - x0) * (y2 - y0) - (x2 - x0) * (py - y0);
  var has_neg = d1 < 0.0 || d2 < 0.0 || d3 < 0.0;
  var has_pos = d1 > 0.0 || d2 > 0.0 || d3 > 0.0;
  return !(has_neg && has_pos);
}

// Intersection point of segments p1p2 and p3p4; None if disjoint or parallel.
// The result is a 3-component point. O(1).
pub fn segment_intersect(p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], p4: &Vec[Float64]) -> Option[Vec[Float64]] {
  var out = Vec[Float64].new();
  if p1.len() < 2 || p2.len() < 2 || p3.len() < 2 || p4.len() < 2 {
    return None;
  }
  var r1x = p2[0] - p1[0];
  var r1y = p2[1] - p1[1];
  var r2x = p4[0] - p3[0];
  var r2y = p4[1] - p3[1];
  var det = r1x * r2y - r1y * r2x;
  if math.abs_float(det) < 0.000000000001 {
    return None;
  }
  var qpx = p3[0] - p1[0];
  var qpy = p3[1] - p1[1];
  var t = (qpx * r2y - qpy * r2x) / det;
  var u = (qpx * r1y - qpy * r1x) / det;
  if t < 0.0 || t > 1.0 || u < 0.0 || u > 1.0 {
    return None;
  }
  out.push(p1[0] + t * r1x);
  out.push(p1[1] + t * r1y);
  return Some(out);
}

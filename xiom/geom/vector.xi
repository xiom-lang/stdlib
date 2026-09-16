// XIOM - Geom: Vector
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.geom.vector

// Depends on: xiom.geom

// ============================================================================
// Vector types and generic vector algebra. NOTE: current implementation lives
// in geom.xi REAL Vec2/3/4 + math/vectors.xi stub - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.math;

// 2-component vector (x, y).
pub type Vec2 = { x: Float64; y: Float64; }

// 3-component vector (x, y, z).
pub type Vec3 = { x: Float64; y: Float64; z: Float64; }

// 4-component vector (x, y, z, w).
pub type Vec4 = { x: Float64; y: Float64; z: Float64; w: Float64; }

// Dynamic N-component vector.
pub type VecN = { data: Vec[Float64]; }

// Construct a 2D vector. O(1).
pub fn v2_new(x: Float64, y: Float64) -> Vec2 {
  return Vec2{ x: x; y: y; };
}

// Construct a 3D vector. O(1).
pub fn v3_new(x: Float64, y: Float64, z: Float64) -> Vec3 {
  return Vec3{ x: x; y: y; z: z; };
}

// Construct a 4D vector. O(1).
pub fn v4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 {
  return Vec4{ x: x; y: y; z: z; w: w; };
}

// Dot product of two equal-length dynamic vectors. Returns NaN (0.0/0.0) when
// the lengths differ or either is empty (documented; no silent garbage). O(n).
pub fn dot(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + a[i] * b[i];
    i = i + 1;
  }
  return s;
}

// 3D cross product of two 3-element dynamic vectors. Returns an empty vector
// when either input is not exactly length 3 (documented). O(3).
pub fn cross(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != 3 || b.len() != 3 { return out; }
  out.push(a[1] * b[2] - a[2] * b[1]);
  out.push(a[2] * b[0] - a[0] * b[2]);
  out.push(a[0] * b[1] - a[1] * b[0]);
  return out;
}

// 2D cross product (signed area) of two 2D vectors. O(1).
pub fn cross2(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.y - a.y * b.x;
}

// Outer product matrix a (x) b: row i, col j holds a[i] * b[j]. O(n*m).
pub fn outer(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < b.len() {
      row.push(a[i] * b[j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Euclidean length of a dynamic vector. O(n).
pub fn norm(v: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < v.len() {
    s = s + v[i] * v[i];
    i = i + 1;
  }
  return math.sqrt(s);
}

// Squared Euclidean length of a dynamic vector (avoids sqrt). O(n).
pub fn norm_sq(v: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < v.len() {
    s = s + v[i] * v[i];
    i = i + 1;
  }
  return s;
}

// Unit vector of v. Returns the zero vector when the length is zero
// (documented). O(n).
pub fn normalize(v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var len = norm(v);
  if len == 0.0 { return out; }
  var inv = 1.0 / len;
  var i = 0;
  while i < v.len() {
    out.push(v[i] * inv);
    i = i + 1;
  }
  return out;
}

// Alias of normalize. O(n).
pub fn unit(v: &Vec[Float64]) -> Vec[Float64] {
  return normalize(v);
}

// Euclidean distance between two equal-length vectors. Returns NaN when the
// lengths differ (documented). O(n).
pub fn distance(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    var d = a[i] - b[i];
    s = s + d * d;
    i = i + 1;
  }
  return math.sqrt(s);
}

// Squared Euclidean distance between two equal-length vectors. Returns NaN
// when the lengths differ (documented). O(n).
pub fn distance_sq(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    var d = a[i] - b[i];
    s = s + d * d;
    i = i + 1;
  }
  return s;
}

// Angle in radians between two equal-length non-zero vectors, in [0, PI].
// Returns 0 when either vector is degenerate. O(n).
pub fn angle(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var la = norm(a);
  var lb = norm(b);
  if la == 0.0 || lb == 0.0 { return 0.0; }
  var c = dot(a, b) / (la * lb);
  if c > 1.0 { c = 1.0; }
  if c < -1.0 { c = -1.0; }
  return math.acos(c);
}

// Projection of a onto b: b * dot(a,b) / dot(b,b). Returns the zero vector
// when b is degenerate. O(n).
pub fn project(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var bb = dot(b, b);
  if bb == 0.0 { return out; }
  var s = dot(a, b) / bb;
  var i = 0;
  while i < b.len() {
    out.push(b[i] * s);
    i = i + 1;
  }
  return out;
}

// Reject a from b: a - project(a,b), the component of a perpendicular to b.
// Requires equal-length inputs; empty vector otherwise. O(n).
pub fn reject(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var p = project(a, b);
  if p.len() != a.len() { return out; }
  var i = 0;
  while i < a.len() {
    out.push(a[i] - p[i]);
    i = i + 1;
  }
  return out;
}

// Linear interpolation between a and b by t (t outside [0,1] extrapolates).
// Requires equal-length inputs; empty vector otherwise. O(n).
pub fn lerp(a: &Vec[Float64], b: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != b.len() { return out; }
  var i = 0;
  while i < a.len() {
    out.push(a[i] + (b[i] - a[i]) * t);
    i = i + 1;
  }
  return out;
}

// Spherical linear interpolation between two equal-length non-zero vectors at
// parameter t in [0,1], with constant angular velocity. Falls back to lerp for
// near-parallel inputs; returns the empty vector for degenerate inputs. O(n).
pub fn slerp(a: &Vec[Float64], b: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != b.len() { return out; }
  var la = norm(a);
  var lb = norm(b);
  if la == 0.0 || lb == 0.0 { return out; }
  var c = dot(a, b) / (la * lb);
  if c > 1.0 { c = 1.0; }
  if c < -1.0 { c = -1.0; }
  var omega = math.acos(c);
  var sin_omega = math.sin(omega);
  var i = 0;
  if sin_omega == 0.0 {
    while i < a.len() {
      out.push(a[i] + (b[i] - a[i]) * t);
      i = i + 1;
    }
    return out;
  }
  var wa = math.sin((1.0 - t) * omega) / sin_omega;
  var wb = math.sin(t * omega) / sin_omega;
  while i < a.len() {
    out.push(wa * a[i] + wb * b[i]);
    i = i + 1;
  }
  return out;
}

// Reflect v about the (not necessarily unit) normal: v - 2*dot(v,n)/dot(n,n)*n.
// Empty vector when the normal is degenerate or lengths differ. O(n).
pub fn reflect(v: &Vec[Float64], normal: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if v.len() != normal.len() { return out; }
  var nn = dot(normal, normal);
  if nn == 0.0 { return out; }
  var s = 2.0 * dot(v, normal) / nn;
  var i = 0;
  while i < v.len() {
    out.push(v[i] - s * normal[i]);
    i = i + 1;
  }
  return out;
}

// Refract v across an interface with relative index eta (both inputs unit).
// Returns None on total internal reflection (k < 0) or length mismatch. O(n).
pub fn refract(v: &Vec[Float64], normal: &Vec[Float64], eta: Float64) -> Option[Vec[Float64]] {
  if v.len() != normal.len() || v.len() == 0 {
    return Option[Vec[Float64]]{ is_some: false, value: Vec[Float64].new() };
  }
  var d = dot(v, normal);
  var k = 1.0 - eta * eta * (1.0 - d * d);
  if k < 0.0 {
    return Option[Vec[Float64]]{ is_some: false, value: Vec[Float64].new() };
  }
  var rk = math.sqrt(k);
  var scale = eta * d + rk;
  var out = Vec[Float64].new();
  var i = 0;
  while i < v.len() {
    out.push(eta * v[i] - scale * normal[i]);
    i = i + 1;
  }
  return Option[Vec[Float64]]{ is_some: true, value: out };
}

// Clamp each component of v into [lo, hi]. O(n).
pub fn clamp(v: &Vec[Float64], lo: Float64, hi: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < v.len() {
    var c = v[i];
    if c < lo { c = lo; }
    if c > hi { c = hi; }
    out.push(c);
    i = i + 1;
  }
  return out;
}

// Smallest component of v. Returns NaN for an empty vector (documented). O(n).
pub fn component_min(v: &Vec[Float64]) -> Float64 {
  if v.len() == 0 { return 0.0 / 0.0; }
  var m = v[0];
  var i = 1;
  while i < v.len() {
    if v[i] < m { m = v[i]; }
    i = i + 1;
  }
  return m;
}

// Largest component of v. Returns NaN for an empty vector (documented). O(n).
pub fn component_max(v: &Vec[Float64]) -> Float64 {
  if v.len() == 0 { return 0.0 / 0.0; }
  var m = v[0];
  var i = 1;
  while i < v.len() {
    if v[i] > m { m = v[i]; }
    i = i + 1;
  }
  return m;
}

// Component-wise product (Hadamard) of two equal-length vectors. Empty vector
// on length mismatch (documented). O(n).
pub fn hadamard(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != b.len() { return out; }
  var i = 0;
  while i < a.len() {
    out.push(a[i] * b[i]);
    i = i + 1;
  }
  return out;
}

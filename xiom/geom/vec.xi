// XIOM - Geom: Vec
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Home: geom.xi - this sublib splits the vector domain; the canonical Vec2/3/4
// types and operations live in geom.xi.

module xiom.geom.vec

// Depends on: xiom.geom

// ============================================================================
// Vector operations split from geom.xi: construction, arithmetic, projections,
// reflections, angles. TODO(compiler): implement.
// ============================================================================

use xiom.geom;
use xiom.math;

/// Construct a 2D vector. Delegates to geom.vec2_new. O(1).
pub fn vec2(x: Float64, y: Float64) -> Vec2 {
  return geom.vec2_new(x, y);
}

/// Add two 2D vectors component-wise. Implemented locally (same name as the
/// canonical geom.vec2_add; same-name delegation is avoided). O(1).
pub fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x + b.x; y: a.y + b.y; };
}

/// Subtract b from a component-wise. Implemented locally (name collision). O(1).
pub fn vec2_sub(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x - b.x; y: a.y - b.y; };
}

/// Multiply each component of v by scalar s. Delegates to geom.vec2_mul_scalar. O(1).
pub fn vec2_scale(v: Vec2, s: Float64) -> Vec2 {
  return geom.vec2_mul_scalar(v, s);
}

/// Dot product of two 2D vectors. Implemented locally (name collision). O(1).
pub fn vec2_dot(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.x + a.y * b.y;
}

/// 2D cross product (scalar, signed area). Implemented locally (name collision). O(1).
pub fn vec2_cross(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.y - a.y * b.x;
}

/// Euclidean length of a 2D vector. Delegates to geom.vec2_length. O(1).
pub fn vec2_len(v: Vec2) -> Float64 {
  return geom.vec2_length(v);
}

/// Unit vector of v; zero vector when the length is zero. Delegates to
/// geom.vec2_normalize. O(1).
pub fn vec2_norm(v: Vec2) -> Vec2 {
  return geom.vec2_normalize(v);
}

/// Euclidean distance between two 2D points. Delegates to geom.vec2_distance. O(1).
pub fn vec2_dist(a: Vec2, b: Vec2) -> Float64 {
  return geom.vec2_distance(a, b);
}

/// Linear interpolation between a and b by t (t outside [0,1] extrapolates).
/// Implemented locally: the canonical geom.vec2_lerp returns a scalar, so a
/// full Vec2 result requires a dedicated implementation. O(1).
pub fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Vec2 {
  return Vec2{
    x: a.x + (b.x - a.x) * t;
    y: a.y + (b.y - a.y) * t;
  };
}

/// Construct a 3D vector. Implemented locally (name collision). O(1).
pub fn vec3_new(x: Float64, y: Float64, z: Float64) -> Vec3 {
  return Vec3{ x: x; y: y; z: z; };
}

/// Add two 3D vectors component-wise. Implemented locally (name collision). O(1).
pub fn vec3_add(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x + b.x; y: a.y + b.y; z: a.z + b.z; };
}

/// Subtract b from a component-wise. Implemented locally (name collision). O(1).
pub fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x - b.x; y: a.y - b.y; z: a.z - b.z; };
}

/// Multiply each component of v by scalar s. Delegates to geom.vec3_mul_scalar. O(1).
pub fn vec3_scale(v: Vec3, s: Float64) -> Vec3 {
  return geom.vec3_mul_scalar(v, s);
}

/// Dot product of two 3D vectors. Implemented locally (name collision). O(1).
pub fn vec3_dot(a: Vec3, b: Vec3) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Right-handed cross product a x b. Implemented locally (name collision). O(1).
pub fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{
    x: a.y * b.z - a.z * b.y;
    y: a.z * b.x - a.x * b.z;
    z: a.x * b.y - a.y * b.x;
  };
}

/// Euclidean length of a 3D vector. Delegates to geom.vec3_length. O(1).
pub fn vec3_len(v: Vec3) -> Float64 {
  return geom.vec3_length(v);
}

/// Unit vector of v; zero vector when the length is zero. Delegates to
/// geom.vec3_normalize. O(1).
pub fn vec3_norm(v: Vec3) -> Vec3 {
  return geom.vec3_normalize(v);
}

/// Euclidean distance between two 3D points. Delegates to geom.vec3_distance. O(1).
pub fn vec3_dist(a: Vec3, b: Vec3) -> Float64 {
  return geom.vec3_distance(a, b);
}

/// Construct a 4D vector. Implemented locally (name collision). O(1).
pub fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 {
  return Vec4{ x: x; y: y; z: z; w: w; };
}

/// Add two 4D vectors component-wise. No canonical dynamic equivalent; local. O(1).
pub fn vec4_add(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x + b.x; y: a.y + b.y; z: a.z + b.z; w: a.w + b.w; };
}

/// Subtract b from a component-wise. No canonical dynamic equivalent; local. O(1).
pub fn vec4_sub(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x - b.x; y: a.y - b.y; z: a.z - b.z; w: a.w - b.w; };
}

/// Multiply each component of v by scalar s. Implemented locally (name collision). O(1).
pub fn vec4_scale(v: Vec4, s: Float64) -> Vec4 {
  return Vec4{ x: v.x * s; y: v.y * s; z: v.z * s; w: v.w * s; };
}

/// Dot product of two 4D vectors. No canonical equivalent; local. O(1).
pub fn vec4_dot(a: Vec4, b: Vec4) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

/// Euclidean length of a 4D vector. No canonical equivalent; local. O(4).
pub fn vec4_len(v: Vec4) -> Float64 {
  var s = v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w;
  return math.sqrt(s);
}

/// Unit vector of v; zero vector when the length is zero. Local (no canonical
/// equivalent for the vec4 length/normalise pair). O(4).
pub fn vec4_norm(v: Vec4) -> Vec4 {
  var len = vec4_len(v);
  if len == 0.0 { return Vec4{ x: 0.0; y: 0.0; z: 0.0; w: 0.0; }; }
  return Vec4{ x: v.x / len; y: v.y / len; z: v.z / len; w: v.w / len; };
}

/// Reflect the dynamic vector v about a surface normal n: v - 2*dot(v,n)*n.
/// The normal is normalised first (any non-zero direction is accepted); a
/// degenerate normal returns a copy of v. Dynamic-domain operation with no
/// canonical Vec[Float64] equivalent in geom.xi. O(n).
pub fn vec_reflect(v: &Vec[Float64], n: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if v.len() != n.len() { return out; }
  var nl = 0.0;
  var i = 0;
  while i < n.len() {
    nl = nl + n[i] * n[i];
    i = i + 1;
  }
  if nl == 0.0 {
    i = 0;
    while i < v.len() {
      out.push(v[i]);
      i = i + 1;
    }
    return out;
  }
  var inv = 1.0 / math.sqrt(nl);
  var d = 0.0;
  i = 0;
  while i < v.len() {
    d = d + v[i] * (n[i] * inv);
    i = i + 1;
  }
  var s = 2.0 * d;
  i = 0;
  while i < v.len() {
    out.push(v[i] - s * (n[i] * inv));
    i = i + 1;
  }
  return out;
}

/// Scalar projection of a onto b: dot(a, b) / |b|. Zero when b is degenerate.
/// Dynamic-domain operation with no canonical Vec[Float64] equivalent. O(n).
pub fn vec_project(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() || b.len() == 0 { return 0.0 / 0.0; }
  var lb = 0.0;
  var d = 0.0;
  var i = 0;
  while i < a.len() {
    lb = lb + b[i] * b[i];
    d = d + a[i] * b[i];
    i = i + 1;
  }
  if lb == 0.0 { return 0.0; }
  return d / math.sqrt(lb);
}

/// Angle in radians between two equal-length non-zero vectors, in [0, PI].
/// Returns 0 when either vector is degenerate. Dynamic-domain operation. O(n).
pub fn vec_angle(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() || a.len() == 0 { return 0.0 / 0.0; }
  var la = 0.0;
  var lb = 0.0;
  var d = 0.0;
  var i = 0;
  while i < a.len() {
    la = la + a[i] * a[i];
    lb = lb + b[i] * b[i];
    d = d + a[i] * b[i];
    i = i + 1;
  }
  if la == 0.0 || lb == 0.0 { return 0.0; }
  var c = d / (math.sqrt(la) * math.sqrt(lb));
  if c > 1.0 { c = 1.0; }
  if c < -1.0 { c = -1.0; }
  return math.acos(c);
}

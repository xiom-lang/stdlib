// XIOM - Math: Vectors
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.vectors

// Depends on: xiom.math

// ============================================================================
// Fixed-size 2/3/4 component vectors and generic dynamic vectors.
//
// The fixed-size structs (Vec2/Vec3/Vec4) are declared here and stay in this
// module (nominal struct types: geom.xi declares semantically identical
// vectors, but cross-module delegation is impossible without conversions, so
// the component arithmetic is implemented directly). Lengths reuse
// math.roots.hypot for overflow-safe norms. The dynamic vec_* functions
// operate on generic Vec[Float64]. All domain handling is guarded in the
// bodies (requires/ensures are runtime-enforced and would trap).
// ============================================================================

use xiom.math;

/// 2-component vector (x, y).
pub type Vec2 = { x: Float64; y: Float64; }

/// 3-component vector (x, y, z).
pub type Vec3 = { x: Float64; y: Float64; z: Float64; }

/// 4-component vector (x, y, z, w).
pub type Vec4 = { x: Float64; y: Float64; z: Float64; w: Float64; }

// ============================================================================
// Vec2
// ============================================================================

/// Construct a 2D vector. O(1).
pub fn vec2_new(x: Float64, y: Float64) -> Vec2 {
  return Vec2{ x: x; y: y; };
}

/// Component-wise addition of two 2D vectors. O(1).
pub fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x + b.x; y: a.y + b.y; };
}

/// Component-wise subtraction (a - b) of two 2D vectors. O(1).
pub fn vec2_sub(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x - b.x; y: a.y - b.y; };
}

/// Multiply each component of a 2D vector by scalar s. O(1).
pub fn vec2_scale(v: Vec2, s: Float64) -> Vec2 {
  return Vec2{ x: v.x * s; y: v.y * s; };
}

/// Dot product of two 2D vectors. O(1).
pub fn vec2_dot(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.x + a.y * b.y;
}

/// Euclidean length of a 2D vector. Overflow-safe via math.roots.hypot. O(1).
pub fn vec2_len(v: Vec2) -> Float64 {
  return math.roots.hypot(v.x, v.y);
}

/// Unit vector of a 2D vector. Returns the zero vector when the length is
/// zero (documented). O(1).
pub fn vec2_norm(v: Vec2) -> Vec2 {
  var len = math.roots.hypot(v.x, v.y);
  if len == 0.0 { return Vec2{ x: 0.0; y: 0.0; }; }
  return Vec2{ x: v.x / len; y: v.y / len; };
}

/// Euclidean distance between two 2D points. O(1).
pub fn vec2_dist(a: Vec2, b: Vec2) -> Float64 {
  return math.roots.hypot(a.x - b.x, a.y - b.y);
}

/// Component-wise linear interpolation between a and b by t (t outside [0, 1]
/// extrapolates; t is not clamped). O(1).
pub fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Vec2 {
  return Vec2{
    x: a.x + (b.x - a.x) * t;
    y: a.y + (b.y - a.y) * t;
  };
}

// ============================================================================
// Vec3
// ============================================================================

/// Construct a 3D vector. O(1).
pub fn vec3_new(x: Float64, y: Float64, z: Float64) -> Vec3 {
  return Vec3{ x: x; y: y; z: z; };
}

/// Component-wise addition of two 3D vectors. O(1).
pub fn vec3_add(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x + b.x; y: a.y + b.y; z: a.z + b.z; };
}

/// Component-wise subtraction (a - b) of two 3D vectors. O(1).
pub fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x - b.x; y: a.y - b.y; z: a.z - b.z; };
}

/// Multiply each component of a 3D vector by scalar s. O(1).
pub fn vec3_scale(v: Vec3, s: Float64) -> Vec3 {
  return Vec3{ x: v.x * s; y: v.y * s; z: v.z * s; };
}

/// Dot product of two 3D vectors. O(1).
pub fn vec3_dot(a: Vec3, b: Vec3) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Right-handed cross product a x b of two 3D vectors. O(1).
pub fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{
    x: a.y * b.z - a.z * b.y;
    y: a.z * b.x - a.x * b.z;
    z: a.x * b.y - a.y * b.x;
  };
}

/// Euclidean length of a 3D vector. Overflow-safe via math.roots.hypot3. O(1).
pub fn vec3_len(v: Vec3) -> Float64 {
  return math.roots.hypot3(v.x, v.y, v.z);
}

/// Unit vector of a 3D vector. Returns the zero vector when the length is
/// zero (documented). O(1).
pub fn vec3_norm(v: Vec3) -> Vec3 {
  var len = math.roots.hypot3(v.x, v.y, v.z);
  if len == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  return Vec3{ x: v.x / len; y: v.y / len; z: v.z / len; };
}

// ============================================================================
// Vec4
// ============================================================================

/// Construct a 4D vector. O(1).
pub fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 {
  return Vec4{ x: x; y: y; z: z; w: w; };
}

/// Component-wise addition of two 4D vectors. O(1).
pub fn vec4_add(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x + b.x; y: a.y + b.y; z: a.z + b.z; w: a.w + b.w; };
}

/// Component-wise subtraction (a - b) of two 4D vectors. O(1).
pub fn vec4_sub(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x - b.x; y: a.y - b.y; z: a.z - b.z; w: a.w - b.w; };
}

/// Multiply each component of a 4D vector by scalar s. O(1).
pub fn vec4_scale(v: Vec4, s: Float64) -> Vec4 {
  return Vec4{ x: v.x * s; y: v.y * s; z: v.z * s; w: v.w * s; };
}

/// Dot product of two 4D vectors. O(1).
pub fn vec4_dot(a: Vec4, b: Vec4) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

/// Euclidean length of a 4D vector: sqrt(sum of squared components). O(4).
pub fn vec4_len(v: Vec4) -> Float64 {
  return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
}

/// Unit vector of a 4D vector. Returns the zero vector when the length is
/// zero (documented). O(4).
pub fn vec4_norm(v: Vec4) -> Vec4 {
  var len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
  if len == 0.0 { return Vec4{ x: 0.0; y: 0.0; z: 0.0; w: 0.0; }; }
  return Vec4{ x: v.x / len; y: v.y / len; z: v.z / len; w: v.w / len; };
}

// ============================================================================
// Dynamic vectors (generic Vec[Float64])
// ============================================================================

/// Dot product of two equal-length dynamic vectors. Returns NaN (0.0/0.0)
/// when the vectors differ in length (documented; no silent garbage). O(n).
pub fn vec_dot(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
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

/// Euclidean length of a dynamic vector. O(n).
pub fn vec_norm(v: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < v.len() {
    s = s + v[i] * v[i];
    i = i + 1;
  }
  return math.sqrt(s);
}

/// Multiply each component of v by scalar s, returning a new vector. O(n).
pub fn vec_scale(v: &Vec[Float64], s: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i] * s);
    i = i + 1;
  }
  return out;
}

// XIOM - SIMD: 4-lane Vectors
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.vec4

// Depends on: none

use xiom.math.sqrt;

// ============================================================================
// 4-lane single-precision and 32-bit integer SIMD vector arithmetic, loads
// and stores.
//
// Scalar fallback: each vector is four scalar lanes stored in a plain struct.
// There is no real SIMD acceleration in this build (that is the compiler
// session's runtime domain); the API is fully implemented with scalar
// arithmetic. Use `f32x4_extract`/`f32x4_insert` and friends to read lanes --
// direct cross-module field reads of multi-field structs are unreliable in
// this build.
// ============================================================================

/// A 4-lane single-precision SIMD vector.
pub type F32x4 = {
  a: Float32;
  b: Float32;
  c: Float32;
  d: Float32;
} derive[Clone]

/// A 4-lane 32-bit integer SIMD vector.
pub type I32x4 = {
  a: Int;
  b: Int;
  c: Int;
  d: Int;
} derive[Clone]

/// Build a vector from four lanes.
/// Complexity: O(1).
pub fn f32x4_new(a: Float32, b: Float32, c: Float32, d: Float32) -> F32x4 {
  F32x4{ a: a; b: b; c: c; d: d; }
}

/// Lane-wise addition.
/// Complexity: O(1).
pub fn f32x4_add(x: F32x4, y: F32x4) -> F32x4 {
  F32x4{ a: x.a + y.a; b: x.b + y.b; c: x.c + y.c; d: x.d + y.d; }
}

/// Lane-wise subtraction.
/// Complexity: O(1).
pub fn f32x4_sub(x: F32x4, y: F32x4) -> F32x4 {
  F32x4{ a: x.a - y.a; b: x.b - y.b; c: x.c - y.c; d: x.d - y.d; }
}

/// Lane-wise multiplication.
/// Complexity: O(1).
pub fn f32x4_mul(x: F32x4, y: F32x4) -> F32x4 {
  F32x4{ a: x.a * y.a; b: x.b * y.b; c: x.c * y.c; d: x.d * y.d; }
}

/// Lane-wise division.
/// Complexity: O(1).
pub fn f32x4_div(x: F32x4, y: F32x4) -> F32x4 {
  F32x4{ a: x.a / y.a; b: x.b / y.b; c: x.c / y.c; d: x.d / y.d; }
}

/// Lane-wise square root.
/// Complexity: O(1).
pub fn f32x4_sqrt(x: F32x4) -> F32x4
  requires: true  // extern sqrt calls below (T002 confinement)
{
  F32x4{ a: sqrt(x.a as Float64) as Float32; b: sqrt(x.b as Float64) as Float32; c: sqrt(x.c as Float64) as Float32; d: sqrt(x.d as Float64) as Float32; }
}

/// Lane-wise minimum.
/// Complexity: O(1).
pub fn f32x4_min(x: F32x4, y: F32x4) -> F32x4 {
  var a = x.a;
  if y.a < a {
    a = y.a;
  };
  var b = x.b;
  if y.b < b {
    b = y.b;
  };
  var c = x.c;
  if y.c < c {
    c = y.c;
  };
  var d = x.d;
  if y.d < d {
    d = y.d;
  };
  F32x4{ a: a; b: b; c: c; d: d; }
}

/// Lane-wise maximum.
/// Complexity: O(1).
pub fn f32x4_max(x: F32x4, y: F32x4) -> F32x4 {
  var a = x.a;
  if y.a > a {
    a = y.a;
  };
  var b = x.b;
  if y.b > b {
    b = y.b;
  };
  var c = x.c;
  if y.c > c {
    c = y.c;
  };
  var d = x.d;
  if y.d > d {
    d = y.d;
  };
  F32x4{ a: a; b: b; c: c; d: d; }
}

/// The dot product of two vectors.
/// Complexity: O(1).
pub fn f32x4_dot(x: F32x4, y: F32x4) -> Float32 {
  x.a * y.a + x.b * y.b + x.c * y.c + x.d * y.d
}

/// Load a vector from aligned memory (16 bytes, four Float32 values).
/// Complexity: O(1).
pub fn f32x4_load(ptr: Int) -> F32x4
  requires: ptr != 0
{
  unsafe {
    let p = ptr as *Float32;
    F32x4{ a: p[0]; b: p[1]; c: p[2]; d: p[3]; }
  }
}

/// Store a vector to aligned memory (16 bytes).
/// Complexity: O(1).
pub fn f32x4_store(ptr: Int, x: F32x4)
  requires: ptr != 0
{
  unsafe {
    let p = ptr as *Float32;
    p[0] = x.a;
    p[1] = x.b;
    p[2] = x.c;
    p[3] = x.d;
  }
}

/// Fill every lane with `v`.
/// Complexity: O(1).
pub fn f32x4_splat(v: Float32) -> F32x4 {
  F32x4{ a: v; b: v; c: v; d: v; }
}

/// Read lane `i` (0..3).
/// Complexity: O(1).
pub fn f32x4_extract(x: F32x4, i: Int) -> Float32 {
  if i <= 0 {
    return x.a;
  };
  if i == 1 {
    return x.b;
  };
  if i == 2 {
    return x.c;
  };
  x.d
}

/// Write lane `i` and return the vector.
/// Complexity: O(1).
pub fn f32x4_insert(x: F32x4, i: Int, v: Float32) -> F32x4 {
  var a = x.a;
  var b = x.b;
  var c = x.c;
  var d = x.d;
  if i <= 0 {
    a = v;
  } elif i == 1 {
    b = v;
  } elif i == 2 {
    c = v;
  } else {
    d = v;
  };
  F32x4{ a: a; b: b; c: c; d: d; }
}

/// The sum of all lanes.
/// Complexity: O(1).
pub fn f32x4_sum(x: F32x4) -> Float32 {
  x.a + x.b + x.c + x.d
}

/// Build a vector from four integer lanes.
/// Complexity: O(1).
pub fn i32x4_new(a: Int, b: Int, c: Int, d: Int) -> I32x4 {
  I32x4{ a: a; b: b; c: c; d: d; }
}

/// Lane-wise addition.
/// Complexity: O(1).
pub fn i32x4_add(x: I32x4, y: I32x4) -> I32x4 {
  I32x4{ a: x.a + y.a; b: x.b + y.b; c: x.c + y.c; d: x.d + y.d; }
}

/// Lane-wise subtraction.
/// Complexity: O(1).
pub fn i32x4_sub(x: I32x4, y: I32x4) -> I32x4 {
  I32x4{ a: x.a - y.a; b: x.b - y.b; c: x.c - y.c; d: x.d - y.d; }
}

/// Lane-wise multiplication.
/// Complexity: O(1).
pub fn i32x4_mul(x: I32x4, y: I32x4) -> I32x4 {
  I32x4{ a: x.a * y.a; b: x.b * y.b; c: x.c * y.c; d: x.d * y.d; }
}

/// Lane-wise minimum.
/// Complexity: O(1).
pub fn i32x4_min(x: I32x4, y: I32x4) -> I32x4 {
  var a = x.a;
  if y.a < a {
    a = y.a;
  };
  var b = x.b;
  if y.b < b {
    b = y.b;
  };
  var c = x.c;
  if y.c < c {
    c = y.c;
  };
  var d = x.d;
  if y.d < d {
    d = y.d;
  };
  I32x4{ a: a; b: b; c: c; d: d; }
}

/// Lane-wise maximum.
/// Complexity: O(1).
pub fn i32x4_max(x: I32x4, y: I32x4) -> I32x4 {
  var a = x.a;
  if y.a > a {
    a = y.a;
  };
  var b = x.b;
  if y.b > b {
    b = y.b;
  };
  var c = x.c;
  if y.c > c {
    c = y.c;
  };
  var d = x.d;
  if y.d > d {
    d = y.d;
  };
  I32x4{ a: a; b: b; c: c; d: d; }
}

/// Fill every lane with `v`.
/// Complexity: O(1).
pub fn i32x4_splat(v: Int) -> I32x4 {
  I32x4{ a: v; b: v; c: v; d: v; }
}

/// Read lane `i` (0..3).
/// Complexity: O(1).
pub fn i32x4_extract(x: I32x4, i: Int) -> Int {
  if i <= 0 {
    return x.a;
  };
  if i == 1 {
    return x.b;
  };
  if i == 2 {
    return x.c;
  };
  x.d
}

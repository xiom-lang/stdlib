// XIOM - SIMD: 8-lane Vectors
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.vec8

// Depends on: none

use xiom.math.sqrt;

// ============================================================================
// 8-lane single-precision and 32-bit integer SIMD vector arithmetic, loads
// and stores.
//
// Scalar fallback: each vector is eight scalar lanes stored in a plain
// struct. There is no real SIMD acceleration in this build (that is the
// compiler session's runtime domain). Use `f32x8_extract`/`f32x8_insert` to
// read and write lanes -- direct cross-module field reads of multi-field
// structs are unreliable in this build.
// ============================================================================

/// An 8-lane single-precision SIMD vector.
pub type F32x8 = {
  a0: Float32;
  a1: Float32;
  a2: Float32;
  a3: Float32;
  a4: Float32;
  a5: Float32;
  a6: Float32;
  a7: Float32;
} derive[Clone]

/// An 8-lane 32-bit integer SIMD vector.
pub type I32x8 = {
  a0: Int;
  a1: Int;
  a2: Int;
  a3: Int;
  a4: Int;
  a5: Int;
  a6: Int;
  a7: Int;
} derive[Clone]

/// Build a vector from a fixed 8-element array.
/// Complexity: O(1).
pub fn f32x8_new(v: [8]Float32) -> F32x8 {
  F32x8{ a0: v[0]; a1: v[1]; a2: v[2]; a3: v[3]; a4: v[4]; a5: v[5]; a6: v[6]; a7: v[7]; }
}

/// Lane-wise addition.
/// Complexity: O(1).
pub fn f32x8_add(x: F32x8, y: F32x8) -> F32x8 {
  F32x8{ a0: x.a0 + y.a0; a1: x.a1 + y.a1; a2: x.a2 + y.a2; a3: x.a3 + y.a3; a4: x.a4 + y.a4; a5: x.a5 + y.a5; a6: x.a6 + y.a6; a7: x.a7 + y.a7; }
}

/// Lane-wise subtraction.
/// Complexity: O(1).
pub fn f32x8_sub(x: F32x8, y: F32x8) -> F32x8 {
  F32x8{ a0: x.a0 - y.a0; a1: x.a1 - y.a1; a2: x.a2 - y.a2; a3: x.a3 - y.a3; a4: x.a4 - y.a4; a5: x.a5 - y.a5; a6: x.a6 - y.a6; a7: x.a7 - y.a7; }
}

/// Lane-wise multiplication.
/// Complexity: O(1).
pub fn f32x8_mul(x: F32x8, y: F32x8) -> F32x8 {
  F32x8{ a0: x.a0 * y.a0; a1: x.a1 * y.a1; a2: x.a2 * y.a2; a3: x.a3 * y.a3; a4: x.a4 * y.a4; a5: x.a5 * y.a5; a6: x.a6 * y.a6; a7: x.a7 * y.a7; }
}

/// Lane-wise division.
/// Complexity: O(1).
pub fn f32x8_div(x: F32x8, y: F32x8) -> F32x8 {
  F32x8{ a0: x.a0 / y.a0; a1: x.a1 / y.a1; a2: x.a2 / y.a2; a3: x.a3 / y.a3; a4: x.a4 / y.a4; a5: x.a5 / y.a5; a6: x.a6 / y.a6; a7: x.a7 / y.a7; }
}

/// Lane-wise square root.
/// Complexity: O(1).
pub fn f32x8_sqrt(x: F32x8) -> F32x8 {
  F32x8{ a0: sqrt(x.a0 as Float64) as Float32; a1: sqrt(x.a1 as Float64) as Float32; a2: sqrt(x.a2 as Float64) as Float32; a3: sqrt(x.a3 as Float64) as Float32; a4: sqrt(x.a4 as Float64) as Float32; a5: sqrt(x.a5 as Float64) as Float32; a6: sqrt(x.a6 as Float64) as Float32; a7: sqrt(x.a7 as Float64) as Float32; }
}

/// Lane-wise minimum.
/// Complexity: O(1).
pub fn f32x8_min(x: F32x8, y: F32x8) -> F32x8 {
  var a0 = x.a0;
  if y.a0 < a0 {
    a0 = y.a0;
  };
  var a1 = x.a1;
  if y.a1 < a1 {
    a1 = y.a1;
  };
  var a2 = x.a2;
  if y.a2 < a2 {
    a2 = y.a2;
  };
  var a3 = x.a3;
  if y.a3 < a3 {
    a3 = y.a3;
  };
  var a4 = x.a4;
  if y.a4 < a4 {
    a4 = y.a4;
  };
  var a5 = x.a5;
  if y.a5 < a5 {
    a5 = y.a5;
  };
  var a6 = x.a6;
  if y.a6 < a6 {
    a6 = y.a6;
  };
  var a7 = x.a7;
  if y.a7 < a7 {
    a7 = y.a7;
  };
  F32x8{ a0: a0; a1: a1; a2: a2; a3: a3; a4: a4; a5: a5; a6: a6; a7: a7; }
}

/// Lane-wise maximum.
/// Complexity: O(1).
pub fn f32x8_max(x: F32x8, y: F32x8) -> F32x8 {
  var a0 = x.a0;
  if y.a0 > a0 {
    a0 = y.a0;
  };
  var a1 = x.a1;
  if y.a1 > a1 {
    a1 = y.a1;
  };
  var a2 = x.a2;
  if y.a2 > a2 {
    a2 = y.a2;
  };
  var a3 = x.a3;
  if y.a3 > a3 {
    a3 = y.a3;
  };
  var a4 = x.a4;
  if y.a4 > a4 {
    a4 = y.a4;
  };
  var a5 = x.a5;
  if y.a5 > a5 {
    a5 = y.a5;
  };
  var a6 = x.a6;
  if y.a6 > a6 {
    a6 = y.a6;
  };
  var a7 = x.a7;
  if y.a7 > a7 {
    a7 = y.a7;
  };
  F32x8{ a0: a0; a1: a1; a2: a2; a3: a3; a4: a4; a5: a5; a6: a6; a7: a7; }
}

/// Fill every lane with `v`.
/// Complexity: O(1).
pub fn f32x8_splat(v: Float32) -> F32x8 {
  F32x8{ a0: v; a1: v; a2: v; a3: v; a4: v; a5: v; a6: v; a7: v; }
}

/// Read lane `i` (0..7).
/// Complexity: O(1).
pub fn f32x8_extract(x: F32x8, i: Int) -> Float32 {
  if i <= 0 {
    return x.a0;
  };
  if i == 1 {
    return x.a1;
  };
  if i == 2 {
    return x.a2;
  };
  if i == 3 {
    return x.a3;
  };
  if i == 4 {
    return x.a4;
  };
  if i == 5 {
    return x.a5;
  };
  if i == 6 {
    return x.a6;
  };
  x.a7
}

/// Write lane `i` and return the vector.
/// Complexity: O(1).
pub fn f32x8_insert(x: F32x8, i: Int, v: Float32) -> F32x8 {
  var a0 = x.a0;
  var a1 = x.a1;
  var a2 = x.a2;
  var a3 = x.a3;
  var a4 = x.a4;
  var a5 = x.a5;
  var a6 = x.a6;
  var a7 = x.a7;
  if i <= 0 {
    a0 = v;
  } elif i == 1 {
    a1 = v;
  } elif i == 2 {
    a2 = v;
  } elif i == 3 {
    a3 = v;
  } elif i == 4 {
    a4 = v;
  } elif i == 5 {
    a5 = v;
  } elif i == 6 {
    a6 = v;
  } else {
    a7 = v;
  };
  F32x8{ a0: a0; a1: a1; a2: a2; a3: a3; a4: a4; a5: a5; a6: a6; a7: a7; }
}

/// The sum of all lanes.
/// Complexity: O(1).
pub fn f32x8_sum(x: F32x8) -> Float32 {
  x.a0 + x.a1 + x.a2 + x.a3 + x.a4 + x.a5 + x.a6 + x.a7
}

/// Load a vector from aligned memory (32 bytes, eight Float32 values).
/// Complexity: O(1).
pub fn f32x8_load(ptr: Int) -> F32x8
  requires: ptr != 0
{
  unsafe {
    let p = ptr as *Float32;
    F32x8{ a0: p[0]; a1: p[1]; a2: p[2]; a3: p[3]; a4: p[4]; a5: p[5]; a6: p[6]; a7: p[7]; }
  }
}

/// Store a vector to aligned memory (32 bytes).
/// Complexity: O(1).
pub fn f32x8_store(ptr: Int, x: F32x8)
  requires: ptr != 0
{
  unsafe {
    let p = ptr as *Float32;
    p[0] = x.a0;
    p[1] = x.a1;
    p[2] = x.a2;
    p[3] = x.a3;
    p[4] = x.a4;
    p[5] = x.a5;
    p[6] = x.a6;
    p[7] = x.a7;
  }
}

/// Build a vector from a fixed 8-element integer array.
/// Complexity: O(1).
pub fn i32x8_new(v: [8]Int) -> I32x8 {
  I32x8{ a0: v[0]; a1: v[1]; a2: v[2]; a3: v[3]; a4: v[4]; a5: v[5]; a6: v[6]; a7: v[7]; }
}

/// Lane-wise addition.
/// Complexity: O(1).
pub fn i32x8_add(x: I32x8, y: I32x8) -> I32x8 {
  I32x8{ a0: x.a0 + y.a0; a1: x.a1 + y.a1; a2: x.a2 + y.a2; a3: x.a3 + y.a3; a4: x.a4 + y.a4; a5: x.a5 + y.a5; a6: x.a6 + y.a6; a7: x.a7 + y.a7; }
}

/// Lane-wise subtraction.
/// Complexity: O(1).
pub fn i32x8_sub(x: I32x8, y: I32x8) -> I32x8 {
  I32x8{ a0: x.a0 - y.a0; a1: x.a1 - y.a1; a2: x.a2 - y.a2; a3: x.a3 - y.a3; a4: x.a4 - y.a4; a5: x.a5 - y.a5; a6: x.a6 - y.a6; a7: x.a7 - y.a7; }
}

/// Lane-wise multiplication.
/// Complexity: O(1).
pub fn i32x8_mul(x: I32x8, y: I32x8) -> I32x8 {
  I32x8{ a0: x.a0 * y.a0; a1: x.a1 * y.a1; a2: x.a2 * y.a2; a3: x.a3 * y.a3; a4: x.a4 * y.a4; a5: x.a5 * y.a5; a6: x.a6 * y.a6; a7: x.a7 * y.a7; }
}

/// Fill every lane with `v`.
/// Complexity: O(1).
pub fn i32x8_splat(v: Int) -> I32x8 {
  I32x8{ a0: v; a1: v; a2: v; a3: v; a4: v; a5: v; a6: v; a7: v; }
}

/// Read lane `i` (0..7).
/// Complexity: O(1).
pub fn i32x8_extract(x: I32x8, i: Int) -> Int {
  if i <= 0 {
    return x.a0;
  };
  if i == 1 {
    return x.a1;
  };
  if i == 2 {
    return x.a2;
  };
  if i == 3 {
    return x.a3;
  };
  if i == 4 {
    return x.a4;
  };
  if i == 5 {
    return x.a5;
  };
  if i == 6 {
    return x.a6;
  };
  x.a7
}

// p_wave76_shapes.xi -- wave 76 shape validation: simd (gather/mask/vec4/vec8)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-76 clause guards on xiom.simd.gather (5),
// xiom.simd.mask (14), xiom.simd.vec4 (17) and xiom.simd.vec8 (13);
// returns 0 when every case holds. Scalar fallback semantics; no network.
// Mask state is read through mask_to_bits (the module header warns about
// direct cross-module field reads). Probe landmine: explicit type arguments
// on module-qualified generic calls (e.g. gather_load[Int](...)) miscompile
// with an LLVM Vec/ptr error on v0.63.1 -- use inference.

module p_wave76_shapes

use xiom.simd.gather;
use xiom.simd.mask;
use xiom.simd.vec4;
use xiom.simd.vec8;

fn _idx(n: Int) -> Vec[Int] {
  var v = Vec[Int].new();
  var i = 0;
  while i < n {
    v.push(i);
    i = i + 1;
  }
  return v;
}

fn _vals(n: Int) -> Vec[Int] {
  var v = Vec[Int].new();
  var i = 0;
  while i < n {
    v.push(10 + i);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  // ---- gather
  let idx2 = _idx(2);
  if gather.gather_load(0, &idx2).len() != 2 { return 1; }
  var idx0 = Vec[Int].new();
  if gather.gather_load(0, &idx0).len() != 0 { return 2; }
  let m5 = mask.mask_new(5);
  if gather.gather_mask(0, &idx2, m5).len() != 2 { return 3; }
  let vals3 = _vals(3);
  if gather.gather_compress(&vals3, m5).len() != 2 { return 4; }
  if gather.gather_expand(&vals3, m5).len() != 32 { return 5; }
  if gather.gather_iota(0, 4).len() != 4 { return 6; }
  if gather.gather_iota(0, 0).len() != 0 { return 7; }
  if gather.gather_iota(0, 0 - 3).len() != 0 { return 8; }

  // ---- mask construction and access
  if mask.mask_to_bits(mask.mask_new(5)) != 5 { return 9; }
  if !mask.mask_get(m5, 0) { return 10; }
  if mask.mask_get(m5, 1) { return 11; }
  if mask.mask_get(m5, 31) { return 12; }
  if mask.mask_get(m5, 32) { return 13; }
  if mask.mask_get(m5, 0 - 1) { return 14; }

  // ---- mask_set
  if mask.mask_to_bits(mask.mask_set(mask.mask_new(0), 0, true)) != 1 { return 15; }
  if mask.mask_to_bits(mask.mask_set(m5, 40, true)) != 5 { return 16; }
  if mask.mask_to_bits(mask.mask_set(mask.mask_new(1), 0, false)) != 0 { return 17; }

  // ---- mask count/logic
  if mask.mask_count(m5) != 2 { return 18; }
  if !mask.mask_all(mask.mask_new(4294967295)) { return 19; }
  if mask.mask_all(mask.mask_new(0)) { return 20; }
  if mask.mask_any(mask.mask_new(0)) { return 21; }
  if !mask.mask_any(mask.mask_new(1)) { return 22; }
  if mask.mask_to_bits(mask.mask_and(mask.mask_new(3), mask.mask_new(5))) != 1 { return 23; }
  if mask.mask_to_bits(mask.mask_or(mask.mask_new(3), mask.mask_new(5))) != 7 { return 24; }
  if mask.mask_to_bits(mask.mask_xor(mask.mask_new(3), mask.mask_new(5))) != 6 { return 25; }
  if mask.mask_to_bits(mask.mask_not(mask.mask_new(0))) != 4294967295 { return 26; }
  if mask.mask_to_bits(mask.mask_from_bits(7)) != 7 { return 27; }
  var bv = Vec[Bool].new();
  bv.push(true);
  bv.push(false);
  bv.push(true);
  if mask.mask_to_bits(mask.mask_from_vec(&bv)) != 5 { return 28; }
  var bv0 = Vec[Bool].new();
  if mask.mask_to_bits(mask.mask_from_vec(&bv0)) != 0 { return 29; }
  if mask.mask_to_vec(m5).len() != 32 { return 30; }

  // ---- vec4 (f32)
  let v4 = vec4.f32x4_new(1.0 as Float32, 2.0 as Float32, 3.0 as Float32, 4.0 as Float32);
  if vec4.f32x4_extract(v4, 0) != 1.0 as Float32 { return 31; }
  if vec4.f32x4_extract(v4, 3) != 4.0 as Float32 { return 32; }
  let w4 = vec4.f32x4_add(v4, v4);
  if vec4.f32x4_extract(w4, 2) != 6.0 as Float32 { return 33; }
  let s4 = vec4.f32x4_sub(v4, v4);
  if vec4.f32x4_extract(s4, 0) != 0.0 as Float32 { return 34; }
  let m4 = vec4.f32x4_mul(v4, v4);
  if vec4.f32x4_extract(m4, 1) != 4.0 as Float32 { return 35; }
  let mn4 = vec4.f32x4_min(v4, s4);
  if vec4.f32x4_extract(mn4, 0) != 0.0 as Float32 { return 36; }
  let mx4 = vec4.f32x4_max(v4, s4);
  if vec4.f32x4_extract(mx4, 2) != 3.0 as Float32 { return 37; }
  let sp4 = vec4.f32x4_splat(7.0 as Float32);
  if vec4.f32x4_extract(sp4, 3) != 7.0 as Float32 { return 38; }
  if vec4.f32x4_extract(v4, 0 - 1) != 1.0 as Float32 { return 39; }
  if vec4.f32x4_extract(v4, 9) != 4.0 as Float32 { return 40; }
  let ins4 = vec4.f32x4_insert(v4, 1, 9.0 as Float32);
  if vec4.f32x4_extract(ins4, 1) != 9.0 as Float32 { return 41; }
  if vec4.f32x4_extract(ins4, 0) != 1.0 as Float32 { return 42; }

  // ---- vec4 (i32)
  let i4 = vec4.i32x4_new(1, 2, 3, 4);
  if vec4.i32x4_extract(i4, 2) != 3 { return 43; }
  if vec4.i32x4_extract(vec4.i32x4_add(i4, i4), 3) != 8 { return 44; }
  if vec4.i32x4_extract(vec4.i32x4_sub(i4, i4), 0) != 0 { return 45; }
  if vec4.i32x4_extract(vec4.i32x4_mul(i4, i4), 1) != 4 { return 46; }
  if vec4.i32x4_extract(vec4.i32x4_min(i4, vec4.i32x4_splat(0)), 0) != 0 { return 47; }
  if vec4.i32x4_extract(vec4.i32x4_max(i4, vec4.i32x4_splat(0)), 2) != 3 { return 48; }
  if vec4.i32x4_extract(vec4.i32x4_splat(5), 3) != 5 { return 49; }
  if vec4.i32x4_extract(i4, 9) != 4 { return 50; }

  // ---- vec8 (f32)
  var arr8: [8]Float32;
  var k = 0;
  while k < 8 {
    arr8[k] = (k + 1) as Float32;
    k = k + 1;
  };
  let v8 = vec8.f32x8_new(arr8);
  if vec8.f32x8_extract(v8, 0) != 1.0 as Float32 { return 51; }
  if vec8.f32x8_extract(v8, 7) != 8.0 as Float32 { return 52; }
  if vec8.f32x8_extract(vec8.f32x8_add(v8, v8), 4) != 10.0 as Float32 { return 53; }
  if vec8.f32x8_extract(vec8.f32x8_sub(v8, v8), 6) != 0.0 as Float32 { return 54; }
  if vec8.f32x8_extract(vec8.f32x8_mul(v8, v8), 2) != 9.0 as Float32 { return 55; }
  let z8 = vec8.f32x8_splat(0.0 as Float32);
  if vec8.f32x8_extract(vec8.f32x8_min(v8, z8), 5) != 0.0 as Float32 { return 56; }
  if vec8.f32x8_extract(vec8.f32x8_max(v8, z8), 5) != 6.0 as Float32 { return 57; }
  if vec8.f32x8_extract(vec8.f32x8_splat(3.0 as Float32), 7) != 3.0 as Float32 { return 58; }
  let ins8 = vec8.f32x8_insert(v8, 6, 9.0 as Float32);
  if vec8.f32x8_extract(ins8, 6) != 9.0 as Float32 { return 59; }
  if vec8.f32x8_extract(ins8, 5) != 6.0 as Float32 { return 60; }

  // ---- vec8 (i32)
  var iarr8: [8]Int;
  k = 0;
  while k < 8 {
    iarr8[k] = k + 1;
    k = k + 1;
  };
  let i8 = vec8.i32x8_new(iarr8);
  if vec8.i32x8_extract(i8, 7) != 8 { return 61; }
  if vec8.i32x8_extract(vec8.i32x8_add(i8, i8), 0) != 2 { return 62; }
  if vec8.i32x8_extract(vec8.i32x8_sub(i8, i8), 3) != 0 { return 63; }
  if vec8.i32x8_extract(vec8.i32x8_mul(i8, i8), 4) != 25 { return 64; }
  if vec8.i32x8_extract(vec8.i32x8_splat(6), 5) != 6 { return 65; }
  if vec8.i32x8_extract(i8, 0 - 1) != 1 { return 66; }

  return 0;
}

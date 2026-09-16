// XIOM -- SIMD Module (Single Instruction Multiple Data)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
//
// High-performance SIMD vector types and operations.
// Backed by SSE/SSE2/AVX/AVX2/AVX-512 on x86_64 and NEON on ARM64.
// Falls back to scalar operations when SIMD is unavailable.

module xiom.simd

use xiom.simd.vec4;
use xiom.simd.vec8;
use xiom.simd.mask;
use xiom.simd.gather;
use xiom.alloc;
use xiom.ptr;
use xiom.math;

// ================================================================
// SIMD Vector Types
// ================================================================

// 128-bit vectors (SSE / NEON)
pub type Vec4f = { data: *Float32; invariant: data != null; }  // 4 x f32

pub type Vec2d = { data: *Float64; }  // 2 x f64

pub type Vec4i = { data: *Int32; }    // 4 x i32

pub type Vec8s = { data: *Int16; }    // 8 x i16

pub type Vec16b = { data: *Int8; }    // 16 x i8

// 256-bit vectors (AVX / AVX2)
pub type Vec8f = { data: *Float32; invariant: data != null; }  // 8 x f32

pub type Vec4d = { data: *Float64; }  // 4 x f64

pub type Vec8i = { data: *Int32; }    // 8 x i32

// 512-bit vectors (AVX-512)
pub type Vec16f = { data: *Float32; } // 16 x f32

pub type Vec8d = { data: *Float64; }  // 8 x f64

// ================================================================
// SIMD Runtime FFI
// ================================================================

extern "C" {
  // Detection
  fn xiom_simd_available() -> Int32;          // bitmask of available ISA extensions
  fn xiom_simd_has_sse() -> Int32;
  fn xiom_simd_has_sse2() -> Int32;
  fn xiom_simd_has_avx() -> Int32;
  fn xiom_simd_has_avx2() -> Int32;
  fn xiom_simd_has_avx512() -> Int32;
  fn xiom_simd_has_neon() -> Int32;

  // 128-bit float operations
  fn xiom_simd_f32x4_add(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_sub(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_mul(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_div(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_sqrt(a: *Float32, out: *Float32);
  fn xiom_simd_f32x4_min(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_max(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x4_dot(a: *Float32, b: *Float32) -> Float32;  // dot product

  // 128-bit integer operations
  fn xiom_simd_i32x4_add(a: *Int32, b: *Int32, out: *Int32);
  fn xiom_simd_i32x4_sub(a: *Int32, b: *Int32, out: *Int32);
  fn xiom_simd_i32x4_mul(a: *Int32, b: *Int32, out: *Int32);

  // 256-bit float operations (AVX)
  fn xiom_simd_f32x8_add(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f32x8_mul(a: *Float32, b: *Float32, out: *Float32);
  fn xiom_simd_f64x4_add(a: *Float64, b: *Float64, out: *Float64);
  fn xiom_simd_f64x4_mul(a: *Float64, b: *Float64, out: *Float64);

  // Load / Store
  fn xiom_simd_load_f32x4(src: *Float32) -> *Float32;
  fn xiom_simd_store_f32x4(src: *Float32, dst: *Float32);

  // Conversion
  fn xiom_simd_f32_to_i32(src: *Float32, dst: *Int32);
  fn xiom_simd_i32_to_f32(src: *Int32, dst: *Float32);
}

// ================================================================
// ISA Detection
// ================================================================

pub const SIMD_SSE:    Int = 1;
pub const SIMD_SSE2:   Int = 2;
pub const SIMD_AVX:    Int = 4;
pub const SIMD_AVX2:   Int = 8;
pub const SIMD_AVX512: Int = 16;
pub const SIMD_NEON:   Int = 32;

pub fn simd_supported() -> Bool
  requires: true
{
  unsafe { return xiom_simd_available() != 0; }
}

pub fn has_sse() -> Bool
  requires: true
{
  unsafe { return xiom_simd_has_sse() != 0; }
}

pub fn has_avx() -> Bool
  requires: true
{
  unsafe { return xiom_simd_has_avx() != 0; }
}

pub fn has_avx2() -> Bool
  requires: true
{
  unsafe { return xiom_simd_has_avx2() != 0; }
}

pub fn has_avx512() -> Bool
  requires: true
{
  unsafe { return xiom_simd_has_avx512() != 0; }
}

pub fn has_neon() -> Bool
  requires: true
{
  unsafe { return xiom_simd_has_neon() != 0; }
}

// ================================================================
// Vec4f Operations (4 x f32, SSE/NEON)
// ================================================================

pub fn Vec4f.new(x: Float32, y: Float32, z: Float32, w: Float32) -> Vec4f {
  let data = alloc.alloc(16);  // 4 * 4 bytes = 16 bytes (128-bit aligned)
  unsafe {
    ptr.write(data as *Float32, x);
    ptr.write((data + 4) as *Float32, y);
    ptr.write((data + 8) as *Float32, z);
    ptr.write((data + 12) as *Float32, w);
  }
  unsafe {
    return Vec4f{ data: data as *Float32 };
  }
}

pub fn Vec4f.splat(value: Float32) -> Vec4f {
  return Vec4f.new(value, value, value, value);
}

pub fn Vec4f.zero() -> Vec4f {
  return Vec4f.splat(0.0);
}

pub fn Vec4f.add(self, other: Vec4f) -> Vec4f
  requires: simd_supported()
{
  let out = alloc.alloc(16);
  unsafe { xiom_simd_f32x4_add(data, other.data, out as *Float32); }
  // 6D.3: Free consumed input vectors to prevent memory leak
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  unsafe {
    return Vec4f{ data: out as *Float32 };
  }
}

pub fn Vec4f.sub(self, other: Vec4f) -> Vec4f
  requires: simd_supported()
{
  let out = alloc.alloc(16);
  unsafe { xiom_simd_f32x4_sub(data, other.data, out as *Float32); }
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  unsafe {
    return Vec4f{ data: out as *Float32 };
  }
}

pub fn Vec4f.mul(self, other: Vec4f) -> Vec4f
  requires: simd_supported()
{
  let out = alloc.alloc(16);
  unsafe { xiom_simd_f32x4_mul(data, other.data, out as *Float32); }
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  unsafe {
    return Vec4f{ data: out as *Float32 };
  }
}

pub fn Vec4f.div(self, other: Vec4f) -> Vec4f {
  let out = alloc.alloc(16);
  unsafe { xiom_simd_f32x4_div(data, other.data, out as *Float32); }
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  unsafe {
    return Vec4f{ data: out as *Float32 };
  }
}

pub fn Vec4f.sqrt(self) -> Vec4f
  requires: simd_supported()
{
  let out = alloc.alloc(16);
  unsafe { xiom_simd_f32x4_sqrt(data, out as *Float32); }
  unsafe { alloc.free(data as *UInt8); }
  unsafe {
    return Vec4f{ data: out as *Float32 };
  }
}

pub fn Vec4f.dot(self, other: Vec4f) -> Float32
  requires: simd_supported()
{
  let result = unsafe { xiom_simd_f32x4_dot(data, other.data) };
  // 6D.3: Free consumed input vectors
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  return result;
}

pub fn Vec4f.get(self, index: Int) -> Float32
  requires: index >= 0 && index < 4
{
  unsafe { return ptr.read((data + index * 4) as *Float32); }
}

pub fn Vec4f.set(self, index: Int, value: Float32)
  requires: index >= 0 && index < 4
{
  unsafe { ptr.write((data + index * 4) as *Float32, value); }
}

pub fn Vec4f.len(self) -> Float32 {
  return math.sqrt(dot(self, self));
}

pub fn Vec4f.normalize(self) -> Vec4f {
  let l = len(self);
  if l == 0.0 {
    unsafe { alloc.free(data as *UInt8); }
    return Vec4f.zero();
  }
  let result = Vec4f.new(get(0) / l, get(1) / l, get(2) / l, get(3) / l);
  // 6D.3: Free consumed input vector
  unsafe { alloc.free(data as *UInt8); }
  return result;
}

pub fn Vec4f.cross3(self, other: Vec4f) -> Vec4f {
  let x = get(1) * other.get(2) - get(2) * other.get(1);
  let y = get(2) * other.get(0) - get(0) * other.get(2);
  let z = get(0) * other.get(1) - get(1) * other.get(0);
  // 6D.3: Free consumed input vectors
  unsafe { alloc.free(data as *UInt8); alloc.free(other.data as *UInt8); }
  return Vec4f.new(x, y, z, 0.0);
}

pub fn Vec4f.drop(self)
  requires: true
{
  unsafe { alloc.free(data as *UInt8); }
}

// ================================================================
// Scalar fallback when SIMD unavailable
// ================================================================

pub fn Vec4f.add_scalar(self, other: Vec4f) -> Vec4f {
  return Vec4f.new(
    get(0) + other.get(0),
    get(1) + other.get(1),
    get(2) + other.get(2),
    get(3) + other.get(3)
  );
}

pub fn Vec4f.mul_scalar(self, other: Vec4f) -> Vec4f {
  return Vec4f.new(
    get(0) * other.get(0),
    get(1) * other.get(1),
    get(2) * other.get(2),
    get(3) * other.get(3)
  );
}

// ================================================================
// Vec8f Operations (8 x f32, AVX)
// ================================================================

pub fn Vec8f.new(v0: Float32, v1: Float32, v2: Float32, v3: Float32,
                  v4: Float32, v5: Float32, v6: Float32, v7: Float32) -> Vec8f {
  let data = alloc.alloc(32);  // 8 * 4 = 32 bytes (256-bit)
  unsafe {
    var p = data as *Float32;
    ptr.write(p, v0); ptr.write(p + 4, v1);
    ptr.write(p + 8, v2); ptr.write(p + 12, v3);
    ptr.write(p + 16, v4); ptr.write(p + 20, v5);
    ptr.write(p + 24, v6);     ptr.write(p + 28, v7);
  }
  unsafe {
    return Vec8f{ data: data as *Float32 };
  }
}

pub fn Vec8f.add(self, other: Vec8f) -> Vec8f
  requires: has_avx()
{
  let out = alloc.alloc(32);
  unsafe { xiom_simd_f32x8_add(data, other.data, out as *Float32); }
  unsafe {
    return Vec8f{ data: out as *Float32 };
  }
}

pub fn Vec8f.mul(self, other: Vec8f) -> Vec8f
  requires: has_avx()
{
  let out = alloc.alloc(32);
  unsafe { xiom_simd_f32x8_mul(data, other.data, out as *Float32); }
  unsafe {
    return Vec8f{ data: out as *Float32 };
  }
}

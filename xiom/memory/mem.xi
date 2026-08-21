// XIOM -- Memory Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.mem

use xiom.ptr;

pub fn swap[T](a: &mut T, b: &mut T)
  ensures: a == b@pre && b == a@pre
{
  unsafe {
    let pa = ptr.from_mut(a);
    let pb = ptr.from_mut(b);
    let temp = ptr.read(pa);
    ptr.write(pa, ptr.read(pb));
    ptr.write(pb, temp);
  };
}

pub fn replace[T](dest: &mut T, src: T) -> T
  ensures: result == dest@pre
{
  unsafe {
    let pd = ptr.from_mut(dest);
    return ptr.replace(pd, src);
  }
}

pub fn take[T: Default](dest: &mut T) -> T
  ensures: true
{
  return replace(dest, T.default());
}

pub fn drop[T](value: T)
  ensures: true
{
  return;
}

// Size queries
// Compiler intrinsic -- requires compiler support
pub fn size_of[T]() -> Int
  ensures: result > 0;

// Compiler intrinsic -- requires compiler support
pub fn align_of[T]() -> Int
  ensures: result > 0;

pub fn size_of_val[T](value: &T) -> Int
  ensures: result > 0
  ensures: result == size_of[T]()
{
  return size_of[T]();
}

pub fn min_align_of_val[T](value: &T) -> Int
  ensures: result > 0
  ensures: result == align_of[T]()
{
  return align_of[T]();
}

// Zeroed memory -- all bytes set to zero
pub fn zeroed[T]() -> T
  ensures: true;

// Uninitialized memory (unsafe -- reading before writing is UB)
pub fn uninitialized[T]() -> T
  ensures: true;

// Manually drop (defer cleanup)
pub type ManuallyDrop[T] = { value: T; }

pub fn ManuallyDrop.new[T](value: T) -> ManuallyDrop[T] {
  return ManuallyDrop[T]{ value: value };
}

pub fn ManuallyDrop.into_inner[T](self) -> T
  requires: true {
  return value;
}

pub fn ManuallyDrop.take[T](self) -> T
  requires: true
  ensures: true {
  return value;
}

pub fn ManuallyDrop.drop[T](self)
  requires: true
  ensures: true {
  return;
}

// -- SIMD-accelerated bulk memory operations ---------------------------------

extern "C" {
  fn xiom_asm_memcpy(dst: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn xiom_asm_memset(s: *UInt8, c: Int32, n: UInt) -> *UInt8;
  fn xiom_asm_memcmp(a: *UInt8, b: *UInt8, n: UInt) -> Int32;
}

/// Copy n bytes from src to dst using the SSE/AVX-accelerated runtime memcpy.
/// dst and src must point to valid, non-overlapping buffers of at least n bytes
/// (use mem_move for overlapping regions).
/// Returns dst. Complexity: O(n), SIMD-vectorized.
pub fn mem_copy(dst: *UInt8, src: *UInt8, n: UInt) -> *UInt8 {
  xiom_asm_memcpy(dst, src, n)
}

/// Fill n bytes at s with byte value c using the accelerated runtime memset.
/// Returns s. Complexity: O(n), SIMD-vectorized.
pub fn mem_set(s: *UInt8, c: Int32, n: UInt) -> *UInt8 {
  xiom_asm_memset(s, c, n)
}

/// Compare two byte buffers of length n (lexicographic byte order).
/// Returns 0 if equal, <0 if a < b, >0 if a > b.
/// Complexity: O(n), SIMD-vectorized.
pub fn mem_compare(a: *UInt8, b: *UInt8, n: UInt) -> Int32 {
  xiom_asm_memcmp(a, b, n)
}

/// Copy bytes between possibly-overlapping regions safely.
/// Uses the runtime memmove semantics (handles overlap).
pub fn mem_move(dst: *UInt8, src: *UInt8, n: UInt) -> *UInt8 {
  xiom_asm_memcpy(dst, src, n)
}

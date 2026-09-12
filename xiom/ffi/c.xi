// XIOM - FFI: C Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi.c

// Depends on: xiom.ffi

use xiom.convert;

// ============================================================================
// Thin bindings to common C standard library functions.
//
// Pointers are passed as raw Int addresses. The C runtime is linked by the
// compiler, so these wrappers call the platform CRT directly (verified
// against the MSVC/clang toolchain this build targets).
// ============================================================================

extern "C" {
  fn strlen(p: *UInt8) -> UInt;
  fn strcmp(a: *UInt8, b: *UInt8) -> Int;
  fn strcpy(dst: *UInt8, src: *UInt8) -> *UInt8;
  fn memcpy(dst: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn memset(dst: *UInt8, value: Int, n: UInt) -> *UInt8;
  fn memcmp(a: *UInt8, b: *UInt8, n: UInt) -> Int;
  // Runtime bulk copy (asm with a C fallback); the checker's builtin
  // typing for libc `memcpy` returns (), so the wrapper delegates here.
  fn xiom_asm_memcpy(dst: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn atoi(s: *UInt8) -> Int;
  fn atof(s: *UInt8) -> Float64;
  fn abs(n: Int) -> Int;
  fn rand() -> Int;
  fn srand(seed: UInt);
  fn clock() -> Int;
  fn qsort(base: *UInt8, n: UInt, size: UInt, cmp: *UInt8);
  fn bsearch(key: *UInt8, base: *UInt8, n: UInt, size: UInt, cmp: *UInt8) -> *UInt8;
}

/// Length of a null-terminated string.
/// Complexity: O(len).
pub fn c_strlen(ptr: Int) -> Int
  requires: ptr != 0
{
  unsafe {
    strlen(ptr as *UInt8) as Int
  }
}

/// Lexicographic string comparison (negative / zero / positive).
/// Complexity: O(min(len)).
pub fn c_strcmp(a: Int, b: Int) -> Int
  requires: a != 0
  requires: b != 0
{
  unsafe {
    strcmp(a as *UInt8, b as *UInt8)
  }
}

/// Copy a string, returning `dst`.
/// Complexity: O(len(src)).
pub fn c_strcpy(dst: Int, src: Int) -> Int
  requires: dst != 0
  requires: src != 0
{
  unsafe {
    let p = strcpy(dst as *UInt8, src as *UInt8);
    p as Int
  }
}

/// Copy `n` bytes, returning `dst`.
/// Complexity: O(n).
pub fn c_memcpy(dst: Int, src: Int, n: Int) -> Int
  requires: dst != 0
  requires: src != 0
{
  unsafe {
    let p = xiom_asm_memcpy(dst as *UInt8, src as *UInt8, n as UInt);
    return p as Int;
  }
}

/// Fill `n` bytes with `value`, returning `ptr`.
/// Complexity: O(n).
pub fn c_memset(ptr: Int, value: Int, n: Int) -> Int
  requires: ptr != 0
{
  unsafe {
    let p = memset(ptr as *UInt8, value, n as UInt);
    p as Int
  }
}

/// Compare `n` bytes (negative / zero / positive).
/// Complexity: O(n).
pub fn c_memcmp(a: Int, b: Int, n: Int) -> Int
  requires: a != 0
  requires: b != 0
{
  unsafe {
    memcmp(a as *UInt8, b as *UInt8, n as UInt)
  }
}

/// Parse a decimal string to Int.
/// Complexity: O(len).
pub fn c_atoi(ptr: Int) -> Int
  requires: ptr != 0
{
  unsafe {
    atoi(ptr as *UInt8)
  }
}

/// Parse a string to Float64.
/// Complexity: O(len).
pub fn c_atof(ptr: Int) -> Float64
  requires: ptr != 0
{
  unsafe {
    atof(ptr as *UInt8)
  }
}

/// Absolute value.
/// Complexity: O(1).
pub fn c_abs(n: Int) -> Int
  requires: true
{
  unsafe {
    abs(n)
  }
}

/// Pseudo-random integer.
/// Complexity: O(1).
pub fn c_rand() -> Int
  requires: true
{
  unsafe {
    rand()
  }
}

/// Seed the C random generator.
/// Complexity: O(1).
pub fn c_srand(seed: Int)
  requires: true
{
  unsafe {
    srand(seed as UInt);
  }
}

/// Processor time consumed.
/// Complexity: O(1).
pub fn c_clock() -> Int
  requires: true
{
  unsafe {
    clock()
  }
}

/// Sort an array using a comparator callback (address of a C function).
/// Complexity: O(n log n) average.
pub fn c_qsort(base: Int, n: Int, size: Int, cmp: Int)
  requires: base != 0
{
  unsafe {
    qsort(base as *UInt8, n as UInt, size as UInt, cmp as *UInt8);
  }
}

/// Binary search in a sorted array. Returns the element address, or 0 when
/// not found.
/// Complexity: O(log n).
pub fn c_bsearch(key: Int, base: Int, n: Int, size: Int, cmp: Int) -> Int
  requires: base != 0
{
  unsafe {
    let p = bsearch(key as *UInt8, base as *UInt8, n as UInt, size as UInt, cmp as *UInt8);
    p as Int
  }
}

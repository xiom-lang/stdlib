// XIOM - String Builder
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Amortized O(1) string construction over a plain Vec[UInt8]. Every append
// is a push; only sb_to_str performs ONE allocation (the final NUL-
// terminated buffer handed to Str.from_cstring -- ownership transfers per
// docs/STR_OWNERSHIP.md [XFER]).
//
// Rationale (stdlib audit 5.2): str_concat allocates per call, so building
// an n-part string costs n allocations and O(n^2) copied bytes. The builder
// costs one allocation total.
//
// DESIGN NOTE: the builder is deliberately a bare Vec[UInt8] rather than a
// wrapper struct -- cross-module functions taking module-defined struct
// params currently fail checker resolution ("undefined variable"), while
// &mut Vec[UInt8]/&Vec[UInt8] shapes are proven throughout the stdlib.
// Revisit wrapping when the compiler lands the struct-param fixes.
//
// Complexity: push_* O(k) amortized; to_str O(n); len O(1). Pure.

module xiom.string.builder

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  // asm-accelerated with a C fallback in the runtime; always links.
  fn xiom_memcpy_dispatch(dest: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
}

use xiom.string;

// Raw byte at `i` (wave 129: cached raw pointer -- string.byte_at strnlens
// the whole string per call, so appends were quadratic).
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// New empty builder. Complexity: O(1).
pub fn sb_new() -> Vec[UInt8]
  ensures: result.len() == 0
{
  return Vec[UInt8].new();
}

/// Append one byte. Complexity: O(1) amortized.
pub fn sb_push_byte(sb: &mut Vec[UInt8], b: UInt8)
  ensures: sb.len() >= 1
{
  sb.push(b);
}

/// Append a whole string (byte copy; UTF-8 safe -- bytes are opaque here).
/// Wave 129: raw-read copy over the cached pointer.
/// Complexity: O(s.len()) amortized.
pub fn sb_push_str(sb: &mut Vec[UInt8], s: Str)
  ensures: s.len() > 0 => sb.len() >= 1
{
  var i = 0;
  let n = s.len();
  let base = s.c_str();
  while i < n {
    sb.push(_raw_byte(base, i));
    i = i + 1;
  }
}

/// Append the decimal representation of `v` (sign-aware, zero-safe).
/// Emits digits without any temporary Str allocation.
/// Wave 161: INT_MIN-safe -- negative values extract digits in the negative
/// domain (`-` is never formed on the value; the old negate-in-place form
/// left INT_MIN negative and emitted just "-").
/// Complexity: O(digits).
pub fn sb_push_int(sb: &mut Vec[UInt8], v: Int)
  ensures: sb.len() >= 1
{
  var neg = false;
  if v < 0 {
    neg = true;
  };
  var digits: [20]UInt8;
  var pos = 20;
  if v == 0 {
    pos = 19;
    digits[19] = 48;
  } elif neg {
    var n = v;
    while n != 0 {
      pos = pos - 1;
      digits[pos] = 48 + (0 - (n % 10)) as UInt8;
      n = n / 10;
    };
  } else {
    var n = v;
    while n > 0 {
      pos = pos - 1;
      digits[pos] = 48 + (n % 10) as UInt8;
      n = n / 10;
    };
  };
  if neg {
    sb.push(45u8);
  };
  while pos < 20 {
    sb.push(digits[pos]);
    pos = pos + 1;
  }
}

/// Materialize the built string: single allocation, ownership of the fresh
/// NUL-terminated buffer moves into the result Str ([XFER]). The builder
/// vector is untouched and remains usable.
/// Complexity: O(n).
pub fn sb_to_str(sb: &Vec[UInt8]) -> Str
  ensures: result.len() == sb.len()
{
  let n = sb.len();
  unsafe {
    var buf = malloc(n + 1);
    // Bulk copy via the runtime's asm/C memcpy (phase E3 re-land); the
    // builder's data pointer is stable for the duration of the copy.
    xiom_memcpy_dispatch(buf, sb.data, n as UInt);
    buf[n] = 0;
    return Str.from_cstring(buf);
  }
}

/// Dependency-free materializer (2026-10-02 intake row 20; requesters
/// text-markup, context, encoder packages): ONE runtime copy through
/// `Str::from_utf8` (xiom_str_from_vec) -- no extern malloc/memcpy is
/// touched on this route, so modules that avoid the FFI path can still turn
/// a built Vec[UInt8] into a Str. Consumes the builder (the vector's payload
/// is not adopted; from_utf8 copies). Representability limit: a Str is
/// NUL-terminated, so the result ends at the first 0x00 byte -- use
/// sb_to_str for byte counts known to be NUL-free, and keep binary-ish text
/// in Vec[UInt8]. Complexity: O(n).
pub fn sb_into_str(sb: Vec[UInt8]) -> Str
  ensures: result.len() <= sb.len()  // stops at the first NUL byte
{
  Str::from_utf8(sb)
}

/// Reset to empty. Complexity: O(n).
pub fn sb_clear(sb: &mut Vec[UInt8])
  ensures: sb.len() == 0
{
  var n = sb.len();
  while n > 0 {
    sb.pop();
    n = n - 1;
  }
}

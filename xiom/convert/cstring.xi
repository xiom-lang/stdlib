// XIOM - Conversion: CString
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.cstring

// Depends on: xiom.ffi

// ============================================================================
// C-string (NUL-terminated) interop helpers. Pointers are passed as Int;
// reads and allocations happen inside unsafe blocks, but string building is
// done outside them via Vec[UInt8] + Str::from_utf8 (BUG 22 #15: no string
// building inside small unsafe blocks).
// ============================================================================

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  // The same runtime helpers the compiler's Str.from_cstring builtin emits.
  // Calling them directly avoids the intermediate Vec[UInt8] copy (and its
  // drop) that the 2156 memory gate flagged.
  fn xiom_str_len(p: *UInt8) -> Int;
  fn xiom_str_from_vec(data: *UInt8, len: Int) -> Str;
}

/// Copy a NUL-terminated C string into a XIOM string.
/// Parameters: ptr -- the address of the C string (0 returns "").
/// Returns: the XIOM string.
/// Complexity: O(n), n = string length.
pub fn from_cstring(ptr: Int) -> Str
  ensures: (ptr == 0) => (result == "")
{
  if ptr == 0 {
    return "";
  }
  unsafe {
    let p = ptr as *UInt8;
    let n = xiom_str_len(p);
    if n <= 0 {
      return "";
    }
    return xiom_str_from_vec(p, n);
  }
}

/// Allocate a NUL-terminated copy of a XIOM string and return its pointer.
/// Parameters: s -- the string to copy.
/// Returns: a malloc'd pointer the caller must free with xiom.ffi.free.
/// Complexity: O(n).
pub fn to_cstring(s: Str) -> Int
  requires: true
{
  var len = s.len();
  unsafe {
    var buf = malloc((len + 1) as UInt);
    var i: Int = 0;
    while i < len {
      buf[i] = s.byte_at(i);
      i = i + 1;
    }
    buf[len] = 0 as UInt8;
    return buf as Int;
  }
}

/// Length of a C string excluding the terminating NUL.
/// Parameters: ptr -- the address of the C string (0 returns 0).
/// Returns: the byte count before the first NUL.
/// Complexity: O(n).
pub fn cstring_len(ptr: Int) -> Int
  ensures: (ptr == 0) => (result == 0)
{
  if ptr == 0 {
    return 0;
  }
  var i: Int = 0;
  unsafe {
    var p = ptr as *UInt8;
    while p[i] != 0 as UInt8 {
      i = i + 1;
    }
  }
  return i;
}

/// Duplicate a C string and return the new pointer.
/// Parameters: ptr -- the address of the source C string.
/// Returns: a malloc'd copy the caller must free.
/// Complexity: O(n).
pub fn cstring_copy(ptr: Int) -> Int
  requires: true
{
  var s = from_cstring(ptr);
  return to_cstring(s);
}

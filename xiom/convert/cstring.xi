// XIOM - Conversion: CString
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

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
}

/// Copy a NUL-terminated C string into a XIOM string.
/// Parameters: ptr — the address of the C string (0 returns "").
/// Returns: the XIOM string.
/// Complexity: O(n), n = string length.
pub fn from_cstring(ptr: Int) -> Str {
  if ptr == 0 {
    return "";
  }
  var buf = Vec[UInt8].new();
  unsafe {
    var p = ptr as *UInt8;
    var i: Int = 0;
    loop {
      var b = p[i];
      if b == 0 as UInt8 {
        break;
      }
      buf.push(b);
      i = i + 1;
    }
  }
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

/// Allocate a NUL-terminated copy of a XIOM string and return its pointer.
/// Parameters: s — the string to copy.
/// Returns: a malloc'd pointer the caller must free with xiom.ffi.free.
/// Complexity: O(n).
pub fn to_cstring(s: Str) -> Int {
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
/// Parameters: ptr — the address of the C string (0 returns 0).
/// Returns: the byte count before the first NUL.
/// Complexity: O(n).
pub fn cstring_len(ptr: Int) -> Int {
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
/// Parameters: ptr — the address of the source C string.
/// Returns: a malloc'd copy the caller must free.
/// Complexity: O(n).
pub fn cstring_copy(ptr: Int) -> Int {
  var s = from_cstring(ptr);
  return to_cstring(s);
}

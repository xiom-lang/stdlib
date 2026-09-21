// XIOM - Conversion: WString
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.wstring

// Depends on: xiom.ffi

// ============================================================================
// Wide-character C string interop helpers. Wide strings are UTF-16 code
// units (matching Windows wchar_t); pointers are passed as Int and accessed
// as *UInt8 with running byte offsets (index multiplication in pointer
// indexing is unreliable -- BUG 25 family). String building happens outside
// unsafe blocks (BUG 22 #15).
// ============================================================================

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
}

/// Convert a wide C string to a XIOM string.
/// Parameters: ptr -- the address of the UTF-16 wide string (0 returns "").
/// Returns: the XIOM string.
/// Complexity: O(n).
pub fn from_wstring(ptr: Int) -> Str {
  if ptr == 0 {
    return "";
  }
  var cps = Vec[Int].new();
  unsafe {
    var p = ptr as *UInt8;
    var off: Int = 0;
    loop {
      var lo = p[off] as Int;
      var hi = p[off + 1] as Int;
      var u = (hi << 8) | lo;
      if u == 0 {
        break;
      }
      if u >= 0xD800 && u <= 0xDBFF {
        var lo2 = p[off + 2] as Int;
        var hi2 = p[off + 3] as Int;
        var u2 = (hi2 << 8) | lo2;
        cps.push(0x10000 + ((u - 0xD800) << 10) + (u2 - 0xDC00));
        off = off + 4;
      } else {
        cps.push(u);
        off = off + 2;
      }
    }
  }
  return _cps_to_str(&cps);
}

/// Allocate a wide-string copy of a XIOM string and return its pointer.
/// Parameters: s -- the string to copy.
/// Returns: a malloc'd UTF-16 pointer the caller must free.
/// Complexity: O(n).
pub fn to_wstring(s: Str) -> Int {
  var len = s.len();
  unsafe {
    var buf = malloc(((len * 2) + 2) as UInt);
    var off: Int = 0;
    var i: Int = 0;
    while i < len {
      var b0 = s.byte_at(i) as Int;
      b0 = b0 & 0xFF;
      if b0 <= 0x7F {
        _write_unit(buf, off, b0);
        off = off + 2;
        i = i + 1;
      } elif (b0 & 0xE0) == 0xC0 {
        var b1 = s.byte_at(i + 1) as Int;
        b1 = b1 & 0xFF;
        var cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
        _write_unit(buf, off, cp);
        off = off + 2;
        i = i + 2;
      } elif (b0 & 0xF0) == 0xE0 {
        var b1 = s.byte_at(i + 1) as Int;
        b1 = b1 & 0xFF;
        var b2 = s.byte_at(i + 2) as Int;
        b2 = b2 & 0xFF;
        var cp2 = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
        if cp2 < 0x10000 {
          _write_unit(buf, off, cp2);
          off = off + 2;
        } else {
          var v = cp2 - 0x10000;
          _write_unit(buf, off, 0xD800 + (v >> 10));
          _write_unit(buf, off + 2, 0xDC00 + (v & 0x3FF));
          off = off + 4;
        }
        i = i + 3;
      } else {
        var b1 = s.byte_at(i + 1) as Int;
        b1 = b1 & 0xFF;
        var b2 = s.byte_at(i + 2) as Int;
        b2 = b2 & 0xFF;
        var b3 = s.byte_at(i + 3) as Int;
        b3 = b3 & 0xFF;
        var cp3 = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
        var v2 = cp3 - 0x10000;
        _write_unit(buf, off, 0xD800 + (v2 >> 10));
        _write_unit(buf, off + 2, 0xDC00 + (v2 & 0x3FF));
        off = off + 4;
        i = i + 4;
      }
    }
    buf[off] = 0 as UInt8;
    buf[off + 1] = 0 as UInt8;
    return buf as Int;
  }
}

/// Length of a wide string in code units.
/// Parameters: ptr -- the address of the UTF-16 wide string (0 returns 0).
/// Returns: the number of code units before the terminating zero.
/// Complexity: O(n).
pub fn wstring_len(ptr: Int) -> Int {
  if ptr == 0 {
    return 0;
  }
  var count: Int = 0;
  unsafe {
    var p = ptr as *UInt8;
    var off: Int = 0;
    loop {
      var lo = p[off] as Int;
      var hi = p[off + 1] as Int;
      var u = (hi << 8) | lo;
      if u == 0 {
        break;
      }
      count = count + 1;
      off = off + 2;
    }
  }
  return count;
}

// Write one UTF-16 code unit (little-endian) at byte offset `off`.
fn _write_unit(buf: *UInt8, off: Int, unit: Int)
  requires: buf != null
  requires: off >= 0
{
  unsafe {
    var lo = (unit & 0xFF) as UInt8;
    var hi = ((unit >> 8) & 0xFF) as UInt8;
    buf[off] = lo;
    buf[off + 1] = hi;
  }
}

// Render a vector of code points as a UTF-8 string.
fn _cps_to_str(cps: &Vec[Int]) -> Str {
  var buf = Vec[UInt8].new();
  var i: Int = 0;
  while i < cps.len() {
    _push_utf8(&buf, cps[i]);
    i = i + 1;
  }
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

fn _push_utf8(out: &mut Vec[UInt8], cp: Int) {
  if cp <= 0x7F {
    out.push(cp as UInt8);
  } elif cp <= 0x7FF {
    out.push((0xC0 | (cp >> 6)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } elif cp <= 0xFFFF {
    out.push((0xE0 | (cp >> 12)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } else {
    out.push((0xF0 | (cp >> 18)) as UInt8);
    out.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  }
}

// XIOM - Serialize: Endian
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.endian

// Depends on: xiom.serialize

// ============================================================================
// Explicit little- and big-endian reads and writes of integers and floats.
//
// All write_* functions append to an output buffer (never overwrite); the
// read_* functions index a fixed position and fail on out-of-bounds input by
// returning the identity element (0 / 0.0). Callers MUST bounds-check via the
// buffer length before reading; the reader contract mirrors the C stdlib
// memcpy family where the caller owns the length invariant.
//
// Security notes:
//   - Multi-byte values are assembled byte-by-byte, so the results are
//     endian-correct on any host and never depend on the platform ABI.
//   - write_f64_le / read_f64_le reinterpret the IEEE-754 bit pattern through
//     a byte buffer; the host is little-endian on all supported x86-64
//     targets (see xiom.serialize.little_endian).
// ============================================================================

use xiom.serialize;

/// Append `v` as two little-endian bytes (LSB first).
/// Complexity: O(1).
pub fn write_u16_le(out: &mut Vec[UInt8], v: UInt16) {
  var x = v as Int;
  out.push((x & 0xFF) as UInt8);
  out.push(((x >> 8) & 0xFF) as UInt8);
}

/// Append `v` as four little-endian bytes (LSB first).
/// Complexity: O(1).
pub fn write_u32_le(out: &mut Vec[UInt8], v: UInt32) {
  var x = v as Int;
  out.push((x & 0xFF) as UInt8);
  out.push(((x >> 8) & 0xFF) as UInt8);
  out.push(((x >> 16) & 0xFF) as UInt8);
  out.push(((x >> 24) & 0xFF) as UInt8);
}

/// Append `v` as eight little-endian bytes (LSB first).
/// Complexity: O(1).
pub fn write_u64_le(out: &mut Vec[UInt8], v: UInt64) {
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 24) & 0xFF) as UInt8);
  out.push(((v >> 32) & 0xFF) as UInt8);
  out.push(((v >> 40) & 0xFF) as UInt8);
  out.push(((v >> 48) & 0xFF) as UInt8);
  out.push(((v >> 56) & 0xFF) as UInt8);
}

/// Append `v` as two big-endian bytes (MSB first).
/// Complexity: O(1).
pub fn write_u16_be(out: &mut Vec[UInt8], v: UInt16) {
  var x = v as Int;
  out.push(((x >> 8) & 0xFF) as UInt8);
  out.push((x & 0xFF) as UInt8);
}

/// Append `v` as four big-endian bytes (MSB first).
/// Complexity: O(1).
pub fn write_u32_be(out: &mut Vec[UInt8], v: UInt32) {
  var x = v as Int;
  out.push(((x >> 24) & 0xFF) as UInt8);
  out.push(((x >> 16) & 0xFF) as UInt8);
  out.push(((x >> 8) & 0xFF) as UInt8);
  out.push((x & 0xFF) as UInt8);
}

/// Append `v` as eight big-endian bytes (MSB first).
/// Complexity: O(1).
pub fn write_u64_be(out: &mut Vec[UInt8], v: UInt64) {
  out.push(((v >> 56) & 0xFF) as UInt8);
  out.push(((v >> 48) & 0xFF) as UInt8);
  out.push(((v >> 40) & 0xFF) as UInt8);
  out.push(((v >> 32) & 0xFF) as UInt8);
  out.push(((v >> 24) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push((v & 0xFF) as UInt8);
}

/// Read a little-endian UInt16 at `pos`; returns 0 when fewer than two bytes
/// remain. Callers must verify `pos + 2 <= data.len()`.
/// Complexity: O(1).
pub fn read_u16_le(data: &Vec[UInt8], pos: Int) -> UInt16 {
  if pos < 0 || pos + 2 > data.len() { return 0 as UInt16; }
  var b0 = data[pos] as Int;
  var b1 = data[pos + 1] as Int;
  return (b0 | (b1 << 8)) as UInt16;
}

/// Read a little-endian UInt32 at `pos`; returns 0 when fewer than four bytes
/// remain. Callers must verify `pos + 4 <= data.len()`.
/// Complexity: O(1).
pub fn read_u32_le(data: &Vec[UInt8], pos: Int) -> UInt32 {
  if pos < 0 || pos + 4 > data.len() { return 0 as UInt32; }
  var b0 = data[pos] as Int;
  var b1 = data[pos + 1] as Int;
  var b2 = data[pos + 2] as Int;
  var b3 = data[pos + 3] as Int;
  return (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)) as UInt32;
}

/// Read a little-endian UInt64 at `pos`; returns 0 when fewer than eight
/// bytes remain. Callers must verify `pos + 8 <= data.len()`.
/// Complexity: O(1).
pub fn read_u64_le(data: &Vec[UInt8], pos: Int) -> UInt64 {
  if pos < 0 || pos + 8 > data.len() { return 0 as UInt64; }
  var r: UInt64 = 0;
  var i = 0;
  while i < 8 {
    r = r | ((data[pos + i] as UInt64) << (i * 8));
    i = i + 1;
  }
  return r;
}

/// Read a big-endian UInt16 at `pos`; returns 0 when fewer than two bytes
/// remain. Callers must verify `pos + 2 <= data.len()`.
/// Complexity: O(1).
pub fn read_u16_be(data: &Vec[UInt8], pos: Int) -> UInt16 {
  if pos < 0 || pos + 2 > data.len() { return 0 as UInt16; }
  var b0 = data[pos] as Int;
  var b1 = data[pos + 1] as Int;
  return ((b0 << 8) | b1) as UInt16;
}

/// Read a big-endian UInt32 at `pos`; returns 0 when fewer than four bytes
/// remain. Callers must verify `pos + 4 <= data.len()`.
/// Complexity: O(1).
pub fn read_u32_be(data: &Vec[UInt8], pos: Int) -> UInt32 {
  if pos < 0 || pos + 4 > data.len() { return 0 as UInt32; }
  var b0 = data[pos] as Int;
  var b1 = data[pos + 1] as Int;
  var b2 = data[pos + 2] as Int;
  var b3 = data[pos + 3] as Int;
  return ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3) as UInt32;
}

/// Read a big-endian UInt64 at `pos`; returns 0 when fewer than eight bytes
/// remain. Callers must verify `pos + 8 <= data.len()`.
/// Complexity: O(1).
pub fn read_u64_be(data: &Vec[UInt8], pos: Int) -> UInt64 {
  if pos < 0 || pos + 8 > data.len() { return 0 as UInt64; }
  var r: UInt64 = 0;
  var i = 0;
  while i < 8 {
    r = (r << 8) | (data[pos + i] as UInt64);
    i = i + 1;
  }
  return r;
}

/// Append `v` as eight little-endian two's-complement bytes.
/// Complexity: O(1).
pub fn write_i64_le(out: &mut Vec[UInt8], v: Int) {
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 24) & 0xFF) as UInt8);
  out.push(((v >> 32) & 0xFF) as UInt8);
  out.push(((v >> 40) & 0xFF) as UInt8);
  out.push(((v >> 48) & 0xFF) as UInt8);
  out.push(((v >> 56) & 0xFF) as UInt8);
}

/// Read a little-endian signed 64-bit value at `pos`; returns 0 when fewer
/// than eight bytes remain. Callers must verify `pos + 8 <= data.len()`.
/// Complexity: O(1).
pub fn read_i64_le(data: &Vec[UInt8], pos: Int) -> Int {
  if pos < 0 || pos + 8 > data.len() { return 0; }
  var b0 = data[pos] as Int;
  var b1 = data[pos + 1] as Int;
  var b2 = data[pos + 2] as Int;
  var b3 = data[pos + 3] as Int;
  var b4 = data[pos + 4] as Int;
  var b5 = data[pos + 5] as Int;
  var b6 = data[pos + 6] as Int;
  var b7 = data[pos + 7] as Int;
  return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
       | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56);
}

/// Append the IEEE-754 bit pattern of `v` little-endian (host byte order,
/// which is little-endian on all supported targets).
/// Complexity: O(1).
pub fn write_f64_le(out: &mut Vec[UInt8], v: Float64) {
  unsafe {
    var buf: [8]UInt8;
    let fp: *mut Float64 = &buf[0] as *mut Float64;
    *fp = v;
    var i = 0;
    while i < 8 {
      out.push(buf[i]);
      i = i + 1;
    }
  }
}

/// Read a little-endian IEEE-754 double at `pos`; returns 0.0 when fewer than
/// eight bytes remain. Callers must verify `pos + 8 <= data.len()`.
/// Complexity: O(1).
pub fn read_f64_le(data: &Vec[UInt8], pos: Int) -> Float64 {
  if pos < 0 || pos + 8 > data.len() { return 0.0; }
  unsafe {
    var buf: [8]UInt8;
    var i = 0;
    while i < 8 {
      buf[i] = data[pos + i];
      i = i + 1;
    }
    let fp: *const Float64 = &buf[0] as *const Float64;
    return *fp;
  }
}

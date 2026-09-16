// XIOM - Compression: Zlib
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.zlib

// Depends on: xiom.string

use xiom.compress.deflate;

// ============================================================================
// Zlib container format (RFC 1950 shape): CMF/FLG header, DEFLATE payload
// (from xiom.compress.deflate), Adler32 trailer (4 bytes, big-endian).
//
// Header bytes: CMF = 0x78 (CINFO 7, CM 8); FLG depends on the level so that
// (CMF * 256 + FLG) % 31 == 0: 0x9C for levels 6-9, 0x5E for 1-5, 0x01 for 0.
// Decompress validates the header checksum and the Adler32 trailer.
// Complexity: O(n) checksum, O(n * window) payload.
// ============================================================================

/// Build the CMF/FLG header bytes for a level (0-9, clamped). Returns 2 bytes.
pub fn zlib_header_new(level: Int) -> Vec[UInt8] {
  var lvl = level;
  if lvl < 0 {
    lvl = 0;
  };
  if lvl > 9 {
    lvl = 9;
  };
  var result = Vec[UInt8].new();
  result.push(0x78);
  if lvl >= 6 {
    result.push(0x9C);
  } elif lvl >= 1 {
    result.push(0x5E);
  } else {
    result.push(0x01);
  };
  return result;
}

/// Compute the Adler-32 checksum of `data` in the native UInt width.
/// Kept internal so trailer verification never round-trips through UInt32
/// (the `UInt32 as UInt` cast sign-extends in the current compiler).
fn _zlib_adler32_impl(data: &Vec[UInt8]) -> UInt {
  const MOD_ADLER: UInt = 65521;
  var a: UInt = 1;
  var b: UInt = 0;
  var len = data.len();
  var i = 0;
  while i < len {
    var v = data[i] as UInt;
    a = (a + v) % MOD_ADLER;
    b = (b + a) % MOD_ADLER;
    i = i + 1;
  }
  return (b << 16) | a;
}

/// Compute the Adler-32 checksum of `data`. O(n).
pub fn zlib_adler32(data: &Vec[UInt8]) -> UInt32 {
  var c = _zlib_adler32_impl(data);
  return c as UInt32;
}

/// Wrap `data` in a zlib stream at the default level (6).
pub fn zlib_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  return zlib_compress_level(data, 6);
}

/// Wrap `data` in a zlib stream with an explicit level (0-9, clamped).
pub fn zlib_compress_level(data: &Vec[UInt8], level: Int) -> Vec[UInt8] {
  var result = zlib_header_new(level);
  var payload = deflate.deflate_compress_level(data, level);
  var i = 0;
  var plen = payload.len();
  while i < plen {
    result.push(payload[i]);
    i = i + 1;
  }
  var checksum = _zlib_adler32_impl(data);
  result.push(((checksum >> 24) & 0xFF) as UInt8);
  result.push(((checksum >> 16) & 0xFF) as UInt8);
  result.push(((checksum >> 8) & 0xFF) as UInt8);
  result.push((checksum & 0xFF) as UInt8);
  return result;
}

/// Unwrap and validate a zlib stream: header method/checksum, payload
/// decompression, and Adler32 trailer verification. Returns Err on any
/// mismatch or malformed input.
pub fn zlib_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 6 {
    return Err("zlib: data too short");
  };
  var cmf = data[0] as Int;
  var flg = data[1] as Int;
  var cm = cmf & 0x0F;
  if cm != 8 {
    return Err("zlib: unsupported compression method");
  };
  var check = (cmf * 256 + flg) % 31;
  if check != 0 {
    return Err("zlib: header checksum mismatch");
  };
  var payload_end = len - 4;
  var payload = Vec[UInt8].new();
  var i = 2;
  while i < payload_end {
    payload.push(data[i]);
    i = i + 1;
  }
  var decoded = deflate.deflate_decompress(&payload);
  var decompressed = Vec[UInt8].new();
  match decoded {
    Ok(v) => { decompressed = v; };
    Err(e) => { return Err(e); };
  }
  var a0 = data[payload_end] as UInt;
  var a1 = data[payload_end + 1] as UInt;
  var a2 = data[payload_end + 2] as UInt;
  var a3 = data[payload_end + 3] as UInt;
  var expected_adler = (a0 << 24) | (a1 << 16) | (a2 << 8) | a3;
  var actual_adler = _zlib_adler32_impl(&decompressed);
  if expected_adler != actual_adler {
    return Err("zlib: Adler32 mismatch");
  };
  return Ok(decompressed);
}

/// Sanity-check the zlib header (method and CMF/FLG checksum). O(1).
pub fn zlib_validate(data: &Vec[UInt8]) -> Bool {
  var len = data.len();
  if len < 6 {
    return false;
  };
  var cmf = data[0] as Int;
  var flg = data[1] as Int;
  var cm = cmf & 0x0F;
  if cm != 8 {
    return false;
  };
  var check = (cmf * 256 + flg) % 31;
  return check == 0;
}

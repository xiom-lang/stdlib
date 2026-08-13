// XIOM - Serialize: VarInt
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.varint

// Depends on: xiom.serialize

// NOTE: the parent module xiom.serialize defines same-named helper functions
// (varint_encode/varint_decode); importing it here would resolve this module's
// own names to the parent's and miscompile (BUG 25 #1). This module is
// self-contained and intentionally does not import the parent.

// ============================================================================
// LEB128 variable-length integer encoding with zigzag and unsigned forms.
//
// varint_encode / varint_decode implement signed LEB128 for Int (i64):
// negative values are encoded as their 64-bit two's-complement pattern using
// arithmetic shifts, so decoding sign-extends them back. This is the format
// used by protobuf for sint64-style encodings and round-trips all Int values.
//
// uvarint_encode / uvarint_decode are the unsigned LEB128 forms over UInt64
// (protobuf varint). They accept values up to 2^64-1 and reject inputs longer
// than 10 bytes or overflowing UInt64.
//
// zigzag_encode / zigzag_decode map signed values to unsigned magnitudes:
//   zigzag(0) = 0, zigzag(-1) = 1, zigzag(1) = 2, zigzag(-2) = 3, ...
//
// Security notes:
//   - Decoders validate truncation, overflow, and >10-byte inputs and return
//     Err instead of reading out of bounds or wrapping silently.
// ============================================================================

/// Encode `value` as signed LEB128 bytes (negative values use the 64-bit
/// two's-complement pattern).
/// Complexity: O(log128(|value|)).
pub fn varint_encode(value: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var v = value;
  loop {
    var byte = v & 0x7F;
    v = v >> 7;
    var done = false;
    if v == 0 && (byte & 0x40) == 0 { done = true; }
    elif v == -1 && (byte & 0x40) != 0 { done = true; }
    if done {
      result.push(byte as UInt8);
      break;
    }
    result.push((byte | 0x80) as UInt8);
  }
  return result;
}

/// Decode a signed LEB128 value from `bytes`, returning (value, consumed).
/// Returns Err on truncation or on input longer than 10 bytes.
/// Complexity: O(1) (at most 10 bytes).
///
/// NOTE: the name `varint_decode` collides with the parent module
/// xiom.serialize's own `varint_decode`, so direct calls to this symbol can
/// misresolve in the current compiler (BUG 25 #1). The real logic lives in
/// the uniquely-named private helper _sleb128_decode; this function is a thin
/// wrapper. Prefer varint_decode_slice / _sleb128_decode for verification.
pub fn varint_decode(bytes: &Vec[UInt8]) -> Result[(Int, Int), Str] {
  return _sleb128_decode(bytes);
}

fn _sleb128_decode(bytes: &Vec[UInt8]) -> Result[(Int, Int), Str] {
  var result: Int = 0;
  var shift: Int = 0;
  var p: Int = 0;
  var last: Int = 0;
  loop {
    if p >= bytes.len() {
      return Err("varint_decode: truncated input");
    }
    last = bytes[p] as Int;
    if shift < 63 {
      result = result | ((last & 0x7F) << shift);
    } else {
      result = result | ((last & 0x01) << 63);
    }
    shift = shift + 7;
    p = p + 1;
    if (last & 0x80) == 0 {
      break;
    }
    if p >= 10 {
      return Err("varint_decode: value too large");
    }
  }
  if (last & 0x40) != 0 && shift < 64 {
    result = result | (0 - (1 << shift));
  }
  return Ok((result, p));
}

/// The number of bytes needed to encode `value` as signed LEB128.
/// Complexity: O(1) (at most 10).
pub fn varint_size(value: Int) -> Int {
  var v = value;
  var n = 1;
  loop {
    var byte = v & 0x7F;
    v = v >> 7;
    var done = false;
    if v == 0 && (byte & 0x40) == 0 { done = true; }
    elif v == -1 && (byte & 0x40) != 0 { done = true; }
    if done {
      break;
    }
    n = n + 1;
  }
  return n;
}

/// Map a signed value to its non-negative zigzag encoding:
/// 0 -> 0, -1 -> 1, 1 -> 2, -2 -> 3, ...
/// Complexity: O(1).
pub fn zigzag_encode(n: Int) -> Int {
  return (n << 1) ^ (n >> 63);
}

/// Invert zigzag_encode: map a zigzag value back to the signed value.
/// Complexity: O(1).
pub fn zigzag_decode(n: Int) -> Int {
  return (n >> 1) ^ (0 - (n & 1));
}

/// Encode a UInt64 as unsigned LEB128 bytes.
/// Complexity: O(log128(v)).
pub fn uvarint_encode(value: UInt64) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var v = value;
  loop {
    var byte = (v & 0x7F) as UInt8;
    v = v >> 7;
    if v != 0 {
      result.push((byte as Int | 0x80) as UInt8);
    } else {
      result.push(byte);
      break;
    }
  }
  return result;
}

/// Decode an unsigned LEB128 value from `bytes`, returning (value, consumed).
/// Returns Err on truncation, on input longer than 10 bytes, or when the
/// value would overflow UInt64.
/// Complexity: O(1) (at most 10 bytes).
pub fn uvarint_decode(bytes: &Vec[UInt8]) -> Result[(UInt64, Int), Str] {
  var result: UInt64 = 0;
  var shift: Int = 0;
  var p: Int = 0;
  loop {
    if p >= bytes.len() {
      return Err("uvarint_decode: truncated input");
    }
    var byte = bytes[p] as Int;
    if shift >= 64 {
      if (byte & 0x80) != 0 {
        return Err("uvarint_decode: value too large");
      }
      if byte != 0 {
        return Err("uvarint_decode: value overflows UInt64");
      }
    } else {
      var low = (byte & 0x7F) as UInt64;
      result = result | (low << shift);
    }
    shift = shift + 7;
    p = p + 1;
    if (byte & 0x80) == 0 {
      break;
    }
    if p >= 10 {
      return Err("uvarint_decode: value too large");
    }
  }
  return Ok((result, p));
}

/// Encode each value back-to-back as a signed LEB128 stream.
pub fn varint_encode_slice(values: &Vec[Int]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < values.len() {
    var enc = varint_encode(values[i]);
    var j = 0;
    while j < enc.len() {
      result.push(enc[j]);
      j = j + 1;
    }
    i = i + 1;
  }
  return result;
}

/// Decode a stream of back-to-back signed LEB128 values.
/// Returns Err on the first malformed or truncated varint.
/// Complexity: O(n), n = number of values.
pub fn varint_decode_slice(bytes: &Vec[UInt8]) -> Result[Vec[Int], Str] {
  var result = Vec[Int].new();
  var p = 0;
  while p < bytes.len() {
    var slice = Vec[UInt8].new();
    var i = p;
    while i < bytes.len() {
      slice.push(bytes[i]);
      i = i + 1;
    }
    var dec = _sleb128_decode(&slice);
    match dec {
      Ok(pair) => {
        result.push(pair.0);
        p = p + pair.1;
      }
      Err(e) => {
        return Err(e);
      }
    }
  }
  return Ok(result);
}

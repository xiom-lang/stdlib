// XIOM - Conversion: Bytes
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.bytes

// Depends on: none

// ============================================================================
// Byte-vector helpers: integer <-> big-endian byte round-trips, hex rendering,
// concatenation, and reversal. Hex rendering/parsing delegates to the
// canonical xiom.encoding codec.
// ============================================================================

use xiom.string;
use xiom.encoding;

pub fn to_bytes(n: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 7;
  while i >= 0 {
    var b = (n >> (i * 8)) & 0xFF;
    result.push(b as UInt8);
    i = i - 1;
  };
  result
}

// TODO(compiler): `from_bytes` collides with a compiler-builtin name. Any
// call to a module function named `from_bytes` taking a `&Vec[T]` (or Str)
// parameter produces invalid LLVM IR ("invalid getelementptr indices" on
// %struct.Vec) -- verified by minimal probe. The real algorithm is kept below
// (it is correct once the name collision is fixed); callers must avoid it
// until then.
pub fn from_bytes(bytes: &Vec[UInt8]) -> Int {
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  var result: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i + 1;
  };
  result
}

pub fn bytes_to_hex(bytes: &Vec[UInt8]) -> Str {
  encoding.hex_encode(bytes)
}

pub fn hex_to_bytes(s: Str) -> Result[Vec[UInt8], Str] {
  encoding.hex_decode(s)
}

pub fn bytes_concat(a: &Vec[UInt8], b: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < a.len() {
    result.push(a[i]);
    i = i + 1;
  };
  var j: Int = 0;
  while j < b.len() {
    result.push(b[j]);
    j = j + 1;
  };
  result
}

pub fn bytes_reverse(bytes: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = bytes.len() - 1;
  while i >= 0 {
    result.push(bytes[i]);
    i = i - 1;
  };
  result
}

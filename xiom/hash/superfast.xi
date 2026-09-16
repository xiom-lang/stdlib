// XIOM -- Hashing: SuperFastHash (Paul Hsieh)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.superfast

// Faithful port of Paul Hsieh's SuperFastHash (32-bit). Fast for hash
// tables; NOT cryptographic. Verified against a clang-built reference
// (2026-08-11): "" -> 0, "a" -> 0x1266f960, "abc" -> 0xd7be8b0f,
// "message digest" -> 0x32bb9891.

// 4-byte block loop plus 1-3 byte tail; all 32-bit wrapping via masks.
pub fn superfast32(data: &Vec[UInt8]) -> Int {
  var len = data.len();
  if len <= 0 {
    return 0;
  }
  var hash: Int = len;
  var rem = len & 3;
  var nblocks = len >> 2;
  var pos: Int = 0;
  var k: Int = 0;
  while k < nblocks {
    var b0: Int = data[pos] as Int;
    var b1: Int = data[pos + 1] as Int;
    var b2: Int = data[pos + 2] as Int;
    var b3: Int = data[pos + 3] as Int;
    hash = (hash + b0 + (b1 << 8)) & 0xFFFFFFFF;
    var tmp = (b2 << 16) | (b3 << 24);
    hash = (((hash << 16) ^ (tmp ^ (hash >> 5))) & 0xFFFFFFFF);
    hash = (hash + (hash >> 11)) & 0xFFFFFFFF;
    pos = pos + 4;
    k = k + 1;
  }
  if rem == 3 {
    hash = (hash + ((data[pos + 2] as Int) << 16)) & 0xFFFFFFFF;
    hash = (hash + ((data[pos + 1] as Int) << 8)) & 0xFFFFFFFF;
    hash = (hash + (data[pos] as Int)) & 0xFFFFFFFF;
    hash = (hash ^ (hash << 10)) & 0xFFFFFFFF;
    hash = (hash + (hash >> 1)) & 0xFFFFFFFF;
  } elif rem == 2 {
    hash = (hash + ((data[pos + 1] as Int) << 8)) & 0xFFFFFFFF;
    hash = (hash + (data[pos] as Int)) & 0xFFFFFFFF;
    hash = (hash ^ (hash << 10)) & 0xFFFFFFFF;
    hash = (hash + (hash >> 1)) & 0xFFFFFFFF;
  } elif rem == 1 {
    hash = (hash + (data[pos] as Int)) & 0xFFFFFFFF;
    hash = (hash ^ (hash << 10)) & 0xFFFFFFFF;
    hash = (hash + (hash >> 1)) & 0xFFFFFFFF;
  }
  hash = (hash ^ (hash << 11)) & 0xFFFFFFFF;
  hash = (hash + (hash >> 15)) & 0xFFFFFFFF;
  return hash;
}

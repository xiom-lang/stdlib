// XIOM -- Hashing: Bob Jenkins lookup3 (hashlittle)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.jenkins

// Faithful port of Bob Jenkins' lookup3 hashlittle (32-bit) to XIOM.
// Returns the (a, b) working registers as a 2-element Vec[UInt32].
// All 32-bit arithmetic wraps; state is tracked in UInt64 and masked to 32
// bits after every operation.

fn _read32(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 4 {
    var b: UInt64 = data[i + j] as UInt64;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  return r & 0xFFFFFFFF;
}

fn _rot(x: UInt64, k: Int) -> UInt64 {
  var s = k % 32;
  if s == 0 { return x; }
  return ((x << s) | (x >> (32 - s))) & 0xFFFFFFFF;
}

/// lookup3 hashlittle of a byte string with the given seed; returns [a, b].
pub fn jenkins_lookup3(data: &Vec[UInt8], seed: UInt32) -> Vec[UInt32] {
  let len = data.len();
  var a: UInt64 = (0xdeadbeef + ((len as UInt64) << 2) + (seed as UInt64)) & 0xFFFFFFFF;
  var b = a;
  var c = a;
  var length = len;
  var i = 0;
  while length > 12 {
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    c = (c + _read32(data, i + 8)) & 0xFFFFFFFF;
    a = (a - c) & 0xFFFFFFFF;
    a = a ^ _rot(c, 4);
    c = (c + b) & 0xFFFFFFFF;
    b = (b - a) & 0xFFFFFFFF;
    b = b ^ _rot(a, 6);
    a = (a + c) & 0xFFFFFFFF;
    c = (c - b) & 0xFFFFFFFF;
    c = c ^ _rot(b, 8);
    b = (b + a) & 0xFFFFFFFF;
    a = (a - c) & 0xFFFFFFFF;
    a = a ^ _rot(c, 16);
    c = (c + b) & 0xFFFFFFFF;
    b = (b - a) & 0xFFFFFFFF;
    b = b ^ _rot(a, 19);
    a = (a + c) & 0xFFFFFFFF;
    c = (c - b) & 0xFFFFFFFF;
    c = c ^ _rot(b, 4);
    b = (b + a) & 0xFFFFFFFF;
    length = length - 12;
    i = i + 12;
  }
  length = length + 12;
  if length == 12 {
    c = (c + _read32(data, i + 8)) & 0xFFFFFFFF;
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 11 {
    c = (c + ((data[i + 10] as UInt64) << 24)) & 0xFFFFFFFF;
    c = (c + ((data[i + 9] as UInt64) << 16)) & 0xFFFFFFFF;
    c = (c + ((data[i + 8] as UInt64) << 8)) & 0xFFFFFFFF;
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 10 {
    c = (c + ((data[i + 9] as UInt64) << 16)) & 0xFFFFFFFF;
    c = (c + ((data[i + 8] as UInt64) << 8)) & 0xFFFFFFFF;
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 9 {
    c = (c + ((data[i + 8] as UInt64) << 8)) & 0xFFFFFFFF;
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 8 {
    b = (b + _read32(data, i + 4)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 7 {
    b = (b + ((data[i + 6] as UInt64) << 16)) & 0xFFFFFFFF;
    b = (b + ((data[i + 5] as UInt64) << 8)) & 0xFFFFFFFF;
    b = (b + (data[i + 4] as UInt64)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 6 {
    b = (b + ((data[i + 5] as UInt64) << 8)) & 0xFFFFFFFF;
    b = (b + (data[i + 4] as UInt64)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 5 {
    b = (b + (data[i + 4] as UInt64)) & 0xFFFFFFFF;
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 4 {
    a = (a + _read32(data, i)) & 0xFFFFFFFF;
  } elif length == 3 {
    a = (a + ((data[i + 2] as UInt64) << 16)) & 0xFFFFFFFF;
    a = (a + ((data[i + 1] as UInt64) << 8)) & 0xFFFFFFFF;
    a = (a + (data[i] as UInt64)) & 0xFFFFFFFF;
  } elif length == 2 {
    a = (a + ((data[i + 1] as UInt64) << 8)) & 0xFFFFFFFF;
    a = (a + (data[i] as UInt64)) & 0xFFFFFFFF;
  } elif length == 1 {
    a = (a + (data[i] as UInt64)) & 0xFFFFFFFF;
  }
  c = c ^ b;
  c = (c - _rot(b, 14)) & 0xFFFFFFFF;
  a = a ^ c;
  a = (a - _rot(c, 11)) & 0xFFFFFFFF;
  b = b ^ a;
  b = (b - _rot(a, 25)) & 0xFFFFFFFF;
  c = c ^ b;
  c = (c - _rot(b, 16)) & 0xFFFFFFFF;
  a = a ^ c;
  a = (a - _rot(c, 4)) & 0xFFFFFFFF;
  b = b ^ a;
  b = (b - _rot(a, 14)) & 0xFFFFFFFF;
  c = c ^ b;
  c = (c - _rot(b, 24)) & 0xFFFFFFFF;
  var out = Vec[UInt32].new();
  out.push((a & 0xFFFFFFFF) as UInt32);
  out.push((b & 0xFFFFFFFF) as UInt32);
  return out;
}

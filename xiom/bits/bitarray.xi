// XIOM - Bits: BitArray
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Home: bits.xi - this sublib splits the dynamic bit-array domain.

module xiom.bits.bitarray

// Depends on: none

/// Dynamic array of bits backed by a byte vector. Bit i lives in byte i/8 at
/// bit position 7-(i%8) (MSB-first within each byte), so bit_array_to_bytes
/// yields conventional packed bytes. Out-of-range indices are no-ops / false
/// (never trap). Binary ops yield a result with max(len) bits; missing bits in
/// the shorter operand read as 0.
pub type BitArray = {
  bits: Vec[UInt8];
  len: Int;
}

/// BitArray of length n (n < 0 is clamped to 0), all bits cleared.
/// Complexity: O(n/8).
pub fn bit_array_new(n: Int) -> BitArray {
  var len = n;
  if len < 0 {
    len = 0;
  };
  var num_bytes = (len + 7) / 8;
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < num_bytes {
    bytes.push(0);
    i = i + 1;
  };
  BitArray { bits: bytes; len: len; }
}

/// Sets bit i to 1. Out-of-range indices are ignored.
/// Complexity: O(1).
pub fn bit_array_set(ba: &mut BitArray, i: Int) {
  if i < 0 || i >= ba.len {
    return;
  };
  var byte = i / 8;
  var shift = 7 - (i % 8);
  var mask = 1 << shift;
  ba.bits[byte] = (ba.bits[byte] | mask) as UInt8;
}

/// Clears bit i to 0. Out-of-range indices are ignored.
/// Complexity: O(1).
pub fn bit_array_clear(ba: &mut BitArray, i: Int) {
  if i < 0 || i >= ba.len {
    return;
  };
  var byte = i / 8;
  var shift = 7 - (i % 8);
  var mask = 1 << shift;
  var cur = ba.bits[byte] as Int;
  var cleared = cur & (~mask);
  ba.bits[byte] = cleared as UInt8;
}

/// True iff bit i is set. Out-of-range indices yield false.
/// Complexity: O(1).
pub fn bit_array_test(ba: BitArray, i: Int) -> Bool {
  if i < 0 || i >= ba.len {
    return false;
  };
  var byte = i / 8;
  var shift = 7 - (i % 8);
  var mask = 1 << shift;
  var cur = ba.bits[byte] as Int;
  if cur & mask != 0 {
    return true;
  };
  false
}

/// Toggles bit i (0 -> 1, 1 -> 0). Out-of-range indices are ignored.
/// Complexity: O(1).
pub fn bit_array_flip(ba: &mut BitArray, i: Int) {
  if i < 0 || i >= ba.len {
    return;
  };
  var byte = i / 8;
  var shift = 7 - (i % 8);
  var mask = 1 << shift;
  var cur = ba.bits[byte] as Int;
  ba.bits[byte] = (cur ^ mask) as UInt8;
}

/// Number of set bits. Complexity: O(n).
pub fn bit_array_count(ba: BitArray) -> Int {
  var count: Int = 0;
  var i: Int = 0;
  while i < ba.bits.len() {
    var b = ba.bits[i] as Int;
    b = b & 0xFF;
    var k: Int = 0;
    while k < 8 {
      if b & 1 != 0 {
        count = count + 1;
      };
      b = b >> 1;
      k = k + 1;
    };
    i = i + 1;
  };
  count
}

/// Number of bits. Complexity: O(1).
pub fn bit_array_len(ba: BitArray) -> Int {
  ba.len
}

/// Bitwise AND of two bit arrays; the result has max(a.len, b.len) bits and
/// missing bits read as 0. Complexity: O(max/8).
pub fn bit_array_and(a: BitArray, b: BitArray) -> BitArray {
  _bop(a, b, 0)
}

/// Bitwise OR of two bit arrays; the result has max(a.len, b.len) bits.
/// Complexity: O(max/8).
pub fn bit_array_or(a: BitArray, b: BitArray) -> BitArray {
  _bop(a, b, 1)
}

/// Bitwise XOR of two bit arrays; the result has max(a.len, b.len) bits and
/// missing bits read as 0. Complexity: O(max/8).
pub fn bit_array_xor(a: BitArray, b: BitArray) -> BitArray {
  _bop(a, b, 2)
}

/// Shared binary op: 0 = AND, 1 = OR, 2 = XOR.
fn _bop(a: BitArray, b: BitArray, op: Int) -> BitArray {
  var out_len = a.len;
  if b.len > out_len {
    out_len = b.len;
  };
  var num_bytes = (out_len + 7) / 8;
  var a_bytes = a.bits.len();
  var b_bytes = b.bits.len();
  var result_bytes = Vec[UInt8].new();
  var j: Int = 0;
  while j < num_bytes {
    var av: Int = 0;
    var bv: Int = 0;
    if j < a_bytes {
      var t = a.bits[j] as Int;
      av = t & 0xFF;
    };
    if j < b_bytes {
      var t = b.bits[j] as Int;
      bv = t & 0xFF;
    };
    var r: Int = 0;
    if op == 0 {
      r = av & bv;
    } elif op == 1 {
      r = av | bv;
    } else {
      r = av ^ bv;
    };
    result_bytes.push(r as UInt8);
    j = j + 1;
  };
  BitArray { bits: result_bytes; len: out_len; }
}

/// Bitwise complement over ba.len bits; trailing bits beyond len in the last
/// byte are cleared. Complexity: O(n/8).
pub fn bit_array_not(ba: BitArray) -> BitArray {
  var num_bytes = ba.bits.len();
  var result_bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < num_bytes {
    var b = ba.bits[i] as Int;
    b = b & 0xFF;
    var nb = ~b;
    var v = nb & 0xFF;
    if i == num_bytes - 1 {
      var rem = ba.len % 8;
      if rem != 0 {
        var m = (1 << rem) - 1;
        v = v & m;
      };
    };
    result_bytes.push(v as UInt8);
    i = i + 1;
  };
  BitArray { bits: result_bytes; len: ba.len; }
}

/// Packed byte representation, MSB-first within each byte (bit i of the array
/// is bit 7-(i%8) of byte i/8). Complexity: O(n/8).
pub fn bit_array_to_bytes(ba: BitArray) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < ba.bits.len() {
    result.push(ba.bits[i]);
    i = i + 1;
  };
  result
}

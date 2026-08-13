// XIOM - SIMD: Masks
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.mask

// Depends on: none

// ============================================================================
// Bit-packed SIMD comparison masks with per-lane access, counting, logic and
// vector conversion.
//
// Scalar fallback: a `Mask` is an Int bit pattern over 32 lanes (lane 0 is
// the least-significant bit). Access mask data through the functions in this
// module — direct cross-module field reads of the leading Int field of a
// struct are unreliable in this build.
// ============================================================================

/// A SIMD comparison mask holding one bit per lane (32 lanes in the scalar
/// fallback).
pub type Mask = {
  bits: Int;
} derive[Clone]

/// Build a mask from an integer bit pattern.
/// Complexity: O(1).
pub fn mask_new(bits: Int) -> Mask {
  Mask{ bits: bits; }
}

/// Read lane `i` of a mask (0..31). Out-of-range lanes read false.
/// Complexity: O(1).
pub fn mask_get(m: Mask, i: Int) -> Bool {
  if i < 0 || i > 31 {
    return false;
  };
  let shifted = m.bits >> i;
  (shifted & 1) == 1
}

/// Set lane `i` of a mask (`on`) and return the new mask.
/// Complexity: O(1).
pub fn mask_set(m: Mask, i: Int, on: Bool) -> Mask {
  var bits = m.bits;
  if i < 0 || i > 31 {
    return Mask{ bits: bits; };
  };
  let one = 1 << i;
  if on {
    bits = bits | one;
  } else {
    let shifted = bits >> i;
    if (shifted & 1) == 1 {
      bits = bits - one;
    };
  };
  Mask{ bits: bits; }
}

/// The number of set lanes.
/// Complexity: O(32).
pub fn mask_count(m: Mask) -> Int {
  var count: Int = 0;
  var i: Int = 0;
  while i < 32 {
    let shifted = m.bits >> i;
    if (shifted & 1) == 1 {
      count = count + 1;
    };
    i = i + 1;
  };
  count
}

/// Whether every lane is set.
/// Complexity: O(32).
pub fn mask_all(m: Mask) -> Bool {
  mask_count(m) == 32
}

/// Whether any lane is set.
/// Complexity: O(1).
pub fn mask_any(m: Mask) -> Bool {
  m.bits != 0
}

/// Lane-wise logical AND.
/// Complexity: O(1).
pub fn mask_and(a: Mask, b: Mask) -> Mask {
  Mask{ bits: a.bits & b.bits; }
}

/// Lane-wise logical OR.
/// Complexity: O(1).
pub fn mask_or(a: Mask, b: Mask) -> Mask {
  Mask{ bits: a.bits | b.bits; }
}

/// Lane-wise logical XOR.
/// Complexity: O(1).
pub fn mask_xor(a: Mask, b: Mask) -> Mask {
  Mask{ bits: a.bits ^ b.bits; }
}

/// Lane-wise logical NOT (32 lanes).
/// Complexity: O(1).
pub fn mask_not(m: Mask) -> Mask {
  var result: Int = 0;
  var i: Int = 0;
  while i < 32 {
    let shifted = m.bits >> i;
    if (shifted & 1) == 0 {
      result = result | (1 << i);
    };
    i = i + 1;
  };
  Mask{ bits: result; }
}

/// The integer bit pattern of a mask.
/// Complexity: O(1).
pub fn mask_to_bits(m: Mask) -> Int {
  m.bits
}

/// Build a mask from an integer bit pattern.
/// Complexity: O(1).
pub fn mask_from_bits(bits: Int) -> Mask {
  Mask{ bits: bits; }
}

/// Build a mask from a boolean vector (lane i = v[i]).
/// Complexity: O(len(v)).
pub fn mask_from_vec(v: &Vec[Bool]) -> Mask {
  var bits: Int = 0;
  var i: Int = 0;
  while i < v.len() && i < 32 {
    if v[i] {
      bits = bits | (1 << i);
    };
    i = i + 1;
  };
  Mask{ bits: bits; }
}

/// Expand a mask to a boolean vector of 32 lanes.
/// Complexity: O(32).
pub fn mask_to_vec(m: Mask) -> Vec[Bool] {
  var out = Vec[Bool].new();
  var i: Int = 0;
  while i < 32 {
    let shifted = m.bits >> i;
    out.push((shifted & 1) == 1);
    i = i + 1;
  };
  out
}

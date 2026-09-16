// XIOM - Iterator: Zip
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.iter.zip

// Depends on: none

// ============================================================================
// Combination adapters: zip_longest, chain, cartesian, interleave.
// ============================================================================

/// (a[i], b[i]) pairs padded with fill on the shorter input, iterating to the
/// length of the longer vector. O(max(len)). Returns Vec[(Int, Int)].
/// fill is the padding value used for whichever side ran out.
pub fn iter_zip_longest(a: &Vec[Int], b: &Vec[Int], fill: Int) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var n = a.len();
  if b.len() > n { n = b.len(); }
  var i = 0;
  while i < n {
    if i < a.len() && i < b.len() {
      out.push((a[i], b[i]));
    } elif i < a.len() {
      out.push((a[i], fill));
    } else {
      out.push((fill, b[i]));
    }
    i = i + 1;
  }
  out
}

/// Concatenate a followed by b. O(a.len() + b.len()).
pub fn iter_chain(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    out.push(a[i]);
    i = i + 1;
  }
  i = 0;
  while i < b.len() {
    out.push(b[i]);
    i = i + 1;
  }
  out
}

/// Concatenate a list of vectors in order. O(sum of lengths).
/// NOTE: reading elements of the nested Vec[Vec[Int]] is unreliable in the
/// current compiler; prefer iter_chain for two vectors.
pub fn iter_chain_many(parts: &Vec[Vec[Int]]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < parts.len() {
    var part = parts[i];
    var j = 0;
    while j < part.len() {
      out.push(part[j]);
      j = j + 1;
    }
    i = i + 1;
  }
  out
}

/// All (a[i], b[j]) tuple combinations in row-major order. O(len(a) * len(b)).
/// Returns Vec[(Int, Int)].
pub fn iter_cartesian_product(a: &Vec[Int], b: &Vec[Int]) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var i = 0;
  while i < a.len() {
    var x = a[i];
    var j = 0;
    while j < b.len() {
      out.push((x, b[j]));
      j = j + 1;
    }
    i = i + 1;
  }
  out
}

/// Alternate elements of a and b: a[0], b[0], a[1], b[1], ...
/// The tail of the longer vector is appended after pairing stops. O(n + m).
pub fn iter_interleave(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  var an = a.len();
  var bn = b.len();
  while i < an || i < bn {
    if i < an { out.push(a[i]); }
    if i < bn { out.push(b[i]); }
    i = i + 1;
  }
  out
}

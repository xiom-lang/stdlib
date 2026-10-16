// XIOM - Collections: bit-set dataflow primitives
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.bitset

// Depends on: none (built-in Vec only)

// ============================================================================
// BitSet -- fixed-universe bit set with the dataflow pass primitives
// (packages wishlist row 18: "bit-set union/intersection/subset over integer
// sets for dataflow fixes" -- requesters: analyzer (dominators/liveness),
// compiler-ish packages; their workaround was flat 0/1 Vec[Int] matrices
// with O(n^2) memory).
//
// Words are 64-bit Ints in a Vec; bit `i` lives in word i / 64 at position
// i % 64. Bits at index >= nbits are always zero (fill masks the last word),
// so subset/equality compare raw words. The in-place or/and pairs return a
// "changed" flag: the worklist/fixpoint inner loop of a dataflow pass.
//
// This file is NEW and self-contained; it does not touch the existing
// xiom.bits modules.
// ============================================================================

/// Fixed-universe bit set over `nbits` bit positions.
pub type BitSet = {
  words: Vec[Int];
  nbits: Int;
}

// Popcount of the low 32 bits of `v` (SWAR; v's low 32 bits only).
fn _bs_popcount32(v: Int) -> Int {
  var x = v & 0xFFFFFFFF;
  x = x - ((x >> 1) & 0x55555555);
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F;
  x = (x * 0x01010101) & 0x7FFFFFFF;
  return (x >> 24) & 0xFF;
}

// Popcount of all 64 bits of `v`.
fn _bs_popcount64(v: Int) -> Int {
  var lo = _bs_popcount32(v);
  var hi = _bs_popcount32((v >> 32) & 0xFFFFFFFF);
  return lo + hi;
}

/// Create a zeroed bit set with `nbits` positions (`nbits <= 0` -> empty).
pub fn bitset_new(nbits: Int) -> BitSet
  ensures: result.nbits >= 0
  ensures: nbits <= 0 => result.nbits == 0
{
  var n = nbits;
  if n < 0 { n = 0; }
  var words = Vec[Int].new();
  var nwords = (n + 63) / 64;
  var i = 0;
  while i < nwords {
    words.push(0);
    i = i + 1;
  }
  return BitSet{ words: words; nbits: n; };
}

/// Universe size (number of bit positions).
pub fn bitset_len(b: &BitSet) -> Int
  ensures: result >= 0
{
  return b.nbits;
}

/// Number of 64-bit words backing the set.
pub fn bitset_word_count(b: &BitSet) -> Int
  ensures: result >= 0
{
  return b.words.len();
}

/// Set bit `i`. False (no change) when `i` is out of range or already set.
pub fn bitset_set(b: &mut BitSet, i: Int) -> Bool {
  if i < 0 || i >= b.nbits { return false; }
  var w = i / 64;
  var bit = i % 64;
  var mask = (1 as Int) << bit;
  var word = b.words[w];
  if (word & mask) != 0 { return false; }
  b.words[w] = word | mask;
  return true;
}

/// Clear bit `i`. False (no change) when `i` is out of range or already clear.
pub fn bitset_clear(b: &mut BitSet, i: Int) -> Bool {
  if i < 0 || i >= b.nbits { return false; }
  var w = i / 64;
  var bit = i % 64;
  var mask = (1 as Int) << bit;
  var word = b.words[w];
  if (word & mask) == 0 { return false; }
  b.words[w] = word & ((0 - 1) ^ mask);
  return true;
}

/// True when bit `i` is set (false out of range).
pub fn bitset_get(b: &BitSet, i: Int) -> Bool {
  if i < 0 || i >= b.nbits { return false; }
  var w = i / 64;
  var bit = i % 64;
  var mask = (1 as Int) << bit;
  return (b.words[w] & mask) != 0;
}

/// Set every bit in the universe. Bits beyond `nbits` stay zero.
pub fn bitset_fill(b: &mut BitSet) {
  var i = 0;
  while i < b.words.len() {
    b.words[i] = 0 - 1;
    i = i + 1;
  }
  var r = b.nbits % 64;
  if r > 0 && b.words.len() > 0 {
    var last = b.words.len() - 1;
    b.words[last] = b.words[last] & (((1 as Int) << r) - 1);
  }
}

/// Clear every bit.
pub fn bitset_clear_all(b: &mut BitSet)
  ensures: bitset_count(b) == 0
{
  var i = 0;
  while i < b.words.len() {
    b.words[i] = 0;
    i = i + 1;
  }
}

/// Number of set bits.
pub fn bitset_count(b: &BitSet) -> Int
  ensures: result >= 0
{
  var total = 0;
  var i = 0;
  while i < b.words.len() {
    total = total + _bs_popcount64(b.words[i]);
    i = i + 1;
  }
  return total;
}

/// True when no bit is set.
pub fn bitset_is_empty(b: &BitSet) -> Bool
  ensures: result == (bitset_count(b) == 0)
{
  var i = 0;
  while i < b.words.len() {
    if b.words[i] != 0 { return false; }
    i = i + 1;
  }
  return true;
}

/// Lowest set bit index >= `from`, or -1 when none. O(words + 64).
pub fn bitset_next_set(b: &BitSet, from: Int) -> Int
  ensures: result >= -1
{
  var start = from;
  if start < 0 { start = 0; }
  if start >= b.nbits { return -1; }
  var wstart = start / 64;
  var skip = start % 64;
  var w = wstart;
  while w < b.words.len() {
    var word = b.words[w];
    var base = 0;
    if w == wstart && skip > 0 {
      word = (word >> skip) & (0x7FFFFFFFFFFFFFFF >> (skip - 1));
      base = skip;
    }
    if word != 0 {
      var k = 0;
      while k < 64 {
        if (word & 1) != 0 {
          var idx = w * 64 + base + k;
          if idx >= b.nbits { return -1; }
          return idx;
        }
        word = (word >> 1) & 0x7FFFFFFFFFFFFFFF;
        k = k + 1;
      }
    }
    w = w + 1;
  }
  return -1;
}

/// Set-bit indices in ascending order.
pub fn bitset_to_vec(b: &BitSet) -> Vec[Int]
  ensures: result.len() == bitset_count(b)
{
  var out = Vec[Int].new();
  var i = 0;
  while i < b.nbits {
    var w = i / 64;
    var bit = i % 64;
    var mask = (1 as Int) << bit;
    if (b.words[w] & mask) != 0 {
      out.push(i);
    }
    i = i + 1;
  }
  return out;
}

// Word `i` of `b` (0 when past the end).
fn _bs_word(b: &BitSet, i: Int) -> Int {
  if i < 0 || i >= b.words.len() { return 0; }
  return b.words[i];
}

// A BitSet of `nbits` bits whose words are `a | b` (length = max words).
fn _bs_binop(a: &BitSet, b: &BitSet, op: Int) -> BitSet {
  var n = a.nbits;
  if b.nbits > n { n = b.nbits; }
  var nw = a.words.len();
  if b.words.len() > nw { nw = b.words.len(); }
  var out = Vec[Int].new();
  var i = 0;
  while i < nw {
    var wa = _bs_word(a, i);
    var wb = _bs_word(b, i);
    if op == 0 {
      out.push(wa | wb);
    } elif op == 1 {
      out.push(wa & wb);
    } else {
      out.push(wa & ((0 - 1) ^ wb));
    }
    i = i + 1;
  }
  return BitSet{ words: out; nbits: n; };
}

/// Union as a fresh set (universe = max of the operands').
pub fn bitset_or(a: &BitSet, b: &BitSet) -> BitSet {
  return _bs_binop(a, b, 0);
}

/// Intersection as a fresh set (universe = max of the operands').
pub fn bitset_and(a: &BitSet, b: &BitSet) -> BitSet {
  return _bs_binop(a, b, 1);
}

/// Difference a \ b as a fresh set (universe = max of the operands').
pub fn bitset_andnot(a: &BitSet, b: &BitSet) -> BitSet {
  return _bs_binop(a, b, 2);
}

/// True when every set bit of `a` is also set in `b`.
pub fn bitset_is_subset(a: &BitSet, b: &BitSet) -> Bool {
  var i = 0;
  while i < a.words.len() {
    var wb = _bs_word(b, i);
    if (a.words[i] & ((0 - 1) ^ wb)) != 0 { return false; }
    i = i + 1;
  }
  return true;
}

/// True when both sets hold the same bits.
pub fn bitset_equal(a: &BitSet, b: &BitSet) -> Bool
  ensures: result == true => bitset_count(a) == bitset_count(b)
{
  return bitset_is_subset(a, b) && bitset_is_subset(b, a);
}

/// In-place union `dst |= src`; returns true when `dst` gained bits. Grows
/// `dst`'s universe (never shrinks it) when `src` is wider.
pub fn bitset_or_into(dst: &mut BitSet, src: &BitSet) -> Bool {
  var changed = false;
  var i = 0;
  while i < src.words.len() {
    if i >= dst.words.len() {
      dst.words.push(src.words[i]);
      if src.words[i] != 0 { changed = true; }
    } else {
      var merged = dst.words[i] | src.words[i];
      if merged != dst.words[i] {
        dst.words[i] = merged;
        changed = true;
      }
    }
    i = i + 1;
  }
  if src.nbits > dst.nbits { dst.nbits = src.nbits; }
  return changed;
}

/// In-place intersection `dst &= src`; returns true when `dst` lost bits.
pub fn bitset_and_into(dst: &mut BitSet, src: &BitSet) -> Bool {
  var changed = false;
  var i = 0;
  while i < dst.words.len() {
    var merged = dst.words[i] & _bs_word(src, i);
    if merged != dst.words[i] {
      dst.words[i] = merged;
      changed = true;
    }
    i = i + 1;
  }
  return changed;
}

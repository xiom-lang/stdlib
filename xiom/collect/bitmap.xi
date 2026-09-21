// XIOM - Collections: Bitmap
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.bitmap

// Depends on: none

/// Compact set of bits indexed 0..n-1 with O(1) test/set/clear/flip.
/// Bits are packed into UInt8 bytes (the pattern proven in collect.hash); the
/// padding bits of the last byte are never reported. Index arithmetic uses
/// only small masks (0..255) so the compiler's large-Int AND bug (BUG 25 #7)
/// cannot be hit. Out-of-range positions are ignored (documented).
pub type Bitmap = {
  bytes: Vec[UInt8];
  nbits: Int;
}

/// Create a bitmap of `n` bits, all clear. A size below 1 yields 0 bits.
/// O(n/8).
pub fn bitmap_new(n: Int) -> Bitmap
  ensures: result.nbits >= 0
  ensures: n >= 0 => result.nbits == n
{
  var nb = n;
  if nb < 0 { nb = 0; }
  var nbytes = (nb + 7) / 8;
  if nbytes < 1 { nbytes = 1; }
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < nbytes {
    bytes.push((0) as UInt8);
    i = i + 1;
  }
  return Bitmap{ bytes: bytes; nbits: nb; };
}

fn bm_valid(b: &Bitmap, pos: Int) -> Bool {
  return pos >= 0 && pos < b.nbits;
}

/// Set the bit at `pos`. Positions outside [0, n) are ignored. O(1).
pub fn bitmap_set(b: &mut Bitmap, pos: Int)
  ensures: pos < 0 || pos >= b.nbits || bitmap_test(b, pos)
{
  if !bm_valid(b, pos) { return; }
  var byte_idx = pos / 8;
  var bit_idx = pos % 8;
  var cur = b.bytes[byte_idx] as Int;
  cur = cur | (1 << bit_idx);
  b.bytes[byte_idx] = cur as UInt8;
}

/// Clear the bit at `pos`. Positions outside [0, n) are ignored. O(1).
pub fn bitmap_clear(b: &mut Bitmap, pos: Int)
  ensures: pos < 0 || pos >= b.nbits || bitmap_test(b, pos) == false
{
  if !bm_valid(b, pos) { return; }
  var byte_idx = pos / 8;
  var bit_idx = pos % 8;
  var cur = b.bytes[byte_idx] as Int;
  cur = cur & (255 - (1 << bit_idx));
  b.bytes[byte_idx] = cur as UInt8;
}

/// Test the bit at `pos`. Positions outside [0, n) read as false. O(1).
pub fn bitmap_test(b: &Bitmap, pos: Int) -> Bool
  ensures: pos < 0 || pos >= b.nbits => result == false
{
  if !bm_valid(b, pos) { return false; }
  var byte_idx = pos / 8;
  var bit_idx = pos % 8;
  var cur = b.bytes[byte_idx] as Int;
  return (cur & (1 << bit_idx)) != 0;
}

/// Flip the bit at `pos`. Positions outside [0, n) are ignored. O(1).
pub fn bitmap_flip(b: &mut Bitmap, pos: Int)
  ensures: pos < 0 || pos >= b.nbits || b.nbits >= 1
{
  if !bm_valid(b, pos) { return; }
  var byte_idx = pos / 8;
  var bit_idx = pos % 8;
  var cur = b.bytes[byte_idx] as Int;
  cur = cur ^ (1 << bit_idx);
  b.bytes[byte_idx] = cur as UInt8;
}

/// Number of set bits among the first `nbits` positions. O(n).
pub fn bitmap_count(b: &Bitmap) -> Int
  ensures: result >= 0
{
  var count: Int = 0;
  var i: Int = 0;
  while i < b.nbits {
    if bitmap_test(b, i) {
      count = count + 1;
    }
    i = i + 1;
  }
  return count;
}

/// Index of the first set bit, or None when the bitmap is empty. O(n).
pub fn bitmap_first_set(b: &Bitmap) -> Option[Int]
  ensures: result is None => bitmap_count(b) == 0
  ensures: result is Some => bitmap_count(b) >= 1
{
  var i: Int = 0;
  while i < b.nbits {
    if bitmap_test(b, i) {
      return Some(i);
    }
    i = i + 1;
  }
  return None;
}

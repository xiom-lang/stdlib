// XIOM - Collections: Bloom Filter
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.bloom

// Depends on: xiom.math (Float64 exp/pow for the false-positive estimate)

use xiom.math;

// ============================================================================
// Space-efficient probabilistic set over Int values with no false negatives
// and a tunable false positive rate. `bits` holds `bit_count` usable bits
// packed into UInt8 bytes (the collect.hash pattern). Two independent
// multiplicative hashes (the collect.cuckoo pattern) are combined into
// `num_hashes` positions via h1 + i*h2 mod m; hashing uses shifts and
// multiplies only, so the large-Int AND compiler bug (BUG 25 #7) is avoided.
// `inserted` tracks insertions so the false positive rate can be estimated
// as (1 - e^(-k*n/m))^k.
// ============================================================================

pub type BloomFilter = {
  bits: Vec[UInt8];
  bit_count: Int;
  num_hashes: Int;
  inserted: Int;
}

fn bf_hash1(v: Int) -> Int {
  var x = v * 0x9E3779B97F4A7C15;
  x = x ^ (x >> 29);
  return x;
}

fn bf_hash2(v: Int) -> Int {
  var x = v * 0xC2B2AE3D27D4EB4F;
  x = x ^ (x >> 32);
  x = x * 0x165667B19E3779F9;
  x = x ^ (x >> 29);
  return x;
}

/// Create a Bloom filter with `bits` usable bits and `hashes` hash functions.
/// Both values are clamped to at least 1; the bit count is rounded up to a
/// whole number of bytes. O(bits/8).
pub fn bloom_new(bits: Int, hashes: Int) -> BloomFilter {
  var nbytes = (bits + 7) / 8;
  if nbytes < 1 { nbytes = 1; }
  var bit_count = nbytes * 8;
  var nh = hashes;
  if nh < 1 { nh = 1; }
  var data = Vec[UInt8].new();
  var i: Int = 0;
  while i < nbytes {
    data.push((0) as UInt8);
    i = i + 1;
  }
  return BloomFilter{ bits: data; bit_count: bit_count; num_hashes: nh; inserted: 0; };
}

/// Insert `value` into the filter. O(k).
pub fn bloom_insert(b: &mut BloomFilter, value: Int) {
  var h1 = bf_hash1(value);
  var h2 = bf_hash2(value);
  var i: Int = 0;
  while i < b.num_hashes {
    var pos = (h1 + i * h2) % b.bit_count;
    if pos < 0 { pos = -pos; }
    var byte_idx = pos / 8;
    var bit_idx = pos % 8;
    var cur = b.bits[byte_idx] as Int;
    cur = cur | (1 << bit_idx);
    b.bits[byte_idx] = cur as UInt8;
    i = i + 1;
  }
  b.inserted = b.inserted + 1;
}

/// True if `value` may be present. Never reports a false negative. O(k).
pub fn bloom_may_contain(b: &BloomFilter, value: Int) -> Bool {
  var h1 = bf_hash1(value);
  var h2 = bf_hash2(value);
  var i: Int = 0;
  while i < b.num_hashes {
    var pos = (h1 + i * h2) % b.bit_count;
    if pos < 0 { pos = -pos; }
    var byte_idx = pos / 8;
    var bit_idx = pos % 8;
    var cur = b.bits[byte_idx] as Int;
    if (cur & (1 << bit_idx)) == 0 { return false; }
    i = i + 1;
  }
  return true;
}

/// Reset all bits and the insertion counter. O(m/8).
pub fn bloom_clear(b: &mut BloomFilter) {
  var i: Int = 0;
  while i < b.bits.len() {
    b.bits[i] = (0) as UInt8;
    i = i + 1;
  }
  b.inserted = 0;
}

/// Estimated false positive rate (1 - e^(-k*n/m))^k for the current
/// insertion count, where k = num_hashes, n = inserted, m = bit_count.
/// O(1).
pub fn bloom_false_positive_rate(b: &BloomFilter) -> Float64 {
  var k = b.num_hashes as Float64;
  var n = b.inserted as Float64;
  var m = b.bit_count as Float64;
  var exponent = -((k * n) / m);
  var inner = 1.0 - xiom.math.exp(exponent);
  return xiom.math.pow(inner, k);
}

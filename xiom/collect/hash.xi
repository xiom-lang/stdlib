// XIOM -- Hash Collection (Bloom Filter + Insertion-ordered Map)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.hash

use xiom.math;

// ============================================================================
// Bloom Filter (UInt8 byte inputs)
// `bits` is a byte array holding `bit_count` usable bits (rounded up to a byte
// multiple). Two independent base hashes (FNV-1a and DJB2) are combined into
// `num_hashes` positions via h1 + i*h2 mod m. `inserted` tracks the number of
// insertions so the false positive rate can be estimated as
// (1 - e^(-k*n/m))^k.
// ============================================================================

pub type BloomFilter = {
  bits: Vec[UInt8];
  bit_count: Int;
  num_hashes: Int;
  inserted: Int;
}

/// FNV-1a 32-bit hash over the input bytes.
fn bloom_hash1(data: &Vec[UInt8]) -> Int {
  var hash: Int = 0x811C9DC5;
  var i: Int = 0;
  while i < data.len() {
    var byte = data[i] as Int;
    hash = hash ^ byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    i = i + 1;
  }
  return hash;
}

/// DJB2 hash over the input bytes.
fn bloom_hash2(data: &Vec[UInt8]) -> Int {
  var hash: Int = 5381;
  var i: Int = 0;
  while i < data.len() {
    var byte = data[i] as Int;
    hash = ((hash * 33) + byte) & 0xFFFFFFFF;
    i = i + 1;
  }
  return hash;
}

/// Create a bloom filter with `bits` usable bits and `num_hashes` hash
/// functions. The bit count is rounded up to a whole number of bytes.
pub fn bloom_new(bits: Int, num_hashes: Int) -> BloomFilter {
  var nbytes = (bits + 7) / 8;
  if nbytes < 1 { nbytes = 1; }
  var bit_count = nbytes * 8;
  var nh = num_hashes;
  if nh < 1 { nh = 1; }
  var data = Vec[UInt8].new();
  var i = 0;
  while i < nbytes {
    data.push((0) as UInt8);
    i = i + 1;
  }
  return BloomFilter{ bits: data; bit_count: bit_count; num_hashes: nh; inserted: 0; };
}

/// Insert the given bytes into the filter.
pub fn bloom_insert(b: &mut BloomFilter, data: &Vec[UInt8]) {
  var h1 = bloom_hash1(data);
  var h2 = bloom_hash2(data);
  var i = 0;
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

/// True if the bytes may be present. Never reports a false negative.
pub fn bloom_maybe_contains(b: &BloomFilter, data: &Vec[UInt8]) -> Bool {
  var h1 = bloom_hash1(data);
  var h2 = bloom_hash2(data);
  var i = 0;
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

/// Clear all bits and reset the insertion counter.
pub fn bloom_clear(b: &mut BloomFilter) {
  var i = 0;
  while i < b.bits.len() {
    b.bits[i] = (0) as UInt8;
    i = i + 1;
  }
  b.inserted = 0;
}

/// Estimated false positive rate: (1 - e^(-k*n/m))^k using the tracked
/// insertion count, where k = num_hashes, n = inserted, m = bit_count.
pub fn bloom_false_positive_rate(b: &BloomFilter) -> Float64 {
  var k = b.num_hashes as Float64;
  var n = b.inserted as Float64;
  var m = b.bit_count as Float64;
  var exponent = -((k * n) / m);
  var inner = 1.0 - xiom.math.exp(exponent);
  return xiom.math.pow(inner, k);
}

// ============================================================================
// LhMap -- insertion-ordered map (Int keys -> Int values)
// Inserting a new key appends; updating an existing key keeps its position.
// ============================================================================

pub type LhMap = {
  keys: Vec[Int];
  values: Vec[Int];
}

/// Create an empty insertion-ordered map.
pub fn lhmap_new() -> LhMap {
  return LhMap{ keys: Vec[Int].new(); values: Vec[Int].new(); };
}

/// Index of `key` in the map, or -1 if absent.
fn lhmap_find(m: &LhMap, key: Int) -> Int {
  var i = 0;
  while i < m.keys.len() {
    if m.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

/// Insert or update a key. New keys are appended in insertion order.
pub fn lhmap_put(m: &mut LhMap, key: Int, value: Int) {
  var idx = lhmap_find(m, key);
  if idx >= 0 {
    m.values[idx] = value;
    return;
  }
  m.keys.push(key);
  m.values.push(value);
}

/// Fetch a value by key. None if absent.
pub fn lhmap_get(m: &LhMap, key: Int) -> Option[Int] {
  var idx = lhmap_find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// True if the key is present.
pub fn lhmap_contains(m: &LhMap, key: Int) -> Bool {
  return lhmap_find(m, key) >= 0;
}

/// Remove a key, preserving the relative order of the remaining entries.
/// Returns true if the key was present.
pub fn lhmap_remove(m: &mut LhMap, key: Int) -> Bool {
  var idx = lhmap_find(m, key);
  if idx < 0 { return false; }
  var j = idx;
  while j + 1 < m.keys.len() {
    m.keys[j] = m.keys[j + 1];
    m.values[j] = m.values[j + 1];
    j = j + 1;
  }
  m.keys.pop();
  m.values.pop();
  return true;
}

/// Number of entries in the map.
pub fn lhmap_size(m: &LhMap) -> Int
  ensures: result >= 0
{
  return m.keys.len();
}

/// The keys in insertion order.
pub fn lhmap_keys_in_order(m: &LhMap) -> Vec[Int] {
  var result = Vec[Int].new();
  var i = 0;
  while i < m.keys.len() {
    result.push(m.keys[i]);
    i = i + 1;
  }
  return result;
}

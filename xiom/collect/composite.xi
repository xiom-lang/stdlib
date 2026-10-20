// XIOM - Collections: composite-key map (Int-tuple keys, no string packing)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.composite

// Depends on: none (built-in Vec only)

// ============================================================================
// CompositeKeyMap -- hashed lookups on fixed-arity Int-tuple keys
// (packages wishlist: "composite-key lookup over parallel vectors
// (name/address/port)" -- requesters: discovery, layers).
//
// The module face pairs a documented key-hash with a key-equality helper:
//   * `ckmap_key_hash(key, arity)` -- FNV-1a 64 mixing over the first `arity`
//     components, masked to 63 bits so bucket modulo is well-defined;
//   * `ckmap_key_eq(a, b, arity)`  -- component-wise equality of the first
//     `arity` components.
// The map uses separate chaining over those two primitives; entries live in a
// flat `keys` arena (`arity` Ints per entry) with parallel `values`/`next`/
// `live`. Removed entries are unlinked and flagged dead but stay in the
// arena. The table doubles when the load factor exceeds 0.75, re-linking only
// live entries.
//
// Rust-style derived Eq on struct keys already works on the builtin linear
// Map; this module exists for O(1) hashed lookups over tuple keys carried in
// parallel Int vectors without packing them into strings. It does not touch
// the builtin core collections.
// ============================================================================

/// Hash map with fixed-arity Int-tuple keys and Int values.
pub type CompositeKeyMap = {
  arity: Int;
  buckets: Vec[Int];
  keys: Vec[Int];
  values: Vec[Int];
  next: Vec[Int];
  live: Vec[Bool];
  count: Int;
}

const _CKM_INITIAL: Int = 8;

/// Create an empty composite-key map whose keys have `arity` components.
/// `arity < 1` is clamped to 1.
pub fn ckmap_new(arity: Int) -> CompositeKeyMap
  ensures: result.arity >= 1
  ensures: result.count == 0
{
  var a = arity;
  if a < 1 { a = 1; }
  var buckets = Vec[Int].new();
  var i: Int = 0;
  while i < _CKM_INITIAL {
    buckets.push(-1);
    i = i + 1;
  }
  return CompositeKeyMap{ arity: a; buckets: buckets; keys: Vec[Int].new(); values: Vec[Int].new(); next: Vec[Int].new(); live: Vec[Bool].new(); count: 0; };
}

/// Documented key hash: FNV-1a 64 over the first `arity` Int components of
/// `key`, masked to 63 bits (always non-negative). Deterministic; stable
/// across runs. Reads at most `min(arity, key.len())` components.
pub fn ckmap_key_hash(key: &Vec[Int], arity: Int) -> Int
  ensures: result >= 0
{
  var a = arity;
  if a > key.len() { a = key.len(); }
  var h: Int = 0xCBF29CE484222325;
  var i = 0;
  while i < a {
    h = h ^ key[i];
    h = h * 0x00000100000001B3;
    i = i + 1;
  }
  return h & 0x7FFFFFFFFFFFFFFF;
}

/// Documented key equality: component-wise compare of the first `arity`
/// components. False when either key has fewer than `arity` components.
pub fn ckmap_key_eq(a: &Vec[Int], b: &Vec[Int], arity: Int) -> Bool
  ensures: arity <= 0 => result
  ensures: result => a.len() >= arity && b.len() >= arity
{
  if a.len() < arity { return false; }
  if b.len() < arity { return false; }
  var i = 0;
  while i < arity {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  return true;
}

// Bucket index for `key` (non-negative hash, positive bucket count).
fn _ckm_bucket(m: &CompositeKeyMap, key: &Vec[Int]) -> Int {
  var h = ckmap_key_hash(key, m.arity);
  return h % m.buckets.len();
}

// True when entry `e`'s key equals `key`.
fn _ckm_entry_eq(m: &CompositeKeyMap, e: Int, key: &Vec[Int]) -> Bool {
  var base = e * m.arity;
  var j = 0;
  while j < m.arity {
    if m.keys[base + j] != key[j] { return false; }
    j = j + 1;
  }
  return true;
}

// Entry index for `key`, or -1 if absent.
fn _ckm_find(m: &CompositeKeyMap, key: &Vec[Int]) -> Int {
  if key.len() < m.arity { return -1; }
  var b = _ckm_bucket(m, key);
  var e = m.buckets[b];
  while e != -1 {
    if _ckm_entry_eq(m, e, key) { return e; }
    e = m.next[e];
  }
  return -1;
}

// Double the table and re-link every live entry into the new buckets.
fn _ckm_grow(m: &mut CompositeKeyMap) {
  var nb = m.buckets.len() * 2;
  var new_buckets = Vec[Int].new();
  var i: Int = 0;
  while i < nb {
    new_buckets.push(-1);
    i = i + 1;
  }
  i = 0;
  while i < m.live.len() {
    if m.live[i] {
      var b = _ckm_entry_bucket(m, i, nb);
      m.next[i] = new_buckets[b];
      new_buckets[b] = i;
    }
    i = i + 1;
  }
  m.buckets = new_buckets;
}

// Bucket index for arena entry `e` within `nb` buckets.
fn _ckm_entry_bucket(m: &CompositeKeyMap, e: Int, nb: Int) -> Int {
  var base = e * m.arity;
  var h: Int = 0xCBF29CE484222325;
  var j = 0;
  while j < m.arity {
    h = h ^ m.keys[base + j];
    h = h * 0x00000100000001B3;
    j = j + 1;
  }
  var masked = h & 0x7FFFFFFFFFFFFFFF;
  return masked % nb;
}

/// Insert or update `key` -> `value`. The first `arity` components of `key`
/// are the key; `key` must carry at least `arity` components.
pub fn ckmap_put(m: &mut CompositeKeyMap, key: &Vec[Int], value: Int)
  requires: key.len() >= m.arity
  ensures: ckmap_contains(m, key)
{
  if key.len() < m.arity { return; }
  var e = _ckm_find(m, key);
  if e >= 0 {
    m.values[e] = value;
    return;
  }
  if m.count * 4 > m.buckets.len() * 3 {
    _ckm_grow(m);
  }
  var b = _ckm_bucket(m, key);
  var id = m.live.len();
  var j = 0;
  while j < m.arity {
    m.keys.push(key[j]);
    j = j + 1;
  }
  m.values.push(value);
  m.next.push(m.buckets[b]);
  m.live.push(true);
  m.buckets[b] = id;
  m.count = m.count + 1;
}

/// Get the value for a key. None when absent.
pub fn ckmap_get(m: &CompositeKeyMap, key: &Vec[Int]) -> Option[Int]
  requires: key.len() >= m.arity
  ensures: result.is_some == ckmap_contains(m, key)
{
  var e = _ckm_find(m, key);
  if e < 0 { return None; }
  return Some(m.values[e]);
}

/// Check whether a key is present.
pub fn ckmap_contains(m: &CompositeKeyMap, key: &Vec[Int]) -> Bool
  requires: key.len() >= m.arity
{
  return _ckm_find(m, key) >= 0;
}

/// Remove a key. Returns true when it was present. Arena memory is retained.
pub fn ckmap_remove(m: &mut CompositeKeyMap, key: &Vec[Int]) -> Bool
  requires: key.len() >= m.arity
  ensures: !ckmap_contains(m, key)
  ensures: result == true => ckmap_size(m) == ckmap_size(m)@pre - 1
  ensures: result == false => ckmap_size(m) == ckmap_size(m)@pre
{
  if key.len() < m.arity { return false; }
  var b = _ckm_bucket(m, key);
  var prev: Int = -1;
  var e = m.buckets[b];
  while e != -1 {
    if _ckm_entry_eq(m, e, key) {
      if prev == -1 {
        m.buckets[b] = m.next[e];
      } else {
        m.next[prev] = m.next[e];
      }
      m.live[e] = false;
      m.count = m.count - 1;
      return true;
    }
    prev = e;
    e = m.next[e];
  }
  return false;
}

/// Number of live entries.
pub fn ckmap_size(m: &CompositeKeyMap) -> Int
  ensures: result >= 0
{
  return m.count;
}

/// Number of key components per key.
pub fn ckmap_arity(m: &CompositeKeyMap) -> Int
  ensures: result >= 1
{
  return m.arity;
}

/// Number of arena slots ever used (live + removed; removal keeps entries).
pub fn ckmap_entry_count(m: &CompositeKeyMap) -> Int
  ensures: result >= 0
{
  return m.live.len();
}

/// True when arena entry `e` is live.
pub fn ckmap_entry_live(m: &CompositeKeyMap, e: Int) -> Bool
  ensures: result => e >= 0 && e < m.live.len()
{
  if e < 0 || e >= m.live.len() { return false; }
  return m.live[e];
}

/// Key components of arena entry `e` (empty when `e` is out of range).
pub fn ckmap_entry_key(m: &CompositeKeyMap, e: Int) -> Vec[Int]
  ensures: e < 0 => result.len() == 0
  ensures: e >= m.live.len() => result.len() == 0
{
  var out = Vec[Int].new();
  if e < 0 || e >= m.live.len() { return out; }
  var base = e * m.arity;
  var j = 0;
  while j < m.arity {
    out.push(m.keys[base + j]);
    j = j + 1;
  }
  return out;
}

/// Value of arena entry `e`. None when `e` is dead or out of range.
pub fn ckmap_entry_value(m: &CompositeKeyMap, e: Int) -> Option[Int]
  ensures: result.is_some == ckmap_entry_live(m, e)
{
  if e < 0 || e >= m.live.len() { return None; }
  if !m.live[e] { return None; }
  return Some(m.values[e]);
}

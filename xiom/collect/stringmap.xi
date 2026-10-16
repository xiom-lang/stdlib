// XIOM - Collections: String Map
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.stringmap

// Depends on: xiom.string

// ============================================================================
// Hash map with string keys and Int values.
// Separate chaining with Str keys; the bucket index comes from SipHash-2-4
// keyed per process from OS entropy (hash-DoS hardening -- replaced the
// previous fixed-key DJB2 default). Entries live in parallel `keys` (Str) /
// `values` (Int) / `next` / `live` arenas; removed entries are unlinked and
// flagged dead but stay in the arena. The table doubles when the load
// factor exceeds 0.75, re-linking only live entries.
// ============================================================================

use xiom.string;
use xiom.hash.siphash;

/// Insertion-ordered string-keyed map.
pub type StringMap = {
  buckets: Vec[Int];
  keys: Vec[Str];
  values: Vec[Int];
  next: Vec[Int];
  live: Vec[Bool];
  count: Int;
}

const _SMAP_INITIAL: Int = 8;

// Seeded SipHash-2-4 over the key, masked to 63 bits so the bucket modulo
// is well-defined. Key material: per-process from OS entropy (see
// xiom.hash.siphash._sip_ensure_keys; degraded to a time-derived key only
// when no OS entropy source answers).
fn _hash_str(key: Str) -> Int {
  let h = siphash.siphash24_str_seeded(key);
  return (h & 0x7FFFFFFFFFFFFFFF) as Int;
}

fn _bucket(m: &StringMap, key: Str) -> Int {
  var h = _hash_str(key);
  return h % m.buckets.len();
}

/// Create a new empty string map.
/// Returns: a map with a small initial table and zero entries.
/// Complexity: O(1).
pub fn string_map_new() -> StringMap
  ensures: result.count == 0
{
  var buckets = Vec[Int].new();
  var i: Int = 0;
  while i < _SMAP_INITIAL {
    buckets.push(-1);
    i = i + 1;
  }
  return StringMap{ buckets: buckets; keys: Vec[Str].new(); values: Vec[Int].new(); next: Vec[Int].new(); live: Vec[Bool].new(); count: 0; };
}

// Entry index for `key`, or -1 if absent.
fn _find(m: &StringMap, key: Str) -> Int {
  var b = _bucket(m, key);
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
      return e;
    }
    e = m.next[e];
  }
  return -1;
}

// Double the table and re-link every live entry into the new buckets.
fn _grow(m: &mut StringMap) {
  var nb = m.buckets.len() * 2;
  var new_buckets = Vec[Int].new();
  var i: Int = 0;
  while i < nb {
    new_buckets.push(-1);
    i = i + 1;
  }
  i = 0;
  while i < m.keys.len() {
    if m.live[i] {
      var k = m.keys[i];
      var b = _hash_str(k) % nb;
      m.next[i] = new_buckets[b];
      new_buckets[b] = i;
    }
    i = i + 1;
  }
  m.buckets = new_buckets;
}

/// Insert or update `key` -> `value`.
/// Params: m - the map; key - Str key; value - Int value.
/// Re-inserting an existing key updates its value.
/// Complexity: O(1) amortized.
pub fn string_map_put(m: &mut StringMap, key: Str, value: Int)
  ensures: m.count >= 1
{
  var idx = _find(m, key);
  if idx >= 0 {
    m.values[idx] = value;
    return;
  }
  if m.count * 4 > m.buckets.len() * 3 {
    _grow(m);
  }
  var b = _bucket(m, key);
  var id = m.keys.len();
  m.keys.push(key);
  m.values.push(value);
  m.next.push(m.buckets[b]);
  m.live.push(true);
  m.buckets[b] = id;
  m.count = m.count + 1;
}

/// Get the value for a key. None when absent.
/// Params: m - the map; key - Str key.
/// Returns: Some(value) if present, None otherwise.
/// Complexity: O(1) amortized.
pub fn string_map_get(m: &StringMap, key: Str) -> Option[Int] {
  var idx = _find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// Check whether a key is present.
/// Params: m - the map; key - Str key.
/// Returns: true if `key` maps to a value.
/// Complexity: O(1) amortized.
pub fn string_map_contains(m: &StringMap, key: Str) -> Bool {
  return _find(m, key) >= 0;
}

/// Remove a key.
/// Params: m - the map; key - Str key.
/// Absent keys are a no-op. Arena memory is retained.
/// Complexity: O(1) amortized.
pub fn string_map_remove(m: &mut StringMap, key: Str)
  ensures: m.count >= 0
{
  var b = _bucket(m, key);
  var prev: Int = -1;
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
      if prev == -1 {
        m.buckets[b] = m.next[e];
      } else {
        m.next[prev] = m.next[e];
      }
      m.live[e] = false;
      m.count = m.count - 1;
      return;
    }
    prev = e;
    e = m.next[e];
  }
}

/// Number of entries.
/// Params: m - the map.
/// Returns: the number of live key/value pairs.
/// Complexity: O(1).
pub fn string_map_size(m: &StringMap) -> Int
  ensures: result >= 0
{
  return m.count;
}

// ============================================================================
// StringStrMap -- insertion-ordered string-keyed map with Str values
// (packages wishlist row 43: "Str -> Str ordered map/table type"; requesters:
// puppet scopes/hiera/hash-merge, helm. `xiom.collect.stringmap` was
// Str -> Int only).
//
// Same separate-chaining design as StringMap: SipHash-2-4 bucket index, Str
// key/value arenas, unlinked-but-retained removals. Callers never hash
// manually -- the module face does it. Iteration follows arena order, which
// is first-introduction order for live entries.
// ============================================================================

/// Insertion-ordered string-keyed map with string values.
pub type StringStrMap = {
  buckets: Vec[Int];
  keys: Vec[Str];
  values: Vec[Str];
  next: Vec[Int];
  live: Vec[Bool];
  count: Int;
}

/// Create a new empty string->string map.
pub fn string_str_map_new() -> StringStrMap
  ensures: result.count == 0
{
  var buckets = Vec[Int].new();
  var i: Int = 0;
  while i < _SMAP_INITIAL {
    buckets.push(-1);
    i = i + 1;
  }
  return StringStrMap{ buckets: buckets; keys: Vec[Str].new(); values: Vec[Str].new(); next: Vec[Int].new(); live: Vec[Bool].new(); count: 0; };
}

// Entry index for `key`, or -1 if absent.
fn _ssm_find(m: &StringStrMap, key: Str) -> Int {
  var b = _bucket_ss(m, key);
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
      return e;
    }
    e = m.next[e];
  }
  return -1;
}

// Bucket index of `key` for the map's current bucket table.
fn _bucket_ss(m: &StringStrMap, key: Str) -> Int {
  var h = _hash_str(key);
  return h % m.buckets.len();
}

// Double the table and re-link every live entry into the new buckets.
fn _ssm_grow(m: &mut StringStrMap) {
  var nb = m.buckets.len() * 2;
  var new_buckets = Vec[Int].new();
  var i: Int = 0;
  while i < nb {
    new_buckets.push(-1);
    i = i + 1;
  }
  i = 0;
  while i < m.keys.len() {
    if m.live[i] {
      var k = m.keys[i];
      var b = _hash_str(k) % nb;
      m.next[i] = new_buckets[b];
      new_buckets[b] = i;
    }
    i = i + 1;
  }
  m.buckets = new_buckets;
}

/// Insert or update `key` -> `value`. Re-inserting an existing key updates
/// its value in place (position kept).
pub fn string_str_map_put(m: &mut StringStrMap, key: Str, value: Str)
  ensures: string_str_map_contains(m, key)
{
  var idx = _ssm_find(m, key);
  if idx >= 0 {
    m.values[idx] = value;
    return;
  }
  if m.count * 4 > m.buckets.len() * 3 {
    _ssm_grow(m);
  }
  var b = _bucket_ss(m, key);
  var id = m.keys.len();
  m.keys.push(key);
  m.values.push(value);
  m.next.push(m.buckets[b]);
  m.live.push(true);
  m.buckets[b] = id;
  m.count = m.count + 1;
}

/// Get the value for a key. None when absent.
pub fn string_str_map_get(m: &StringStrMap, key: Str) -> Option[Str]
  ensures: result.is_some == string_str_map_contains(m, key)
{
  var idx = _ssm_find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// Check whether a key is present.
pub fn string_str_map_contains(m: &StringStrMap, key: Str) -> Bool {
  return _ssm_find(m, key) >= 0;
}

/// Remove a key. Returns true when it was present. Arena memory is retained.
pub fn string_str_map_remove(m: &mut StringStrMap, key: Str) -> Bool
  ensures: !string_str_map_contains(m, key)
{
  var b = _bucket_ss(m, key);
  var prev: Int = -1;
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
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
pub fn string_str_map_size(m: &StringStrMap) -> Int
  ensures: result >= 0
{
  return m.count;
}

/// Number of arena slots ever used (live + removed).
pub fn string_str_map_entry_count(m: &StringStrMap) -> Int
  ensures: result >= 0
{
  return m.live.len();
}

/// True when arena entry `e` is live.
pub fn string_str_map_entry_live(m: &StringStrMap, e: Int) -> Bool {
  if e < 0 || e >= m.live.len() { return false; }
  return m.live[e];
}

/// Key of arena entry `e`. None when `e` is dead or out of range.
pub fn string_str_map_entry_key(m: &StringStrMap, e: Int) -> Option[Str]
  ensures: result.is_some == string_str_map_entry_live(m, e)
{
  if e < 0 || e >= m.live.len() { return None; }
  if !m.live[e] { return None; }
  return Some(m.keys[e]);
}

/// Value of arena entry `e`. None when `e` is dead or out of range.
pub fn string_str_map_entry_value(m: &StringStrMap, e: Int) -> Option[Str]
  ensures: result.is_some == string_str_map_entry_live(m, e)
{
  if e < 0 || e >= m.live.len() { return None; }
  if !m.live[e] { return None; }
  return Some(m.values[e]);
}

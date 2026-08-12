// XIOM - Collections: Optimized Keyed Maps
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.intmap

// Depends on: xiom.string

// ============================================================================
// Optimized keyed maps. int_map uses a flat open-addressing table sized for the
// expected capacity (Int keys -> Int values); string_map uses a string-keyed
// variant. Both reject duplicate keys and iterate over stored keys in
// insertion order via int_map_iter.
//
// Flat-arena style. The int_map table stores parallel `keys`/`vals`/`occ`/
// `tomb` vectors of `cap` slots with linear probing and a multiplicative hash
// (high 32 bits of key * golden ratio, forced non-negative) so INT_MIN and
// other pathological keys are safe. Deleted slots become tombstones so probing
// chains stay intact; the table doubles when the load factor reaches 1/2. A
// separate `order` vector tracks the insertion order of live keys for
// `int_map_iter`. string_map is a simpler linear Vec[Str] map (strings are
// compared via bound locals, compiler BUG 8 workaround).
// ============================================================================

pub type IntMap = {
  cap: Int;
  size: Int;
  keys: Vec[Int];
  vals: Vec[Int];
  occ: Vec[Bool];
  tomb: Vec[Bool];
  order: Vec[Int];
}

fn _imap_hash(key: Int, cap: Int) -> Int {
  var h = key * 0x9E3779B97F4A7C15;
  h = h >> 32;
  h = h & 0x7FFFFFFF;
  var r = h % cap;
  return r;
}

fn _imap_alloc(m: &mut IntMap, cap: Int) {
  m.cap = cap;
  var i = 0;
  while i < cap {
    m.keys.push(0);
    m.vals.push(0);
    m.occ.push(false);
    m.tomb.push(false);
    i = i + 1;
  }
}

// Place a live key/value in the table (no order bookkeeping, no growth).
fn _imap_place(m: &mut IntMap, key: Int, value: Int) {
  var probe = _imap_hash(key, m.cap);
  var first_free = -1;
  var i = 0;
  while i < m.cap {
    if m.occ[probe] {
      if m.keys[probe] == key {
        m.vals[probe] = value;
        return;
      }
    } else {
      if first_free == -1 {
        first_free = probe;
      }
      if !m.tomb[probe] {
        break;
      }
    }
    probe = (probe + 1) % m.cap;
    i = i + 1;
  }
  var slot = first_free;
  if slot == -1 {
    slot = probe;
  }
  m.keys[slot] = key;
  m.vals[slot] = value;
  m.occ[slot] = true;
  m.tomb[slot] = false;
  m.size = m.size + 1;
}

fn _imap_resize(m: &mut IntMap, new_cap: Int) {
  var old_keys = Vec[Int].new();
  var old_vals = Vec[Int].new();
  var i = 0;
  while i < m.cap {
    if m.occ[i] {
      old_keys.push(m.keys[i]);
      old_vals.push(m.vals[i]);
    }
    i = i + 1;
  }
  m.cap = new_cap;
  m.keys = Vec[Int].new();
  m.vals = Vec[Int].new();
  m.occ = Vec[Bool].new();
  m.tomb = Vec[Bool].new();
  m.size = 0;
  _imap_alloc(m, new_cap);
  i = 0;
  while i < old_keys.len() {
    _imap_place(m, old_keys[i], old_vals[i]);
    i = i + 1;
  }
}

// Slot index of `key` in the table, or -1 if absent.
fn _imap_find(m: &IntMap, key: Int) -> Int {
  if m.size == 0 {
    return -1;
  }
  var probe = _imap_hash(key, m.cap);
  var i = 0;
  while i < m.cap {
    if m.occ[probe] {
      if m.keys[probe] == key {
        return probe;
      }
    } else {
      if !m.tomb[probe] {
        return -1;
      }
    }
    probe = (probe + 1) % m.cap;
    i = i + 1;
  }
  return -1;
}

/// Create an Int-keyed map with `capacity` slots. The table grows
/// automatically, so `capacity` is an initial hint; it is clamped to >= 1.
/// O(capacity).
pub fn int_map_new(capacity: Int) -> IntMap {
  var m = IntMap{ cap: 0; size: 0; keys: Vec[Int].new(); vals: Vec[Int].new(); occ: Vec[Bool].new(); tomb: Vec[Bool].new(); order: Vec[Int].new(); };
  var cap = capacity;
  if cap < 1 {
    cap = 1;
  }
  _imap_alloc(&mut m, cap);
  return m;
}

/// Insert or overwrite `key` -> `value`. A re-insert of an existing key
/// updates its value without changing its insertion position.
/// O(1) amortized.
pub fn int_map_put(m: &mut IntMap, key: Int, value: Int) {
  var hit = _imap_find(m, key);
  if hit >= 0 {
    m.vals[hit] = value;
    return;
  }
  if m.size * 2 >= m.cap {
    _imap_resize(m, m.cap * 2);
  }
  _imap_place(m, key, value);
  m.order.push(key);
}

/// Value for `key`, or None if absent.
/// O(1) amortized.
pub fn int_map_get(m: &IntMap, key: Int) -> Option[Int] {
  var slot = _imap_find(m, key);
  if slot < 0 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  return Option[Int]{ is_some: true; value: m.vals[slot]; };
}

/// True if `key` is present.
/// O(1) amortized.
pub fn int_map_contains(m: &IntMap, key: Int) -> Bool {
  return _imap_find(m, key) >= 0;
}

/// Remove `key`. Returns true if it was present.
/// O(n) amortized (order compaction).
pub fn int_map_remove(m: &mut IntMap, key: Int) -> Bool {
  var slot = _imap_find(m, key);
  if slot < 0 {
    return false;
  }
  m.occ[slot] = false;
  m.tomb[slot] = true;
  m.size = m.size - 1;
  var i = 0;
  while i < m.order.len() {
    if m.order[i] == key {
      var j = i;
      while j + 1 < m.order.len() {
        m.order[j] = m.order[j + 1];
        j = j + 1;
      }
      m.order.pop();
      break;
    }
    i = i + 1;
  }
  return true;
}

/// Number of key/value pairs.
/// O(1).
pub fn int_map_size(m: &IntMap) -> Int {
  return m.size;
}

/// All keys in insertion order.
/// O(n).
pub fn int_map_iter(m: &IntMap) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < m.order.len() {
    out.push(m.order[i]);
    i = i + 1;
  }
  return out;
}

// ============================================================================
// StringMap (Str keys -> Int values, insertion-ordered)
// ============================================================================

pub type StringMap = {
  keys: Vec[Str];
  vals: Vec[Int];
}

/// Create a Str-keyed map.
/// O(1).
pub fn string_map_new() -> StringMap {
  return StringMap{ keys: Vec[Str].new(); vals: Vec[Int].new(); };
}

/// Insert or overwrite `key` -> `value`. A re-insert of an existing key
/// updates its value without changing its insertion position.
/// O(n).
pub fn string_map_put(m: &mut StringMap, key: Str, value: Int) {
  var i = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k == key {
      m.vals[i] = value;
      return;
    }
    i = i + 1;
  }
  m.keys.push(key);
  m.vals.push(value);
}

/// Value for `key`, or None if absent.
/// O(n).
pub fn string_map_get(m: &StringMap, key: Str) -> Option[Int] {
  var i = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k == key {
      return Option[Int]{ is_some: true; value: m.vals[i]; };
    }
    i = i + 1;
  }
  return Option[Int]{ is_some: false; value: 0; };
}

/// True if `key` is present.
/// O(n).
pub fn string_map_contains(m: &StringMap, key: Str) -> Bool {
  var i = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k == key {
      return true;
    }
    i = i + 1;
  }
  return false;
}

/// Remove `key`. Returns true if it was present.
/// O(n).
pub fn string_map_remove(m: &mut StringMap, key: Str) -> Bool {
  var i = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k == key {
      var j = i;
      while j + 1 < m.keys.len() {
        m.keys[j] = m.keys[j + 1];
        m.vals[j] = m.vals[j + 1];
        j = j + 1;
      }
      m.keys.pop();
      m.vals.pop();
      return true;
    }
    i = i + 1;
  }
  return false;
}

/// Number of key/value pairs.
/// O(1).
pub fn string_map_size(m: &StringMap) -> Int {
  return m.keys.len();
}

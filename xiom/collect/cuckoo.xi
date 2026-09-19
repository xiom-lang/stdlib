// XIOM -- Collections: Cuckoo hash map (Int keys, Int values)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.cuckoo

// ============================================================================
// CuckooMap (Int keys, Int values)
// Two power-of-two tables with two independent multiplicative hashes. Insert
// displaces the victim to the other table (bounded at 16 relocations, then
// the tables double). O(1) expected lookups with at most 2 probes.
// ============================================================================

pub type CuckooMap = {
  t0_keys: Vec[Int];
  t0_vals: Vec[Int];
  t1_keys: Vec[Int];
  t1_vals: Vec[Int];
  size: Int;
  cap: Int;
}

const EMPTY: Int = -9223372036854775807;

fn _h1(key: Int, cap: Int) -> Int {
  var v = key * 0x9E3779B97F4A7C15;
  v = v ^ (v >> 29);
  return (v & (cap - 1));
}

fn _h2(key: Int, cap: Int) -> Int {
  var v = key * 0xC2B2AE3D27D4EB4F;
  v = v ^ (v >> 32);
  v = v * 0x165667B19E3779F9;
  return (v & (cap - 1));
}

fn _empty_table(n: Int) -> Vec[Int] {
  var v = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    v.push(EMPTY);
    i = i + 1;
  }
  return v;
}

/// Create an empty cuckoo map with at least `capacity` slots (rounded up to
/// a power of two).
pub fn cuckoo_new(capacity: Int) -> CuckooMap
  ensures: result.cap >= 8
  ensures: result.size == 0
  ensures: result.t0_keys.len() == result.cap
{
  var n: Int = 8;
  while n < capacity {
    n = n * 2;
  }
  return CuckooMap{
    t0_keys: _empty_table(n);
    t0_vals: _empty_table(n);
    t1_keys: _empty_table(n);
    t1_vals: _empty_table(n);
    size: 0;
    cap: n;
  };
}

fn _lookup(m: &CuckooMap, key: Int) -> (Int, Int, Int) {
  // returns (table, slot, found): found 1 = present
  var i0 = _h1(key, m.cap);
  if m.t0_keys[i0] == key {
    return (0, i0, 1);
  }
  var i1 = _h2(key, m.cap);
  if m.t1_keys[i1] == key {
    return (1, i1, 1);
  }
  return (0, 0, 0);
}

fn _place(m: &mut CuckooMap, key: Int, value: Int, table: Int, slot: Int) {
  if table == 0 {
    m.t0_keys[slot] = key;
    m.t0_vals[slot] = value;
  } else {
    m.t1_keys[slot] = key;
    m.t1_vals[slot] = value;
  }
}

fn _read_val(m: &CuckooMap, table: Int, slot: Int) -> Int {
  if table == 0 {
    return m.t0_vals[slot];
  }
  return m.t1_vals[slot];
}

fn _grow(m: &mut CuckooMap) {
  var old0k = m.t0_keys;
  var old0v = m.t0_vals;
  var old1k = m.t1_keys;
  var old1v = m.t1_vals;
  var old_cap = m.cap;
  m.cap = old_cap * 2;
  m.t0_keys = _empty_table(m.cap);
  m.t0_vals = _empty_table(m.cap);
  m.t1_keys = _empty_table(m.cap);
  m.t1_vals = _empty_table(m.cap);
  m.size = 0;
  var i: Int = 0;
  while i < old_cap {
    if old0k[i] != EMPTY {
      cuckoo_put(m, old0k[i], old0v[i]);
    }
    if old1k[i] != EMPTY {
      cuckoo_put(m, old1k[i], old1v[i]);
    }
    i = i + 1;
  }
}

/// Insert or overwrite `key` -> `value`. Doubles the tables when the
/// displacement bound is exceeded.
pub fn cuckoo_put(m: &mut CuckooMap, key: Int, value: Int)
  ensures: cuckoo_contains(m, key)
{
  var existing = _lookup(m, key);
  if existing.2 == 1 {
    if existing.0 == 0 {
      m.t0_vals[existing.1] = value;
    } else {
      m.t1_vals[existing.1] = value;
    }
    return;
  }
  var k = key;
  var v = value;
  var table: Int = 0;
  var slot = _h1(k, m.cap);
  var round: Int = 0;
  while round <= 16 {
    var occupant = m.t0_keys[slot];
    if table == 1 {
      occupant = m.t1_keys[slot];
    }
    if occupant == EMPTY {
      _place(m, k, v, table, slot);
      m.size = m.size + 1;
      return;
    }
    // displace
    var ok = occupant;
    var ov: Int = 0;
    if table == 0 {
      ov = m.t0_vals[slot];
    } else {
      ov = m.t1_vals[slot];
    }
    _place(m, k, v, table, slot);
    k = ok;
    v = ov;
    if table == 0 {
      slot = _h2(k, m.cap);
      table = 1;
    } else {
      slot = _h1(k, m.cap);
      table = 0;
    }
    round = round + 1;
  }
  // too many relocations -- grow and retry
  _grow(m);
  cuckoo_put(m, k, v);
}

/// Value for `key` (None if absent).
pub fn cuckoo_get(m: &CuckooMap, key: Int) -> Option[Int]
  ensures: result.is_some == cuckoo_contains(m, key)
{
  var found = _lookup(m, key);
  if found.2 == 0 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  return Option[Int]{ is_some: true; value: _read_val(m, found.0, found.1); };
}

/// True if `key` is present.
pub fn cuckoo_contains(m: &CuckooMap, key: Int) -> Bool
  ensures: result == true => cuckoo_size(m) >= 1
{
  return _lookup(m, key).2 == 1;
}

/// Remove `key`. Returns true if it was present.
pub fn cuckoo_remove(m: &mut CuckooMap, key: Int) -> Bool
  ensures: result == true => cuckoo_contains(m, key) == false
  ensures: result == false => cuckoo_contains(m, key)
{
  var found = _lookup(m, key);
  if found.2 == 0 {
    return false;
  }
  if found.0 == 0 {
    m.t0_keys[found.1] = EMPTY;
  } else {
    m.t1_keys[found.1] = EMPTY;
  }
  m.size = m.size - 1;
  return true;
}

/// Number of stored keys.
pub fn cuckoo_size(m: &CuckooMap) -> Int
  ensures: result >= 0
{
  return m.size;
}

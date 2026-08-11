// XIOM — Cache Collection (LRU + LFU)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.cache

// ============================================================================
// LRU Cache (Int keys, Int values)
// Simple bookkeeping: `keys`/`values` are parallel vectors and `order` is a
// vector of keys in recency order, front = most recently used. `lru_get` and
// `lru_put` move an accessed key to the front; when full, the key at the back
// of `order` (least recently used) is evicted.
// ============================================================================

pub type LruCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  order: Vec[Int];
}

/// Create an LRU cache holding at most `capacity` entries.
pub fn lru_new(capacity: Int) -> LruCache {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  return LruCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); order: Vec[Int].new(); };
}

/// Move `key` to the front of the recency order (most recently used).
fn lru_touch(c: &mut LruCache, key: Int) {
  var i = 0;
  while i < c.order.len() {
    if c.order[i] == key {
      c.order.remove(i);
      break;
    }
    i = i + 1;
  }
  c.order.insert(0, key);
}

/// Index of `key` in the parallel `keys` vector, or -1 if absent.
fn lru_find(c: &LruCache, key: Int) -> Int {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

/// Fetch a value, marking the key as most recently used. None if absent.
pub fn lru_get(c: &mut LruCache, key: Int) -> Option[Int] {
  var idx = lru_find(c, key);
  if idx < 0 { return None; }
  var val = c.values[idx];
  lru_touch(c, key);
  return Some(val);
}

/// Insert or update a key. Evicts the least recently used key when full.
pub fn lru_put(c: &mut LruCache, key: Int, value: Int) {
  var idx = lru_find(c, key);
  if idx >= 0 {
    c.values[idx] = value;
    lru_touch(c, key);
    return;
  }
  if c.keys.len() >= c.capacity {
    var victim = c.order[c.order.len() - 1];
    var vi = lru_find(c, victim);
    if vi >= 0 {
      c.keys.remove(vi);
      c.values.remove(vi);
    }
    c.order.pop();
  }
  c.keys.push(key);
  c.values.push(value);
  c.order.insert(0, key);
}

/// True if the key is present in the cache.
pub fn lru_contains(c: &LruCache, key: Int) -> Bool {
  return lru_find(c, key) >= 0;
}

/// Number of entries currently cached.
pub fn lru_size(c: &LruCache) -> Int {
  return c.keys.len();
}

/// Maximum number of entries the cache can hold.
pub fn lru_capacity(c: &LruCache) -> Int {
  return c.capacity;
}

// ============================================================================
// LFU Cache (Int keys, Int values)
// Parallel `keys`/`values`/`counts` vectors plus an insertion-sequence vector
// `seq` used as a deterministic tie-break: when several keys share the lowest
// frequency, the least recently inserted one is evicted first.
// ============================================================================

pub type LfuCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  counts: Vec[Int];
  seq: Vec[Int];
  next_seq: Int;
}

/// Create an LFU cache holding at most `capacity` entries.
pub fn lfu_new(capacity: Int) -> LfuCache {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  return LfuCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); counts: Vec[Int].new(); seq: Vec[Int].new(); next_seq: 0; };
}

/// Fetch a value and increment its access frequency. None if absent.
pub fn lfu_get(c: &mut LfuCache, key: Int) -> Option[Int] {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.counts[i] = c.counts[i] + 1;
      return Some(c.values[i]);
    }
    i = i + 1;
  }
  return None;
}

/// Insert or update a key. On overflow, evicts the lowest-frequency key
/// (tie-break: least recently inserted among the minimum-frequency group).
pub fn lfu_put(c: &mut LfuCache, key: Int, value: Int) {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.values[i] = value;
      c.counts[i] = c.counts[i] + 1;
      return;
    }
    i = i + 1;
  }
  if c.keys.len() >= c.capacity {
    var mi = 0;
    var j = 1;
    while j < c.keys.len() {
      if c.counts[j] < c.counts[mi] {
        mi = j;
      } elif c.counts[j] == c.counts[mi] {
        if c.seq[j] < c.seq[mi] {
          mi = j;
        }
      }
      j = j + 1;
    }
    c.keys.remove(mi);
    c.values.remove(mi);
    c.counts.remove(mi);
    c.seq.remove(mi);
  }
  c.keys.push(key);
  c.values.push(value);
  c.counts.push(1);
  c.seq.push(c.next_seq);
  c.next_seq = c.next_seq + 1;
}

/// True if the key is present in the cache.
pub fn lfu_contains(c: &LfuCache, key: Int) -> Bool {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key { return true; }
    i = i + 1;
  }
  return false;
}

/// Number of entries currently cached.
pub fn lfu_size(c: &LfuCache) -> Int {
  return c.keys.len();
}

// ============================================================================
// ArcCache ? Adaptive Replacement Cache (2026-08-11)
// Standard ARC (Megiddo & Modha): T1 (recent) / T2 (frequent) hold cached
// (key, value) pairs, B1/B2 are ghost lists (keys only). `p` is the target
// size of T1 and adapts on ghost hits. Lists are parallel Vecs with the MRU
// at the FRONT; lookups are O(n) linear scans (documented ? this is a
// correctness-focused reference implementation; the compiler's Vec lacks a
// map container for struct elements). Int keys/values.
//
// NOTE: all list operations are inlined on the &mut ArcCache struct ? helper
// fns taking `&mut Vec[Int]` params get a fresh-alloca COPY for non-ident
// args (`&mut c.t1k`), so their push/pop/shift mutations would be lost
// (COMPILER_BUGS.md BUG 16).
// ============================================================================

pub type ArcCache = {
  capacity: Int;
  p: Int;
  t1k: Vec[Int];
  t1v: Vec[Int];
  t2k: Vec[Int];
  t2v: Vec[Int];
  b1: Vec[Int];
  b2: Vec[Int];
}

fn _find_idx(keys: &Vec[Int], key: Int) -> Int {
  var i: Int = 0;
  while i < keys.len() {
    if keys[i] == key {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// Move keys[idx]/vals[idx] to the front (recency), shifting the rest right.
fn _move_to_front(c: &mut ArcCache, list: Int, idx: Int) {
  var k = c.t1k[idx];
  var v = c.t1v[idx];
  if list == 1 {
    k = c.t2k[idx];
    v = c.t2v[idx];
  }
  var i = idx;
  while i > 0 {
    c.t1k[i] = c.t1k[i - 1];
    c.t1v[i] = c.t1v[i - 1];
    i = i - 1;
  }
  if list == 0 {
    c.t1k[0] = k;
    c.t1v[0] = v;
  } else {
    c.t2k[0] = k;
    c.t2v[0] = v;
  }
}

fn _push_front(c: &mut ArcCache, list: Int, key: Int, value: Int) {
  // snapshot → clear → key → restore (Vec append-shift cannot front-insert)
  var tmpk = Vec[Int].new();
  var tmpv = Vec[Int].new();
  var i: Int = 0;
  if list == 0 {
    while i < c.t1k.len() {
      tmpk.push(c.t1k[i]);
      tmpv.push(c.t1v[i]);
      i = i + 1;
    }
    while c.t1k.len() > 0 {
      c.t1k.pop();
    }
    while c.t1v.len() > 0 {
      c.t1v.pop();
    }
    c.t1k.push(key);
    c.t1v.push(value);
    i = 0;
    while i < tmpk.len() {
      c.t1k.push(tmpk[i]);
      c.t1v.push(tmpv[i]);
      i = i + 1;
    }
  } else {
    while i < c.t2k.len() {
      tmpk.push(c.t2k[i]);
      tmpv.push(c.t2v[i]);
      i = i + 1;
    }
    while c.t2k.len() > 0 {
      c.t2k.pop();
    }
    while c.t2v.len() > 0 {
      c.t2v.pop();
    }
    c.t2k.push(key);
    c.t2v.push(value);
    i = 0;
    while i < tmpk.len() {
      c.t2k.push(tmpk[i]);
      c.t2v.push(tmpv[i]);
      i = i + 1;
    }
  }
}

fn _remove_at(c: &mut ArcCache, list: Int, idx: Int) {
  var i = idx;
  if list == 0 {
    while i + 1 < c.t1k.len() {
      c.t1k[i] = c.t1k[i + 1];
      c.t1v[i] = c.t1v[i + 1];
      i = i + 1;
    }
    c.t1k.pop();
    c.t1v.pop();
  } else {
    while i + 1 < c.t2k.len() {
      c.t2k[i] = c.t2k[i + 1];
      c.t2v[i] = c.t2v[i + 1];
      i = i + 1;
    }
    c.t2k.pop();
    c.t2v.pop();
  }
}

// Ghost lists are key-only; same push-front/remove/back-pop semantics.
fn _ghost_push(c: &mut ArcCache, ghost: Int, key: Int) {
  // remove existing occurrence first
  var glen: Int = 0;
  if ghost == 0 {
    glen = c.b1.len();
  } else {
    glen = c.b2.len();
  }
  var i: Int = 0;
  while i < glen {
    var gk: Int = 0;
    if ghost == 0 {
      gk = c.b1[i];
    } else {
      gk = c.b2[i];
    }
    if gk == key {
      var j = i;
      if ghost == 0 {
        while j + 1 < c.b1.len() {
          c.b1[j] = c.b1[j + 1];
          j = j + 1;
        }
        c.b1.pop();
      } else {
        while j + 1 < c.b2.len() {
          c.b2[j] = c.b2[j + 1];
          j = j + 1;
        }
        c.b2.pop();
      }
      break;
    }
    i = i + 1;
  }
  // snapshot → clear → key → restore
  var tmp = Vec[Int].new();
  i = 0;
  if ghost == 0 {
    while i < c.b1.len() {
      tmp.push(c.b1[i]);
      i = i + 1;
    }
    while c.b1.len() > 0 {
      c.b1.pop();
    }
    c.b1.push(key);
    i = 0;
    while i < tmp.len() {
      c.b1.push(tmp[i]);
      i = i + 1;
    }
  } else {
    while i < c.b2.len() {
      tmp.push(c.b2[i]);
      i = i + 1;
    }
    while c.b2.len() > 0 {
      c.b2.pop();
    }
    c.b2.push(key);
    i = 0;
    while i < tmp.len() {
      c.b2.push(tmp[i]);
      i = i + 1;
    }
  }
}

fn _ghost_pop_back(c: &mut ArcCache, ghost: Int) {
  if ghost == 0 {
    if c.b1.len() > 0 {
      c.b1.pop();
    }
  } else {
    if c.b2.len() > 0 {
      c.b2.pop();
    }
  }
}

/// Create an ARC cache with `capacity` entries (>= 1).
pub fn arc_new(capacity: Int) -> ArcCache {
  var c = capacity;
  if c < 1 { c = 1; }
  return ArcCache{
    capacity: c;
    p: 0;
    t1k: Vec[Int].new();
    t1v: Vec[Int].new();
    t2k: Vec[Int].new();
    t2v: Vec[Int].new();
    b1: Vec[Int].new();
    b2: Vec[Int].new();
  };
}

/// Value for `key` (promotes recent→frequent on hit). None on miss.
pub fn arc_get(c: &mut ArcCache, key: Int) -> Option[Int] {
  var i1 = _find_idx(&c.t1k, key);
  if i1 >= 0 {
    _move_to_front(c, 0, i1);
    return Option[Int]{ is_some: true; value: c.t1v[0]; };
  }
  var i2 = _find_idx(&c.t2k, key);
  if i2 >= 0 {
    _move_to_front(c, 1, i2);
    return Option[Int]{ is_some: true; value: c.t2v[0]; };
  }
  return Option[Int]{ is_some: false; value: 0; };
}

/// True if `key` is cached (does not change recency).
pub fn arc_contains(c: &ArcCache, key: Int) -> Bool {
  return _find_idx(&c.t1k, key) >= 0 || _find_idx(&c.t2k, key) >= 0;
}

/// Number of cached entries.
pub fn arc_size(c: &ArcCache) -> Int {
  return c.t1k.len() + c.t2k.len();
}

/// Capacity.
pub fn arc_capacity(c: &ArcCache) -> Int {
  return c.capacity;
}

// Replace per the ARC rules (evicts LRU of T1 into B1, or T2 into B2).
fn _arc_replace(c: &mut ArcCache) {
  if c.t1k.len() > 0 && (c.t1k.len() > c.p || (c.b2.len() > 0 && c.t1k.len() == c.p)) {
    var lru = c.t1k[c.t1k.len() - 1];
    c.t1k.pop();
    c.t1v.pop();
    _ghost_push(c, 0, lru);
  } elif c.t2k.len() > 0 {
    var lru2 = c.t2k[c.t2k.len() - 1];
    c.t2k.pop();
    c.t2v.pop();
    _ghost_push(c, 1, lru2);
  } else {
    var lru3 = c.t1k[c.t1k.len() - 1];
    c.t1k.pop();
    c.t1v.pop();
    _ghost_push(c, 0, lru3);
  }
}

/// Insert or update `key` → `value`, adapting p on ghost hits.
pub fn arc_put(c: &mut ArcCache, key: Int, value: Int) {
  var i1 = _find_idx(&c.t1k, key);
  if i1 >= 0 {
    c.t1v[i1] = value;
    _move_to_front(c, 0, i1);
    return;
  }
  var i2 = _find_idx(&c.t2k, key);
  if i2 >= 0 {
    c.t2v[i2] = value;
    _move_to_front(c, 1, i2);
    return;
  }
  var in_b1 = _find_idx(&c.b1, key);
  if in_b1 >= 0 {
    var delta: Int = 1;
    if c.b2.len() > 0 && c.b2.len() > c.b1.len() {
      delta = c.b2.len() / c.b1.len();
      if delta < 1 { delta = 1; }
    }
    c.p = c.p + delta;
    if c.p > c.capacity { c.p = c.capacity; }
    _ghost_pop_back(c, 0);
    _arc_replace(c);
    _push_front(c, 0, key, value);
    return;
  }
  var in_b2 = _find_idx(&c.b2, key);
  if in_b2 >= 0 {
    var delta2: Int = 1;
    if c.b1.len() > 0 && c.b1.len() > c.b2.len() {
      delta2 = c.b1.len() / c.b2.len();
      if delta2 < 1 { delta2 = 1; }
    }
    c.p = c.p - delta2;
    if c.p < 0 { c.p = 0; }
    _ghost_pop_back(c, 1);
    _arc_replace(c);
    _push_front(c, 1, key, value);
    return;
  }
  if c.t1k.len() + c.b1.len() == c.capacity {
    if c.t1k.len() < c.capacity {
      _ghost_pop_back(c, 0);
      _arc_replace(c);
    } else {
      c.t1k.pop();
      c.t1v.pop();
      _ghost_pop_back(c, 0);
    }
  } elif c.t1k.len() + c.t2k.len() + c.b1.len() + c.b2.len() >= c.capacity {
    if c.t1k.len() + c.t2k.len() + c.b1.len() + c.b2.len() == 2 * c.capacity {
      _ghost_pop_back(c, 1);
    }
    _arc_replace(c);
  }
  _push_front(c, 0, key, value);
}

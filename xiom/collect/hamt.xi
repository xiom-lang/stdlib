// XIOM - Collections: Hash Array Mapped Trie
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.hamt

// Depends on: none (pure)

// ============================================================================
// Hash array mapped trie (Int keys, Int values). A space-efficient persistent
// map built on a trie of 32-way nodes using the hash of the key. Average
// O(log_32 n) operations with fast structural sharing and cache locality.
// Duplicate keys are rejected by insert.
//
// Flat-arena style (the established collect/ pattern -- tree.xi/graph.xi use
// parallel Vec[Int]s because Vec-of-struct instantiations collide at startup
// in combined programs). Every node owns 32 child slots in the flat `kids`
// vector (`kids[i * 32 + slot]`), so table nodes and leaf nodes share one
// uniform layout. Leaf nodes additionally carry the key, the value and the
// full 64-bit hash of the key; `is_leaf[i]` distinguishes the two kinds.
// The 5-bit window of the key hash at depth d selects the child slot, so a
// path is at most 13 nodes deep (64 hash bits / 5 bits). Node 0 is always a
// table node (the root).
// ============================================================================

pub type Hamt = {
  root: Int;
  size: Int;
  keys: Vec[Int];
  values: Vec[Int];
  hashes: Vec[Int];
  is_leaf: Vec[Bool];
  kids: Vec[Int];
}

// SplitMix64-style finalizer: mixes a 64-bit key into a well-distributed
// 64-bit hash. Uses wrapping 64-bit arithmetic (Int is 64-bit signed).
fn _hash(key: Int) -> Int {
  var z = key + 0x9E3779B97F4A7C15;
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EB;
  z = z ^ (z >> 31);
  return z;
}

// Child slot of `hash` at depth `level` (5 bits per level).
fn _slot(hash: Int, level: Int) -> Int {
  var shift = 5 * level;
  var v = hash >> shift;
  var s = v & 31;
  return s;
}

fn _kid_at(h: &Hamt, node: Int, slot: Int) -> Int {
  return h.kids[node * 32 + slot];
}

fn _set_kid(h: &mut Hamt, node: Int, slot: Int, child: Int) {
  h.kids[node * 32 + slot] = child;
}

// Append a table node (no key payload) and return its index.
fn _add_table(h: &mut Hamt) -> Int {
  h.keys.push(0);
  h.values.push(0);
  h.hashes.push(0);
  h.is_leaf.push(false);
  var id = h.is_leaf.len() - 1;
  var i: Int = 0;
  while i < 32 {
    h.kids.push(-1);
    i = i + 1;
  }
  return id;
}

// Append a leaf node carrying key/value and return its index.
fn _add_leaf(h: &mut Hamt, key: Int, value: Int) -> Int {
  var hval = _hash(key);
  h.keys.push(key);
  h.values.push(value);
  h.hashes.push(hval);
  h.is_leaf.push(true);
  var id = h.is_leaf.len() - 1;
  var i: Int = 0;
  while i < 32 {
    h.kids.push(-1);
    i = i + 1;
  }
  return id;
}

/// Create an empty HAMT (a single empty root table node).
/// Returns a fresh Hamt with size 0.
/// O(1) time, O(1) memory.
pub fn hamt_new() -> Hamt {
  var h = Hamt{ root: -1; size: 0; keys: Vec[Int].new(); values: Vec[Int].new(); hashes: Vec[Int].new(); is_leaf: Vec[Bool].new(); kids: Vec[Int].new(); };
  var root = _add_table(&mut h);
  h.root = root;
  return h;
}

/// Insert `key` -> `value`. Returns false if the key already exists
/// (the map keeps the original value). True on a fresh insert.
/// O(log_32 n) expected.
pub fn hamt_insert(h: &mut Hamt, key: Int, value: Int) -> Bool {
  var hval = _hash(key);
  var node = h.root;
  var parent = -1;
  var pslot = 0;
  var level = 0;
  loop {
    if h.is_leaf[node] {
      if h.hashes[node] == hval && h.keys[node] == key {
        return false;
      }
      var table = _add_table(h);
      var slot_leaf = _slot(h.hashes[node], level);
      var slot_new = _slot(hval, level);
      _set_kid(h, table, slot_leaf, node);
      if parent == -1 {
        h.root = table;
      } else {
        _set_kid(h, parent, pslot, table);
      }
      if slot_leaf == slot_new {
        parent = table;
        pslot = slot_leaf;
        level = level + 1;
        continue;
      }
      _set_kid(h, table, slot_new, _add_leaf(h, key, value));
      h.size = h.size + 1;
      return true;
    }
    var slot = _slot(hval, level);
    var child = _kid_at(h, node, slot);
    if child == -1 {
      _set_kid(h, node, slot, _add_leaf(h, key, value));
      h.size = h.size + 1;
      return true;
    }
    parent = node;
    pslot = slot;
    node = child;
    level = level + 1;
  }
}

/// Leaf node index for `key`, or -1 if the key is absent.
fn _find_leaf(h: &Hamt, key: Int) -> Int {
  var hval = _hash(key);
  var node = h.root;
  var level = 0;
  loop {
    if h.is_leaf[node] {
      if h.hashes[node] == hval && h.keys[node] == key {
        return node;
      }
      return -1;
    }
    var slot = _slot(hval, level);
    var child = _kid_at(h, node, slot);
    if child == -1 {
      return -1;
    }
    node = child;
    level = level + 1;
  }
}

/// Value stored for `key`, or None if the key is absent.
/// O(log_32 n) expected.
pub fn hamt_get(h: &Hamt, key: Int) -> Option[Int] {
  var leaf = _find_leaf(h, key);
  if leaf == -1 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  return Option[Int]{ is_some: true; value: h.values[leaf]; };
}

/// True if `key` is present in the map.
/// O(log_32 n) expected.
pub fn hamt_contains(h: &Hamt, key: Int) -> Bool {
  return _find_leaf(h, key) != -1;
}

/// Remove `key`. Returns true if it was present.
/// O(log_32 n) expected.
pub fn hamt_remove(h: &mut Hamt, key: Int) -> Bool {
  var hval = _hash(key);
  var node = h.root;
  var parent = -1;
  var pslot = 0;
  var level = 0;
  loop {
    if h.is_leaf[node] {
      if h.hashes[node] == hval && h.keys[node] == key {
        if parent != -1 {
          _set_kid(h, parent, pslot, -1);
        }
        h.size = h.size - 1;
        return true;
      }
      return false;
    }
    var slot = _slot(hval, level);
    var child = _kid_at(h, node, slot);
    if child == -1 {
      return false;
    }
    parent = node;
    pslot = slot;
    node = child;
    level = level + 1;
  }
}

/// Number of key/value pairs in the map.
/// O(1).
pub fn hamt_size(h: &Hamt) -> Int
  ensures: result >= 0
{
  return h.size;
}

/// Remove all entries, leaving the map empty.
/// O(1) (arena memory is retained).
pub fn hamt_clear(h: &mut Hamt)
  ensures: hamt_size(h) == 0
{
  var fresh = hamt_new();
  h.root = fresh.root;
  h.size = 0;
  h.keys = fresh.keys;
  h.values = fresh.values;
  h.hashes = fresh.hashes;
  h.is_leaf = fresh.is_leaf;
  h.kids = fresh.kids;
}

// XIOM -- Collections: SkipList (ordered map, probabilistic)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.skiplist

// TODO(compiler): combining this module with collect.trie in one program
// fast-fails at exit (0xC0000409) -- see docs/COMPILER_BUGS.md BUG 16.
// The modules are correct individually; keep them in separate smokes.


// ============================================================================
// SkipList (Int keys)
// Flat-arena style (the established collect/ pattern -- tree.xi/graph.xi use
// parallel Vec[Int]s because Vec-of-struct instantiations collide at startup
// in combined programs, COMPILER_BUGS.md BUG 16). `keys[i]` is the key of
// node i; the successor of node i at level L is nexts[i * MAX_LEVEL + L]
// (-1 = none); `head` is the header node. Insert uses a deterministic LCG
// for the level (p = 1/2). O(log n) expected; duplicates rejected.
// ============================================================================

const MAX_LEVEL: Int = 16;

pub type SkipList = { head: Int; keys: Vec[Int]; nexts: Vec[Int]; size: Int; rng: Int; }

fn _lcg(s: Int) -> Int {
  return s * 6364136223846793005 + 1442695040888963407;
}

// Random level in 0..MAX_LEVEL-1 with p = 1/2 (deterministic per rng state).
fn _rand_level(r: &mut SkipList) -> Int {
  var level: Int = 0;
  r.rng = _lcg(r.rng);
  var v = r.rng;
  while level < MAX_LEVEL - 1 && (v & 1) == 0 {
    level = level + 1;
    v = v >> 1;
  }
  return level;
}

fn _slot(node: Int, level: Int) -> Int {
  return node * MAX_LEVEL + level;
}

fn _key_at(l: &SkipList, node: Int) -> Int {
  return l.keys[node];
}

fn _next_at(l: &SkipList, node: Int, level: Int) -> Int {
  return l.nexts[_slot(node, level)];
}

// Lower-bound search: update[i] = rightmost node at level i with key < key;
// node = the node whose key >= key, or -1.
type SkipSearch = { node: Int; update: Vec[Int]; }
fn _search(l: &SkipList, key: Int) -> SkipSearch {
  var update = Vec[Int].new();
  var x = l.head;
  var i: Int = MAX_LEVEL - 1;
  while i >= 0 {
    while x != -1 {
      var nxt = _next_at(l, x, i);
      if nxt != -1 {
        if _key_at(l, nxt) < key {
          x = nxt;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    while update.len() <= i {
      update.push(0);
    }
    update[i] = x;
    i = i - 1;
  }
  var node_idx: Int = -1;
  if x != -1 {
    node_idx = _next_at(l, x, 0);
  }
  return SkipSearch{ node: node_idx; update: update; };
}

// Append a new node with all -1 levels; returns its index.
fn _add_node(l: &mut SkipList, key: Int) -> Int {
  l.keys.push(key);
  var idx = l.keys.len() - 1;
  var i: Int = 0;
  while i < MAX_LEVEL {
    l.nexts.push(-1);
    i = i + 1;
  }
  return idx;
}

/// Create an empty skip list (header node with key INT_MIN).
pub fn skiplist_new() -> SkipList {
  var keys = Vec[Int].new();
  var nexts = Vec[Int].new();
  keys.push(-9223372036854775807);
  var i: Int = 0;
  while i < MAX_LEVEL {
    nexts.push(-1);
    i = i + 1;
  }
  return SkipList{ head: 0; keys: keys; nexts: nexts; size: 0; rng: 0x9E3779B97F4A7C15; };
}

/// Insert `key`. Returns false if the key already exists.
pub fn skiplist_insert(l: &mut SkipList, key: Int) -> Bool {
  var found = _search(l, key);
  if found.node != -1 && _key_at(l, found.node) == key {
    return false;
  }
  var level = _rand_level(l);
  var node_idx = _add_node(l, key);
  var i: Int = 0;
  while i <= level {
    var prev = found.update[i];
    var old_next: Int = -1;
    if prev != -1 {
      old_next = _next_at(l, prev, i);
      l.nexts[_slot(prev, i)] = node_idx;
    }
    l.nexts[_slot(node_idx, i)] = old_next;
    i = i + 1;
  }
  l.size = l.size + 1;
  return true;
}

/// True if `key` is present.
pub fn skiplist_contains(l: &SkipList, key: Int) -> Bool {
  var found = _search(l, key);
  if found.node == -1 {
    return false;
  }
  return _key_at(l, found.node) == key;
}

/// Remove `key`. Returns true if it was present.
pub fn skiplist_remove(l: &mut SkipList, key: Int) -> Bool {
  var found = _search(l, key);
  if found.node == -1 || _key_at(l, found.node) != key {
    return false;
  }
  var target = found.node;
  var i: Int = 0;
  while i < MAX_LEVEL {
    var prev = found.update[i];
    if prev != -1 && _next_at(l, prev, i) == target {
      l.nexts[_slot(prev, i)] = _next_at(l, target, i);
    }
    i = i + 1;
  }
  l.size = l.size - 1;
  return true;
}

/// Number of keys.
pub fn skiplist_size(l: &SkipList) -> Int
  ensures: result >= 0
{
  return l.size;
}

/// Smallest key (None if empty).
pub fn skiplist_min(l: &SkipList) -> Option[Int] {
  if l.size == 0 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  var x = _next_at(l, l.head, 0);
  return Option[Int]{ is_some: true; value: _key_at(l, x); };
}

/// Largest key (None if empty).
pub fn skiplist_max(l: &SkipList) -> Option[Int] {
  if l.size == 0 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  var x = _next_at(l, l.head, 0);
  while x != -1 {
    var nxt = _next_at(l, x, 0);
    if nxt == -1 {
      break;
    }
    x = nxt;
  }
  return Option[Int]{ is_some: true; value: _key_at(l, x); };
}



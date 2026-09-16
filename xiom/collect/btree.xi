// XIOM - Collections: B-Tree
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.btree

// Depends on: none

// ============================================================================
// B-tree ordered map of Int keys to Int values with a configurable order.
// `order` is the maximum number of children per node (clamped to >= 2); a
// node holds at most order-1 keys. Flat-arena representation: every node is
// `mk = order-1` key/value slots and `mk+1` child slots in parallel Vec[Int]s,
// with a per-node key count and a leaf flag. Inserts pre-split full nodes on
// the way down (CLRS), so insert/update is O(log n). `btree_remove` collects
// the surviving entries and rebuilds the tree, keeping it perfectly balanced
// (no underflow; O(n), documented). Removed nodes become unreachable arena
// entries.
// ============================================================================

pub type BTree = {
  root: Int;
  mk: Int;
  nkeys: Vec[Int];
  keys: Vec[Int];
  vals: Vec[Int];
  childs: Vec[Int];
  leafs: Vec[Int];
  size: Int;
}

/// Append a fresh node with `mk` key/value slots and `mk+1` child slots.
fn btree_new_node(t: &mut BTree, is_leaf: Int) -> Int {
  var mk = t.mk;
  var i: Int = 0;
  while i < mk {
    t.keys.push(0);
    t.vals.push(0);
    i = i + 1;
  }
  i = 0;
  while i <= mk {
    t.childs.push(-1);
    i = i + 1;
  }
  t.nkeys.push(0);
  t.leafs.push(is_leaf);
  return t.nkeys.len() - 1;
}

/// Create an empty B-tree with the given order. The root is allocated lazily
/// on the first insert. O(1).
pub fn btree_new(order: Int) -> BTree {
  var ord = order;
  if ord < 2 { ord = 2; }
  return BTree{
    root: -1;
    mk: ord - 1;
    nkeys: Vec[Int].new();
    keys: Vec[Int].new();
    vals: Vec[Int].new();
    childs: Vec[Int].new();
    leafs: Vec[Int].new();
    size: 0;
  };
}

/// Node index that holds `key`, or -1 when absent. O(log n).
fn btree_search(t: &BTree, key: Int) -> Int {
  var cur = t.root;
  var mk = t.mk;
  while cur != -1 {
    var nk = t.nkeys[cur];
    var kb = cur * mk;
    var cb = cur * (mk + 1);
    var i: Int = 0;
    var found: Int = -1;
    while i < nk {
      if t.keys[kb + i] == key { found = cur; break; }
      i = i + 1;
    }
    if found != -1 { return found; }
    if t.leafs[cur] == 1 { return -1; }
    i = 0;
    while i < nk {
      if key < t.keys[kb + i] { break; }
      i = i + 1;
    }
    cur = t.childs[cb + i];
  }
  return -1;
}

/// Value for `key`, or None when absent. O(log n).
pub fn btree_get(t: &BTree, key: Int) -> Option[Int] {
  var node = btree_search(t, key);
  if node == -1 { return None; }
  var mk = t.mk;
  var kb = node * mk;
  var i: Int = 0;
  var nk = t.nkeys[node];
  while i < nk {
    if t.keys[kb + i] == key {
      return Some(t.vals[kb + i]);
    }
    i = i + 1;
  }
  return None;
}

/// True if `key` is present. O(log n).
pub fn btree_contains(t: &BTree, key: Int) -> Bool {
  return btree_search(t, key) != -1;
}

/// Split the full `child` of `parent` (child holds `mk` keys). The median key
/// is promoted into `parent` at `slot`; the right half moves to a new sibling
/// linked at `slot + 1`.
fn btree_split_child(t: &mut BTree, parent: Int, child: Int, slot: Int) {
  var mk = t.mk;
  var m = (mk - 1) / 2;
  var leaf = t.leafs[child];
  var child_nk = t.nkeys[child];
  var sib = btree_new_node(t, leaf);
  var ck = child * mk;
  var ck2 = sib * mk;
  var cc = child * (mk + 1);
  var cc2 = sib * (mk + 1);
  var moved = child_nk - m - 1;
  var j: Int = 0;
  while j < moved {
    t.keys[ck2 + j] = t.keys[ck + m + 1 + j];
    t.vals[ck2 + j] = t.vals[ck + m + 1 + j];
    j = j + 1;
  }
  if leaf == 0 {
    j = 0;
    while j <= moved {
      t.childs[cc2 + j] = t.childs[cc + m + 1 + j];
      j = j + 1;
    }
  }
  t.nkeys[sib] = moved;
  t.nkeys[child] = m;
  var pk = parent * mk;
  var pc = parent * (mk + 1);
  var pnk = t.nkeys[parent];
  j = pnk;
  while j > slot {
    t.keys[pk + j] = t.keys[pk + j - 1];
    t.vals[pk + j] = t.vals[pk + j - 1];
    t.childs[pc + j + 1] = t.childs[pc + j];
    j = j - 1;
  }
  var median_key = t.keys[ck + m];
  var median_val = t.vals[ck + m];
  t.keys[pk + slot] = median_key;
  t.vals[pk + slot] = median_val;
  t.childs[pc + slot + 1] = sib;
  t.nkeys[parent] = pnk + 1;
}

/// Split a full root: a new internal root takes the old root as child 0.
fn btree_split_root(t: &mut BTree) {
  var mk = t.mk;
  var old_root = t.root;
  var nr = btree_new_node(t, 0);
  t.childs[nr * (mk + 1)] = old_root;
  t.root = nr;
  btree_split_child(t, nr, old_root, 0);
}

/// Insert into a subtree whose root is guaranteed non-full. Updates the
/// value when the key already exists.
fn btree_insert_nonfull(t: &mut BTree, node: Int, key: Int, value: Int) {
  var mk = t.mk;
  var nk = t.nkeys[node];
  var kb = node * mk;
  var cb = node * (mk + 1);
  var i: Int = 0;
  while i < nk {
    var k = t.keys[kb + i];
    if key == k {
      t.vals[kb + i] = value;
      return;
    }
    if key < k { break; }
    i = i + 1;
  }
  if t.leafs[node] == 1 {
    var j = nk;
    while j > i {
      t.keys[kb + j] = t.keys[kb + j - 1];
      t.vals[kb + j] = t.vals[kb + j - 1];
      j = j - 1;
    }
    t.keys[kb + i] = key;
    t.vals[kb + i] = value;
    t.nkeys[node] = nk + 1;
    t.size = t.size + 1;
    return;
  }
  var child = t.childs[cb + i];
  var child_nk = t.nkeys[child];
  if child_nk == mk {
    btree_split_child(t, node, child, i);
    var kb2 = node * mk;
    var split_key = t.keys[kb2 + i];
    if key > split_key {
      i = i + 1;
    }
    child = t.childs[node * (mk + 1) + i];
  }
  btree_insert_nonfull(t, child, key, value);
}

/// Insert or update `key` -> `value`. O(log n).
pub fn btree_insert(t: &mut BTree, key: Int, value: Int) {
  if t.root == -1 {
    t.root = btree_new_node(t, 1);
  }
  var mk = t.mk;
  var root_nk = t.nkeys[t.root];
  if root_nk == mk {
    btree_split_root(t);
  }
  btree_insert_nonfull(t, t.root, key, value);
}

/// Number of entries. O(1).
pub fn btree_size(t: &BTree) -> Int
  ensures: result >= 0
{
  return t.size;
}

/// Append all live (key, value) pairs of the subtree in sorted order.
fn btree_collect_at(t: &BTree, node: Int, ks: &mut Vec[Int], vs: &mut Vec[Int]) {
  var mk = t.mk;
  var nk = t.nkeys[node];
  var kb = node * mk;
  var cb = node * (mk + 1);
  var i: Int = 0;
  if t.leafs[node] == 1 {
    while i < nk {
      ks.push(t.keys[kb + i]);
      vs.push(t.vals[kb + i]);
      i = i + 1;
    }
    return;
  }
  while i < nk {
    btree_collect_at(t, t.childs[cb + i], ks, vs);
    ks.push(t.keys[kb + i]);
    vs.push(t.vals[kb + i]);
    i = i + 1;
  }
  btree_collect_at(t, t.childs[cb + nk], ks, vs);
}

/// Rebuild the tree from scratch without `key` (used by `btree_remove` so the
/// result is always a perfectly balanced B-tree, never an underflowed one).
fn btree_rebuild_without(t: &mut BTree, key: Int) {
  var ks = Vec[Int].new();
  var vs = Vec[Int].new();
  btree_collect_at(t, t.root, &mut ks, &mut vs);
  t.nkeys = Vec[Int].new();
  t.keys = Vec[Int].new();
  t.vals = Vec[Int].new();
  t.childs = Vec[Int].new();
  t.leafs = Vec[Int].new();
  t.root = btree_new_node(t, 1);
  t.size = 0;
  var i: Int = 0;
  while i < ks.len() {
    if ks[i] != key {
      btree_insert(t, ks[i], vs[i]);
    }
    i = i + 1;
  }
}

/// Remove `key`; returns true if it was present. O(n) worst case (the tree is
/// rebuilt so it stays perfectly balanced).
pub fn btree_remove(t: &mut BTree, key: Int) -> Bool {
  if !btree_contains(t, key) { return false; }
  btree_rebuild_without(t, key);
  return true;
}

/// Smallest key, or None when the tree is empty. O(log n).
pub fn btree_min(t: &BTree) -> Option[Int] {
  if t.size == 0 { return None; }
  var mk = t.mk;
  var cur = t.root;
  while t.leafs[cur] == 0 {
    cur = t.childs[cur * (mk + 1)];
  }
  var kb = cur * mk;
  return Some(t.keys[kb]);
}

/// Largest key, or None when the tree is empty. O(log n).
pub fn btree_max(t: &BTree) -> Option[Int] {
  if t.size == 0 { return None; }
  var mk = t.mk;
  var cur = t.root;
  while t.leafs[cur] == 0 {
    var nk = t.nkeys[cur];
    cur = t.childs[cur * (mk + 1) + nk];
  }
  var kb = cur * mk;
  var last = t.nkeys[cur] - 1;
  return Some(t.keys[kb + last]);
}

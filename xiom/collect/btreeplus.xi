// XIOM - Collections: B+ Tree
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.btreeplus

// Depends on: none

// ============================================================================
// B+ tree ordered map of Int keys to Int values, leaves linked for fast
// range scans. All data lives in leaves; internal nodes hold routing keys
// and child pointers only. `order` is the maximum number of children per
// internal node (clamped to >= 2); every node holds at most `mk = order-1`
// keys. Flat-arena representation: per-node blocks of `mk` key/value slots
// and `mk+1` child slots in parallel Vec[Int]s, with per-node key counts,
// leaf flags and a `nexts` leaf chain. Inserts pre-split full nodes on the
// way down (O(log n)). Removals delete lazily from the leaf (routing keys
// stay valid as range separators; empty leaves remain traversable), so
// `bptree_range` walks the leaf chain in O(log n + m). Removed nodes become
// unreachable arena entries.
// ============================================================================

pub type BPlusTree = {
  root: Int;
  mk: Int;
  nkeys: Vec[Int];
  keys: Vec[Int];
  vals: Vec[Int];
  childs: Vec[Int];
  leafs: Vec[Int];
  nexts: Vec[Int];
  size: Int;
}

fn bp_new_node(t: &mut BPlusTree, is_leaf: Int) -> Int {
  var i: Int = 0;
  while i < t.mk {
    t.keys.push(0);
    t.vals.push(0);
    i = i + 1;
  }
  i = 0;
  while i <= t.mk {
    t.childs.push(-1);
    i = i + 1;
  }
  t.nkeys.push(0);
  t.leafs.push(is_leaf);
  t.nexts.push(-1);
  return t.nkeys.len() - 1;
}

/// Create an empty B+ tree with the given order. The root is allocated
/// lazily on the first insert. O(1).
pub fn bptree_new(order: Int) -> BPlusTree
  ensures: result.root == -1
  ensures: result.size == 0
  ensures: result.mk >= 1
{
  var ord = order;
  if ord < 2 { ord = 2; }
  return BPlusTree{
    root: -1;
    mk: ord - 1;
    nkeys: Vec[Int].new();
    keys: Vec[Int].new();
    vals: Vec[Int].new();
    childs: Vec[Int].new();
    leafs: Vec[Int].new();
    nexts: Vec[Int].new();
    size: 0;
  };
}

/// Split a full leaf `child` of `parent` at `slot`. The right half moves to a
/// new sibling (linked into the leaf chain); `keys[mid]` is promoted into
/// `parent` and stays as the first key of the right leaf.
fn bp_split_leaf_child(t: &mut BPlusTree, parent: Int, child: Int, slot: Int) {
  var mid = t.mk / 2;
  var sib = bp_new_node(t, 1);
  var ck = child * t.mk;
  var ck2 = sib * t.mk;
  var moved = t.mk - mid;
  var j: Int = 0;
  while j < moved {
    t.keys[ck2 + j] = t.keys[ck + mid + j];
    t.vals[ck2 + j] = t.vals[ck + mid + j];
    j = j + 1;
  }
  t.nkeys[sib] = moved;
  t.nkeys[child] = mid;
  t.nexts[sib] = t.nexts[child];
  t.nexts[child] = sib;
  var pk = parent * t.mk;
  var pc = parent * (t.mk + 1);
  var pnk = t.nkeys[parent];
  j = pnk;
  while j > slot {
    t.keys[pk + j] = t.keys[pk + j - 1];
    t.childs[pc + j + 1] = t.childs[pc + j];
    j = j - 1;
  }
  t.keys[pk + slot] = t.keys[ck + mid];
  t.childs[pc + slot + 1] = sib;
  t.nkeys[parent] = pnk + 1;
}

/// Split a full internal `child` of `parent` at `slot`. The median key is
/// promoted into `parent` (acting as a pure separator); the right half
/// (keys and children) moves to a new sibling.
fn bp_split_internal_child(t: &mut BPlusTree, parent: Int, child: Int, slot: Int) {
  var mid = t.mk / 2;
  var sib = bp_new_node(t, 0);
  var ck = child * t.mk;
  var ck2 = sib * t.mk;
  var cc = child * (t.mk + 1);
  var cc2 = sib * (t.mk + 1);
  var moved = t.mk - mid - 1;
  var j: Int = 0;
  while j < moved {
    t.keys[ck2 + j] = t.keys[ck + mid + 1 + j];
    j = j + 1;
  }
  j = 0;
  while j <= moved {
    t.childs[cc2 + j] = t.childs[cc + mid + 1 + j];
    j = j + 1;
  }
  t.nkeys[sib] = moved;
  t.nkeys[child] = mid;
  var pk = parent * t.mk;
  var pc = parent * (t.mk + 1);
  var pnk = t.nkeys[parent];
  j = pnk;
  while j > slot {
    t.keys[pk + j] = t.keys[pk + j - 1];
    t.childs[pc + j + 1] = t.childs[pc + j];
    j = j - 1;
  }
  t.keys[pk + slot] = t.keys[ck + mid];
  t.childs[pc + slot + 1] = sib;
  t.nkeys[parent] = pnk + 1;
}

/// Split a full root: a new internal root takes the old root as child 0 and
/// splits it (leaf or internal) into two.
fn bp_split_root(t: &mut BPlusTree) {
  var old_root = t.root;
  var nr = bp_new_node(t, 0);
  t.childs[nr * (t.mk + 1)] = old_root;
  t.root = nr;
  if t.leafs[old_root] == 1 {
    bp_split_leaf_child(t, nr, old_root, 0);
  } else {
    bp_split_internal_child(t, nr, old_root, 0);
  }
}

/// Insert into a subtree whose root is guaranteed non-full. Updates the value
/// when the key already exists.
fn bp_insert_nonfull(t: &mut BPlusTree, node: Int, key: Int, value: Int) {
  if t.leafs[node] == 1 {
    var nk = t.nkeys[node];
    var kb = node * t.mk;
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
  var nk2 = t.nkeys[node];
  var kb2 = node * t.mk;
  var cb = node * (t.mk + 1);
  var i2: Int = 0;
  while i2 < nk2 && key >= t.keys[kb2 + i2] {
    i2 = i2 + 1;
  }
  var child = t.childs[cb + i2];
  if t.nkeys[child] == t.mk {
    if t.leafs[child] == 1 {
      bp_split_leaf_child(t, node, child, i2);
    } else {
      bp_split_internal_child(t, node, child, i2);
    }
    var split_key = t.keys[node * t.mk + i2];
    if key >= split_key {
      i2 = i2 + 1;
    }
    child = t.childs[node * (t.mk + 1) + i2];
  }
  bp_insert_nonfull(t, child, key, value);
}

/// Insert or update `key` -> `value`. O(log n).
pub fn bptree_insert(t: &mut BPlusTree, key: Int, value: Int)
  ensures: bptree_contains(t, key)
{
  if t.root == -1 {
    t.root = bp_new_node(t, 1);
  }
  if t.nkeys[t.root] == t.mk {
    bp_split_root(t);
  }
  bp_insert_nonfull(t, t.root, key, value);
}

/// Leaf whose range may contain `key` (standard B+ descent), or -1 when the
/// tree is empty. O(log n).
fn bp_find_leaf(t: &BPlusTree, key: Int) -> Int {
  if t.root == -1 { return -1; }
  var cur = t.root;
  while t.leafs[cur] == 0 {
    var nk = t.nkeys[cur];
    var kb = cur * t.mk;
    var cb = cur * (t.mk + 1);
    var i: Int = 0;
    while i < nk && key >= t.keys[kb + i] {
      i = i + 1;
    }
    cur = t.childs[cb + i];
  }
  return cur;
}

/// Value for `key`, or None when absent. O(log n).
pub fn bptree_get(t: &BPlusTree, key: Int) -> Option[Int]
  ensures: result is Some => bptree_contains(t, key)
  ensures: result is None => bptree_contains(t, key) == false
{
  var leaf = bp_find_leaf(t, key);
  if leaf == -1 { return None; }
  var nk = t.nkeys[leaf];
  var kb = leaf * t.mk;
  var i: Int = 0;
  while i < nk {
    var k = t.keys[kb + i];
    if k == key {
      return Some(t.vals[kb + i]);
    }
    if k > key { return None; }
    i = i + 1;
  }
  return None;
}

/// True if `key` is present. O(log n).
pub fn bptree_contains(t: &BPlusTree, key: Int) -> Bool
  ensures: result == true => bptree_size(t) >= 1
{
  var leaf = bp_find_leaf(t, key);
  if leaf == -1 { return false; }
  var nk = t.nkeys[leaf];
  var kb = leaf * t.mk;
  var i: Int = 0;
  while i < nk {
    var k = t.keys[kb + i];
    if k == key { return true; }
    if k > key { return false; }
    i = i + 1;
  }
  return false;
}

/// Remove `key`; returns true if it was present. The key is removed from its
/// leaf (lazy deletion); routing keys stay valid as separators. O(log n).
pub fn bptree_remove(t: &mut BPlusTree, key: Int) -> Bool
  ensures: bptree_contains(t, key) == false
{
  var leaf = bp_find_leaf(t, key);
  if leaf == -1 { return false; }
  var nk = t.nkeys[leaf];
  var kb = leaf * t.mk;
  var i: Int = 0;
  while i < nk {
    var k = t.keys[kb + i];
    if k == key { break; }
    if k > key { return false; }
    i = i + 1;
  }
  if i >= nk { return false; }
  var j = i;
  while j + 1 < nk {
    t.keys[kb + j] = t.keys[kb + j + 1];
    t.vals[kb + j] = t.vals[kb + j + 1];
    j = j + 1;
  }
  t.nkeys[leaf] = nk - 1;
  t.size = t.size - 1;
  return true;
}

/// Number of entries. O(1).
pub fn bptree_size(t: &BPlusTree) -> Int
  ensures: result >= 0
{
  return t.size;
}

/// Values of keys in the inclusive range [l, r], in ascending key order,
/// collected by walking the linked leaf chain. O(log n + m).
pub fn bptree_range(t: &BPlusTree, l: Int, r: Int) -> Vec[Int]
  ensures: result.len() <= bptree_size(t)
  ensures: r < l => result.len() == 0
{
  var out = Vec[Int].new();
  if t.size == 0 { return out; }
  var cur = bp_find_leaf(t, l);
  var done = false;
  while cur != -1 && !done {
    var nk = t.nkeys[cur];
    var kb = cur * t.mk;
    var i: Int = 0;
    while i < nk {
      var k = t.keys[kb + i];
      if k >= l {
        if k <= r {
          out.push(t.vals[kb + i]);
        } else {
          done = true;
          break;
        }
      }
      i = i + 1;
    }
    cur = t.nexts[cur];
  }
  return out;
}

// XIOM - Collections: Ordered Tree Map
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.treemap

// Depends on: none

/// Balanced binary search tree map keeping Int keys in sorted order.
/// The balance policy is AVL (the proven collect.tree pattern) so put/get/
/// contains/remove run in O(log n). Flat-arena representation: nodes live in
/// parallel Vec[Int]s (`keys`/`values`/`left`/`right`/`heights`) addressed by
/// a root index; -1 is the "no node" sentinel. `treemap_iter` returns
/// (key, value) pairs in ascending key order. Removed nodes become
/// unreachable arena entries.
pub type BTreeMap = {
  root: Int;
  keys: Vec[Int];
  values: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  heights: Vec[Int];
  size: Int;
}

/// Create a new empty tree map. O(1).
pub fn treemap_new() -> BTreeMap {
  return BTreeMap{
    root: -1;
    keys: Vec[Int].new(); values: Vec[Int].new();
    left: Vec[Int].new(); right: Vec[Int].new();
    heights: Vec[Int].new(); size: 0;
  };
}

fn tm_new_node(m: &mut BTreeMap, key: Int, value: Int) -> Int {
  m.keys.push(key);
  m.values.push(value);
  m.left.push(-1);
  m.right.push(-1);
  m.heights.push(1);
  return m.keys.len() - 1;
}

fn tm_height_node(m: &BTreeMap, idx: Int) -> Int {
  if idx == -1 { return 0; }
  return m.heights[idx];
}

fn tm_update_height(m: &mut BTreeMap, idx: Int) {
  var lh = tm_height_node(m, m.left[idx]);
  var rh = tm_height_node(m, m.right[idx]);
  if lh > rh {
    m.heights[idx] = 1 + lh;
  } else {
    m.heights[idx] = 1 + rh;
  }
}

fn tm_rotate_right(m: &mut BTreeMap, x: Int) -> Int {
  var y = m.left[x];
  var b = m.right[y];
  m.right[y] = x;
  m.left[x] = b;
  tm_update_height(m, x);
  tm_update_height(m, y);
  return y;
}

fn tm_rotate_left(m: &mut BTreeMap, x: Int) -> Int {
  var y = m.right[x];
  var b = m.left[y];
  m.left[y] = x;
  m.right[x] = b;
  tm_update_height(m, x);
  tm_update_height(m, y);
  return y;
}

fn tm_balance(m: &mut BTreeMap, idx: Int) -> Int {
  if idx == -1 { return -1; }
  var lh = tm_height_node(m, m.left[idx]);
  var rh = tm_height_node(m, m.right[idx]);
  var bf = lh - rh;
  if bf > 1 {
    var lc = m.left[idx];
    var llh = tm_height_node(m, m.left[lc]);
    var lrh = tm_height_node(m, m.right[lc]);
    if llh < lrh {
      m.left[idx] = tm_rotate_left(m, lc);
    }
    return tm_rotate_right(m, idx);
  }
  if bf < -1 {
    var rc = m.right[idx];
    var rlh = tm_height_node(m, m.left[rc]);
    var rrh = tm_height_node(m, m.right[rc]);
    if rrh < rlh {
      m.right[idx] = tm_rotate_right(m, rc);
    }
    return tm_rotate_left(m, idx);
  }
  tm_update_height(m, idx);
  return idx;
}

fn tm_put_at(m: &mut BTreeMap, idx: Int, key: Int, value: Int) -> Int {
  if idx == -1 {
    return tm_new_node(m, key, value);
  }
  var k = m.keys[idx];
  if key < k {
    m.left[idx] = tm_put_at(m, m.left[idx], key, value);
  } elif key > k {
    m.right[idx] = tm_put_at(m, m.right[idx], key, value);
  } else {
    m.values[idx] = value;
    return idx;
  }
  return tm_balance(m, idx);
}

/// Insert or update `key` -> `value`. O(log n).
pub fn treemap_put(m: &mut BTreeMap, key: Int, value: Int) {
  var old_nodes = m.keys.len();
  m.root = tm_put_at(m, m.root, key, value);
  if m.keys.len() > old_nodes {
    m.size = m.size + 1;
  }
}

/// Value for `key`, or None when absent. O(log n).
pub fn treemap_get(m: &BTreeMap, key: Int) -> Option[Int] {
  var cur = m.root;
  while cur != -1 {
    var k = m.keys[cur];
    if key == k { return Some(m.values[cur]); }
    if key < k {
      cur = m.left[cur];
    } else {
      cur = m.right[cur];
    }
  }
  return None;
}

/// True if `key` is present. O(log n).
pub fn treemap_contains(m: &BTreeMap, key: Int) -> Bool {
  var cur = m.root;
  while cur != -1 {
    var k = m.keys[cur];
    if key == k { return true; }
    if key < k {
      cur = m.left[cur];
    } else {
      cur = m.right[cur];
    }
  }
  return false;
}

fn tm_remove_at(m: &mut BTreeMap, idx: Int, key: Int) -> Int {
  if idx == -1 { return -1; }
  var k = m.keys[idx];
  if key < k {
    m.left[idx] = tm_remove_at(m, m.left[idx], key);
  } elif key > k {
    m.right[idx] = tm_remove_at(m, m.right[idx], key);
  } else {
    var l = m.left[idx];
    var r = m.right[idx];
    if l == -1 { return r; }
    if r == -1 { return l; }
    var succ = r;
    while m.left[succ] != -1 {
      succ = m.left[succ];
    }
    m.keys[idx] = m.keys[succ];
    m.values[idx] = m.values[succ];
    m.right[idx] = tm_remove_at(m, m.right[idx], m.keys[idx]);
    return tm_balance(m, idx);
  }
  return tm_balance(m, idx);
}

/// Remove `key`; returns true if it was present. O(log n).
pub fn treemap_remove(m: &mut BTreeMap, key: Int) -> Bool {
  if !treemap_contains(m, key) { return false; }
  m.root = tm_remove_at(m, m.root, key);
  m.size = m.size - 1;
  return true;
}

/// Number of entries. O(1).
pub fn treemap_size(m: &BTreeMap) -> Int
  ensures: result >= 0
{
  return m.size;
}

/// Smallest key, or None when the map is empty. O(log n).
pub fn treemap_min(m: &BTreeMap) -> Option[Int] {
  if m.root == -1 { return None; }
  var cur = m.root;
  while m.left[cur] != -1 {
    cur = m.left[cur];
  }
  return Some(m.keys[cur]);
}

/// Largest key, or None when the map is empty. O(log n).
pub fn treemap_max(m: &BTreeMap) -> Option[Int] {
  if m.root == -1 { return None; }
  var cur = m.root;
  while m.right[cur] != -1 {
    cur = m.right[cur];
  }
  return Some(m.keys[cur]);
}

fn tm_walk(m: &BTreeMap, node: Int, out: &mut Vec[(Int, Int)]) {
  if node == -1 { return; }
  tm_walk(m, m.left[node], out);
  out.push((m.keys[node], m.values[node]));
  tm_walk(m, m.right[node], out);
}

/// All entries as (key, value) pairs in ascending key order. O(n).
pub fn treemap_iter(m: &BTreeMap) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  tm_walk(m, m.root, &mut out);
  return out;
}

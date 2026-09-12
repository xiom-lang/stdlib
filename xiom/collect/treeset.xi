// XIOM - Collections: Ordered Tree Set
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.treeset

// Depends on: none

// ============================================================================
// Balanced binary search tree set keeping Int elements in sorted order.
// The balance policy is AVL (the proven collect.tree pattern) so insert/
// contains/remove run in O(log n). Flat-arena representation: nodes live in
// parallel Vec[Int]s (`keys`/`left`/`right`/`heights`) addressed by a root
// index; -1 is the "no node" sentinel. Removed nodes become unreachable
// arena entries.
// ============================================================================

pub type BTreeSet = {
  root: Int;
  keys: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  heights: Vec[Int];
  size: Int;
}

/// Create a new empty tree set. O(1).
pub fn treeset_new() -> BTreeSet {
  return BTreeSet{
    root: -1;
    keys: Vec[Int].new(); left: Vec[Int].new();
    right: Vec[Int].new(); heights: Vec[Int].new();
    size: 0;
  };
}

fn ts_new_node(s: &mut BTreeSet, value: Int) -> Int {
  s.keys.push(value);
  s.left.push(-1);
  s.right.push(-1);
  s.heights.push(1);
  return s.keys.len() - 1;
}

fn ts_height_node(s: &BTreeSet, idx: Int) -> Int {
  if idx == -1 { return 0; }
  return s.heights[idx];
}

fn ts_update_height(s: &mut BTreeSet, idx: Int) {
  var lh = ts_height_node(s, s.left[idx]);
  var rh = ts_height_node(s, s.right[idx]);
  if lh > rh {
    s.heights[idx] = 1 + lh;
  } else {
    s.heights[idx] = 1 + rh;
  }
}

fn ts_rotate_right(s: &mut BTreeSet, x: Int) -> Int {
  var y = s.left[x];
  var b = s.right[y];
  s.right[y] = x;
  s.left[x] = b;
  ts_update_height(s, x);
  ts_update_height(s, y);
  return y;
}

fn ts_rotate_left(s: &mut BTreeSet, x: Int) -> Int {
  var y = s.right[x];
  var b = s.left[y];
  s.left[y] = x;
  s.right[x] = b;
  ts_update_height(s, x);
  ts_update_height(s, y);
  return y;
}

fn ts_balance(s: &mut BTreeSet, idx: Int) -> Int {
  if idx == -1 { return -1; }
  var lh = ts_height_node(s, s.left[idx]);
  var rh = ts_height_node(s, s.right[idx]);
  var bf = lh - rh;
  if bf > 1 {
    var lc = s.left[idx];
    var llh = ts_height_node(s, s.left[lc]);
    var lrh = ts_height_node(s, s.right[lc]);
    if llh < lrh {
      s.left[idx] = ts_rotate_left(s, lc);
    }
    return ts_rotate_right(s, idx);
  }
  if bf < -1 {
    var rc = s.right[idx];
    var rlh = ts_height_node(s, s.left[rc]);
    var rrh = ts_height_node(s, s.right[rc]);
    if rrh < rlh {
      s.right[idx] = ts_rotate_right(s, rc);
    }
    return ts_rotate_left(s, idx);
  }
  ts_update_height(s, idx);
  return idx;
}

fn ts_insert_at(s: &mut BTreeSet, idx: Int, value: Int) -> Int {
  if idx == -1 {
    return ts_new_node(s, value);
  }
  var k = s.keys[idx];
  if value < k {
    s.left[idx] = ts_insert_at(s, s.left[idx], value);
  } elif value > k {
    s.right[idx] = ts_insert_at(s, s.right[idx], value);
  } else {
    return idx;
  }
  return ts_balance(s, idx);
}

/// Insert `value`; returns true if it was newly added, false if it was
/// already present. O(log n).
pub fn treeset_insert(s: &mut BTreeSet, value: Int) -> Bool {
  if treeset_contains(s, value) { return false; }
  s.root = ts_insert_at(s, s.root, value);
  s.size = s.size + 1;
  return true;
}

/// True if `value` is present. O(log n).
pub fn treeset_contains(s: &BTreeSet, value: Int) -> Bool {
  var cur = s.root;
  while cur != -1 {
    var k = s.keys[cur];
    if value == k { return true; }
    if value < k {
      cur = s.left[cur];
    } else {
      cur = s.right[cur];
    }
  }
  return false;
}

fn ts_remove_at(s: &mut BTreeSet, idx: Int, value: Int) -> Int {
  if idx == -1 { return -1; }
  var k = s.keys[idx];
  if value < k {
    s.left[idx] = ts_remove_at(s, s.left[idx], value);
  } elif value > k {
    s.right[idx] = ts_remove_at(s, s.right[idx], value);
  } else {
    var l = s.left[idx];
    var r = s.right[idx];
    if l == -1 { return r; }
    if r == -1 { return l; }
    var succ = r;
    while s.left[succ] != -1 {
      succ = s.left[succ];
    }
    s.keys[idx] = s.keys[succ];
    s.right[idx] = ts_remove_at(s, s.right[idx], s.keys[idx]);
    return ts_balance(s, idx);
  }
  return ts_balance(s, idx);
}

/// Remove `value`; returns true if it was present. O(log n).
pub fn treeset_remove(s: &mut BTreeSet, value: Int) -> Bool {
  if !treeset_contains(s, value) { return false; }
  s.root = ts_remove_at(s, s.root, value);
  s.size = s.size - 1;
  return true;
}

/// Number of elements. O(1).
pub fn treeset_size(s: &BTreeSet) -> Int
  ensures: result >= 0
{
  return s.size;
}

/// Smallest element, or None when the set is empty. O(log n).
pub fn treeset_min(s: &BTreeSet) -> Option[Int] {
  if s.root == -1 { return None; }
  var cur = s.root;
  while s.left[cur] != -1 {
    cur = s.left[cur];
  }
  return Some(s.keys[cur]);
}

/// Largest element, or None when the set is empty. O(log n).
pub fn treeset_max(s: &BTreeSet) -> Option[Int] {
  if s.root == -1 { return None; }
  var cur = s.root;
  while s.right[cur] != -1 {
    cur = s.right[cur];
  }
  return Some(s.keys[cur]);
}

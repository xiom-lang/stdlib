// XIOM - Collections: AVL Tree
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.avl

// Depends on: none

// ============================================================================
// Self-balancing AVL tree of unique Int elements.
// Flat-arena representation (the established collect/ pattern, shared with
// collect.tree): nodes live in parallel Vec[Int]s addressed by a root index;
// -1 is the "no node" sentinel. `heights[i]` holds the height of node i
// (leaf = 1, empty subtree = 0); every insert/remove rebalances via
// single/double rotations so |balance factor| <= 1 holds on every node.
// Removed nodes become unreachable arena entries.
// ============================================================================

pub type Avl = {
  root: Int;
  keys: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  heights: Vec[Int];
}

/// Create a new empty AVL tree. O(1).
pub fn avl_new() -> Avl {
  return Avl{ root: -1; keys: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); heights: Vec[Int].new(); };
}

fn avl_new_node(a: &mut Avl, value: Int) -> Int {
  a.keys.push(value);
  a.left.push(-1);
  a.right.push(-1);
  a.heights.push(1);
  return a.keys.len() - 1;
}

fn avl_height_node(a: &Avl, idx: Int) -> Int {
  if idx == -1 { return 0; }
  return a.heights[idx];
}

fn avl_update_height(a: &mut Avl, idx: Int) {
  var lh = avl_height_node(a, a.left[idx]);
  var rh = avl_height_node(a, a.right[idx]);
  if lh > rh {
    a.heights[idx] = 1 + lh;
  } else {
    a.heights[idx] = 1 + rh;
  }
}

fn avl_rotate_right(a: &mut Avl, x: Int) -> Int {
  var y = a.left[x];
  var b = a.right[y];
  a.right[y] = x;
  a.left[x] = b;
  avl_update_height(a, x);
  avl_update_height(a, y);
  return y;
}

fn avl_rotate_left(a: &mut Avl, x: Int) -> Int {
  var y = a.right[x];
  var b = a.left[y];
  a.left[y] = x;
  a.right[x] = b;
  avl_update_height(a, x);
  avl_update_height(a, y);
  return y;
}

/// Rebalance the subtree rooted at `idx` and return the (possibly new) root.
fn avl_balance(a: &mut Avl, idx: Int) -> Int {
  if idx == -1 { return -1; }
  var lh = avl_height_node(a, a.left[idx]);
  var rh = avl_height_node(a, a.right[idx]);
  var bf = lh - rh;
  if bf > 1 {
    var lc = a.left[idx];
    var llh = avl_height_node(a, a.left[lc]);
    var lrh = avl_height_node(a, a.right[lc]);
    if llh < lrh {
      a.left[idx] = avl_rotate_left(a, lc);
    }
    return avl_rotate_right(a, idx);
  }
  if bf < -1 {
    var rc = a.right[idx];
    var rlh = avl_height_node(a, a.left[rc]);
    var rrh = avl_height_node(a, a.right[rc]);
    if rrh < rlh {
      a.right[idx] = avl_rotate_right(a, rc);
    }
    return avl_rotate_left(a, idx);
  }
  avl_update_height(a, idx);
  return idx;
}

fn avl_insert_at(a: &mut Avl, idx: Int, value: Int) -> Int {
  if idx == -1 {
    return avl_new_node(a, value);
  }
  var k = a.keys[idx];
  if value < k {
    a.left[idx] = avl_insert_at(a, a.left[idx], value);
  } elif value > k {
    a.right[idx] = avl_insert_at(a, a.right[idx], value);
  } else {
    return idx;
  }
  return avl_balance(a, idx);
}

/// Insert `value`, rebalancing as needed. Duplicates are ignored. O(log n).
pub fn avl_insert(t: &mut Avl, value: Int) {
  t.root = avl_insert_at(t, t.root, value);
}

/// True if `value` is present. O(log n).
pub fn avl_contains(t: &Avl, value: Int) -> Bool {
  var cur = t.root;
  while cur != -1 {
    var k = t.keys[cur];
    if value == k { return true; }
    if value < k {
      cur = t.left[cur];
    } else {
      cur = t.right[cur];
    }
  }
  return false;
}

fn avl_remove_at(a: &mut Avl, idx: Int, value: Int) -> Int {
  if idx == -1 { return -1; }
  var k = a.keys[idx];
  if value < k {
    a.left[idx] = avl_remove_at(a, a.left[idx], value);
  } elif value > k {
    a.right[idx] = avl_remove_at(a, a.right[idx], value);
  } else {
    var l = a.left[idx];
    var r = a.right[idx];
    if l == -1 { return r; }
    if r == -1 { return l; }
    // two children: replace with the in-order successor (min of the right
    // subtree) and delete the successor from the right subtree.
    var succ = r;
    while a.left[succ] != -1 {
      succ = a.left[succ];
    }
    a.keys[idx] = a.keys[succ];
    a.right[idx] = avl_remove_at(a, a.right[idx], a.keys[idx]);
    return avl_balance(a, idx);
  }
  return avl_balance(a, idx);
}

/// Remove `value`, rebalancing as needed. Missing values are a no-op.
/// O(log n).
pub fn avl_remove(t: &mut Avl, value: Int) {
  t.root = avl_remove_at(t, t.root, value);
}

/// Smallest value, or None if the tree is empty. O(log n).
pub fn avl_min(t: &Avl) -> Option[Int] {
  if t.root == -1 { return None; }
  var cur = t.root;
  while t.left[cur] != -1 {
    cur = t.left[cur];
  }
  return Some(t.keys[cur]);
}

/// Largest value, or None if the tree is empty. O(log n).
pub fn avl_max(t: &Avl) -> Option[Int] {
  if t.root == -1 { return None; }
  var cur = t.root;
  while t.right[cur] != -1 {
    cur = t.right[cur];
  }
  return Some(t.keys[cur]);
}

/// Height of the tree; an empty tree has height 0. O(1).
pub fn avl_height(t: &Avl) -> Int {
  return avl_height_node(t, t.root);
}

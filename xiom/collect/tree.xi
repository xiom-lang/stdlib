// XIOM -- Tree Collection (BST + AVL)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.tree

// ============================================================================
// Binary Search Tree (Int keys)
// Arena representation: nodes live in parallel Vec[Int]s, addressed by a
// root index. The sentinel index -1 denotes "no node". Removed nodes become
// unreachable arena entries; all queries traverse the reachable tree.
// ============================================================================

pub type Bst = {
  root: Int;
  keys: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
}

/// Create an empty BST.
pub fn bst_new() -> Bst {
  return Bst{ root: -1; keys: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); };
}

fn bst_new_node(b: &mut Bst, key: Int) -> Int {
  b.keys.push(key);
  b.left.push(-1);
  b.right.push(-1);
  return b.keys.len() - 1;
}

/// Insert a key. Duplicates are ignored.
pub fn bst_insert(b: &mut Bst, key: Int) {
  if b.root == -1 {
    b.root = bst_new_node(b, key);
    return;
  }
  var cur = b.root;
  loop {
    var k = b.keys[cur];
    if key < k {
      var l = b.left[cur];
      if l == -1 {
        b.left[cur] = bst_new_node(b, key);
        return;
      }
      cur = l;
    } elif key > k {
      var r = b.right[cur];
      if r == -1 {
        b.right[cur] = bst_new_node(b, key);
        return;
      }
      cur = r;
    } else {
      return;
    }
  }
}

/// Returns true if the key is present.
pub fn bst_contains(b: &Bst, key: Int) -> Bool {
  var cur = b.root;
  while cur != -1 {
    var k = b.keys[cur];
    if key == k { return true; }
    if key < k {
      cur = b.left[cur];
    } else {
      cur = b.right[cur];
    }
  }
  return false;
}

/// Remove a key. Two-child nodes are replaced by their in-order successor.
/// Returns true if the key was found and removed.
pub fn bst_remove(b: &mut Bst, key: Int) -> Bool {
  if b.root == -1 { return false; }
  var cur = b.root;
  var parent = -1;
  var is_left = false;
  loop {
    var k = b.keys[cur];
    if key == k { break; }
    parent = cur;
    if key < k {
      is_left = true;
      cur = b.left[cur];
    } else {
      is_left = false;
      cur = b.right[cur];
    }
    if cur == -1 { return false; }
  }
  var l = b.left[cur];
  var r = b.right[cur];
  if l == -1 && r == -1 {
    if parent == -1 {
      b.root = -1;
    } elif is_left {
      b.left[parent] = -1;
    } else {
      b.right[parent] = -1;
    }
  } elif l == -1 {
    if parent == -1 {
      b.root = r;
    } elif is_left {
      b.left[parent] = r;
    } else {
      b.right[parent] = r;
    }
  } elif r == -1 {
    if parent == -1 {
      b.root = l;
    } elif is_left {
      b.left[parent] = l;
    } else {
      b.right[parent] = l;
    }
  } else {
    var succ = b.right[cur];
    var succ_parent = cur;
    while b.left[succ] != -1 {
      succ_parent = succ;
      succ = b.left[succ];
    }
    b.keys[cur] = b.keys[succ];
    var succ_right = b.right[succ];
    if succ_parent == cur {
      b.right[cur] = succ_right;
    } else {
      b.left[succ_parent] = succ_right;
    }
  }
  return true;
}

/// Number of reachable nodes.
pub fn bst_size(b: &Bst) -> Int
  ensures: result >= 0
{
  var count = 0;
  var stack = Vec[Int].new();
  var cur = b.root;
  while cur != -1 || stack.len() > 0 {
    while cur != -1 {
      stack.push(cur);
      cur = b.left[cur];
    }
    var top_opt = stack.pop();
    match top_opt {
      Some(t) => { count = count + 1; cur = b.right[t]; },
      None => { cur = -1; },
    }
  }
  return count;
}

/// Minimum key, or None if the tree is empty.
pub fn bst_min(b: &Bst) -> Option[Int] {
  if b.root == -1 { return None; }
  var cur = b.root;
  while b.left[cur] != -1 {
    cur = b.left[cur];
  }
  return Some(b.keys[cur]);
}

/// Maximum key, or None if the tree is empty.
pub fn bst_max(b: &Bst) -> Option[Int] {
  if b.root == -1 { return None; }
  var cur = b.root;
  while b.right[cur] != -1 {
    cur = b.right[cur];
  }
  return Some(b.keys[cur]);
}

/// In-order traversal as a sorted vector.
pub fn bst_inorder(b: &Bst) -> Vec[Int] {
  var result = Vec[Int].new();
  var stack = Vec[Int].new();
  var cur = b.root;
  while cur != -1 || stack.len() > 0 {
    while cur != -1 {
      stack.push(cur);
      cur = b.left[cur];
    }
    var top_opt = stack.pop();
    match top_opt {
      Some(t) => { result.push(b.keys[t]); cur = b.right[t]; },
      None => { cur = -1; },
    }
  }
  return result;
}

fn bst_height_at(b: &Bst, idx: Int) -> Int {
  if idx == -1 { return 0; }
  var lh = bst_height_at(b, b.left[idx]);
  var rh = bst_height_at(b, b.right[idx]);
  if lh > rh { return 1 + lh; } else { return 1 + rh; }
}

/// Height of the tree; empty tree has height 0.
pub fn bst_height(b: &Bst) -> Int
  ensures: result >= 0
{
  return bst_height_at(b, b.root);
}

/// True if the in-order traversal is strictly sorted (a valid BST).
pub fn bst_is_bst(b: &Bst) -> Bool {
  var v = bst_inorder(b);
  var i = 1;
  while i < v.len() {
    if v[i - 1] >= v[i] { return false; }
    i = i + 1;
  }
  return true;
}

// ============================================================================
// AVL Tree (Int keys)
// Same arena layout as the BST plus a parallel `heights` vector. Node height:
// leaf = 1, empty subtree = 0. Every insert rebalances via single/double
// rotations so |bf| <= 1 holds on every node.
// ============================================================================

pub type Avl = {
  root: Int;
  keys: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  heights: Vec[Int];
}

/// Create an empty AVL tree.
pub fn avl_new() -> Avl {
  return Avl{ root: -1; keys: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); heights: Vec[Int].new(); };
}

fn avl_new_node(a: &mut Avl, key: Int) -> Int {
  a.keys.push(key);
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

/// Rebalance the subtree rooted at `idx` after an insertion and return the
/// (possibly new) subtree root.
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

fn avl_insert_at(a: &mut Avl, idx: Int, key: Int) -> Int {
  if idx == -1 {
    return avl_new_node(a, key);
  }
  var k = a.keys[idx];
  if key < k {
    a.left[idx] = avl_insert_at(a, a.left[idx], key);
  } elif key > k {
    a.right[idx] = avl_insert_at(a, a.right[idx], key);
  } else {
    return idx;
  }
  return avl_balance(a, idx);
}

/// Insert a key. Duplicates are ignored.
pub fn avl_insert(a: &mut Avl, key: Int) {
  a.root = avl_insert_at(a, a.root, key);
}

/// Returns true if the key is present.
pub fn avl_contains(a: &Avl, key: Int) -> Bool {
  var cur = a.root;
  while cur != -1 {
    var k = a.keys[cur];
    if key == k { return true; }
    if key < k {
      cur = a.left[cur];
    } else {
      cur = a.right[cur];
    }
  }
  return false;
}

/// Number of nodes in the tree.
pub fn avl_size(a: &Avl) -> Int
  ensures: result >= 0
{
  return a.keys.len();
}

/// In-order traversal as a sorted vector.
pub fn avl_inorder(a: &Avl) -> Vec[Int] {
  var result = Vec[Int].new();
  var stack = Vec[Int].new();
  var cur = a.root;
  while cur != -1 || stack.len() > 0 {
    while cur != -1 {
      stack.push(cur);
      cur = a.left[cur];
    }
    var top_opt = stack.pop();
    match top_opt {
      Some(t) => { result.push(a.keys[t]); cur = a.right[t]; },
      None => { cur = -1; },
    }
  }
  return result;
}

/// Height of the tree; empty tree has height 0.
pub fn avl_height(a: &Avl) -> Int
  ensures: result >= 0
{
  return avl_height_node(a, a.root);
}

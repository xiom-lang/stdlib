// XIOM - Collections: Red-Black Tree
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.rbtree

// Depends on: none

// ============================================================================
// Red-black tree (Int keys, Int values). Self-balancing BST with a color bit
// per node (1 = red, 0 = black; null is black) that guarantees O(log n)
// insert, delete and lookup. Flat-arena representation (the established
// collect/ pattern): nodes live in parallel Vec[Int]s (`keys`/`values`/
// `left`/`right`/`parent`/`colors`) addressed by a root index; -1 is the
// "no node" sentinel. Duplicate keys are rejected; inorder/preorder/
// postorder return the keys. Removed nodes become unreachable arena entries.
// ============================================================================

pub type RbTree = {
  root: Int;
  keys: Vec[Int];
  values: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  parent: Vec[Int];
  colors: Vec[Int];
  size: Int;
}

/// Create an empty red-black tree. O(1).
pub fn rbtree_new() -> RbTree {
  return RbTree{
    root: -1;
    keys: Vec[Int].new(); values: Vec[Int].new();
    left: Vec[Int].new(); right: Vec[Int].new();
    parent: Vec[Int].new(); colors: Vec[Int].new();
    size: 0;
  };
}

fn rb_new_node(t: &mut RbTree, key: Int, value: Int) -> Int {
  t.keys.push(key);
  t.values.push(value);
  t.left.push(-1);
  t.right.push(-1);
  t.parent.push(-1);
  t.colors.push(1);
  return t.keys.len() - 1;
}

fn rb_is_red(t: &RbTree, n: Int) -> Bool {
  if n == -1 { return false; }
  return t.colors[n] == 1;
}

fn rb_find_node(t: &RbTree, key: Int) -> Int {
  var cur = t.root;
  while cur != -1 {
    var k = t.keys[cur];
    if key == k { return cur; }
    if key < k {
      cur = t.left[cur];
    } else {
      cur = t.right[cur];
    }
  }
  return -1;
}

fn rb_minimum(t: &RbTree, n: Int) -> Int {
  var cur = n;
  while t.left[cur] != -1 {
    cur = t.left[cur];
  }
  return cur;
}

fn rb_rotate_left(t: &mut RbTree, x: Int) {
  var y = t.right[x];
  t.right[x] = t.left[y];
  if t.left[y] != -1 {
    t.parent[t.left[y]] = x;
  }
  t.parent[y] = t.parent[x];
  if t.parent[x] == -1 {
    t.root = y;
  } elif x == t.left[t.parent[x]] {
    t.left[t.parent[x]] = y;
  } else {
    t.right[t.parent[x]] = y;
  }
  t.left[y] = x;
  t.parent[x] = y;
}

fn rb_rotate_right(t: &mut RbTree, x: Int) {
  var y = t.left[x];
  t.left[x] = t.right[y];
  if t.right[y] != -1 {
    t.parent[t.right[y]] = x;
  }
  t.parent[y] = t.parent[x];
  if t.parent[x] == -1 {
    t.root = y;
  } elif x == t.right[t.parent[x]] {
    t.right[t.parent[x]] = y;
  } else {
    t.left[t.parent[x]] = y;
  }
  t.right[y] = x;
  t.parent[x] = y;
}

/// CLRS RB-INSERT-FIXUP. Restores the five red-black invariants after an
/// insertion.
fn rb_insert_fixup(t: &mut RbTree, z: Int) {
  while rb_is_red(t, t.parent[z]) {
    var p = t.parent[z];
    var gp = t.parent[p];
    if p == t.left[gp] {
      var u = t.right[gp];
      if rb_is_red(t, u) {
        t.colors[p] = 0;
        t.colors[u] = 0;
        t.colors[gp] = 1;
        z = gp;
      } else {
        if z == t.right[p] {
          z = p;
          rb_rotate_left(t, z);
        }
        t.colors[t.parent[z]] = 0;
        t.colors[t.parent[t.parent[z]]] = 1;
        rb_rotate_right(t, t.parent[t.parent[z]]);
      }
    } else {
      var u = t.left[gp];
      if rb_is_red(t, u) {
        t.colors[p] = 0;
        t.colors[u] = 0;
        t.colors[gp] = 1;
        z = gp;
      } else {
        if z == t.left[p] {
          z = p;
          rb_rotate_right(t, z);
        }
        t.colors[t.parent[z]] = 0;
        t.colors[t.parent[t.parent[z]]] = 1;
        rb_rotate_left(t, t.parent[t.parent[z]]);
      }
    }
  }
  t.colors[t.root] = 0;
}

/// Insert `key` -> `value`; returns false if the key already exists.
/// O(log n).
pub fn rbtree_insert(t: &mut RbTree, key: Int, value: Int) -> Bool {
  if rb_find_node(t, key) != -1 { return false; }
  var z = rb_new_node(t, key, value);
  var y: Int = -1;
  var x = t.root;
  while x != -1 {
    y = x;
    if key < t.keys[x] {
      x = t.left[x];
    } else {
      x = t.right[x];
    }
  }
  t.parent[z] = y;
  if y == -1 {
    t.root = z;
  } elif key < t.keys[y] {
    t.left[y] = z;
  } else {
    t.right[y] = z;
  }
  rb_insert_fixup(t, z);
  t.size = t.size + 1;
  return true;
}

/// Value for `key`, or None if absent. O(log n).
pub fn rbtree_get(t: &RbTree, key: Int) -> Option[Int] {
  var n = rb_find_node(t, key);
  if n == -1 { return None; }
  return Some(t.values[n]);
}

/// True if `key` is present. O(log n).
pub fn rbtree_contains(t: &RbTree, key: Int) -> Bool {
  return rb_find_node(t, key) != -1;
}

/// Replace subtree at `u` with `v` in the parent linkage (no child fixups).
fn rb_transplant(t: &mut RbTree, u: Int, v: Int) {
  if t.parent[u] == -1 {
    t.root = v;
  } elif u == t.left[t.parent[u]] {
    t.left[t.parent[u]] = v;
  } else {
    t.right[t.parent[u]] = v;
  }
  if v != -1 {
    t.parent[v] = t.parent[u];
  }
}

/// CLRS RB-DELETE-FIXUP. Restores the red-black invariants after a deletion;
/// `x`/`xp` track the moved node and its parent (x may be the nil sentinel).
fn rb_delete_fixup(t: &mut RbTree, x: Int, xp: Int) {
  var node = x;
  var par = xp;
  while node != t.root && !rb_is_red(t, node) {
    if node == t.left[par] {
      var w = t.right[par];
      if rb_is_red(t, w) {
        t.colors[w] = 0;
        t.colors[par] = 1;
        rb_rotate_left(t, par);
        w = t.right[par];
      }
      var wl = t.left[w];
      var wr = t.right[w];
      if !rb_is_red(t, wl) && !rb_is_red(t, wr) {
        t.colors[w] = 1;
        node = par;
        par = t.parent[node];
      } else {
        if !rb_is_red(t, wr) {
          t.colors[wl] = 0;
          t.colors[w] = 1;
          rb_rotate_right(t, w);
          w = t.right[par];
        }
        t.colors[w] = t.colors[par];
        t.colors[par] = 0;
        t.colors[t.right[w]] = 0;
        rb_rotate_left(t, par);
        node = t.root;
        par = t.parent[node];
      }
    } else {
      var w = t.left[par];
      if rb_is_red(t, w) {
        t.colors[w] = 0;
        t.colors[par] = 1;
        rb_rotate_right(t, par);
        w = t.left[par];
      }
      var wl = t.left[w];
      var wr = t.right[w];
      if !rb_is_red(t, wl) && !rb_is_red(t, wr) {
        t.colors[w] = 1;
        node = par;
        par = t.parent[node];
      } else {
        if !rb_is_red(t, wl) {
          t.colors[wr] = 0;
          t.colors[w] = 1;
          rb_rotate_left(t, w);
          w = t.left[par];
        }
        t.colors[w] = t.colors[par];
        t.colors[par] = 0;
        t.colors[t.left[w]] = 0;
        rb_rotate_right(t, par);
        node = t.root;
        par = t.parent[node];
      }
    }
  }
  t.colors[node] = 0;
}

/// Remove `key`; returns true if it was present. O(log n).
pub fn rbtree_remove(t: &mut RbTree, key: Int) -> Bool {
  var z = rb_find_node(t, key);
  if z == -1 { return false; }
  var y = z;
  var y_orig_color = t.colors[y];
  var x: Int = -1;
  var xp: Int = -1;
  if t.left[z] == -1 {
    x = t.right[z];
    xp = t.parent[z];
    rb_transplant(t, z, t.right[z]);
  } elif t.right[z] == -1 {
    x = t.left[z];
    xp = t.parent[z];
    rb_transplant(t, z, t.left[z]);
  } else {
    y = rb_minimum(t, t.right[z]);
    y_orig_color = t.colors[y];
    x = t.right[y];
    if t.parent[y] == z {
      xp = y;
      if x != -1 {
        t.parent[x] = y;
      }
    } else {
      xp = t.parent[y];
      rb_transplant(t, y, t.right[y]);
      t.right[y] = t.right[z];
      if t.right[y] != -1 {
        t.parent[t.right[y]] = y;
      }
    }
    rb_transplant(t, z, y);
    t.left[y] = t.left[z];
    if t.left[y] != -1 {
      t.parent[t.left[y]] = y;
    }
    t.colors[y] = t.colors[z];
  }
  if y_orig_color == 0 {
    rb_delete_fixup(t, x, xp);
  }
  t.size = t.size - 1;
  return true;
}

/// Number of keys. O(1).
pub fn rbtree_size(t: &RbTree) -> Int
  ensures: result >= 0
{
  return t.size;
}

/// Smallest key, or None if the tree is empty. O(log n).
pub fn rbtree_min(t: &RbTree) -> Option[Int] {
  if t.root == -1 { return None; }
  return Some(t.keys[rb_minimum(t, t.root)]);
}

/// Largest key, or None if the tree is empty. O(log n).
pub fn rbtree_max(t: &RbTree) -> Option[Int] {
  if t.root == -1 { return None; }
  var cur = t.root;
  while t.right[cur] != -1 {
    cur = t.right[cur];
  }
  return Some(t.keys[cur]);
}

fn rb_walk_inorder(t: &RbTree, node: Int, out: &mut Vec[Int]) {
  if node == -1 { return; }
  rb_walk_inorder(t, t.left[node], out);
  out.push(t.keys[node]);
  rb_walk_inorder(t, t.right[node], out);
}

/// Keys in ascending order. O(n).
pub fn rbtree_inorder(t: &RbTree) -> Vec[Int] {
  var out = Vec[Int].new();
  rb_walk_inorder(t, t.root, &mut out);
  return out;
}

fn rb_walk_preorder(t: &RbTree, node: Int, out: &mut Vec[Int]) {
  if node == -1 { return; }
  out.push(t.keys[node]);
  rb_walk_preorder(t, t.left[node], out);
  rb_walk_preorder(t, t.right[node], out);
}

/// Keys in preorder (node, left, right). O(n).
pub fn rbtree_preorder(t: &RbTree) -> Vec[Int] {
  var out = Vec[Int].new();
  rb_walk_preorder(t, t.root, &mut out);
  return out;
}

fn rb_walk_postorder(t: &RbTree, node: Int, out: &mut Vec[Int]) {
  if node == -1 { return; }
  rb_walk_postorder(t, t.left[node], out);
  rb_walk_postorder(t, t.right[node], out);
  out.push(t.keys[node]);
}

/// Keys in postorder (left, right, node). O(n).
pub fn rbtree_postorder(t: &RbTree) -> Vec[Int] {
  var out = Vec[Int].new();
  rb_walk_postorder(t, t.root, &mut out);
  return out;
}

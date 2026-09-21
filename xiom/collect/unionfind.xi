// XIOM - Collections: Union-Find
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.unionfind

// Depends on: none

/// Disjoint-set (union-find) over Int element ids with path compression and
/// union by size.
/// 
/// Flat-arena style: `parent[i]` points at the parent of element i (a root
/// points at itself), `size[i]` is the component size valid at the roots, and
/// `count` tracks the number of disjoint sets. `uf_find` applies path
/// compression (both passes) and takes `&mut`; the immutable read-only
/// traversal `uf_find_no_compress` backs `uf_connected` / `uf_component_size`
/// / `uf_components` so they accept `&UnionFind`. Union by size keeps trees
/// shallow, giving ~O(alpha n) amortized operations. Out-of-range element ids
/// are rejected (no silent failure).
pub type UnionFind = {
  parent: Vec[Int];
  size: Vec[Int];
  count: Int;
}

/// Create a disjoint-set with `n` isolated elements (ids 0..n-1), each in its
/// own set of size 1. A negative `n` yields an empty structure.
/// O(n).
pub fn uf_new(n: Int) -> UnionFind {
  var parent = Vec[Int].new();
  var comp_size = Vec[Int].new();
  var i = 0;
  while i < n {
    parent.push(i);
    comp_size.push(1);
    i = i + 1;
  }
  return UnionFind{ parent: parent; size: comp_size; count: n; };
}

fn _find_no_compress(u: &UnionFind, x: Int) -> Int {
  if x < 0 || x >= u.parent.len() {
    return -1;
  }
  var cur = x;
  while u.parent[cur] != cur {
    cur = u.parent[cur];
  }
  return cur;
}

/// Return the representative (root) of the element `x`, applying path
/// compression. Returns -1 for an out-of-range element id.
/// O(alpha n) amortized.
pub fn uf_find(uf: &mut UnionFind, x: Int) -> Int
  ensures: x >= 0 && x < uf.parent.len() => result >= 0
{
  if x < 0 || x >= uf.parent.len() {
    return -1;
  }
  var root = x;
  while uf.parent[root] != root {
    root = uf.parent[root];
  }
  var cur = x;
  while uf.parent[cur] != root {
    var nxt = uf.parent[cur];
    uf.parent[cur] = root;
    cur = nxt;
  }
  return root;
}

/// Merge the sets containing `x` and `y` (union by size). Out-of-range ids are
/// ignored. The size of the merged set is tracked at the new root.
/// O(alpha n) amortized.
pub fn uf_union(uf: &mut UnionFind, x: Int, y: Int) {
  if x < 0 || x >= uf.parent.len() || y < 0 || y >= uf.parent.len() {
    return;
  }
  var rx = uf_find(uf, x);
  var ry = uf_find(uf, y);
  if rx == ry {
    return;
  }
  if uf.size[rx] < uf.size[ry] {
    uf.parent[rx] = ry;
    uf.size[ry] = uf.size[ry] + uf.size[rx];
  } else {
    uf.parent[ry] = rx;
    uf.size[rx] = uf.size[rx] + uf.size[ry];
  }
  uf.count = uf.count - 1;
}

/// Check whether `x` and `y` share a representative. Returns false for
/// out-of-range ids.
/// O(alpha n) amortized (read-only traversal).
pub fn uf_connected(uf: &UnionFind, x: Int, y: Int) -> Bool {
  if x < 0 || x >= uf.parent.len() || y < 0 || y >= uf.parent.len() {
    return false;
  }
  var rx = _find_no_compress(uf, x);
  var ry = _find_no_compress(uf, y);
  return rx == ry;
}

/// Size of the set containing `x` (number of elements in its component).
/// Returns 0 for an out-of-range id.
/// O(alpha n) amortized (read-only traversal).
pub fn uf_component_size(uf: &UnionFind, x: Int) -> Int
  ensures: result >= 0
{
  var root = _find_no_compress(uf, x);
  if root == -1 {
    return 0;
  }
  return uf.size[root];
}

/// Number of disjoint sets.
/// O(1).
pub fn uf_components(uf: &UnionFind) -> Int
  ensures: result >= 0
{
  return uf.count;
}

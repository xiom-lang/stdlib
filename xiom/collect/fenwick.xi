// XIOM -- Collections: Fenwick tree (binary indexed tree)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.fenwick

/// FenwickTree (1-based indices; n = number of slots)
/// Point update + prefix-sum queries in O(log n). `tree[i]` covers the range
/// (i - lowbit(i), i]. All index params are 1-based; 0 is invalid (returns 0).
pub type FenwickTree = { tree: Vec[Int]; n: Int; }

/// Create a fenwick tree with `n` slots, all zero.
pub fn fenwick_new(n: Int) -> FenwickTree
  ensures: result.n == n
  ensures: n >= 0 => result.tree.len() == n + 1
{
  var tree = Vec[Int].new();
  var i: Int = 0;
  while i <= n {
    tree.push(0);
    i = i + 1;
  }
  return FenwickTree{ tree: tree; n: n; };
}

/// Add `delta` to slot `idx` (1-based). O(log n).
pub fn fenwick_add(t: &mut FenwickTree, idx: Int, delta: Int)
  ensures: idx >= 1 && idx <= t.n && delta >= 0 => fenwick_sum(t, t.n) >= fenwick_sum(t, t.n)@pre
{
  if idx < 1 || idx > t.n {
    return;
  }
  var i = idx;
  while i <= t.n {
    t.tree[i] = t.tree[i] + delta;
    i = i + (i & (0 - i));
  }
}

/// Prefix sum of slots 1..=idx. O(log n). idx < 1 -> 0.
pub fn fenwick_sum(t: &FenwickTree, idx: Int) -> Int
  ensures: idx < 1 => result == 0
{
  var i = idx;
  var s: Int = 0;
  while i > 0 {
    s = s + t.tree[i];
    i = i - (i & (0 - i));
  }
  return s;
}

/// Sum of slots l..=r (1-based, inclusive). O(log n).
pub fn fenwick_range(t: &FenwickTree, l: Int, r: Int) -> Int
  ensures: r < l => result == 0
{
  if r < l {
    return 0;
  }
  return fenwick_sum(t, r) - fenwick_sum(t, l - 1);
}

/// Current value at slot `idx` (1-based). O(log n).
pub fn fenwick_get(t: &FenwickTree, idx: Int) -> Int
  ensures: idx < 1 || idx > t.n => result == 0
{
  if idx < 1 || idx > t.n {
    return 0;
  }
  return fenwick_range(t, idx, idx);
}

/// Number of slots.
pub fn fenwick_size(t: &FenwickTree) -> Int
  ensures: result >= 0
{
  return t.n;
}

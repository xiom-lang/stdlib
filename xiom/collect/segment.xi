// XIOM - Collections: Segment Tree
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.segment

// Depends on: none (pure)

/// Segment tree over an Int array (0-based indices). Builds in O(n), supports
/// point updates and range queries (sum, min, max) in O(log n). Indices are
/// inclusive; out-of-range queries return identity values (0 for sum,
/// INT_MAX for min, INT_MIN for max).
/// 
/// Flat-arena style. The tree is stored in three parallel Vec[Int]s of size
/// 4n (`sums`, `mins`, `maxs`) using the classic recursive heap layout: node
/// `k` covers [l, r] with children 2k+1 and 2k+2. Leaves hold a single slot,
/// internal nodes pull from their children. Out-of-range update indices are
/// rejected (no-op); out-of-range queries are clamped and return the identity
/// value when the clamped range is empty.
pub type SegTree = {
  n: Int;
  sums: Vec[Int];
  mins: Vec[Int];
  maxs: Vec[Int];
}

const _INT_MAX: Int = 9223372036854775807;
const _INT_MIN: Int = -9223372036854775808;

fn _pull(t: &mut SegTree, k: Int) {
  var l = 2 * k + 1;
  var r = 2 * k + 2;
  t.sums[k] = t.sums[l] + t.sums[r];
  var mn = t.mins[l];
  if t.mins[r] < mn {
    mn = t.mins[r];
  }
  t.mins[k] = mn;
  var mx = t.maxs[l];
  if t.maxs[r] > mx {
    mx = t.maxs[r];
  }
  t.maxs[k] = mx;
}

fn _build(t: &mut SegTree, k: Int, l: Int, r: Int, vals: &Vec[Int]) {
  if l == r {
    var v = vals[l];
    t.sums[k] = v;
    t.mins[k] = v;
    t.maxs[k] = v;
    return;
  }
  var mid = (l + r) / 2;
  _build(t, 2 * k + 1, l, mid, vals);
  _build(t, 2 * k + 2, mid + 1, r, vals);
  _pull(t, k);
}

fn _update(t: &mut SegTree, k: Int, l: Int, r: Int, idx: Int, value: Int) {
  if l == r {
    t.sums[k] = value;
    t.mins[k] = value;
    t.maxs[k] = value;
    return;
  }
  var mid = (l + r) / 2;
  if idx <= mid {
    _update(t, 2 * k + 1, l, mid, idx, value);
  } else {
    _update(t, 2 * k + 2, mid + 1, r, idx, value);
  }
  _pull(t, k);
}

fn _query_sum(t: &SegTree, k: Int, l: Int, r: Int, ql: Int, qr: Int) -> Int {
  if ql <= l && r <= qr {
    return t.sums[k];
  }
  var mid = (l + r) / 2;
  var total = 0;
  if ql <= mid {
    total = _query_sum(t, 2 * k + 1, l, mid, ql, qr);
  }
  if qr > mid {
    var right = _query_sum(t, 2 * k + 2, mid + 1, r, ql, qr);
    total = total + right;
  }
  return total;
}

fn _query_min(t: &SegTree, k: Int, l: Int, r: Int, ql: Int, qr: Int) -> Int {
  if ql <= l && r <= qr {
    return t.mins[k];
  }
  var mid = (l + r) / 2;
  var result = _INT_MAX;
  if ql <= mid {
    result = _query_min(t, 2 * k + 1, l, mid, ql, qr);
  }
  if qr > mid {
    var right = _query_min(t, 2 * k + 2, mid + 1, r, ql, qr);
    if right < result {
      result = right;
    }
  }
  return result;
}

fn _query_max(t: &SegTree, k: Int, l: Int, r: Int, ql: Int, qr: Int) -> Int {
  if ql <= l && r <= qr {
    return t.maxs[k];
  }
  var mid = (l + r) / 2;
  var result = _INT_MIN;
  if ql <= mid {
    result = _query_max(t, 2 * k + 1, l, mid, ql, qr);
  }
  if qr > mid {
    var right = _query_max(t, 2 * k + 2, mid + 1, r, ql, qr);
    if right > result {
      result = right;
    }
  }
  return result;
}

/// Create a segment tree over `n` zero slots. Out-of-range values clamp to 0.
/// O(n) time, O(4n) memory.
pub fn segtree_new(n: Int) -> SegTree {
  var nn = n;
  if nn < 0 {
    nn = 0;
  }
  var t = SegTree{ n: nn; sums: Vec[Int].new(); mins: Vec[Int].new(); maxs: Vec[Int].new(); };
  var cap = 4 * nn + 4;
  var i: Int = 0;
  while i < cap {
    t.sums.push(0);
    t.mins.push(_INT_MAX);
    t.maxs.push(_INT_MIN);
    i = i + 1;
  }
  return t;
}

/// Build internal nodes from the given values. The tree is resized to match
/// the values length (0-length input leaves the tree empty).
/// O(n).
pub fn segtree_build(t: &mut SegTree, values: &Vec[Int]) {
  var nn = values.len();
  t.n = nn;
  var cap = 4 * nn + 4;
  while t.sums.len() < cap {
    t.sums.push(0);
    t.mins.push(_INT_MAX);
    t.maxs.push(_INT_MIN);
  }
  while t.sums.len() > cap {
    t.sums.pop();
    t.mins.pop();
    t.maxs.pop();
  }
  if nn == 0 {
    return;
  }
  _build(t, 0, 0, nn - 1, values);
}

/// Set slot `idx` to `value`. Out-of-range indices are ignored.
/// O(log n).
pub fn segtree_update(t: &mut SegTree, idx: Int, value: Int) {
  if t.n == 0 {
    return;
  }
  if idx < 0 || idx >= t.n {
    return;
  }
  _update(t, 0, 0, t.n - 1, idx, value);
}

// Clamp [l, r] to the valid range (via `ql`/`qr` out-params); returns false
// when the clamped range is empty.
fn _clamp(t: &SegTree, l: Int, r: Int, ql: &mut Int, qr: &mut Int) -> Bool {
  var a = l;
  var b = r;
  if a < 0 {
    a = 0;
  }
  if b >= t.n {
    b = t.n - 1;
  }
  *ql = a;
  *qr = b;
  return a <= b;
}

/// Sum over [l, r] inclusive. Out-of-range queries are clamped; an empty
/// clamped range returns 0 (the sum identity).
/// O(log n).
pub fn segtree_query_sum(t: &SegTree, l: Int, r: Int) -> Int {
  var ql = 0;
  var qr = 0;
  var ok = _clamp(t, l, r, &mut ql, &mut qr);
  if !ok {
    return 0;
  }
  return _query_sum(t, 0, 0, t.n - 1, ql, qr);
}

/// Minimum over [l, r] inclusive. An empty clamped range returns INT_MAX
/// (the min identity).
/// O(log n).
pub fn segtree_query_min(t: &SegTree, l: Int, r: Int) -> Int {
  var ql = 0;
  var qr = 0;
  var ok = _clamp(t, l, r, &mut ql, &mut qr);
  if !ok {
    return _INT_MAX;
  }
  return _query_min(t, 0, 0, t.n - 1, ql, qr);
}

/// Maximum over [l, r] inclusive. An empty clamped range returns INT_MIN
/// (the max identity).
/// O(log n).
pub fn segtree_query_max(t: &SegTree, l: Int, r: Int) -> Int {
  var ql = 0;
  var qr = 0;
  var ok = _clamp(t, l, r, &mut ql, &mut qr);
  if !ok {
    return _INT_MIN;
  }
  return _query_max(t, 0, 0, t.n - 1, ql, qr);
}

/// Number of slots in the tree.
/// O(1).
pub fn segtree_size(t: &SegTree) -> Int
  ensures: result >= 0
{
  return t.n;
}

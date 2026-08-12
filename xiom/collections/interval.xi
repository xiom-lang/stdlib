// XIOM - Collections: Interval Tree
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.interval

// Depends on: none (pure)

// ============================================================================
// Interval tree (Int start/end, Int value). Stores [start, end] intervals and
// answers stabbing queries (which intervals contain a point) and range queries
// (which intervals overlap [start, end]) in O(log n + k) where k is the number
// of reported intervals. Intervals are inclusive on both ends.
//
// Flat-arena style (the established collect/ pattern). The tree is a BST keyed
// by `start`; each node also tracks `max_ends`, the largest `end` in its
// subtree, which prunes subtrees that cannot intersect a query. Equal starts
// are inserted to the right (multi-map semantics). Removed intervals are
// marked dead (`alive = false`) and skipped by every query, so removal never
// disturbs the tree shape. Queries skip a subtree when its max end is below
// the query point (stabbing) or below the query low bound (overlap).
// ============================================================================

pub type IntervalTree = {
  root: Int;
  size: Int;
  starts: Vec[Int];
  ends: Vec[Int];
  vals: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  max_ends: Vec[Int];
  alive: Vec[Bool];
}

fn _recalc_max(t: &mut IntervalTree, node: Int) {
  var m = t.ends[node];
  var l = t.left[node];
  var r = t.right[node];
  if l != -1 && t.max_ends[l] > m {
    m = t.max_ends[l];
  }
  if r != -1 && t.max_ends[r] > m {
    m = t.max_ends[r];
  }
  t.max_ends[node] = m;
}

/// Create an empty interval tree.
/// O(1).
pub fn interval_tree_new() -> IntervalTree {
  return IntervalTree{ root: -1; size: 0; starts: Vec[Int].new(); ends: Vec[Int].new(); vals: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); max_ends: Vec[Int].new(); alive: Vec[Bool].new(); };
}

/// Insert the interval [start, end] (inclusive) with its value. Duplicate
/// intervals are allowed. An interval with start > end is rejected (ignored).
/// O(h) with h the tree height (O(log n) expected).
pub fn interval_insert(t: &mut IntervalTree, start: Int, end: Int, value: Int) {
  if start > end {
    return;
  }
  var id = t.starts.len();
  t.starts.push(start);
  t.ends.push(end);
  t.vals.push(value);
  t.left.push(-1);
  t.right.push(-1);
  t.max_ends.push(end);
  t.alive.push(true);
  if t.root == -1 {
    t.root = id;
    t.size = t.size + 1;
    return;
  }
  var cur = t.root;
  var path = Vec[Int].new();
  loop {
    path.push(cur);
    if start < t.starts[cur] {
      var l = t.left[cur];
      if l == -1 {
        t.left[cur] = id;
        break;
      }
      cur = l;
    } else {
      var r = t.right[cur];
      if r == -1 {
        t.right[cur] = id;
        break;
      }
      cur = r;
    }
  }
  while path.len() > 0 {
    var n = path[path.len() - 1];
    path.pop();
    _recalc_max(t, n);
  }
  t.size = t.size + 1;
}

fn _stabbing(t: &IntervalTree, node: Int, point: Int, out: &mut Vec[Int]) {
  if node == -1 {
    return;
  }
  if t.max_ends[node] < point {
    return;
  }
  if t.starts[node] <= point {
    if t.alive[node] && t.ends[node] >= point {
      out.push(t.vals[node]);
    }
    _stabbing(t, t.left[node], point, out);
    _stabbing(t, t.right[node], point, out);
  } else {
    _stabbing(t, t.left[node], point, out);
  }
}

/// Values of the intervals containing `point` (inclusive bounds).
/// O(log n + k) expected.
pub fn interval_query(t: &IntervalTree, point: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  _stabbing(t, t.root, point, &mut out);
  return out;
}

fn _overlap(t: &IntervalTree, node: Int, lo: Int, hi: Int, out: &mut Vec[Int]) {
  if node == -1 {
    return;
  }
  if t.max_ends[node] < lo {
    return;
  }
  if t.starts[node] > hi {
    _overlap(t, t.left[node], lo, hi, out);
  } else {
    if t.alive[node] && t.ends[node] >= lo {
      out.push(t.vals[node]);
    }
    _overlap(t, t.left[node], lo, hi, out);
    _overlap(t, t.right[node], lo, hi, out);
  }
}

/// Values of the intervals overlapping [start, end] (inclusive; an interval
/// [a, b] overlaps when a <= end and b >= start).
/// O(log n + k) expected.
pub fn interval_range_query(t: &IntervalTree, start: Int, end: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var lo = start;
  var hi = end;
  if lo > hi {
    var tmp = lo;
    lo = hi;
    hi = tmp;
  }
  _overlap(t, t.root, lo, hi, &mut out);
  return out;
}

/// Remove the first interval matching [start, end]. Returns true if one was
/// found. Intervals are removed lazily (skipped by later queries).
/// O(n) worst case.
pub fn interval_remove(t: &mut IntervalTree, start: Int, end: Int) -> Bool {
  var stack = Vec[Int].new();
  stack.push(t.root);
  while stack.len() > 0 {
    var n = stack[stack.len() - 1];
    stack.pop();
    if n == -1 {
      continue;
    }
    if t.alive[n] {
      if t.starts[n] == start && t.ends[n] == end {
        t.alive[n] = false;
        t.size = t.size - 1;
        return true;
      }
    }
    stack.push(t.left[n]);
    stack.push(t.right[n]);
  }
  return false;
}

/// Number of live intervals.
/// O(1).
pub fn interval_size(t: &IntervalTree) -> Int {
  return t.size;
}

fn _stabbing_hit(t: &IntervalTree, node: Int, point: Int) -> Bool {
  if node == -1 {
    return false;
  }
  if t.max_ends[node] < point {
    return false;
  }
  if t.starts[node] <= point {
    if t.alive[node] && t.ends[node] >= point {
      return true;
    }
    if _stabbing_hit(t, t.left[node], point) {
      return true;
    }
    return _stabbing_hit(t, t.right[node], point);
  }
  return _stabbing_hit(t, t.left[node], point);
}

/// True if any live interval contains `point`.
/// O(log n + k) expected.
pub fn interval_contains_point(t: &IntervalTree, point: Int) -> Bool {
  return _stabbing_hit(t, t.root, point);
}

fn _overlap_hit(t: &IntervalTree, node: Int, lo: Int, hi: Int) -> Bool {
  if node == -1 {
    return false;
  }
  if t.max_ends[node] < lo {
    return false;
  }
  if t.starts[node] > hi {
    return _overlap_hit(t, t.left[node], lo, hi);
  }
  if t.alive[node] && t.ends[node] >= lo {
    return true;
  }
  if _overlap_hit(t, t.left[node], lo, hi) {
    return true;
  }
  return _overlap_hit(t, t.right[node], lo, hi);
}

/// True if any live interval overlaps the range [start, end].
/// O(log n + k) expected.
pub fn interval_overlaps(t: &IntervalTree, start: Int, end: Int) -> Bool {
  var lo = start;
  var hi = end;
  if lo > hi {
    var tmp = lo;
    lo = hi;
    hi = tmp;
  }
  return _overlap_hit(t, t.root, lo, hi);
}

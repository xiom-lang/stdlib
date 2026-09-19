// XIOM - Collections: K-D Tree
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.kdtree

// Depends on: xiom.math

/// 2D k-d tree of Int points with values, supporting nearest-neighbor and
/// rectangular range queries.
/// 
/// Flat-arena style (the established collect/ pattern -- tree.xi/graph.xi use
/// parallel Vec[Int]s because Vec-of-struct instantiations collide at startup
/// in combined programs). Node i lives in the parallel vectors `xs`/`ys`/`vals`
/// plus its `left`/`right` children; the splitting axis alternates by depth
/// (x at even depth, y at odd depth), which is re-derived during every walk so
/// no depth field needs to be stored. Distances are squared Int distances, so
/// no floating point is involved. `kdtree_insert` is an incremental insert
/// (O(h) with h the tree height); the worst case is O(n) per insert for
/// degenerate orders, expected O(log n).
pub type KdTree = {
  root: Int;
  size: Int;
  xs: Vec[Int];
  ys: Vec[Int];
  vals: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
}

/// Create a new empty k-d tree.
/// O(1).
pub fn kdtree_new() -> KdTree {
  return KdTree{ root: -1; size: 0; xs: Vec[Int].new(); ys: Vec[Int].new(); vals: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); };
}

/// Insert a point (x, y) with its value. Duplicate points are allowed and each
/// insertion creates a new node.
/// O(h) expected, O(n) worst case.
pub fn kdtree_insert(t: &mut KdTree, x: Int, y: Int, value: Int) {
  var id = t.xs.len();
  t.xs.push(x);
  t.ys.push(y);
  t.vals.push(value);
  t.left.push(-1);
  t.right.push(-1);
  if t.root == -1 {
    t.root = id;
    t.size = t.size + 1;
    return;
  }
  var cur = t.root;
  var depth = 0;
  loop {
    var axis = depth % 2;
    if axis == 0 {
      var kx = t.xs[cur];
      if x < kx {
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
    } else {
      var ky = t.ys[cur];
      if y < ky {
        var l2 = t.left[cur];
        if l2 == -1 {
          t.left[cur] = id;
          break;
        }
        cur = l2;
      } else {
        var r2 = t.right[cur];
        if r2 == -1 {
          t.right[cur] = id;
          break;
        }
        cur = r2;
      }
    }
    depth = depth + 1;
  }
  t.size = t.size + 1;
}

// Best-known neighbor during the search (id into the arena, squared distance).
type Neighbor = { id: Int; dist: Int; }

fn _nn_search(t: &KdTree, node: Int, x: Int, y: Int, depth: Int, best: &mut Neighbor) {
  if node == -1 {
    return;
  }
  var dx = t.xs[node] - x;
  var dy = t.ys[node] - y;
  var d = dx * dx + dy * dy;
  if d < best.dist {
    best.id = node;
    best.dist = d;
  }
  var axis = depth % 2;
  var near: Int = -1;
  var far: Int = -1;
  var axis_diff = 0;
  if axis == 0 {
    var kx = t.xs[node];
    axis_diff = x - kx;
    if axis_diff < 0 {
      near = t.left[node];
      far = t.right[node];
    } else {
      near = t.right[node];
      far = t.left[node];
    }
  } else {
    var ky = t.ys[node];
    axis_diff = y - ky;
    if axis_diff < 0 {
      near = t.left[node];
      far = t.right[node];
    } else {
      near = t.right[node];
      far = t.left[node];
    }
  }
  _nn_search(t, near, x, y, depth + 1, best);
  var plane = axis_diff * axis_diff;
  if plane < best.dist {
    _nn_search(t, far, x, y, depth + 1, best);
  }
}

/// Value of the point nearest to (x, y), or None if the tree is empty.
/// Ties are broken toward the point visited first. O(n) worst case,
/// O(log n) expected.
pub fn kdtree_nearest(t: &KdTree, x: Int, y: Int) -> Option[Int] {
  if t.root == -1 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  var best = Neighbor{ id: t.root; dist: 9223372036854775807; };
  _nn_search(t, t.root, x, y, 0, &mut best);
  return Option[Int]{ is_some: true; value: t.vals[best.id]; };
}

fn _range_search(t: &KdTree, node: Int, x1: Int, y1: Int, x2: Int, y2: Int, depth: Int, out: &mut Vec[Int]) {
  if node == -1 {
    return;
  }
  var px = t.xs[node];
  var py = t.ys[node];
  if px >= x1 && px <= x2 && py >= y1 && py <= y2 {
    out.push(t.vals[node]);
  }
  var axis = depth % 2;
  if axis == 0 {
    if px >= x1 {
      _range_search(t, t.left[node], x1, y1, x2, y2, depth + 1, out);
    }
    if px <= x2 {
      _range_search(t, t.right[node], x1, y1, x2, y2, depth + 1, out);
    }
  } else {
    if py >= y1 {
      _range_search(t, t.left[node], x1, y1, x2, y2, depth + 1, out);
    }
    if py <= y2 {
      _range_search(t, t.right[node], x1, y1, x2, y2, depth + 1, out);
    }
  }
}

/// Values of all points inside the rectangle [x1, x2] x [y1, y2] (inclusive).
/// Empty regions yield an empty Vec. O(n) worst case.
pub fn kdtree_range(t: &KdTree, x1: Int, y1: Int, x2: Int, y2: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if t.root == -1 {
    return out;
  }
  var rx1 = x1;
  var ry1 = y1;
  var rx2 = x2;
  var ry2 = y2;
  if rx1 > rx2 {
    var tx = rx1;
    rx1 = rx2;
    rx2 = tx;
  }
  if ry1 > ry2 {
    var ty = ry1;
    ry1 = ry2;
    ry2 = ty;
  }
  _range_search(t, t.root, rx1, ry1, rx2, ry2, 0, &mut out);
  return out;
}

/// Number of stored points.
/// O(1).
pub fn kdtree_size(t: &KdTree) -> Int
  ensures: result >= 0
{
  return t.size;
}

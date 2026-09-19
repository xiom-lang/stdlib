// XIOM - Collections: Spatial Indexes
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.spatial

// Depends on: xiom.math

// ============================================================================
// Spatial indexes for 2D and 3D points. KD-tree supports nearest-neighbor and
// rectangular range queries; quadtree and octree partition space recursively
// into cells. Queries return the stored values; empty regions yield empty Vecs.
//
// All three structures use the flat-arena style (the established collect/
// pattern -- tree.xi/graph.xi use parallel Vec[Int]s because Vec-of-struct
// instantiations collide at startup in combined programs). The quadtree and
// octree here take FIXED bounds (unlike xiom.collect.quadtree/octree, whose
// roots grow on demand); points outside the bounds are rejected by insert.
// ============================================================================

// ============================================================================
// KD-tree (2D Int points with values)
// ============================================================================

pub type KdTree = {
  root: Int;
  size: Int;
  xs: Vec[Int];
  ys: Vec[Int];
  vals: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
}

/// Create an empty KD-tree.
/// O(1).
pub fn kdtree_new() -> KdTree
  ensures: result.size == 0
{
  return KdTree{ root: -1; size: 0; xs: Vec[Int].new(); ys: Vec[Int].new(); vals: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); };
}

/// Insert a 2D point (x, y) with its value. Duplicates are allowed.
/// O(h) expected, O(n) worst case.
pub fn kdtree_insert(t: &mut KdTree, x: Int, y: Int, value: Int)
  ensures: kdtree_size(t) >= 1
{
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

type Nearest = { id: Int; dist: Int; }

fn _nn(t: &KdTree, node: Int, x: Int, y: Int, depth: Int, best: &mut Nearest) {
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
  _nn(t, near, x, y, depth + 1, best);
  var plane = axis_diff * axis_diff;
  if plane < best.dist {
    _nn(t, far, x, y, depth + 1, best);
  }
}

/// Value of the closest point to (x, y), or None if the tree is empty.
/// O(n) worst case, O(log n) expected.
pub fn kdtree_nearest(t: &KdTree, x: Int, y: Int) -> Option[Int]
  ensures: result is Some => kdtree_size(t) > 0
  ensures: result is None => kdtree_size(t) == 0
{
  if t.root == -1 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  var best = Nearest{ id: t.root; dist: 9223372036854775807; };
  _nn(t, t.root, x, y, 0, &mut best);
  return Option[Int]{ is_some: true; value: t.vals[best.id]; };
}

fn _range(t: &KdTree, node: Int, x1: Int, y1: Int, x2: Int, y2: Int, depth: Int, out: &mut Vec[Int]) {
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
      _range(t, t.left[node], x1, y1, x2, y2, depth + 1, out);
    }
    if px <= x2 {
      _range(t, t.right[node], x1, y1, x2, y2, depth + 1, out);
    }
  } else {
    if py >= y1 {
      _range(t, t.left[node], x1, y1, x2, y2, depth + 1, out);
    }
    if py <= y2 {
      _range(t, t.right[node], x1, y1, x2, y2, depth + 1, out);
    }
  }
}

/// Values of the points inside the rectangle [x1, x2] x [y1, y2] (inclusive).
/// O(n) worst case.
pub fn kdtree_range(t: &KdTree, x1: Int, y1: Int, x2: Int, y2: Int) -> Vec[Int]
  ensures: result.len() <= kdtree_size(t)
{
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
  _range(t, t.root, rx1, ry1, rx2, ry2, 0, &mut out);
  return out;
}

/// Number of points in the tree.
/// O(1).
pub fn kdtree_size(t: &KdTree) -> Int
  ensures: result >= 0
{
  return t.size;
}

// ============================================================================
// Quadtree (fixed bounds, 2D)
// ============================================================================

const QT_MAX_PTS: Int = 4;
const QT_MAX_DEPTH: Int = 12;

pub type Quadtree = {
  root: Int;
  size: Int;
  nx: Vec[Int];
  ny: Vec[Int];
  nw: Vec[Int];
  nh: Vec[Int];
  kids: Vec[Int];
  phead: Vec[Int];
  px: Vec[Int];
  py: Vec[Int];
  pv: Vec[Int];
  pnxt: Vec[Int];
}

fn _half(v: Int) -> Int {
  var r = v / 2;
  if v % 2 == 1 {
    r = r + 1;
  }
  return r;
}

fn _qt_add_node(q: &mut Quadtree, x: Int, y: Int, w: Int, h: Int) -> Int {
  q.nx.push(x);
  q.ny.push(y);
  q.nw.push(w);
  q.nh.push(h);
  q.phead.push(-1);
  var id = q.nx.len() - 1;
  var i: Int = 0;
  while i < 4 {
    q.kids.push(-1);
    i = i + 1;
  }
  return id;
}

fn _qt_kid_at(q: &Quadtree, node: Int, slot: Int) -> Int {
  return q.kids[node * 4 + slot];
}

fn _qt_set_kid(q: &mut Quadtree, node: Int, slot: Int, child: Int) {
  q.kids[node * 4 + slot] = child;
}

fn _qt_contains(q: &Quadtree, node: Int, x: Int, y: Int) -> Bool {
  if x < q.nx[node] || x >= q.nx[node] + q.nw[node] {
    return false;
  }
  if y < q.ny[node] || y >= q.ny[node] + q.nh[node] {
    return false;
  }
  return true;
}

fn _qt_quadrant(q: &Quadtree, node: Int, x: Int, y: Int) -> Int {
  var midx = q.nx[node] + _half(q.nw[node]);
  var midy = q.ny[node] + _half(q.nh[node]);
  var r = 0;
  if x >= midx {
    r = r + 1;
  }
  if y >= midy {
    r = r + 2;
  }
  return r;
}

fn _qt_ensure_child(q: &mut Quadtree, node: Int, qr: Int) -> Int {
  var c = _qt_kid_at(q, node, qr);
  if c != -1 {
    return c;
  }
  var cw = _half(q.nw[node]);
  var ch = _half(q.nh[node]);
  var c0x = q.nx[node];
  var c0y = q.ny[node];
  if (qr % 2) == 1 {
    c0x = c0x + cw;
  }
  if (qr / 2) == 1 {
    c0y = c0y + ch;
  }
  var child = _qt_add_node(q, c0x, c0y, cw, ch);
  _qt_set_kid(q, node, qr, child);
  return child;
}

fn _qt_subdivide(q: &mut Quadtree, node: Int) {
  var pid = q.phead[node];
  while pid != -1 {
    var nxt = q.pnxt[pid];
    var qr = _qt_quadrant(q, node, q.px[pid], q.py[pid]);
    var child = _qt_ensure_child(q, node, qr);
    q.pnxt[pid] = q.phead[child];
    q.phead[child] = pid;
    pid = nxt;
  }
  q.phead[node] = -1;
}

fn _qt_is_leaf(q: &Quadtree, node: Int) -> Bool {
  var i = 0;
  while i < 4 {
    if _qt_kid_at(q, node, i) != -1 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn _qt_count(q: &Quadtree, node: Int) -> Int {
  var count = 0;
  var pid = q.phead[node];
  while pid != -1 {
    count = count + 1;
    pid = q.pnxt[pid];
  }
  return count;
}

fn _qt_insert_at(q: &mut Quadtree, node: Int, x: Int, y: Int, value: Int, depth: Int) -> Bool {
  if _qt_is_leaf(q, node) {
    if _qt_count(q, node) < QT_MAX_PTS || depth >= QT_MAX_DEPTH {
      var pid = q.px.len();
      q.px.push(x);
      q.py.push(y);
      q.pv.push(value);
      q.pnxt.push(q.phead[node]);
      q.phead[node] = pid;
      q.size = q.size + 1;
      return true;
    }
    _qt_subdivide(q, node);
  }
  var qr = _qt_quadrant(q, node, x, y);
  var child = _qt_ensure_child(q, node, qr);
  return _qt_insert_at(q, child, x, y, value, depth + 1);
}

/// Create a quadtree for the given bounds (top-left (x, y), size (w, h)).
/// O(1).
pub fn quadtree_new(x: Int, y: Int, w: Int, h: Int) -> Quadtree
  ensures: result.size == 0
{
  var q = Quadtree{ root: -1; size: 0; nx: Vec[Int].new(); ny: Vec[Int].new(); nw: Vec[Int].new(); nh: Vec[Int].new(); kids: Vec[Int].new(); phead: Vec[Int].new(); px: Vec[Int].new(); py: Vec[Int].new(); pv: Vec[Int].new(); pnxt: Vec[Int].new(); };
  var ww = w;
  var hh = h;
  if ww < 1 { ww = 1; }
  if hh < 1 { hh = 1; }
  var root = _qt_add_node(&mut q, x, y, ww, hh);
  q.root = root;
  return q;
}

/// Insert a 2D point (x, y) with its value. Returns false if the point lies
/// outside the quadtree bounds.
/// O(depth).
pub fn quadtree_insert(q: &mut Quadtree, x: Int, y: Int, value: Int) -> Bool
  ensures: result == true => quadtree_size(q) >= 1
{
  if !_qt_contains(q, q.root, x, y) {
    return false;
  }
  return _qt_insert_at(q, q.root, x, y, value, 0);
}

fn _qt_region_hits(q: &Quadtree, node: Int, x1: Int, y1: Int, x2: Int, y2: Int) -> Bool {
  if q.nx[node] > x2 {
    return false;
  }
  if q.nx[node] + q.nw[node] - 1 < x1 {
    return false;
  }
  if q.ny[node] > y2 {
    return false;
  }
  if q.ny[node] + q.nh[node] - 1 < y1 {
    return false;
  }
  return true;
}

fn _qt_rect(q: &Quadtree, node: Int, x1: Int, y1: Int, x2: Int, y2: Int, out: &mut Vec[Int]) {
  var pid = q.phead[node];
  while pid != -1 {
    if q.px[pid] >= x1 && q.px[pid] <= x2 && q.py[pid] >= y1 && q.py[pid] <= y2 {
      out.push(q.pv[pid]);
    }
    pid = q.pnxt[pid];
  }
  var i = 0;
  while i < 4 {
    var c = _qt_kid_at(q, node, i);
    if c != -1 {
      if _qt_region_hits(q, c, x1, y1, x2, y2) {
        _qt_rect(q, c, x1, y1, x2, y2, out);
      }
    }
    i = i + 1;
  }
}

/// Values of the points inside the rectangle [x1, x2] x [y1, y2] (inclusive).
/// O(n) worst case.
pub fn quadtree_query(q: &Quadtree, x1: Int, y1: Int, x2: Int, y2: Int) -> Vec[Int]
  ensures: result.len() <= quadtree_size(q)
{
  var out = Vec[Int].new();
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
  _qt_rect(q, q.root, rx1, ry1, rx2, ry2, &mut out);
  return out;
}

/// Number of points in the tree.
/// O(1).
pub fn quadtree_size(q: &Quadtree) -> Int
  ensures: result >= 0
{
  return q.size;
}

// ============================================================================
// Octree (fixed bounds, 3D)
// ============================================================================

pub type Octree = {
  root: Int;
  size: Int;
  nx: Vec[Int];
  ny: Vec[Int];
  nz: Vec[Int];
  nw: Vec[Int];
  nh: Vec[Int];
  nd: Vec[Int];
  kids: Vec[Int];
  phead: Vec[Int];
  px: Vec[Int];
  py: Vec[Int];
  pz: Vec[Int];
  pv: Vec[Int];
  pnxt: Vec[Int];
}

fn _oc_add_node(o: &mut Octree, x: Int, y: Int, z: Int, w: Int, h: Int, d: Int) -> Int {
  o.nx.push(x);
  o.ny.push(y);
  o.nz.push(z);
  o.nw.push(w);
  o.nh.push(h);
  o.nd.push(d);
  o.phead.push(-1);
  var id = o.nx.len() - 1;
  var i: Int = 0;
  while i < 8 {
    o.kids.push(-1);
    i = i + 1;
  }
  return id;
}

fn _oc_kid_at(o: &Octree, node: Int, slot: Int) -> Int {
  return o.kids[node * 8 + slot];
}

fn _oc_set_kid(o: &mut Octree, node: Int, slot: Int, child: Int) {
  o.kids[node * 8 + slot] = child;
}

fn _oc_contains(o: &Octree, node: Int, x: Int, y: Int, z: Int) -> Bool {
  if x < o.nx[node] || x >= o.nx[node] + o.nw[node] {
    return false;
  }
  if y < o.ny[node] || y >= o.ny[node] + o.nh[node] {
    return false;
  }
  if z < o.nz[node] || z >= o.nz[node] + o.nd[node] {
    return false;
  }
  return true;
}

fn _oc_octant(o: &Octree, node: Int, x: Int, y: Int, z: Int) -> Int {
  var midx = o.nx[node] + _half(o.nw[node]);
  var midy = o.ny[node] + _half(o.nh[node]);
  var midz = o.nz[node] + _half(o.nd[node]);
  var r = 0;
  if x >= midx {
    r = r + 1;
  }
  if y >= midy {
    r = r + 2;
  }
  if z >= midz {
    r = r + 4;
  }
  return r;
}

fn _oc_ensure_child(o: &mut Octree, node: Int, or_: Int) -> Int {
  var c = _oc_kid_at(o, node, or_);
  if c != -1 {
    return c;
  }
  var cw = _half(o.nw[node]);
  var ch = _half(o.nh[node]);
  var cd = _half(o.nd[node]);
  var c0x = o.nx[node];
  var c0y = o.ny[node];
  var c0z = o.nz[node];
  if (or_ % 2) == 1 {
    c0x = c0x + cw;
  }
  if ((or_ / 2) % 2) == 1 {
    c0y = c0y + ch;
  }
  if (or_ / 4) == 1 {
    c0z = c0z + cd;
  }
  var child = _oc_add_node(o, c0x, c0y, c0z, cw, ch, cd);
  _oc_set_kid(o, node, or_, child);
  return child;
}

fn _oc_subdivide(o: &mut Octree, node: Int) {
  var pid = o.phead[node];
  while pid != -1 {
    var nxt = o.pnxt[pid];
    var or_ = _oc_octant(o, node, o.px[pid], o.py[pid], o.pz[pid]);
    var child = _oc_ensure_child(o, node, or_);
    o.pnxt[pid] = o.phead[child];
    o.phead[child] = pid;
    pid = nxt;
  }
  o.phead[node] = -1;
}

fn _oc_is_leaf(o: &Octree, node: Int) -> Bool {
  var i = 0;
  while i < 8 {
    if _oc_kid_at(o, node, i) != -1 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn _oc_count(o: &Octree, node: Int) -> Int {
  var count = 0;
  var pid = o.phead[node];
  while pid != -1 {
    count = count + 1;
    pid = o.pnxt[pid];
  }
  return count;
}

fn _oc_insert_at(o: &mut Octree, node: Int, x: Int, y: Int, z: Int, value: Int, depth: Int) -> Bool {
  if _oc_is_leaf(o, node) {
    if _oc_count(o, node) < QT_MAX_PTS || depth >= QT_MAX_DEPTH {
      var pid = o.px.len();
      o.px.push(x);
      o.py.push(y);
      o.pz.push(z);
      o.pv.push(value);
      o.pnxt.push(o.phead[node]);
      o.phead[node] = pid;
      o.size = o.size + 1;
      return true;
    }
    _oc_subdivide(o, node);
  }
  var or_ = _oc_octant(o, node, x, y, z);
  var child = _oc_ensure_child(o, node, or_);
  return _oc_insert_at(o, child, x, y, z, value, depth + 1);
}

/// Create an octree for the given bounds (corner (x, y, z), size (w, h, d)).
/// O(1).
pub fn octree_new(x: Int, y: Int, z: Int, w: Int, h: Int, d: Int) -> Octree
  ensures: result.size == 0
{
  var o = Octree{ root: -1; size: 0; nx: Vec[Int].new(); ny: Vec[Int].new(); nz: Vec[Int].new(); nw: Vec[Int].new(); nh: Vec[Int].new(); nd: Vec[Int].new(); kids: Vec[Int].new(); phead: Vec[Int].new(); px: Vec[Int].new(); py: Vec[Int].new(); pz: Vec[Int].new(); pv: Vec[Int].new(); pnxt: Vec[Int].new(); };
  var ww = w;
  var hh = h;
  var dd = d;
  if ww < 1 { ww = 1; }
  if hh < 1 { hh = 1; }
  if dd < 1 { dd = 1; }
  var root = _oc_add_node(&mut o, x, y, z, ww, hh, dd);
  o.root = root;
  return o;
}

/// Insert a 3D point (x, y, z) with its value. Returns false if the point lies
/// outside the octree bounds.
/// O(depth).
pub fn octree_insert(o: &mut Octree, x: Int, y: Int, z: Int, value: Int) -> Bool
  ensures: result == true => octree_size(o) >= 1
{
  if !_oc_contains(o, o.root, x, y, z) {
    return false;
  }
  return _oc_insert_at(o, o.root, x, y, z, value, 0);
}

fn _oc_region_hits(o: &Octree, node: Int, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int) -> Bool {
  if o.nx[node] > x2 {
    return false;
  }
  if o.nx[node] + o.nw[node] - 1 < x1 {
    return false;
  }
  if o.ny[node] > y2 {
    return false;
  }
  if o.ny[node] + o.nh[node] - 1 < y1 {
    return false;
  }
  if o.nz[node] > z2 {
    return false;
  }
  if o.nz[node] + o.nd[node] - 1 < z1 {
    return false;
  }
  return true;
}

fn _oc_box(o: &Octree, node: Int, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, out: &mut Vec[Int]) {
  var pid = o.phead[node];
  while pid != -1 {
    if o.px[pid] >= x1 && o.px[pid] <= x2 && o.py[pid] >= y1 && o.py[pid] <= y2 && o.pz[pid] >= z1 && o.pz[pid] <= z2 {
      out.push(o.pv[pid]);
    }
    pid = o.pnxt[pid];
  }
  var i = 0;
  while i < 8 {
    var c = _oc_kid_at(o, node, i);
    if c != -1 {
      if _oc_region_hits(o, c, x1, y1, z1, x2, y2, z2) {
        _oc_box(o, c, x1, y1, z1, x2, y2, z2, out);
      }
    }
    i = i + 1;
  }
}

/// Values of the points inside the box [x1, x2] x [y1, y2] x [z1, z2]
/// (inclusive). O(n) worst case.
pub fn octree_query(o: &Octree, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int) -> Vec[Int]
  ensures: result.len() <= octree_size(o)
{
  var out = Vec[Int].new();
  var rx1 = x1;
  var ry1 = y1;
  var rz1 = z1;
  var rx2 = x2;
  var ry2 = y2;
  var rz2 = z2;
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
  if rz1 > rz2 {
    var tz = rz1;
    rz1 = rz2;
    rz2 = tz;
  }
  _oc_box(o, o.root, rx1, ry1, rz1, rx2, ry2, rz2, &mut out);
  return out;
}

/// Number of points in the tree.
/// O(1).
pub fn octree_size(o: &Octree) -> Int
  ensures: result >= 0
{
  return o.size;
}

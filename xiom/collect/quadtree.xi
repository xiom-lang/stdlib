// XIOM - Collections: Quadtree
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.quadtree

// Depends on: xiom.math

// ============================================================================
// Quadtree of 2D Int points with values, recursively subdividing space into
// four quadrants.
//
// Flat-arena style (the established collect/ pattern). Every node owns 4 child
// slots (`kids[i * 4 + q]`, q = 0 NW, 1 NE, 2 SW, 3 SE) and a region given by
// (nx, ny, nw, nh) -- top-left corner and size. Points are not stored inline:
// each node has a head pointer into a global point pool (`px`/`py`/`pv`/`pnxt`
// as a linked list), and a leaf holds at most MAX_PTS points before it
// subdivides. There is no fixed root bounds: `quadtree_insert` grows the root
// region exponentially (doubling the size and re-homing the old root as a
// child quadrant) until the point fits, so the tree covers any Int
// coordinates. Subdivision is capped at MAX_DEPTH so duplicate points cannot
// recurse forever.
// ============================================================================

const MAX_PTS: Int = 4;
const MAX_DEPTH: Int = 12;

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

// ceil(v / 2) -- child widths and quadrant boundaries must use the SAME
// rounding so that child regions tile their parent without gaps.
fn _half(v: Int) -> Int {
  var r = v / 2;
  if v % 2 == 1 {
    r = r + 1;
  }
  return r;
}

// Append a node with the given region and return its index.
fn _add_node(q: &mut Quadtree, x: Int, y: Int, w: Int, h: Int) -> Int {
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

fn _kid_at(q: &Quadtree, node: Int, slot: Int) -> Int {
  return q.kids[node * 4 + slot];
}

fn _set_kid(q: &mut Quadtree, node: Int, slot: Int, child: Int) {
  q.kids[node * 4 + slot] = child;
}

// True if the node region contains (x, y).
fn _contains(q: &Quadtree, node: Int, x: Int, y: Int) -> Bool {
  if x < q.nx[node] || x >= q.nx[node] + q.nw[node] {
    return false;
  }
  if y < q.ny[node] || y >= q.ny[node] + q.nh[node] {
    return false;
  }
  return true;
}

// Quadrant of the child that contains (x, y): 0 NW, 1 NE, 2 SW, 3 SE.
fn _quadrant(q: &Quadtree, node: Int, x: Int, y: Int) -> Int {
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

// Grow the root region (doubling size, re-homing the old root) until it
// contains (x, y).
fn _expand_root(q: &mut Quadtree, x: Int, y: Int) {
  loop {
    if _contains(q, q.root, x, y) {
      return;
    }
    var rw = q.nw[q.root];
    var rh = q.nh[q.root];
    var rx = q.nx[q.root];
    var ry = q.ny[q.root];
    var nw2 = rw * 2;
    var nh2 = rh * 2;
    var nrx = rx;
    var nry = ry;
    if x >= rx + rw {
      nrx = rx;
    } elif x < rx {
      nrx = rx - rw;
    }
    if y >= ry + rh {
      nry = ry;
    } elif y < ry {
      nry = ry - rh;
    }
    var newroot = _add_node(q, nrx, nry, nw2, nh2);
    var old = q.root;
    var qr = 0;
    var halfx = nrx + nw2 / 2;
    var halfy = nry + nh2 / 2;
    if rx >= halfx {
      qr = qr + 1;
    }
    if ry >= halfy {
      qr = qr + 2;
    }
    _set_kid(q, newroot, qr, old);
    q.root = newroot;
  }
}

// Ensure a child exists for quadrant `qr` of `node`; return its index.
fn _ensure_child(q: &mut Quadtree, node: Int, qr: Int) -> Int {
  var c = _kid_at(q, node, qr);
  if c != -1 {
    return c;
  }
  var cw = _half(q.nw[node]);
  var ch = _half(q.nh[node]);
  var x0 = q.nx[node];
  var y0 = q.ny[node];
  var c0x = x0;
  var c0y = y0;
  if (qr % 2) == 1 {
    c0x = x0 + cw;
  }
  if (qr / 2) == 1 {
    c0y = y0 + ch;
  }
  var child = _add_node(q, c0x, c0y, cw, ch);
  _set_kid(q, node, qr, child);
  return child;
}

// Move every point of `node` into the matching child and clear the node list.
fn _subdivide(q: &mut Quadtree, node: Int) {
  var pid = q.phead[node];
  while pid != -1 {
    var nxt = q.pnxt[pid];
    var qr = _quadrant(q, node, q.px[pid], q.py[pid]);
    var child = _ensure_child(q, node, qr);
    q.pnxt[pid] = q.phead[child];
    q.phead[child] = pid;
    pid = nxt;
  }
  q.phead[node] = -1;
}

fn _node_is_leaf(q: &Quadtree, node: Int) -> Bool {
  var i = 0;
  while i < 4 {
    if _kid_at(q, node, i) != -1 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn _count_points(q: &Quadtree, node: Int) -> Int {
  var count = 0;
  var pid = q.phead[node];
  while pid != -1 {
    count = count + 1;
    pid = q.pnxt[pid];
  }
  return count;
}

fn _insert_at(q: &mut Quadtree, node: Int, x: Int, y: Int, value: Int, depth: Int) {
  if _node_is_leaf(q, node) {
    if _count_points(q, node) < MAX_PTS || depth >= MAX_DEPTH {
      var pid = q.px.len();
      q.px.push(x);
      q.py.push(y);
      q.pv.push(value);
      q.pnxt.push(q.phead[node]);
      q.phead[node] = pid;
      q.size = q.size + 1;
      return;
    }
    _subdivide(q, node);
  }
  var qr = _quadrant(q, node, x, y);
  var child = _ensure_child(q, node, qr);
  _insert_at(q, child, x, y, value, depth + 1);
}

/// Create a new empty quadtree (root region starts at (0, 0, 1, 1) and grows
/// on demand).
/// O(1).
pub fn quadtree_new() -> Quadtree {
  var q = Quadtree{ root: -1; size: 0; nx: Vec[Int].new(); ny: Vec[Int].new(); nw: Vec[Int].new(); nh: Vec[Int].new(); kids: Vec[Int].new(); phead: Vec[Int].new(); px: Vec[Int].new(); py: Vec[Int].new(); pv: Vec[Int].new(); pnxt: Vec[Int].new(); };
  var root = _add_node(&mut q, 0, 0, 1, 1);
  q.root = root;
  return q;
}

/// Insert a point (x, y) with its value. Duplicate points are allowed.
/// O(depth) where depth grows logarithmically with the distance from the
/// initial root region.
pub fn quadtree_insert(t: &mut Quadtree, x: Int, y: Int, value: Int) {
  _expand_root(t, x, y);
  _insert_at(t, t.root, x, y, value, 0);
}

/// Value stored at the point (x, y), or None if no point with those exact
/// coordinates is stored. O(depth).
pub fn quadtree_query(t: &Quadtree, x: Int, y: Int) -> Option[Int] {
  var node = t.root;
  loop {
    var pid = t.phead[node];
    while pid != -1 {
      if t.px[pid] == x && t.py[pid] == y {
        return Option[Int]{ is_some: true; value: t.pv[pid]; };
      }
      pid = t.pnxt[pid];
    }
    if _node_is_leaf(t, node) {
      return Option[Int]{ is_some: false; value: 0; };
    }
    if !_contains(t, node, x, y) {
      return Option[Int]{ is_some: false; value: 0; };
    }
    var qr = _quadrant(t, node, x, y);
    var child = _kid_at(t, node, qr);
    if child == -1 {
      return Option[Int]{ is_some: false; value: 0; };
    }
    node = child;
  }
}

/// Number of stored points.
/// O(1).
pub fn quadtree_size(t: &Quadtree) -> Int
  ensures: result >= 0
{
  return t.size;
}

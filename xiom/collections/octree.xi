// XIOM - Collections: Octree
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.octree

// Depends on: xiom.math

// ============================================================================
// Octree of 3D Int points with values, recursively subdividing space into
// eight octants.
//
// Flat-arena style (the established collect/ pattern — see quadtree.xi for
// the 2D sibling). Every node owns 8 child slots (`kids[i * 8 + o]`; o packs
// x = bit 0, y = bit 1, z = bit 2) and a region (nx, ny, nz, nw, nh, nd).
// Points live in a global pool linked through `phead`/`pnxt`, leaves hold at
// most MAX_PTS points, and the root region grows exponentially on demand so
// any Int coordinates are covered. Subdivision caps at MAX_DEPTH so duplicate
// points cannot recurse forever.
// ============================================================================

const MAX_PTS: Int = 4;
const MAX_DEPTH: Int = 12;

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

// ceil(v / 2) — child extents and octant boundaries must share the SAME
// rounding so children tile their parent without gaps.
fn _half(v: Int) -> Int {
  var r = v / 2;
  if v % 2 == 1 {
    r = r + 1;
  }
  return r;
}

// Append a node with the given region and return its index.
fn _add_node(o: &mut Octree, x: Int, y: Int, z: Int, w: Int, h: Int, d: Int) -> Int {
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

fn _kid_at(o: &Octree, node: Int, slot: Int) -> Int {
  return o.kids[node * 8 + slot];
}

fn _set_kid(o: &mut Octree, node: Int, slot: Int, child: Int) {
  o.kids[node * 8 + slot] = child;
}

// True if the node region contains (x, y, z).
fn _contains(o: &Octree, node: Int, x: Int, y: Int, z: Int) -> Bool {
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

// Octant of the child that contains (x, y, z).
fn _octant(o: &Octree, node: Int, x: Int, y: Int, z: Int) -> Int {
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

// Grow the root region (doubling size, re-homing the old root) until it
// contains (x, y, z).
fn _expand_root(o: &mut Octree, x: Int, y: Int, z: Int) {
  loop {
    if _contains(o, o.root, x, y, z) {
      return;
    }
    var rw = o.nw[o.root];
    var rh = o.nh[o.root];
    var rd = o.nd[o.root];
    var rx = o.nx[o.root];
    var ry = o.ny[o.root];
    var rz = o.nz[o.root];
    var nw2 = rw * 2;
    var nh2 = rh * 2;
    var nd2 = rd * 2;
    var nrx = rx;
    var nry = ry;
    var nrz = rz;
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
    if z >= rz + rd {
      nrz = rz;
    } elif z < rz {
      nrz = rz - rd;
    }
    var newroot = _add_node(o, nrx, nry, nrz, nw2, nh2, nd2);
    var old = o.root;
    var or_ = 0;
    var halfx = nrx + nw2 / 2;
    var halfy = nry + nh2 / 2;
    var halfz = nrz + nd2 / 2;
    if rx >= halfx {
      or_ = or_ + 1;
    }
    if ry >= halfy {
      or_ = or_ + 2;
    }
    if rz >= halfz {
      or_ = or_ + 4;
    }
    _set_kid(o, newroot, or_, old);
    o.root = newroot;
  }
}

// Ensure a child exists for octant `or_` of `node`; return its index.
fn _ensure_child(o: &mut Octree, node: Int, or_: Int) -> Int {
  var c = _kid_at(o, node, or_);
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
  var child = _add_node(o, c0x, c0y, c0z, cw, ch, cd);
  _set_kid(o, node, or_, child);
  return child;
}

// Move every point of `node` into the matching child and clear the node list.
fn _subdivide(o: &mut Octree, node: Int) {
  var pid = o.phead[node];
  while pid != -1 {
    var nxt = o.pnxt[pid];
    var or_ = _octant(o, node, o.px[pid], o.py[pid], o.pz[pid]);
    var child = _ensure_child(o, node, or_);
    o.pnxt[pid] = o.phead[child];
    o.phead[child] = pid;
    pid = nxt;
  }
  o.phead[node] = -1;
}

fn _node_is_leaf(o: &Octree, node: Int) -> Bool {
  var i = 0;
  while i < 8 {
    if _kid_at(o, node, i) != -1 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn _count_points(o: &Octree, node: Int) -> Int {
  var count = 0;
  var pid = o.phead[node];
  while pid != -1 {
    count = count + 1;
    pid = o.pnxt[pid];
  }
  return count;
}

fn _insert_at(o: &mut Octree, node: Int, x: Int, y: Int, z: Int, value: Int, depth: Int) {
  if _node_is_leaf(o, node) {
    if _count_points(o, node) < MAX_PTS || depth >= MAX_DEPTH {
      var pid = o.px.len();
      o.px.push(x);
      o.py.push(y);
      o.pz.push(z);
      o.pv.push(value);
      o.pnxt.push(o.phead[node]);
      o.phead[node] = pid;
      o.size = o.size + 1;
      return;
    }
    _subdivide(o, node);
  }
  var or_ = _octant(o, node, x, y, z);
  var child = _ensure_child(o, node, or_);
  _insert_at(o, child, x, y, z, value, depth + 1);
}

/// Create a new empty octree (root region starts at (0, 0, 0, 1, 1, 1) and
/// grows on demand).
/// O(1).
pub fn octree_new() -> Octree {
  var o = Octree{ root: -1; size: 0; nx: Vec[Int].new(); ny: Vec[Int].new(); nz: Vec[Int].new(); nw: Vec[Int].new(); nh: Vec[Int].new(); nd: Vec[Int].new(); kids: Vec[Int].new(); phead: Vec[Int].new(); px: Vec[Int].new(); py: Vec[Int].new(); pz: Vec[Int].new(); pv: Vec[Int].new(); pnxt: Vec[Int].new(); };
  var root = _add_node(&mut o, 0, 0, 0, 1, 1, 1);
  o.root = root;
  return o;
}

/// Insert a point (x, y, z) with its value. Duplicate points are allowed.
/// O(depth) where depth grows logarithmically with the distance from the
/// initial root region.
pub fn octree_insert(t: &mut Octree, x: Int, y: Int, z: Int, value: Int) {
  _expand_root(t, x, y, z);
  _insert_at(t, t.root, x, y, z, value, 0);
}

/// Value stored at the point (x, y, z), or None if no point with those exact
/// coordinates is stored. O(depth).
pub fn octree_query(t: &Octree, x: Int, y: Int, z: Int) -> Option[Int] {
  var node = t.root;
  loop {
    var pid = t.phead[node];
    while pid != -1 {
      if t.px[pid] == x && t.py[pid] == y && t.pz[pid] == z {
        return Option[Int]{ is_some: true; value: t.pv[pid]; };
      }
      pid = t.pnxt[pid];
    }
    if _node_is_leaf(t, node) {
      return Option[Int]{ is_some: false; value: 0; };
    }
    if !_contains(t, node, x, y, z) {
      return Option[Int]{ is_some: false; value: 0; };
    }
    var or_ = _octant(t, node, x, y, z);
    var child = _kid_at(t, node, or_);
    if child == -1 {
      return Option[Int]{ is_some: false; value: 0; };
    }
    node = child;
  }
}

/// Number of stored points.
/// O(1).
pub fn octree_size(t: &Octree) -> Int {
  return t.size;
}

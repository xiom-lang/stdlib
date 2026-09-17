// XIOM -- Heap Collection (Pairing Heap + Fibonacci Heap)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.heap

// ============================================================================
// Pairing Heap (Int keys)
// Arena of nodes; node i lives at the i-th triple of the `keys` vector:
//   keys[3i]   = key
//   keys[3i+1] = first child
//   keys[3i+2] = next sibling
// (nested `Vec[Vec[Int]]` element access is unreliable in the current
// compiler, so the child lists are stored as first-child/next-sibling links
// in the flat arena; the `children` field is retained per the module spec.)
// Merge works on concrete Int keys; extract uses the two-pass pairwise merge.
// ============================================================================

pub type PHeap = {
  root: Int;
  keys: Vec[Int];
  children: Vec[Vec[Int]];
}

/// Merge two heaps rooted at indices `a` and `b`. The smaller key becomes
/// the parent; the other is linked as its first child.
fn pheap_merge(h: &mut PHeap, a: Int, b: Int) -> Int {
  if a == -1 { return b; }
  if b == -1 { return a; }
  var ka = h.keys[3 * a];
  var kb = h.keys[3 * b];
  if ka <= kb {
    var old = h.keys[3 * a + 1];
    h.keys[3 * a + 1] = b;
    h.keys[3 * b + 2] = old;
    return a;
  }
  var old = h.keys[3 * b + 1];
  h.keys[3 * b + 1] = a;
  h.keys[3 * a + 2] = old;
  return b;
}

/// Create an empty pairing heap.
pub fn pheap_new() -> PHeap
  ensures: result.root == -1
{
  return PHeap{ root: -1; keys: Vec[Int].new(); children: Vec[Vec[Int]].new(); };
}

/// Insert a key into the heap.
pub fn pheap_insert(h: &mut PHeap, key: Int) {
  var id = h.keys.len() / 3;
  h.keys.push(key);
  h.keys.push(-1);
  h.keys.push(-1);
  h.root = pheap_merge(h, h.root, id);
}

/// Minimum key, or None if the heap is empty.
pub fn pheap_find_min(h: &PHeap) -> Option[Int]
  ensures: result.is_some == (pheap_size(h) > 0)
{
  if h.root == -1 { return None; }
  return Some(h.keys[3 * h.root]);
}

/// Remove and return the minimum key, or None if empty.
/// Children of the removed root are merged pairwise (left-to-right pass).
pub fn pheap_extract_min(h: &mut PHeap) -> Option[Int] {
  if h.root == -1 { return None; }
  var r = h.root;
  var min_key = h.keys[3 * r];
  var childs = Vec[Int].new();
  var c = h.keys[3 * r + 1];
  while c != -1 {
    childs.push(c);
    c = h.keys[3 * c + 2];
  }
  var merged = Vec[Int].new();
  var i = 0;
  while i + 1 < childs.len() {
    merged.push(pheap_merge(h, childs[i], childs[i + 1]));
    i = i + 2;
  }
  if i < childs.len() {
    merged.push(childs[i]);
  }
  var new_root = -1;
  i = 0;
  while i < merged.len() {
    new_root = pheap_merge(h, new_root, merged[i]);
    i = i + 1;
  }
  h.root = new_root;
  return Some(min_key);
}

/// Number of reachable nodes in the heap.
pub fn pheap_size(h: &PHeap) -> Int
  ensures: result >= 0
{
  if h.root == -1 { return 0; }
  var count = 0;
  var stack = Vec[Int].new();
  stack.push(h.root);
  while stack.len() > 0 {
    var top_opt = stack.pop();
    match top_opt {
      Some(n) => {
        count = count + 1;
        var c = h.keys[3 * n + 1];
        while c != -1 {
          stack.push(c);
          c = h.keys[3 * c + 2];
        }
      },
      None => {},
    }
  }
  return count;
}

/// True if the heap contains no keys.
pub fn pheap_is_empty(h: &PHeap) -> Bool
  ensures: result == (pheap_size(h) == 0)
{
  return h.root == -1;
}

// ============================================================================
// Fibonacci Heap (Int keys)
// Arena of parallel vectors. The root list and every child list are circular
// doubly-linked rings through the `left`/`right` vectors; sentinel index -1
// denotes "no node". Extract-min consolidates the root list with 64 degree
// buckets. Decrease-key performs a cut + cascading cut (CLRS).
// ============================================================================

pub type FibHeap = {
  min: Int;
  n: Int;
  keys: Vec[Int];
  parent: Vec[Int];
  child: Vec[Int];
  left: Vec[Int];
  right: Vec[Int];
  degree: Vec[Int];
  mark: Vec[Bool];
}

const _FIB_MAX_DEGREE: Int = 64;

fn fib_heap_new_node(h: &mut FibHeap, key: Int) -> Int {
  h.keys.push(key);
  h.parent.push(-1);
  h.child.push(-1);
  h.left.push(-1);
  h.right.push(-1);
  h.degree.push(0);
  h.mark.push(false);
  return h.keys.len() - 1;
}

/// Create an empty Fibonacci heap.
pub fn fib_heap_new() -> FibHeap
  ensures: result.n == 0
{
  return FibHeap{ min: -1; n: 0; keys: Vec[Int].new(); parent: Vec[Int].new(); child: Vec[Int].new(); left: Vec[Int].new(); right: Vec[Int].new(); degree: Vec[Int].new(); mark: Vec[Bool].new(); };
}

/// Insert a key into the heap.
pub fn fib_heap_insert(h: &mut FibHeap, key: Int) {
  var id = fib_heap_new_node(h, key);
  if h.min == -1 {
    h.left[id] = id;
    h.right[id] = id;
    h.min = id;
  } else {
    var ml = h.left[h.min];
    h.right[ml] = id;
    h.left[id] = ml;
    h.right[id] = h.min;
    h.left[h.min] = id;
    if key < h.keys[h.min] {
      h.min = id;
    }
  }
  h.n = h.n + 1;
}

/// Minimum key, or None if the heap is empty.
pub fn fib_heap_find_min(h: &FibHeap) -> Option[Int]
  ensures: result.is_some == (fib_heap_size(h) > 0)
{
  if h.min == -1 { return None; }
  return Some(h.keys[h.min]);
}

/// Remove node `y` from the root list and link it as a child of `x`.
fn fib_heap_link(h: &mut FibHeap, y: Int, x: Int) {
  var yl = h.left[y];
  var yr = h.right[y];
  h.right[yl] = yr;
  h.left[yr] = yl;
  h.parent[y] = x;
  var xc = h.child[x];
  if xc == -1 {
    h.child[x] = y;
    h.left[y] = y;
    h.right[y] = y;
  } else {
    var xcl = h.left[xc];
    h.right[xcl] = y;
    h.left[y] = xcl;
    h.right[y] = xc;
    h.left[xc] = y;
  }
  h.degree[x] = h.degree[x] + 1;
  h.mark[y] = false;
}

/// Rebuild the root list: link nodes of equal degree and rewire the list.
fn fib_heap_consolidate(h: &mut FibHeap, start: Int) {
  var nodes = Vec[Int].new();
  var cur = start;
  loop {
    nodes.push(cur);
    cur = h.right[cur];
    if cur == start { break; }
  }
  var buckets = Vec[Int].new();
  var i = 0;
  while i < _FIB_MAX_DEGREE {
    buckets.push(-1);
    i = i + 1;
  }
  var j = 0;
  while j < nodes.len() {
    var x = nodes[j];
    var d = h.degree[x];
    while buckets[d] != -1 {
      var y = buckets[d];
      if h.keys[x] > h.keys[y] {
        var tmp = x;
        x = y;
        y = tmp;
      }
      fib_heap_link(h, y, x);
      buckets[d] = -1;
      d = d + 1;
    }
    buckets[d] = x;
    j = j + 1;
  }
  h.min = -1;
  var k = 0;
  while k < _FIB_MAX_DEGREE {
    var node = buckets[k];
    if node != -1 {
      if h.min == -1 {
        h.left[node] = node;
        h.right[node] = node;
        h.min = node;
      } else {
        var ml = h.left[h.min];
        h.right[ml] = node;
        h.left[node] = ml;
        h.right[node] = h.min;
        h.left[h.min] = node;
        if h.keys[node] < h.keys[h.min] {
          h.min = node;
        }
      }
    }
    k = k + 1;
  }
}

/// Remove and return the minimum key, or None if empty.
/// Consolidates the root list so future extract-mins stay amortized.
pub fn fib_heap_extract_min(h: &mut FibHeap) -> Option[Int] {
  if h.min == -1 { return None; }
  var z = h.min;
  var min_key = h.keys[z];
  var zc = h.child[z];
  if zc != -1 {
    var ccur = zc;
    loop {
      var cnxt = h.right[ccur];
      h.parent[ccur] = -1;
      var zl = h.left[z];
      h.right[zl] = ccur;
      h.left[ccur] = zl;
      h.right[ccur] = z;
      h.left[z] = ccur;
      ccur = cnxt;
      if ccur == zc { break; }
    }
  }
  var zl = h.left[z];
  var zr = h.right[z];
  h.n = h.n - 1;
  if zl == z {
    h.min = -1;
    h.child[z] = -1;
    h.degree[z] = 0;
    return Some(min_key);
  }
  h.right[zl] = zr;
  h.left[zr] = zl;
  h.child[z] = -1;
  h.degree[z] = 0;
  if zr == z {
    h.min = -1;
  } else {
    fib_heap_consolidate(h, zr);
  }
  return Some(min_key);
}

/// Number of keys in the heap.
pub fn fib_heap_size(h: &FibHeap) -> Int
  ensures: result >= 0
{
  return h.n;
}

/// True if the heap contains no keys.
pub fn fib_heap_is_empty(h: &FibHeap) -> Bool
  ensures: result == (fib_heap_size(h) == 0)
{
  return h.min == -1;
}

/// Remove node `x` from the child list of `y` and add it to the root list.
fn fib_heap_cut(h: &mut FibHeap, x: Int, y: Int) {
  var xl = h.left[x];
  var xr = h.right[x];
  if xl == x {
    h.child[y] = -1;
  } else {
    h.right[xl] = xr;
    h.left[xr] = xl;
    if h.child[y] == x {
      h.child[y] = xr;
    }
  }
  h.degree[y] = h.degree[y] - 1;
  h.parent[x] = -1;
  if h.min == -1 {
    h.left[x] = x;
    h.right[x] = x;
    h.min = x;
  } else {
    var ml = h.left[h.min];
    h.right[ml] = x;
    h.left[x] = ml;
    h.right[x] = h.min;
    h.left[h.min] = x;
    if h.keys[x] < h.keys[h.min] {
      h.min = x;
    }
  }
  h.mark[x] = false;
}

/// Walk up the tree cutting marked nodes (CLRS cascading cut).
fn fib_heap_cascading_cut(h: &mut FibHeap, y: Int) {
  var p = h.parent[y];
  while p != -1 {
    if h.mark[y] == false {
      h.mark[y] = true;
      return;
    }
    fib_heap_cut(h, y, p);
    y = p;
    p = h.parent[y];
  }
}

/// Decrease the key of `node` to `new_key`. Returns false if the node index
/// is out of range or the new key is not smaller.
pub fn fib_heap_decrease_key(h: &mut FibHeap, node: Int, new_key: Int) -> Bool {
  if node < 0 || node >= h.keys.len() { return false; }
  if new_key > h.keys[node] { return false; }
  h.keys[node] = new_key;
  var p = h.parent[node];
  if p != -1 && h.keys[node] < h.keys[p] {
    fib_heap_cut(h, node, p);
    fib_heap_cascading_cut(h, p);
  }
  if h.min == -1 || h.keys[node] < h.keys[h.min] {
    h.min = node;
  }
  return true;
}

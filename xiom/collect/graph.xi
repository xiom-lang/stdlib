// XIOM -- Graph Collection (Adjacency-list Graph + Union-Find)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.graph

/// Graph (Int node ids)
/// The spec struct is `{ n: Int; adj: Vec[Vec[Int]]; }`, but nested
/// `Vec[Vec[Int]]` element access is unreliable in the current compiler (see
/// collect/heap.xi), so the `adj` field is retained per the module spec while
/// the adjacency is stored in a flat linked arena:
///   head[u] = first edge id in u's neighbor list (or -1)
///   to[id]  = destination node of edge id
///   next[id] = next edge id in the same node's list (or -1)
/// Appending is O(1); has_edge/degree/neighbors walk the list. `graph_add_edge`
/// adds both directions and rejects duplicates; `graph_add_directed_edge` adds
/// a single directed edge.
pub type Graph = {
  n: Int;
  adj: Vec[Vec[Int]];
  head: Vec[Int];
  to: Vec[Int];
  next: Vec[Int];
}

/// Create a graph with `n` isolated nodes.
pub fn graph_new(n: Int) -> Graph
  ensures: result.n == n
{
  var head = Vec[Int].new();
  var i = 0;
  while i < n {
    head.push(-1);
    i = i + 1;
  }
  return Graph{ n: n; adj: Vec[Vec[Int]].new(); head: head; to: Vec[Int].new(); next: Vec[Int].new(); };
}

/// Append `v` to the neighbor list of `u` (no duplicate check).
fn graph_link(g: &mut Graph, u: Int, v: Int) {
  var id = g.to.len();
  g.to.push(v);
  g.next.push(g.head[u]);
  g.head[u] = id;
}

/// True if node `v` is a neighbor of node `u`.
pub fn graph_has_edge(g: &Graph, u: Int, v: Int) -> Bool
  ensures: u < 0 || u >= g.n => result == false
{
  if u < 0 || u >= g.n { return false; }
  var id = g.head[u];
  while id != -1 {
    if g.to[id] == v { return true; }
    id = g.next[id];
  }
  return false;
}

/// Add an undirected edge between `u` and `v` (no duplicates).
pub fn graph_add_edge(g: &mut Graph, u: Int, v: Int)
  ensures: u >= 0 && u < g.n && v >= 0 && v < g.n => graph_has_edge(g, u, v)
{
  if u < 0 || u >= g.n || v < 0 || v >= g.n { return; }
  if graph_has_edge(g, u, v) { return; }
  graph_link(g, u, v);
  graph_link(g, v, u);
}

/// Add a directed edge u -> v (no duplicates).
pub fn graph_add_directed_edge(g: &mut Graph, u: Int, v: Int)
  ensures: u >= 0 && u < g.n && v >= 0 && v < g.n => graph_has_edge(g, u, v)
{
  if u < 0 || u >= g.n || v < 0 || v >= g.n { return; }
  if graph_has_edge(g, u, v) { return; }
  graph_link(g, u, v);
}

/// Number of neighbors of node `u`.
pub fn graph_degree(g: &Graph, u: Int) -> Int
  ensures: result >= 0
{
  if u < 0 || u >= g.n { return 0; }
  var count = 0;
  var id = g.head[u];
  while id != -1 {
    count = count + 1;
    id = g.next[id];
  }
  return count;
}

/// A copy of the neighbors of node `u`.
pub fn graph_neighbors(g: &Graph, u: Int) -> Vec[Int]
  ensures: result.len() == graph_degree(g, u)
{
  var result = Vec[Int].new();
  if u < 0 || u >= g.n { return result; }
  var id = g.head[u];
  while id != -1 {
    result.push(g.to[id]);
    id = g.next[id];
  }
  return result;
}

/// Breadth-first traversal from `start`, in visited order.
pub fn graph_bfs(g: &Graph, start: Int) -> Vec[Int]
  ensures: start < 0 || start >= g.n => result.len() == 0
  ensures: result.len() <= g.n
{
  var result = Vec[Int].new();
  if start < 0 || start >= g.n { return result; }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  queue.push(start);
  visited[start] = true;
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    result.push(u);
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      if !visited[w] {
        visited[w] = true;
        queue.push(w);
      }
      id = g.next[id];
    }
  }
  return result;
}

/// Iterative depth-first traversal from `start`, in visited order.
pub fn graph_dfs(g: &Graph, start: Int) -> Vec[Int]
  ensures: start < 0 || start >= g.n => result.len() == 0
  ensures: result.len() <= g.n
{
  var result = Vec[Int].new();
  if start < 0 || start >= g.n { return result; }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var stack = Vec[Int].new();
  stack.push(start);
  while stack.len() > 0 {
    var u = stack[stack.len() - 1];
    stack.pop();
    if visited[u] { continue; }
    visited[u] = true;
    result.push(u);
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      if !visited[w] {
        stack.push(w);
      }
      id = g.next[id];
    }
  }
  return result;
}

/// Number of connected components in the graph.
pub fn graph_connected_components(g: &Graph) -> Int
  ensures: result >= 0
{
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var comps = 0;
  i = 0;
  while i < g.n {
    if !visited[i] {
      comps = comps + 1;
      var queue = Vec[Int].new();
      var head = 0;
      queue.push(i);
      visited[i] = true;
      while head < queue.len() {
        var u = queue[head];
        head = head + 1;
        var id = g.head[u];
        while id != -1 {
          var w = g.to[id];
          if !visited[w] {
            visited[w] = true;
            queue.push(w);
          }
          id = g.next[id];
        }
      }
    }
    i = i + 1;
  }
  return comps;
}

/// True if the (undirected) graph contains a cycle. Uses BFS with a parent
/// check: a visited neighbor that is not the current node's parent closes a
/// cycle.
pub fn graph_has_cycle(g: &Graph) -> Bool
  ensures: result == true => g.n >= 1
{
  var visited = Vec[Bool].new();
  var parent = Vec[Int].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    parent.push(-1);
    i = i + 1;
  }
  i = 0;
  while i < g.n {
    if !visited[i] {
      var queue = Vec[Int].new();
      var head = 0;
      queue.push(i);
      visited[i] = true;
      while head < queue.len() {
        var u = queue[head];
        head = head + 1;
        var id = g.head[u];
        while id != -1 {
          var w = g.to[id];
          if !visited[w] {
            visited[w] = true;
            parent[w] = u;
            queue.push(w);
          } elif w != parent[u] {
            return true;
          }
          id = g.next[id];
        }
      }
    }
    i = i + 1;
  }
  return false;
}

/// True if there is a path from `a` to `b` (BFS).
pub fn graph_path_exists(g: &Graph, a: Int, b: Int) -> Bool
  ensures: a == b && a >= 0 && a < g.n => result == true
{
  if a < 0 || a >= g.n || b < 0 || b >= g.n { return false; }
  if a == b { return true; }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  queue.push(a);
  visited[a] = true;
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      if w == b { return true; }
      if !visited[w] {
        visited[w] = true;
        queue.push(w);
      }
      id = g.next[id];
    }
  }
  return false;
}

/// Union-Find / Disjoint Set (Int elements)
/// `parent` stores each element's parent (root points at itself) and `rank`
/// stores the tree height for union-by-rank. `uf_find` applies path
/// compression; `uf_find_no_compress` is a read-only variant used by
/// `uf_connected` and `uf_count` so they can take an immutable reference.
pub type GraphUnionFind = {
  parent: Vec[Int];
  rank: Vec[Int];
}

/// Create a disjoint set with elements 0..n-1, each in its own set.
pub fn uf_new(n: Int) -> GraphUnionFind
  ensures: result.parent.len() == result.rank.len()
{
  var parent = Vec[Int].new();
  var rank = Vec[Int].new();
  var i = 0;
  while i < n {
    parent.push(i);
    rank.push(0);
    i = i + 1;
  }
  return GraphUnionFind{ parent: parent; rank: rank; };
}

/// Find the root of `x` (read-only, no path compression).
fn uf_find_no_compress(u: &GraphUnionFind, x: Int) -> Int {
  var cur = x;
  while cur < u.parent.len() && u.parent[cur] != cur {
    cur = u.parent[cur];
  }
  return cur;
}

/// Find the root of `x` with path compression.
pub fn uf_find(u: &mut GraphUnionFind, x: Int) -> Int
  ensures: x >= 0 && x < u.parent.len() => result >= 0
{
  var root = x;
  while root < u.parent.len() && u.parent[root] != root {
    root = u.parent[root];
  }
  var cur = x;
  while cur < u.parent.len() && u.parent[cur] != root {
    var nxt = u.parent[cur];
    u.parent[cur] = root;
    cur = nxt;
  }
  return root;
}

/// Merge the sets containing `a` and `b` (union by rank).
/// Returns true if the two sets were merged (i.e. previously disjoint).
pub fn uf_union(u: &mut GraphUnionFind, a: Int, b: Int) -> Bool
  ensures: a >= 0 && a < u.parent.len() && b >= 0 && b < u.parent.len() => uf_connected(u, a, b)
{
  var ra = uf_find(u, a);
  var rb = uf_find(u, b);
  if ra == rb { return false; }
  if u.rank[ra] < u.rank[rb] {
    u.parent[ra] = rb;
  } elif u.rank[ra] > u.rank[rb] {
    u.parent[rb] = ra;
  } else {
    u.parent[rb] = ra;
    u.rank[ra] = u.rank[ra] + 1;
  }
  return true;
}

/// True if `a` and `b` are in the same set.
pub fn uf_connected(u: &GraphUnionFind, a: Int, b: Int) -> Bool
  ensures: a == b => result == true
{
  var ra = uf_find_no_compress(u, a);
  var rb = uf_find_no_compress(u, b);
  return ra == rb;
}

/// Number of distinct roots (sets).
pub fn uf_count(u: &GraphUnionFind) -> Int
  ensures: result >= 0
{
  var seen = Vec[Int].new();
  var i = 0;
  while i < u.parent.len() {
    var r = uf_find_no_compress(u, i);
    var dup = false;
    var j = 0;
    while j < seen.len() {
      if seen[j] == r { dup = true; }
      j = j + 1;
    }
    if !dup {
      seen.push(r);
    }
    i = i + 1;
  }
  return seen.len();
}

// ============================================================================
// Parallel-edge (from/to Vec[Int]) surface
// ----------------------------------------------------------------------------
// Closure, reachability, depth and topological order over CALLER-OWNED edge
// vectors, for consumers that keep an edge list as two parallel Vec[Int]s
// (the packages wishlist shape; the struct-node Graph above is the
// alternative representation). Node ids are 0..n-1. Edge entries whose
// source or destination falls outside [0, n) are skipped, so a partially
// invalid edge list never traps; `from` and `to` are read up to the shorter
// of the two lengths. `max_depth` is a caller budget in hops: >= 0 caps the
// search depth, any negative value means unlimited. All routines are
// deterministic (BFS shortest-hop; smallest-index-first Kahn).
// ============================================================================

/// Build a flat adjacency arena (head/to/next) from parallel edge vectors.
/// Returns head (size max(n, 0)); the arena's `to`/`next` vectors are
/// appended to out_to/out_next. Only edges with both endpoints inside
/// [0, n) are kept. O(n + E).
fn _edge_arena(n: Int, from: &Vec[Int], to: &Vec[Int], out_to: &mut Vec[Int], out_next: &mut Vec[Int]) -> Vec[Int] {
  var head = Vec[Int].new();
  var i = 0;
  while i < n {
    head.push(-1);
    i = i + 1;
  }
  var m = from.len();
  if to.len() < m { m = to.len(); }
  var k = 0;
  while k < m {
    var u = from[k];
    var v = to[k];
    if u >= 0 && u < n && v >= 0 && v < n {
      out_to.push(v);
      out_next.push(head[u]);
      head[u] = out_to.len() - 1;
    }
    k = k + 1;
  }
  return head;
}

/// Shortest-hop distances from `start` over the parallel edge vectors:
/// result[v] is the number of edges on a shortest start -> v path, -1 when v
/// is unreachable or farther than `max_depth` (>= 0; negative = unlimited).
/// result[start] == 0 when start is inside [0, n); every entry is -1 when it
/// is not. O(n + E).
fn _edge_bfs_dist(n: Int, from: &Vec[Int], to: &Vec[Int], start: Int, max_depth: Int) -> Vec[Int] {
  var dist = Vec[Int].new();
  var i = 0;
  while i < n {
    dist.push(-1);
    i = i + 1;
  }
  if start < 0 || start >= n {
    return dist;
  }
  var to_a = Vec[Int].new();
  var next_a = Vec[Int].new();
  var head = _edge_arena(n, from, to, &mut to_a, &mut next_a);
  dist[start] = 0;
  var queue = Vec[Int].new();
  var qh = 0;
  queue.push(start);
  while qh < queue.len() {
    var u = queue[qh];
    qh = qh + 1;
    var du = dist[u];
    if max_depth >= 0 && du >= max_depth { continue; }
    var id = head[u];
    while id != -1 {
      var w = to_a[id];
      if dist[w] == -1 {
        dist[w] = du + 1;
        queue.push(w);
      }
      id = next_a[id];
    }
  }
  return dist;
}

/// True when `target` is reachable from `start` over the parallel edge
/// vectors within `max_depth` hops (start == target counts as reachable with
/// 0 hops). Out-of-range ids (or n <= 0) -> false. O(n + E).
pub fn graph_reaches(n: Int, from: &Vec[Int], to: &Vec[Int], start: Int, target: Int, max_depth: Int) -> Bool
  ensures: start < 0 || start >= n || target < 0 || target >= n => result == false
  ensures: start == target && start >= 0 && start < n => result == true
{
  if start < 0 || start >= n || target < 0 || target >= n {
    return false;
  }
  if start == target {
    return true;
  }
  var dist = _edge_bfs_dist(n, from, to, start, max_depth);
  return dist[target] != -1;
}

/// Transitive closure of `start`: every node reachable over one or more
/// edges within `max_depth` hops, in ascending node order. `start` itself is
/// not included (the zero-hop path); nodes on a cycle back to `start` are
/// still reachable and appear. Out-of-range start (or n <= 0) -> empty.
/// O(n + E).
pub fn graph_closure(n: Int, from: &Vec[Int], to: &Vec[Int], start: Int, max_depth: Int) -> Vec[Int]
  ensures: n >= 0 => result.len() <= n
  ensures: start < 0 || start >= n => result.len() == 0
{
  var out = Vec[Int].new();
  if n <= 0 || start < 0 || start >= n {
    return out;
  }
  var dist = _edge_bfs_dist(n, from, to, start, max_depth);
  var i = 0;
  while i < n {
    if dist[i] > 0 {
      out.push(i);
    }
    i = i + 1;
  }
  return out;
}

/// Reflexive-transitive closure over the parallel edge vectors as a flat
/// row-major Bool matrix of shape n x n: entry `u * n + v` is true when
/// v == u (zero-hop reflexivity) or v is reachable from u within `max_depth`
/// hops. n <= 0 -> empty. O(n * (n + E)).
pub fn graph_closure_matrix(n: Int, from: &Vec[Int], to: &Vec[Int], max_depth: Int) -> Vec[Bool]
  ensures: n <= 0 => result.len() == 0
  ensures: n > 0 => result.len() == n * n
{
  var out = Vec[Bool].new();
  if n <= 0 {
    return out;
  }
  var u = 0;
  while u < n {
    var dist = _edge_bfs_dist(n, from, to, u, max_depth);
    var v = 0;
    while v < n {
      out.push(dist[v] >= 0);
      v = v + 1;
    }
    u = u + 1;
  }
  return out;
}

/// Shortest-hop depth of every node from `start`: result[v] is the number of
/// edges on a shortest start -> v path, -1 for unreachable nodes and for
/// nodes farther than `max_depth` (>= 0; negative = unlimited);
/// result[start] == 0. Length is n (empty for n <= 0). O(n + E).
pub fn graph_depth(n: Int, from: &Vec[Int], to: &Vec[Int], start: Int, max_depth: Int) -> Vec[Int]
  ensures: n >= 0 => result.len() == n
{
  return _edge_bfs_dist(n, from, to, start, max_depth);
}

/// Shortest-hop depth from `start` to `target`; -1 when target is
/// unreachable, farther than `max_depth` hops, or either id is out of range.
/// start == target -> 0. O(n + E).
pub fn graph_depth_of(n: Int, from: &Vec[Int], to: &Vec[Int], start: Int, target: Int, max_depth: Int) -> Int
  ensures: start < 0 || start >= n || target < 0 || target >= n => result == -1
{
  if start < 0 || start >= n || target < 0 || target >= n {
    return -1;
  }
  var dist = _edge_bfs_dist(n, from, to, start, max_depth);
  return dist[target];
}

/// Kahn topological sort over the parallel edge vectors, deterministic:
/// among the currently source-free nodes the smallest node id is emitted
/// first. Duplicate edges and self-loops are honored as written (a self-loop
/// is a cycle). O(n^2 + E) (linear source scan per emitted node). Ok(order)
/// holds all n nodes when the graph is acyclic; Err(nodes) otherwise, where
/// `nodes` (ascending) lists every node left with nonzero remaining
/// indegree -- each node on a cycle plus every node that depends on one.
fn _topo_kahn(n: Int, from: &Vec[Int], to: &Vec[Int]) -> Result[Vec[Int], Vec[Int]] {
  var order = Vec[Int].new();
  if n <= 0 {
    return Ok(order);
  }
  var indeg = Vec[Int].new();
  var emitted = Vec[Bool].new();
  var i = 0;
  while i < n {
    indeg.push(0);
    emitted.push(false);
    i = i + 1;
  }
  var to_a = Vec[Int].new();
  var next_a = Vec[Int].new();
  var head = _edge_arena(n, from, to, &mut to_a, &mut next_a);
  i = 0;
  while i < n {
    var id = head[i];
    while id != -1 {
      var w = to_a[id];
      indeg[w] = indeg[w] + 1;
      id = next_a[id];
    }
    i = i + 1;
  }
  var steps = 0;
  while steps < n {
    var pick = -1;
    i = 0;
    while i < n {
      if !emitted[i] && indeg[i] == 0 {
        pick = i;
        break;
      }
      i = i + 1;
    }
    if pick == -1 {
      break;
    }
    emitted[pick] = true;
    order.push(pick);
    var id2 = head[pick];
    while id2 != -1 {
      var w2 = to_a[id2];
      indeg[w2] = indeg[w2] - 1;
      id2 = next_a[id2];
    }
    steps = steps + 1;
  }
  if order.len() == n {
    return Ok(order);
  }
  var cyc = Vec[Int].new();
  i = 0;
  while i < n {
    if !emitted[i] {
      cyc.push(i);
    }
    i = i + 1;
  }
  return Err(cyc);
}

/// Deterministic topological order of the parallel-edge graph (smallest
/// source id first): Some(order) with all n nodes when acyclic, None when a
/// cycle exists (use graph_topological_report for the cycle report).
/// n <= 0 -> Some(empty). O(n^2 + E).
pub fn graph_topological_sort(n: Int, from: &Vec[Int], to: &Vec[Int]) -> Option[Vec[Int]]
  ensures: n <= 0 => result.is_some == true
{
  if n <= 0 {
    return Some(Vec[Int].new());
  }
  match _topo_kahn(n, from, to) {
    Ok(order) => { return Some(order); },
    Err(_) => { return None; },
  }
}

/// Like graph_topological_sort but the cyclic case reports instead of
/// collapsing: Ok(order) for an acyclic graph, Err(nodes) otherwise with the
/// ascending ids that never reached indegree 0 (cycle members and their
/// dependents). n <= 0 -> Ok(empty). O(n^2 + E).
pub fn graph_topological_report(n: Int, from: &Vec[Int], to: &Vec[Int]) -> Result[Vec[Int], Vec[Int]]
  ensures: n <= 0 => result.is_ok == true
{
  return _topo_kahn(n, from, to);
}

/// True when the parallel-edge graph is acyclic (a topological sort covers
/// all n nodes). n <= 0 -> true. O(n^2 + E).
pub fn graph_is_dag(n: Int, from: &Vec[Int], to: &Vec[Int]) -> Bool
  ensures: n <= 0 => result == true
{
  if n <= 0 {
    return true;
  }
  var report = _topo_kahn(n, from, to);
  return report.is_ok;
}

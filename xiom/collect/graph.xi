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

// XIOM - Collections: Directed Acyclic Graph
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.dag

// Depends on: none

// ============================================================================
// Directed acyclic graph of Int node ids with topological ordering support.
//
// Flat-arena style (the same adjacency representation as collect.graph):
// `head[u]` is the first edge id leaving node u, `to[id]` the destination of
// edge id, `next[id]` the next edge id in the same list (-1 = none). Node ids
// are handed out by `dag_add_node` and never reused. `dag_add_edge` refuses
// to add an edge that would close a cycle (checked via reachability of `from`
// from `to`); `dag_has_cycle` runs a full topological sort. Reachability and
// traversal helpers are BFS based (O(V + E)). Out-of-range ids are rejected
// (no silent failure).
// ============================================================================

pub type Dag = {
  n: Int;
  head: Vec[Int];
  to: Vec[Int];
  next: Vec[Int];
}

/// Create a new empty DAG (no nodes).
/// O(1).
pub fn dag_new() -> Dag {
  return Dag{ n: 0; head: Vec[Int].new(); to: Vec[Int].new(); next: Vec[Int].new(); };
}

/// Add a node and return its id (0-based, monotonically increasing).
/// O(1).
pub fn dag_add_node(g: &mut Dag) -> Int
  ensures: result >= 0
{
  var id = g.n;
  g.head.push(-1);
  g.n = g.n + 1;
  return id;
}

/// True if the edge `from` -> `to` exists.
/// O(degree(from)).
pub fn dag_has_edge(g: &Dag, from: Int, to: Int) -> Bool {
  if from < 0 || from >= g.n {
    return false;
  }
  var id = g.head[from];
  while id != -1 {
    if g.to[id] == to {
      return true;
    }
    id = g.next[id];
  }
  return false;
}

fn _reachable(g: &Dag, src: Int, dst: Int) -> Bool {
  if src < 0 || src >= g.n || dst < 0 || dst >= g.n {
    return false;
  }
  if src == dst {
    return true;
  }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  queue.push(src);
  visited[src] = true;
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      if w == dst {
        return true;
      }
      if !visited[w] {
        visited[w] = true;
        queue.push(w);
      }
      id = g.next[id];
    }
  }
  return false;
}

/// Add a directed edge `from` -> `to`. Returns false if the ids are
/// out of range, if the edge already exists, or if adding it would close a
/// cycle (i.e. `to` can already reach `from`). True when the edge is newly
/// added. Self loops are rejected.
/// O(V + E) for the cycle check.
pub fn dag_add_edge(g: &mut Dag, from: Int, to: Int) -> Bool {
  if from < 0 || from >= g.n || to < 0 || to >= g.n {
    return false;
  }
  if from == to {
    return false;
  }
  if dag_has_edge(g, from, to) {
    return false;
  }
  if _reachable(g, to, from) {
    return false;
  }
  var id = g.to.len();
  g.to.push(to);
  g.next.push(g.head[from]);
  g.head[from] = id;
  return true;
}

/// All transitive predecessors of `node` (nodes u != node with a path
/// u -> ... -> node). Order is BFS order over the reversed edges.
/// O(V + E).
pub fn dag_ancestors(g: &Dag, node: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if node < 0 || node >= g.n {
    return out;
  }
  var rev_head = Vec[Int].new();
  var i = 0;
  while i < g.n {
    rev_head.push(-1);
    i = i + 1;
  }
  var rev_to = Vec[Int].new();
  var rev_next = Vec[Int].new();
  i = 0;
  while i < g.n {
    var id = g.head[i];
    while id != -1 {
      var v = g.to[id];
      rev_to.push(i);
      rev_next.push(rev_head[v]);
      rev_head[v] = rev_to.len() - 1;
      id = g.next[id];
    }
    i = i + 1;
  }
  var visited = Vec[Bool].new();
  i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  queue.push(node);
  visited[node] = true;
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    var id = rev_head[u];
    while id != -1 {
      var w = rev_to[id];
      if !visited[w] {
        visited[w] = true;
        out.push(w);
        queue.push(w);
      }
      id = rev_next[id];
    }
  }
  return out;
}

/// All transitive successors of `node` (nodes v != node with a path
/// node -> ... -> v). Order is BFS order.
/// O(V + E).
pub fn dag_descendants(g: &Dag, node: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if node < 0 || node >= g.n {
    return out;
  }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  queue.push(node);
  visited[node] = true;
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      if !visited[w] {
        visited[w] = true;
        out.push(w);
        queue.push(w);
      }
      id = g.next[id];
    }
  }
  return out;
}

/// A topological ordering of all nodes (Kahn's algorithm). If the graph
/// contains a cycle, the returned order is partial (the cyclic nodes are
/// omitted).
/// O(V + E).
pub fn dag_topological_order(g: &Dag) -> Vec[Int] {
  var indeg = Vec[Int].new();
  var i = 0;
  while i < g.n {
    indeg.push(0);
    i = i + 1;
  }
  i = 0;
  while i < g.n {
    var id = g.head[i];
    while id != -1 {
      indeg[g.to[id]] = indeg[g.to[id]] + 1;
      id = g.next[id];
    }
    i = i + 1;
  }
  var queue = Vec[Int].new();
  var head = 0;
  i = 0;
  while i < g.n {
    if indeg[i] == 0 {
      queue.push(i);
    }
    i = i + 1;
  }
  var out = Vec[Int].new();
  while head < queue.len() {
    var u = queue[head];
    head = head + 1;
    out.push(u);
    var id = g.head[u];
    while id != -1 {
      var w = g.to[id];
      indeg[w] = indeg[w] - 1;
      if indeg[w] == 0 {
        queue.push(w);
      }
      id = g.next[id];
    }
  }
  return out;
}

/// Check whether the graph contains a cycle (a topological sort covers all
/// nodes iff the graph is acyclic).
/// O(V + E).
pub fn dag_has_cycle(g: &Dag) -> Bool {
  var topo = dag_topological_order(g);
  return topo.len() < g.n;
}

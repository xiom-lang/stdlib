// XIOM - Math: Graph Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.graph_theory

// Depends on: none

// ============================================================================
// Graph algorithms: construction, traversal, shortest paths, spanning trees,
// connectivity, and hard combinatorial problems.
//
// Graph is an edge-list graph: vertices are the integers [0, n - 1] (n grows
// automatically on add). Edges are stored as (u, v) pairs with a parallel
// scaled-integer weight vector (1 unit = 1e-5) — the representation avoids
// nested float Vec and 3-tuple element reads, which are unreliable in this
// compiler build (BUG 23 #1 residual; see the smoke notes). Undirected
// graphs store both directions. Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;
use xiom.core.to_float;

const _INF: Float64 = 1.0e300;
const _WSCALE: Int = 100000;

// A graph: n vertices (implicitly 0..n-1), an edge list of (u, v) pairs, a
// parallel weight list (scaled by 1e5), and a directedness flag.
pub type Graph = {
  n: Int;
  edges: Vec[(Int, Int)];
  weights: Vec[Int];
  directed: Bool;
}

// Create an empty graph. Complexity: O(1).
pub fn graph_new() -> Graph {
  return Graph{ n: 0, edges: Vec[(Int, Int)].new(), weights: Vec[Int].new(), directed: false };
}

// Add vertex v (grows n to v + 1; vertices are implicit ids). Returns true.
// Complexity: O(v - n).
pub fn graph_add_vertex(g: &mut Graph, v: Int) -> Bool {
  if v < 0 { return false; }
  while g.n <= v {
    g.n = g.n + 1;
  }
  return true;
}

// Add an unweighted edge (u, v) (weight 1.0). Adds the vertices first; an
// undirected graph also stores the reverse edge. Returns false for negative
// ids. Complexity: O(1) amortized.
pub fn graph_add_edge(g: &mut Graph, u: Int, v: Int) -> Bool {
  return graph_add_weighted_edge(g, u, v, 1.0);
}

// Add a weighted edge (u, v) with weight w (rounded to 1e-5 resolution).
// Complexity: O(1) amortized.
pub fn graph_add_weighted_edge(g: &mut Graph, u: Int, v: Int, w: Float64) -> Bool {
  if u < 0 || v < 0 { return false; }
  if w != w { return false; }
  graph_add_vertex(g, u);
  graph_add_vertex(g, v);
  var wi = to_int(w * (_WSCALE as Float64));
  g.edges.push((u, v));
  g.weights.push(wi);
  if !g.directed {
    g.edges.push((v, u));
    g.weights.push(wi);
  }
  return true;
}

// Remove vertex v and all incident edges. Returns false when v is absent.
// Complexity: O(edges).
pub fn graph_remove_vertex(g: &mut Graph, v: Int) -> Bool {
  if v < 0 || v >= g.n { return false; }
  var keep = Vec[(Int, Int)].new();
  var keepw = Vec[Int].new();
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    if e.0 != v && e.1 != v {
      keep.push(e);
      keepw.push(g.weights[i]);
    }
    i = i + 1;
  }
  g.edges = keep;
  g.weights = keepw;
  return true;
}

// Remove the edge (u, v); an undirected graph removes the reverse too.
// Returns false when no such edge exists. Complexity: O(edges).
pub fn graph_remove_edge(g: &mut Graph, u: Int, v: Int) -> Bool {
  var found = false;
  var keep = Vec[(Int, Int)].new();
  var keepw = Vec[Int].new();
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    var rm = false;
    if e.0 == u && e.1 == v {
      rm = true;
    }
    if !g.directed {
      if e.0 == v && e.1 == u {
        rm = true;
      }
    }
    if rm {
      found = true;
    } else {
      keep.push(e);
      keepw.push(g.weights[i]);
    }
    i = i + 1;
  }
  g.edges = keep;
  g.weights = keepw;
  return found;
}

// Whether v is present. Complexity: O(1).
pub fn graph_has_vertex(g: &Graph, v: Int) -> Bool {
  return v >= 0 && v < g.n;
}

// Whether the edge (u, v) is present (either direction for undirected).
// Complexity: O(edges).
pub fn graph_has_edge(g: &Graph, u: Int, v: Int) -> Bool {
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    if e.0 == u && e.1 == v {
      return true;
    }
    i = i + 1;
  }
  return false;
}

// Degree of vertex v (undirected degree counts once per incident edge).
// Complexity: O(edges).
pub fn graph_degree(g: &Graph, v: Int) -> Int {
  if v < 0 || v >= g.n { return 0; }
  var count = 0;
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    if e.0 == v {
      count = count + 1;
    } else {
      if g.directed {
        if e.1 == v {
          count = count + 1;
        }
      }
    }
    i = i + 1;
  }
  return count;
}

// All vertices as ids [0, n - 1]. Complexity: O(n).
pub fn graph_vertices(g: &Graph) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < g.n {
    out.push(i);
    i = i + 1;
  }
  return out;
}

// All edges as (u, v) pairs (duplicated pairs for undirected graphs, one per
// stored direction). Complexity: O(edges).
pub fn graph_edges(g: &Graph) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    out.push((e.0, e.1));
    i = i + 1;
  }
  return out;
}

// Whether u and v are neighbors. Complexity: O(edges).
pub fn graph_adjacent(g: &Graph, u: Int, v: Int) -> Bool {
  return graph_has_edge(g, u, v);
}

// Rebuild a flat adjacency list (as Vec[Vec[Int]], which is readable in this
// compiler build) from the edge list.
fn _adj(g: &Graph) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var i = 0;
  while i < g.n {
    out.push(Vec[Int].new());
    i = i + 1;
  }
  var e = 0;
  while e < g.edges.len() {
    var edge = g.edges[e];
    if edge.0 >= 0 && edge.0 < g.n {
      out[edge.0].push(edge.1);
    }
    e = e + 1;
  }
  return out;
}

// Weight of edge index i as a Float64.
fn _weight(g: &Graph, i: Int) -> Float64 {
  var wi = g.weights[i];
  return (wi as Float64) / (_WSCALE as Float64);
}

// Depth-first vertex order from start. Returns the empty vector for a start
// outside the graph. Complexity: O(V + E).
pub fn graph_dfs(g: &Graph, start: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if start < 0 || start >= g.n { return out; }
  var adj = _adj(g);
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var stack = Vec[Int].new();
  stack.push(start);
  while stack.len() > 0 {
    var v = stack[stack.len() - 1];
    stack.pop();
    if !visited[v] {
      visited[v] = true;
      out.push(v);
      var j = 0;
      while j < adj[v].len() {
        var nb = adj[v][adj[v].len() - 1 - j];
        if !visited[nb] {
          stack.push(nb);
        }
        j = j + 1;
      }
    }
  }
  return out;
}

// Breadth-first vertex order from start. Complexity: O(V + E).
pub fn graph_bfs(g: &Graph, start: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if start < 0 || start >= g.n { return out; }
  var adj = _adj(g);
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var queue = Vec[Int].new();
  queue.push(start);
  visited[start] = true;
  var head = 0;
  while head < queue.len() {
    var v = queue[head];
    head = head + 1;
    out.push(v);
    var j = 0;
    while j < adj[v].len() {
      var nb = adj[v][j];
      if !visited[nb] {
        visited[nb] = true;
        queue.push(nb);
      }
      j = j + 1;
    }
  }
  return out;
}

// Shortest-path distances from source via Dijkstra's algorithm (edge-list
// scanning; O(V^2 + E) worst case). Unreachable vertices get _INF.
// Complexity: O(V^2 + E).
pub fn graph_dijkstra(g: &Graph, source: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if source < 0 || source >= g.n { return out; }
  var dist = Vec[Float64].new();
  var done = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    dist.push(_INF);
    done.push(false);
    i = i + 1;
  }
  dist[source] = 0.0;
  var iter = 0;
  while iter < g.n {
    var u = -1;
    var best = _INF;
    var j = 0;
    while j < g.n {
      if !done[j] && dist[j] < best {
        best = dist[j];
        u = j;
      }
      j = j + 1;
    }
    if u < 0 { iter = g.n; }
    else {
      done[u] = true;
      var e = 0;
      while e < g.edges.len() {
        var edge = g.edges[e];
        if edge.0 == u && !done[edge.1] {
          var w = _weight(g, e);
          var nd = dist[u] + w;
          if nd < dist[edge.1] {
            dist[edge.1] = nd;
          }
        }
        e = e + 1;
      }
    }
    iter = iter + 1;
  }
  var k = 0;
  while k < g.n {
    out.push(dist[k]);
    k = k + 1;
  }
  return out;
}

// Shortest-path distances from source via Bellman-Ford; None when a negative
// cycle is reachable. Complexity: O(V * E).
pub fn graph_bellman_ford(g: &Graph, source: Int) -> Option[Vec[Float64]] {
  if source < 0 || source >= g.n {
    return Option[Vec[Float64]]{ is_some: false, value: Vec[Float64].new() };
  }
  var dist = Vec[Float64].new();
  var i = 0;
  while i < g.n {
    dist.push(_INF);
    i = i + 1;
  }
  dist[source] = 0.0;
  var pass = 1;
  while pass < g.n {
    var changed = false;
    var e = 0;
    while e < g.edges.len() {
      var edge = g.edges[e];
      if dist[edge.0] < _INF {
        var w = _weight(g, e);
        var nd = dist[edge.0] + w;
        if nd < dist[edge.1] {
          dist[edge.1] = nd;
          changed = true;
        }
      }
      e = e + 1;
    }
    if !changed { pass = g.n; }
    pass = pass + 1;
  }
  var neg = false;
  var e2 = 0;
  while e2 < g.edges.len() {
    var edge = g.edges[e2];
    if dist[edge.0] < _INF {
      var w2 = _weight(g, e2);
      if dist[edge.0] + w2 < dist[edge.1] {
        neg = true;
      }
    }
    e2 = e2 + 1;
  }
  if neg {
    return Option[Vec[Float64]]{ is_some: false, value: Vec[Float64].new() };
  }
  return Option[Vec[Float64]]{ is_some: true, value: dist };
}

// All-pairs shortest-path distances via repeated Bellman-Ford-style edge
// relaxation from every source. The result is a Vec[Vec[Float64]] distance
// matrix (callers can only rely on its shape; element reads of module-returned
// nested float Vecs are unreliable in this compiler build). Complexity: O(V^2 * E).
pub fn graph_floyd_warshall(g: &Graph) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var s = 0;
  while s < g.n {
    var row = Vec[Float64].new();
    var t = 0;
    while t < g.n {
      row.push(0.0);
      t = t + 1;
    }
    out.push(row);
    s = s + 1;
  }
  var src = 0;
  while src < g.n {
    var dist = Vec[Float64].new();
    var i = 0;
    while i < g.n {
      dist.push(_INF);
      i = i + 1;
    }
    dist[src] = 0.0;
    var pass = 1;
    while pass < g.n {
      var e = 0;
      while e < g.edges.len() {
        var edge = g.edges[e];
        if dist[edge.0] < _INF {
          var w = _weight(g, e);
          var nd = dist[edge.0] + w;
          if nd < dist[edge.1] {
            dist[edge.1] = nd;
          }
        }
        e = e + 1;
      }
      pass = pass + 1;
    }
    var row2 = Vec[Float64].new();
    var j = 0;
    while j < g.n {
      row2.push(dist[j]);
      j = j + 1;
    }
    out.push(row2);
    src = src + 1;
  }
  return out;
}

// A* path from start to goal using the heuristic h(vertex, goal); returns the
// vertex sequence (inclusive) or None when no path exists. Complexity:
// O(V^2 + E) (linear scan open set).
pub fn graph_astar(g: &Graph, start: Int, goal: Int, h: fn(Int, Int) -> Float64) -> Option[Vec[Int]] {
  if start < 0 || start >= g.n || goal < 0 || goal >= g.n {
    return Option[Vec[Int]]{ is_some: false, value: Vec[Int].new() };
  }
  var gscore = Vec[Float64].new();
  var fscore = Vec[Float64].new();
  var came = Vec[Int].new();
  var closed = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    gscore.push(_INF);
    fscore.push(_INF);
    came.push(-1);
    closed.push(false);
    i = i + 1;
  }
  gscore[start] = 0.0;
  var hs = h(start, goal);
  fscore[start] = hs;
  var open = Vec[Int].new();
  open.push(start);
  while open.len() > 0 {
    var best_idx = 0;
    var b = 1;
    while b < open.len() {
      if fscore[open[b]] < fscore[open[best_idx]] {
        best_idx = b;
      }
      b = b + 1;
    }
    var cur = open[best_idx];
    open.remove(best_idx);
    if cur == goal {
      var path = Vec[Int].new();
      var node = cur;
      while node != -1 {
        path.push(node);
        node = came[node];
      }
      var rev = Vec[Int].new();
      var k = path.len() - 1;
      while k >= 0 {
        rev.push(path[k]);
        k = k - 1;
      }
      return Option[Vec[Int]]{ is_some: true, value: rev };
    }
    if closed[cur] {
      open.clear();
    } else {
      closed[cur] = true;
      var e = 0;
      while e < g.edges.len() {
        var edge = g.edges[e];
        if edge.0 == cur && !closed[edge.1] {
          var w = _weight(g, e);
          var tentative = gscore[cur] + w;
          if tentative < gscore[edge.1] {
            came[edge.1] = cur;
            gscore[edge.1] = tentative;
            var hh = h(edge.1, goal);
            fscore[edge.1] = tentative + hh;
            open.push(edge.1);
          }
        }
        e = e + 1;
      }
    }
  }
  return Option[Vec[Int]]{ is_some: false, value: Vec[Int].new() };
}

// Minimum spanning tree edges by Prim's algorithm (edge-list scanning);
// None for a disconnected or empty graph. Complexity: O(V^2 + E).
pub fn graph_prim(g: &Graph) -> Option[Vec[(Int, Int)]] {
  var out = Vec[(Int, Int)].new();
  if g.n == 0 { return Option[Vec[(Int, Int)]]{ is_some: false, value: out }; }
  var in_tree = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    in_tree.push(false);
    i = i + 1;
  }
  in_tree[0] = true;
  var added = 1;
  while added < g.n {
    var best_u = -1;
    var best_v = -1;
    var best_w = _INF;
    var e = 0;
    while e < g.edges.len() {
      var edge = g.edges[e];
      if in_tree[edge.0] && !in_tree[edge.1] {
        var w = _weight(g, e);
        if w < best_w {
          best_w = w;
          best_u = edge.0;
          best_v = edge.1;
        }
      }
      e = e + 1;
    }
    if best_u < 0 {
      return Option[Vec[(Int, Int)]]{ is_some: false, value: out };
    }
    in_tree[best_v] = true;
    out.push((best_u, best_v));
    added = added + 1;
  }
  return Option[Vec[(Int, Int)]]{ is_some: true, value: out };
}

// Minimum spanning tree edges by Kruskal's algorithm (union-find with
// min-weight edge selection; compares scaled-integer weights directly).
// None for a disconnected graph. Complexity: O(V * E).
pub fn graph_kruskal(g: &Graph) -> Option[Vec[(Int, Int)]] {
  var out = Vec[(Int, Int)].new();
  if g.n == 0 { return Option[Vec[(Int, Int)]]{ is_some: false, value: out }; }
  var parent = Vec[Int].new();
  var j = 0;
  while j < g.n {
    parent.push(j);
    j = j + 1;
  }
  var count = 0;
  while count < g.n - 1 {
    var best_u = -1;
    var best_v = -1;
    var best_w = 9007199254740991;
    var e = 0;
    while e < g.edges.len() {
      var edge = g.edges[e];
      var ru = _find(&parent, edge.0);
      var rv = _find(&parent, edge.1);
      if ru != rv && g.weights[e] < best_w {
        best_w = g.weights[e];
        best_u = edge.0;
        best_v = edge.1;
      }
      e = e + 1;
    }
    if best_u < 0 {
      return Option[Vec[(Int, Int)]]{ is_some: false, value: out };
    }
    var ru2 = _find(&parent, best_u);
    var rv2 = _find(&parent, best_v);
    parent[ru2] = rv2;
    out.push((best_u, best_v));
    count = count + 1;
  }
  return Option[Vec[(Int, Int)]]{ is_some: true, value: out };
}

// Union-find find with path halving.
fn _find(parent: &Vec[Int], x: Int) -> Int {
  var r = x;
  while parent[r] != r {
    r = parent[r];
  }
  return r;
}

// Strongly connected components by Tarjan's algorithm (iterative). Each
// component is one inner vector. Complexity: O(V + E).
pub fn graph_tarjan_scc(g: &Graph) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if g.n == 0 { return out; }
  var adj = _adj(g);
  var index = Vec[Int].new();
  var lowlink = Vec[Int].new();
  var onstack = Vec[Bool].new();
  var stack = Vec[Int].new();
  var i = 0;
  while i < g.n {
    index.push(-1);
    lowlink.push(-1);
    onstack.push(false);
    i = i + 1;
  }
  var counter = 0;
  var v = 0;
  while v < g.n {
    if index[v] == -1 {
      counter = _tarjan_visit(g, &adj, &mut index, &mut lowlink, &mut onstack, &mut stack, v, counter, &mut out);
    }
    v = v + 1;
  }
  return out;
}

// One Tarjan visit (iterative with an explicit stack of (vertex, edge index)).
fn _tarjan_visit(g: &Graph, adj: &Vec[Vec[Int]], index: &mut Vec[Int], lowlink: &mut Vec[Int],
                 onstack: &mut Vec[Bool], stack: &mut Vec[Int], start: Int, counter: Int, out: &mut Vec[Vec[Int]]) -> Int {
  var c = counter;
  var work = Vec[Int].new();
  var ei = Vec[Int].new();
  work.push(start);
  ei.push(0);
  index[start] = c;
  lowlink[start] = c;
  c = c + 1;
  stack.push(start);
  onstack[start] = true;
  while work.len() > 0 {
    var v = work[work.len() - 1];
    var e = ei[ei.len() - 1];
    if e < adj[v].len() {
      var nb = adj[v][e];
      ei[ei.len() - 1] = e + 1;
      if index[nb] == -1 {
        index[nb] = c;
        lowlink[nb] = c;
        c = c + 1;
        stack.push(nb);
        onstack[nb] = true;
        work.push(nb);
        ei.push(0);
      } else {
        if onstack[nb] && index[nb] < lowlink[v] {
          lowlink[v] = index[nb];
        }
      }
    } else {
      if work.len() > 1 {
        var pv = work[work.len() - 2];
        if lowlink[v] < lowlink[pv] {
          lowlink[pv] = lowlink[v];
        }
      }
      if lowlink[v] == index[v] {
        var comp = Vec[Int].new();
        var keep = true;
        while keep {
          var w = stack[stack.len() - 1];
          stack.pop();
          onstack[w] = false;
          comp.push(w);
          if w == v {
            keep = false;
          }
        }
        out.push(comp);
      }
      work.pop();
      ei.pop();
    }
  }
  return c;
}

// Strongly connected components by Kosaraju's algorithm (two DFS passes).
// Complexity: O(V + E).
pub fn graph_kosaraju_scc(g: &Graph) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if g.n == 0 { return out; }
  var adj = _adj(g);
  var radj = Vec[Vec[Int]].new();
  var i = 0;
  while i < g.n {
    radj.push(Vec[Int].new());
    i = i + 1;
  }
  var e = 0;
  while e < g.edges.len() {
    var edge = g.edges[e];
    if edge.1 >= 0 && edge.1 < g.n {
      radj[edge.1].push(edge.0);
    }
    e = e + 1;
  }
  var visited = Vec[Bool].new();
  var order = Vec[Int].new();
  var j = 0;
  while j < g.n {
    visited.push(false);
    j = j + 1;
  }
  var v = 0;
  while v < g.n {
    if !visited[v] {
      _kosaraju_pass1(&adj, &mut visited, &mut order, v);
    }
    v = v + 1;
  }
  var visited2 = Vec[Bool].new();
  var k = 0;
  while k < g.n {
    visited2.push(false);
    k = k + 1;
  }
  var idx = order.len() - 1;
  while idx >= 0 {
    var node = order[idx];
    if !visited2[node] {
      var comp = Vec[Int].new();
      _kosaraju_pass2(&radj, &mut visited2, node, &mut comp);
      out.push(comp);
    }
    idx = idx - 1;
  }
  return out;
}

// First Kosaraju pass: fill finish order.
fn _kosaraju_pass1(adj: &Vec[Vec[Int]], visited: &mut Vec[Bool], order: &mut Vec[Int], start: Int) {
  var stack = Vec[Int].new();
  stack.push(start);
  visited[start] = true;
  while stack.len() > 0 {
    var v = stack[stack.len() - 1];
    var progressed = false;
    var i = 0;
    while i < adj[v].len() {
      var nb = adj[v][i];
      if !visited[nb] {
        visited[nb] = true;
        stack.push(nb);
        progressed = true;
        i = adj[v].len();
      }
      i = i + 1;
    }
    if !progressed {
      order.push(v);
      stack.pop();
    }
  }
}

// Second Kosaraju pass: collect components on the reversed graph.
fn _kosaraju_pass2(radj: &Vec[Vec[Int]], visited: &mut Vec[Bool], start: Int, comp: &mut Vec[Int]) {
  var stack = Vec[Int].new();
  stack.push(start);
  visited[start] = true;
  while stack.len() > 0 {
    var v = stack[stack.len() - 1];
    stack.pop();
    comp.push(v);
    var i = 0;
    while i < radj[v].len() {
      var nb = radj[v][i];
      if !visited[nb] {
        visited[nb] = true;
        stack.push(nb);
      }
      i = i + 1;
    }
  }
}

// Linear ordering of a directed acyclic graph (Kahn's algorithm); None when
// the graph has a cycle. Complexity: O(V + E).
pub fn graph_topological_sort(g: &Graph) -> Option[Vec[Int]] {
  var out = Vec[Int].new();
  if g.n == 0 {
    return Option[Vec[Int]]{ is_some: true, value: out };
  }
  var indeg = Vec[Int].new();
  var i = 0;
  while i < g.n {
    indeg.push(0);
    i = i + 1;
  }
  var e = 0;
  while e < g.edges.len() {
    var edge = g.edges[e];
    if edge.1 >= 0 && edge.1 < g.n {
      indeg[edge.1] = indeg[edge.1] + 1;
    }
    e = e + 1;
  }
  var queue = Vec[Int].new();
  var j = 0;
  while j < g.n {
    if indeg[j] == 0 {
      queue.push(j);
    }
    j = j + 1;
  }
  var head = 0;
  while head < queue.len() {
    var v = queue[head];
    head = head + 1;
    out.push(v);
    var k = 0;
    while k < g.edges.len() {
      var edge = g.edges[k];
      if edge.0 == v {
        indeg[edge.1] = indeg[edge.1] - 1;
        if indeg[edge.1] == 0 {
          queue.push(edge.1);
        }
      }
      k = k + 1;
    }
  }
  if out.len() != g.n {
    return Option[Vec[Int]]{ is_some: false, value: Vec[Int].new() };
  }
  return Option[Vec[Int]]{ is_some: true, value: out };
}

// Whether the graph is connected (a single BFS reaches every vertex).
// Complexity: O(V + E).
pub fn graph_is_connected(g: &Graph) -> Bool {
  if g.n <= 1 { return true; }
  var bfs = graph_bfs(g, 0);
  return bfs.len() == g.n;
}

// Whether the graph contains a cycle (DFS with colors; undirected uses the
// parent check). Complexity: O(V + E).
pub fn graph_is_cyclic(g: &Graph) -> Bool {
  if g.n == 0 { return false; }
  var adj = _adj(g);
  var color = Vec[Int].new();
  var i = 0;
  while i < g.n {
    color.push(0);
    i = i + 1;
  }
  var v = 0;
  while v < g.n {
    if color[v] == 0 {
      if _has_cycle(&adj, &mut color, v, -1) {
        return true;
      }
    }
    v = v + 1;
  }
  return false;
}

// Iterative DFS cycle detection.
fn _has_cycle(adj: &Vec[Vec[Int]], color: &mut Vec[Int], start: Int, parent: Int) -> Bool {
  var stack = Vec[Int].new();
  var pstack = Vec[Int].new();
  stack.push(start);
  pstack.push(parent);
  while stack.len() > 0 {
    var v = stack[stack.len() - 1];
    var p = pstack[pstack.len() - 1];
    stack.pop();
    pstack.pop();
    color[v] = 1;
    var i = 0;
    while i < adj[v].len() {
      var nb = adj[v][i];
      if color[nb] == 0 {
        stack.push(nb);
        pstack.push(v);
      } else {
        if color[nb] == 1 && nb != p {
          return true;
        }
      }
      i = i + 1;
    }
  }
  return false;
}

// Whether the vertices split into two independent sets (BFS 2-coloring).
// Complexity: O(V + E).
pub fn graph_is_bipartite(g: &Graph) -> Bool {
  if g.n == 0 { return true; }
  var adj = _adj(g);
  var color = Vec[Int].new();
  var i = 0;
  while i < g.n {
    color.push(-1);
    i = i + 1;
  }
  var v = 0;
  while v < g.n {
    if color[v] == -1 {
      color[v] = 0;
      var queue = Vec[Int].new();
      queue.push(v);
      var head = 0;
      while head < queue.len() {
        var u = queue[head];
        head = head + 1;
        var j = 0;
        while j < adj[u].len() {
          var nb = adj[u][j];
          if color[nb] == -1 {
            color[nb] = 1 - color[u];
            queue.push(nb);
          } else {
            if color[nb] == color[u] {
              return false;
            }
          }
          j = j + 1;
        }
      }
    }
    v = v + 1;
  }
  return true;
}

// Whether g1 and g2 are isomorphic. Checks vertex count, edge count, and
// degree sequence; for n <= 6 an exact permutation test is performed.
// Complexity: O(n! * n^2) for small n, O(n^2) otherwise.
pub fn graph_isomorphic(g1: &Graph, g2: &Graph) -> Bool {
  if g1.n != g2.n { return false; }
  if g1.edges.len() != g2.edges.len() { return false; }
  var deg1 = Vec[Int].new();
  var deg2 = Vec[Int].new();
  var i = 0;
  while i < g1.n {
    deg1.push(graph_degree(g1, i));
    deg2.push(graph_degree(g2, i));
    i = i + 1;
  }
  _sort_int(&mut deg1);
  _sort_int(&mut deg2);
  var j = 0;
  while j < deg1.len() {
    if deg1[j] != deg2[j] {
      return false;
    }
    j = j + 1;
  }
  if g1.n > 6 { return true; }
  var vertices = Vec[Int].new();
  var k = 0;
  while k < g1.n {
    vertices.push(k);
    k = k + 1;
  }
  var perms = math.combinatorics.permutations_enum(&vertices);
  var p = 0;
  while p < perms.len() {
    if _perm_is_iso(g1, g2, &perms[p]) {
      return true;
    }
    p = p + 1;
  }
  return false;
}

// Sort an Int vector ascending.
fn _sort_int(v: &mut Vec[Int]) {
  var n = v.len();
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      if v[j] < v[j - 1] {
        var t = v[j];
        v[j] = v[j - 1];
        v[j - 1] = t;
        j = j - 1;
      } else {
        j = 0;
      }
    }
    i = i + 1;
  }
}

// Whether perm is an isomorphism from g1 to g2.
fn _perm_is_iso(g1: &Graph, g2: &Graph, perm: &Vec[Int]) -> Bool {
  var a = 0;
  while a < g1.edges.len() {
    var e = g1.edges[a];
    var fu = perm[e.0];
    var fv = perm[e.1];
    if !graph_has_edge(g2, fu, fv) {
      return false;
    }
    a = a + 1;
  }
  return true;
}

// Greedy vertex coloring (smallest available color per vertex in id order).
// Returns one color per vertex (0-based). Complexity: O(V * E).
pub fn graph_color(g: &Graph) -> Vec[Int] {
  var out = Vec[Int].new();
  var adj = _adj(g);
  var i = 0;
  while i < g.n {
    var used = Vec[Bool].new();
    var c = 0;
    while c < g.n + 1 {
      used.push(false);
      c = c + 1;
    }
    var j = 0;
    while j < adj[i].len() {
      var nb = adj[i][j];
      if nb < out.len() {
        used[out[nb]] = true;
      }
      j = j + 1;
    }
    var chosen = 0;
    var found = true;
    while found {
      if used[chosen] {
        chosen = chosen + 1;
      } else {
        found = false;
      }
    }
    out.push(chosen);
    i = i + 1;
  }
  return out;
}

// Maximum flow from s to t by Edmonds-Karp (BFS augmenting paths) over the
// edge list with parallel residual-capacity tracking. Complexity: O(V * E^2).
pub fn graph_max_flow(g: &Graph, s: Int, t: Int) -> Float64 {
  if s < 0 || s >= g.n || t < 0 || t >= g.n || s == t { return 0.0; }
  var cap = Vec[Float64].new();
  var eu = Vec[Int].new();
  var ev = Vec[Int].new();
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    eu.push(e.0);
    ev.push(e.1);
    cap.push(_weight(g, i));
    i = i + 1;
  }
  var total = 0.0;
  var augment = true;
  while augment {
    var pred = Vec[Int].new();
    var pedge = Vec[Int].new();
    var j = 0;
    while j < g.n {
      pred.push(-1);
      pedge.push(-1);
      j = j + 1;
    }
    var queue = Vec[Int].new();
    queue.push(s);
    pred[s] = s;
    var head = 0;
    var reached = false;
    while head < queue.len() && !reached {
      var u = queue[head];
      head = head + 1;
      var e2 = 0;
      while e2 < cap.len() {
        if eu[e2] == u && cap[e2] > 0.0 && pred[ev[e2]] == -1 {
          pred[ev[e2]] = u;
          pedge[ev[e2]] = e2;
          queue.push(ev[e2]);
          if ev[e2] == t {
            reached = true;
            e2 = cap.len();
          }
        }
        e2 = e2 + 1;
      }
    }
    if !reached {
      augment = false;
    } else {
      var bottleneck = _INF;
      var node = t;
      while node != s {
        var ei = pedge[node];
        if cap[ei] < bottleneck {
          bottleneck = cap[ei];
        }
        node = pred[node];
      }
      node = t;
      while node != s {
        var ei = pedge[node];
        cap[ei] = cap[ei] - bottleneck;
        node = pred[node];
      }
      total = total + bottleneck;
    }
  }
  return total;
}

// Minimum s-t cut: the vertices reachable from s in the residual graph after
// the maximum flow (the S side of the min cut). Complexity: O(V * E^2).
pub fn graph_min_cut(g: &Graph, s: Int, t: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if s < 0 || s >= g.n || t < 0 || t >= g.n { return out; }
  var cap = Vec[Float64].new();
  var eu = Vec[Int].new();
  var ev = Vec[Int].new();
  var i = 0;
  while i < g.edges.len() {
    var e = g.edges[i];
    eu.push(e.0);
    ev.push(e.1);
    cap.push(_weight(g, i));
    i = i + 1;
  }
  var augment = true;
  while augment {
    var pred = Vec[Int].new();
    var pedge = Vec[Int].new();
    var j = 0;
    while j < g.n {
      pred.push(-1);
      pedge.push(-1);
      j = j + 1;
    }
    var queue = Vec[Int].new();
    queue.push(s);
    pred[s] = s;
    var head = 0;
    var reached = false;
    while head < queue.len() && !reached {
      var u = queue[head];
      head = head + 1;
      var e2 = 0;
      while e2 < cap.len() {
        if eu[e2] == u && cap[e2] > 0.0 && pred[ev[e2]] == -1 {
          pred[ev[e2]] = u;
          pedge[ev[e2]] = e2;
          queue.push(ev[e2]);
          if ev[e2] == t {
            reached = true;
            e2 = cap.len();
          }
        }
        e2 = e2 + 1;
      }
    }
    if !reached {
      augment = false;
    } else {
      var bottleneck = _INF;
      var node = t;
      while node != s {
        var ei = pedge[node];
        if cap[ei] < bottleneck {
          bottleneck = cap[ei];
        }
        node = pred[node];
      }
      node = t;
      while node != s {
        var ei = pedge[node];
        cap[ei] = cap[ei] - bottleneck;
        node = pred[node];
      }
    }
  }
  var visited = Vec[Bool].new();
  var k = 0;
  while k < g.n {
    visited.push(false);
    k = k + 1;
  }
  var queue2 = Vec[Int].new();
  queue2.push(s);
  visited[s] = true;
  var head2 = 0;
  while head2 < queue2.len() {
    var u = queue2[head2];
    head2 = head2 + 1;
    var e3 = 0;
    while e3 < cap.len() {
      if eu[e3] == u && cap[e3] > 0.0 && !visited[ev[e3]] {
        visited[ev[e3]] = true;
        queue2.push(ev[e3]);
      }
      e3 = e3 + 1;
    }
  }
  var m = 0;
  while m < g.n {
    if visited[m] {
      out.push(m);
    }
    m = m + 1;
  }
  return out;
}

// Hamiltonian path if one exists (exhaustive DFS; practical for n <= 12).
// Complexity: O(n!).
pub fn graph_hamiltonian_path(g: &Graph) -> Option[Vec[Int]] {
  if g.n == 0 {
    return Option[Vec[Int]]{ is_some: true, value: Vec[Int].new() };
  }
  if g.n > 12 {
    return Option[Vec[Int]]{ is_some: false, value: Vec[Int].new() };
  }
  var adj = _adj(g);
  var path = Vec[Int].new();
  var used = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    used.push(false);
    i = i + 1;
  }
  var start = 0;
  while start < g.n {
    used[start] = true;
    path.push(start);
    var found = _hamilton_dfs(&adj, &mut used, &mut path, g.n);
    if found {
      return Option[Vec[Int]]{ is_some: true, value: path };
    }
    path.pop();
    used[start] = false;
    start = start + 1;
  }
  return Option[Vec[Int]]{ is_some: false, value: Vec[Int].new() };
}

// Backtracking step of the Hamiltonian path search.
fn _hamilton_dfs(adj: &Vec[Vec[Int]], used: &mut Vec[Bool], path: &mut Vec[Int], n: Int) -> Bool {
  if path.len() == n {
    return true;
  }
  var last = path[path.len() - 1];
  var i = 0;
  while i < adj[last].len() {
    var nb = adj[last][i];
    if !used[nb] {
      used[nb] = true;
      path.push(nb);
      if _hamilton_dfs(adj, used, path, n) {
        return true;
      }
      path.pop();
      used[nb] = false;
    }
    i = i + 1;
  }
  return false;
}

// Traveling-salesperson tour by the nearest-neighbor heuristic: visits every
// vertex once starting from vertex 0 and returns to the start. Returns the
// tour as a vertex sequence (length n + 1). Complexity: O(n^2 + n * E).
pub fn graph_tsp(g: &Graph) -> Vec[Int] {
  var out = Vec[Int].new();
  if g.n == 0 { return out; }
  var visited = Vec[Bool].new();
  var i = 0;
  while i < g.n {
    visited.push(false);
    i = i + 1;
  }
  var cur = 0;
  visited[cur] = true;
  out.push(cur);
  var step = 1;
  while step < g.n {
    var best_v = -1;
    var best_w = _INF;
    var e = 0;
    while e < g.edges.len() {
      var edge = g.edges[e];
      if edge.0 == cur && !visited[edge.1] {
        var w = _weight(g, e);
        if w < best_w {
          best_w = w;
          best_v = edge.1;
        }
      }
      e = e + 1;
    }
    if best_v < 0 {
      var v = 0;
      while v < g.n {
        if !visited[v] {
          best_v = v;
          v = g.n;
        }
        v = v + 1;
      }
    }
    visited[best_v] = true;
    out.push(best_v);
    cur = best_v;
    step = step + 1;
  }
  out.push(0);
  return out;
}

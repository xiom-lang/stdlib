// XIOM - Math: Graph Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.graph_theory

// Depends on: none

// ============================================================================
// Graph algorithms: construction, traversal, shortest paths, spanning trees,
// connectivity, and hard combinatorial problems. NOTE: current implementation
// lives in collections/graph.xi REAL Graph/BFS/DFS/dijkstra - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Graph - adjacency-list graph; directed or undirected, optionally weighted.
// fn graph_new() -> Graph - create an empty graph.
// fn graph_add_vertex(g: &mut Graph, v: Int) -> Bool - add vertex v.
// fn graph_add_edge(g: &mut Graph, u: Int, v: Int) -> Bool - add an unweighted edge (u, v).
// fn graph_add_weighted_edge(g: &mut Graph, u: Int, v: Int, w: Float64) -> Bool - add a weighted edge (u, v).
// fn graph_remove_vertex(g: &mut Graph, v: Int) -> Bool - remove vertex v and all incident edges.
// fn graph_remove_edge(g: &mut Graph, u: Int, v: Int) -> Bool - remove the edge (u, v).
// fn graph_has_vertex(g: &Graph, v: Int) -> Bool - whether v is present.
// fn graph_has_edge(g: &Graph, u: Int, v: Int) -> Bool - whether (u, v) is present.
// fn graph_degree(g: &Graph, v: Int) -> Int - degree of vertex v.
// fn graph_vertices(g: &Graph) -> Vec[Int] - all vertices.
// fn graph_edges(g: &Graph) -> Vec[(Int, Int)] - all edges as (u, v) pairs.
// fn graph_adjacent(g: &Graph, u: Int, v: Int) -> Bool - whether u and v are neighbors.
// fn graph_dfs(g: &Graph, start: Int) -> Vec[Int] - vertices in depth-first order from start.
// fn graph_bfs(g: &Graph, start: Int) -> Vec[Int] - vertices in breadth-first order from start.
// fn graph_dijkstra(g: &Graph, source: Int) -> Vec[Float64] - shortest-path distances from source.
// fn graph_bellman_ford(g: &Graph, source: Int) -> Option[Vec[Float64]] - distances; None on a negative cycle.
// fn graph_floyd_warshall(g: &Graph) -> Vec[Vec[Float64]] - all-pairs shortest-path distances.
// fn graph_astar(g: &Graph, start: Int, goal: Int, h: fn(Int, Int) -> Float64) -> Option[Vec[Int]] - A* path using heuristic h.
// fn graph_prim(g: &Graph) -> Option[Vec[(Int, Int)]] - minimum spanning tree edges.
// fn graph_kruskal(g: &Graph) -> Option[Vec[(Int, Int)]] - minimum spanning tree edges.
// fn graph_tarjan_scc(g: &Graph) -> Vec[Vec[Int]] - strongly connected components.
// fn graph_kosaraju_scc(g: &Graph) -> Vec[Vec[Int]] - strongly connected components.
// fn graph_topological_sort(g: &Graph) -> Option[Vec[Int]] - linear order; None when cyclic.
// fn graph_is_connected(g: &Graph) -> Bool - whether the graph is connected.
// fn graph_is_cyclic(g: &Graph) -> Bool - whether the graph contains a cycle.
// fn graph_is_bipartite(g: &Graph) -> Bool - whether vertices split into two independent sets.
// fn graph_isomorphic(g1: &Graph, g2: &Graph) -> Bool - whether g1 and g2 are isomorphic.
// fn graph_color(g: &Graph) -> Vec[Int] - greedy vertex coloring.
// fn graph_max_flow(g: &Graph, s: Int, t: Int) -> Float64 - maximum flow from s to t.
// fn graph_min_cut(g: &Graph, s: Int, t: Int) -> Vec[Int] - minimum s-t cut vertices.
// fn graph_hamiltonian_path(g: &Graph) -> Option[Vec[Int]] - Hamiltonian path if one exists.
// fn graph_tsp(g: &Graph) -> Vec[Int] - traveling-salesperson tour.

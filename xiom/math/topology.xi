// XIOM - Math: Topology
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.topology

// Depends on: none

// ============================================================================
// Point-set topology over finite structures: open/closed sets, continuity,
// compactness, and metric-space notions. TODO(compiler): implement.
// ============================================================================

// TopologicalSpace - pair (points, tau) of a point set and an open-set family.
// MetricSpace - pair (points, d) of a point set and a distance function.
// fn open_set(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool - true iff s is a member of the open-set family tau.
// fn closed_set(tau: &Vec[Vec[Int]], s: &Vec[Int], universe: &Vec[Int]) -> Bool - true iff the complement of s is open.
// fn compactness(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool - every open cover of s has a finite subcover.
// fn connectedness(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool - s cannot be split into two disjoint nonempty open sets.
// fn continuity(f: fn(Int) -> Int, tau_x: &Vec[Vec[Int]], tau_y: &Vec[Vec[Int]]) -> Bool - preimages of open sets under f are open.
// fn homeomorphism(f: fn(Int) -> Int, g: fn(Int) -> Int, tau_x: &Vec[Vec[Int]], tau_y: &Vec[Vec[Int]]) -> Bool - bijective continuous map with continuous inverse.
// fn topological_space(points: &Vec[Int], open_sets: &Vec[Vec[Int]]) -> Bool - validates the topology axioms on a point set.
// fn metric_space(d: fn(Int, Int) -> Float64, points: &Vec[Int]) -> Bool - validates the metric axioms on a point set.
// fn ball(d: fn(Int, Int) -> Float64, center: Int, radius: Float64, points: &Vec[Int]) -> Vec[Int] - open ball of given radius around center.
// fn interior(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] - largest open set contained in s.
// fn closure(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] - smallest closed set containing s.
// fn boundary(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] - points in the closure but not the interior of s.
// fn limit_point(tau: &Vec[Vec[Int]], s: &Vec[Int], x: Int) -> Bool - every neighborhood of x meets s in a point other than x.
// fn neighborhood(tau: &Vec[Vec[Int]], x: Int, s: &Vec[Int]) -> Bool - s contains an open set that contains x.

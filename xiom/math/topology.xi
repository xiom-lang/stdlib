// XIOM - Math: Topology
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.topology

// Depends on: none

use xiom.math;

// ============================================================================
// Point-set topology over finite structures: open/closed sets, continuity,
// compactness, and metric-space notions.
//
// - TopologicalSpace - pair (points, tau) of a point set and an open-set
//   family (the tau argument of the predicates below).
// - MetricSpace - pair (points, d) of a point set and a distance function.
//
// Sets are Vec[Int] (elements unique by convention; membership tests are
// linear scans, so duplicates are tolerated). The open-set family tau is a
// Vec[Vec[Int]] whose rows are the open sets. Every predicate validates
// finitely over its inputs; empty tau / empty point sets are documented per
// function. All checks are exact Int comparisons except the metric axioms,
// which use a 1e-9 tolerance for floating distances.
// ============================================================================

// True iff s is a member of the open-set family tau (set equality, order
// insensitive). An empty tau never contains a non-empty s. Complexity: O(|tau| * |s|).
pub fn open_set(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool {
  var i = 0;
  while i < tau.len() {
    if _set_eq(&tau[i], s) { return true; }
    i = i + 1;
  }
  return false;
}

// True iff the complement of s (within universe) is open in tau. A set is
// closed when universe \ s is a member of the open-set family. Complexity:
// O(|tau| * |universe|).
pub fn closed_set(tau: &Vec[Vec[Int]], s: &Vec[Int], universe: &Vec[Int]) -> Bool {
  var comp = _complement(s, universe);
  return open_set(tau, &comp);
}

// True iff every open cover of s has a finite subcover. Over a finite
// topology every subfamily of tau is itself finite, so this reduces to: tau
// as a whole covers s (a set outside the union of all open sets cannot be
// compact). Returns true when s is covered, false otherwise (including an
// empty s with empty tau). Complexity: O(|tau| * |s|).
pub fn compactness(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool {
  var i = 0;
  while i < s.len() {
    var covered = false;
    var j = 0;
    while j < tau.len() {
      if _contains(tau[j], s[i]) {
        covered = true;
        j = tau.len();
      }
      j = j + 1;
    }
    if !covered { return false; }
    i = i + 1;
  }
  return true;
}

// True iff s cannot be split into two disjoint non-empty open sets. Checks
// every pair (a, b) of open sets: s is disconnected when (a | b) covers s,
// a and b are disjoint on s, and each meets s in a non-empty set. An empty
// s is vacuously connected. Complexity: O(|tau|^2 * |s|).
pub fn connectedness(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Bool {
  if s.len() == 0 { return true; }
  var i = 0;
  while i < tau.len() {
    var j = i + 1;
    while j < tau.len() {
      var ai = _inter(&tau[i], s);
      var bi = _inter(&tau[j], s);
      if ai.len() > 0 && bi.len() > 0 {
        var union_ab = _union(&tau[i], &tau[j]);
        if _subset(s, &union_ab) {
          if _set_disjoint(&ai, &bi) { return false; }
        }
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff f is continuous from (X, tau_x) to (Y, tau_y): the preimage of
// every open set in tau_y is open in tau_x. The domain X is taken as the
// union of all members of tau_x; Y likewise from tau_y. An empty tau_y is
// vacuously continuous. Complexity: O(|tau_x| * |tau_y| * |X|).
pub fn continuity(f: fn(Int) -> Int, tau_x: &Vec[Vec[Int]], tau_y: &Vec[Vec[Int]]) -> Bool {
  var y = 0;
  while y < tau_y.len() {
    var pre = _preimage(f, &tau_y[y], tau_x);
    if !open_set(tau_x, &pre) { return false; }
    y = y + 1;
  }
  return true;
}

// True iff f and g form a homeomorphism: f bijective between the domains,
// both continuous, and g is the two-sided inverse of f. The domains are the
// unions of the tau_x / tau_y members. Complexity: O(|tau_x|*|tau_y|*|X|).
pub fn homeomorphism(f: fn(Int) -> Int, g: fn(Int) -> Int, tau_x: &Vec[Vec[Int]], tau_y: &Vec[Vec[Int]]) -> Bool {
  var dom_x = _family_union(tau_x);
  var dom_y = _family_union(tau_y);
  if !continuity(f, tau_x, tau_y) { return false; }
  if !continuity(g, tau_y, tau_x) { return false; }
  var i = 0;
  while i < dom_x.len() {
    if g(f(dom_x[i])) != dom_x[i] { return false; }
    i = i + 1;
  }
  var j = 0;
  while j < dom_y.len() {
    if f(g(dom_y[j])) != dom_y[j] { return false; }
    j = j + 1;
  }
  return true;
}

// Validates the topology axioms of (points, open_sets): every member of the
// family is a subset of points; the empty set and the full point set are
// open; the family is closed under finite intersections and arbitrary
// unions. Returns false for any violation (an empty points with a family
// containing only the empty set is valid). Complexity: O(2^|tau| * |tau|).
pub fn topological_space(points: &Vec[Int], open_sets: &Vec[Vec[Int]]) -> Bool {
  var empty = Vec[Int].new();
  if !open_set(open_sets, &empty) { return false; }
  if !open_set(open_sets, points) { return false; }
  var i = 0;
  while i < open_sets.len() {
    if !_subset(&open_sets[i], points) { return false; }
    i = i + 1;
  }
  // finite intersections
  var p = 0;
  while p < open_sets.len() {
    var q = p + 1;
    while q < open_sets.len() {
      var inter = _inter(&open_sets[p], &open_sets[q]);
      if !open_set(open_sets, &inter) { return false; }
      q = q + 1;
    }
    p = p + 1;
  }
  // arbitrary unions: every subset of the family
  var n = open_sets.len();
  var mask = 1;
  while mask < _pow2_int(n) {
    var acc = Vec[Int].new();
    var bit = 0;
    while bit < n {
      if (mask / _pow2_int(bit)) % 2 == 1 {
        acc = _union(&acc, &open_sets[bit]);
      }
      bit = bit + 1;
    }
    if !open_set(open_sets, &acc) { return false; }
    mask = mask + 1;
  }
  return true;
}

// Validates the metric axioms of d on points: non-negativity, d(x, y) == 0
// iff x == y, symmetry, and the triangle inequality, all within a 1e-9
// tolerance. An empty point set is vacuously a metric space. Complexity:
// O(|points|^3).
pub fn metric_space(d: fn(Int, Int) -> Float64, points: &Vec[Int]) -> Bool {
  var i = 0;
  while i < points.len() {
    var j = i;
    while j < points.len() {
      var dij = d(points[i], points[j]);
      if dij < -1e-9 { return false; }
      var dji = d(points[j], points[i]);
      var diff = dij - dji;
      if math.abs_float(diff) > 1e-9 { return false; }
      if points[i] == points[j] {
        if dij > 1e-9 { return false; }
      } else {
        if dij < 1e-9 { return false; }
      }
      j = j + 1;
    }
    i = i + 1;
  }
  var a = 0;
  while a < points.len() {
    var b = 0;
    while b < points.len() {
      var c = 0;
      while c < points.len() {
        var dab = d(points[a], points[b]);
        var dbc = d(points[b], points[c]);
        var dac = d(points[a], points[c]);
        var lhs = dab + dbc;
        if dac > lhs + 1e-9 { return false; }
        c = c + 1;
      }
      b = b + 1;
    }
    a = a + 1;
  }
  return true;
}

// Open ball of radius around center: every point p with d(center, p) <
// radius. Returns the empty ball for a negative radius (documented).
// Complexity: O(|points|).
pub fn ball(d: fn(Int, Int) -> Float64, center: Int, radius: Float64, points: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  if radius < 0.0 { return out; }
  var i = 0;
  while i < points.len() {
    if d(center, points[i]) < radius {
      out.push(points[i]);
    }
    i = i + 1;
  }
  return out;
}

// Largest open set contained in s: the union of all members of tau that are
// subsets of s. Returns the empty set when no open subset exists.
// Complexity: O(|tau| * |s|).
pub fn interior(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < tau.len() {
    if _subset(&tau[i], s) {
      out = _union(&out, &tau[i]);
    }
    i = i + 1;
  }
  return out;
}

// Smallest closed set containing s: the intersection of every closed set
// (complement of an open set in tau) that contains s. Returns s itself
// when no closed superset exists. Complexity: O(|tau| * |s|).
pub fn closure(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] {
  var uni = _family_union(tau);
  var found = false;
  var acc = Vec[Int].new();
  var i = 0;
  while i < tau.len() {
    var closed = _complement(&tau[i], &uni);
    if _subset(s, &closed) {
      if !found {
        acc = closed;
        found = true;
      } else {
        acc = _inter(&acc, &closed);
      }
    }
    i = i + 1;
  }
  if !found { return clone_vec_int(s); }
  return acc;
}

// Boundary of s: the points in the closure but not the interior of s.
// Complexity: O(|tau| * |s|).
pub fn boundary(tau: &Vec[Vec[Int]], s: &Vec[Int]) -> Vec[Int] {
  var cl = closure(tau, s);
  var it = interior(tau, s);
  return _set_diff(&cl, &it);
}

// True iff x is a limit point of s: every neighborhood of x (open set
// containing x) meets s in a point other than x. When x has no
// neighborhoods the condition is vacuously true. Complexity: O(|tau| * |s|).
pub fn limit_point(tau: &Vec[Vec[Int]], s: &Vec[Int], x: Int) -> Bool {
  var i = 0;
  while i < tau.len() {
    if _contains(tau[i], x) {
      var hits = _inter(&tau[i], s);
      if _size_without(&hits, x) == 0 { return false; }
    }
    i = i + 1;
  }
  return true;
}

// True iff s contains an open set that contains x (s is a neighborhood of
// x). Complexity: O(|tau| * |s|).
pub fn neighborhood(tau: &Vec[Vec[Int]], x: Int, s: &Vec[Int]) -> Bool {
  var i = 0;
  while i < tau.len() {
    if _contains(tau[i], x) {
      if _subset(&tau[i], s) { return true; }
    }
    i = i + 1;
  }
  return false;
}

// ============================================================================
// Internal helpers
// ============================================================================

// True iff v contains elem.
fn _contains(v: &Vec[Int], elem: Int) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == elem { return true; }
    i = i + 1;
  }
  return false;
}

// True iff a is a subset of b.
fn _subset(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  var i = 0;
  while i < a.len() {
    if !_contains(b, a[i]) { return false; }
    i = i + 1;
  }
  return true;
}

// True iff a and b are disjoint.
fn _set_disjoint(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  var i = 0;
  while i < a.len() {
    if _contains(b, a[i]) { return false; }
    i = i + 1;
  }
  return true;
}

// True iff a and b contain exactly the same elements.
fn _set_eq(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  if a.len() != b.len() { return false; }
  return _subset(a, b);
}

// Element-wise union (duplicates removed by linear scan).
fn _union(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if !_contains(&out, a[i]) { out.push(a[i]); }
    i = i + 1;
  }
  var j = 0;
  while j < b.len() {
    if !_contains(&out, b[j]) { out.push(b[j]); }
    j = j + 1;
  }
  return out;
}

// Element-wise intersection.
fn _inter(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if _contains(b, a[i]) {
      if !_contains(&out, a[i]) { out.push(a[i]); }
    }
    i = i + 1;
  }
  return out;
}

// universe \ s.
fn _complement(s: &Vec[Int], universe: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < universe.len() {
    if !_contains(s, universe[i]) { out.push(universe[i]); }
    i = i + 1;
  }
  return out;
}

// a \ b.
fn _set_diff(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if !_contains(b, a[i]) { out.push(a[i]); }
    i = i + 1;
  }
  return out;
}

// Number of elements of v distinct from x.
fn _size_without(v: &Vec[Int], x: Int) -> Int {
  var count = 0;
  var i = 0;
  while i < v.len() {
    if v[i] != x { count = count + 1; }
    i = i + 1;
  }
  return count;
}

// Union of all members of a family of sets.
fn _family_union(tau: &Vec[Vec[Int]]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < tau.len() {
    out = _union(&out, &tau[i]);
    i = i + 1;
  }
  return out;
}

// Preimage of set s under f, restricted to the family domain of tau_x.
fn _preimage(f: fn(Int) -> Int, s: &Vec[Int], tau_x: &Vec[Vec[Int]]) -> Vec[Int] {
  var dom = _family_union(tau_x);
  var out = Vec[Int].new();
  var i = 0;
  while i < dom.len() {
    if _contains(s, f(dom[i])) { out.push(dom[i]); }
    i = i + 1;
  }
  return out;
}

// 2^n for n >= 0.
fn _pow2_int(n: Int) -> Int {
  var r = 1;
  var i = 0;
  while i < n {
    r = r * 2;
    i = i + 1;
  }
  return r;
}

// Copy of a dynamic integer vector.
fn clone_vec_int(v: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

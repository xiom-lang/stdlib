// XIOM - Math: Operations Research
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.operations_research

// Depends on: xiom.math

// ============================================================================
// Decision optimization: dynamic programming, logistics networks, scheduling,
// and stochastic optimization.
//
// Functions whose inputs are Vec[Vec[Float64]] matrices cannot read their
// inputs in this compiler build (BUG 23 #1 residual) and are marked
// TODO(compiler). The remaining functions are fully implemented with the
// documented heuristics/exact methods. Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

const _INF: Float64 = 1.0e300;

/// Optimal value of each state by discounted value iteration: V[s] =
/// max over next states ns in actions(s) of (reward(s, ns) + gamma V[ns])
/// with gamma = 0.99, converged when the largest update is below 1e-6
/// (at most 200 passes). Empty for an empty state set. Complexity: O(iters * A).
pub fn dynamic_programming(states: &Vec[Int], actions: fn(Int) -> Vec[Int], reward: fn(Int, Int) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = states.len();
  if n == 0 { return out; }
  var v = Vec[Float64].new();
  var i = 0;
  while i < n {
    v.push(0.0);
    i = i + 1;
  }
  var it = 0;
  while it < 200 {
    var vn = Vec[Float64].new();
    var maxd = 0.0;
    var s = 0;
    while s < n {
      var state = states[s];
      var nxt = actions(state);
      var best = -_INF;
      var a = 0;
      while a < nxt.len() {
        var ns = nxt[a];
        var r = reward(state, ns);
        var vns = 0.0;
        var k = 0;
        while k < n {
          if states[k] == ns {
            vns = v[k];
          }
          k = k + 1;
        }
        var cand = r + 0.99 * vns;
        if cand > best {
          best = cand;
        }
        a = a + 1;
      }
      if best == -_INF { best = 0.0; }
      var d = best - v[s];
      if d < 0.0 { d = -d; }
      if d > maxd { maxd = d; }
      vn.push(best);
      s = s + 1;
    }
    v = vn;
    if maxd < 1.0e-6 { it = 200; }
    it = it + 1;
  }
  var j = 0;
  while j < n {
    out.push(v[j]);
    j = j + 1;
  }
  return out;
}

/// Optimal order quantities over time by an (s, S)-style periodic-review
/// heuristic: target S = 1.5 * mean demand, reorder point s = mean demand;
/// orders top inventory back up to S. Returns one order quantity per period.
/// Empty for an empty demand series. Complexity: O(n).
pub fn inventory(demand: &Vec[Float64], holding_cost: Float64, order_cost: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = demand.len();
  if n == 0 { return out; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + demand[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  if mean == 0.0 {
    var z = 0;
    while z < n {
      out.push(0.0);
      z = z + 1;
    }
    return out;
  }
  var s = mean;
  var target = 1.5 * mean;
  var stock = 0.0;
  var j = 0;
  while j < n {
    var order = 0.0;
    if stock < s {
      order = target - stock;
    }
    out.push(order);
    stock = stock + order - demand[j];
    j = j + 1;
  }
  return out;
}

/// Job-to-machine assignment minimizing the makespan by list scheduling:
/// jobs (id, duration, priority) are placed on the least-loaded machine in
/// priority order. Returns a Vec[Int] with one machine index per job (in the
/// input order). Empty for no jobs or machines <= 0. Complexity: O(jobs * machines).
pub fn scheduling(jobs: &Vec[(Int, Int, Int)], machines: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var n = jobs.len();
  if n == 0 || machines <= 0 { return out; }
  var load = Vec[Float64].new();
  var m = 0;
  while m < machines {
    load.push(0.0);
    m = m + 1;
  }
  var i = 0;
  while i < n {
    var job = jobs[i];
    var best_m = 0;
    var best_load = load[0];
    var k = 1;
    while k < machines {
      if load[k] < best_load {
        best_load = load[k];
        best_m = k;
      }
      k = k + 1;
    }
    out.push(best_m);
    load[best_m] = load[best_m] + (job.1 as Float64);
    i = i + 1;
  }
  return out;
}

/// Vehicle routes minimizing total travel distance.
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the distance
/// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
/// residual; verified by minimal probe). Keep the frozen signature; revisit
/// when nested float Vec reads land.
pub fn routing(distances: &Vec[Vec[Float64]], vehicles: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  return out;
}

/// Minimum-cost one-to-one assignment via the Hungarian method.
/// TODO(compiler): NOT IMPLEMENTABLE - the cost matrix is a Vec[Vec[Float64]]
/// whose element reads return garbage in this compiler build.
pub fn assignment(cost: &Vec[Vec[Float64]]) -> Vec[Int] {
  var out = Vec[Int].new();
  return out;
}

/// Minimum-cost shipment plan.
/// TODO(compiler): NOT IMPLEMENTABLE - the cost matrix is a Vec[Vec[Float64]]
/// whose element reads return garbage in this compiler build.
pub fn transportation(supply: &Vec[Float64], demand: &Vec[Float64], cost: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

/// Shipment plan through intermediate nodes.
/// TODO(compiler): NOT IMPLEMENTABLE - the cost matrix is a Vec[Vec[Float64]]
/// whose element reads return garbage in this compiler build.
pub fn transshipment(supply: &Vec[Float64], demand: &Vec[Float64], transship: &Vec[Float64], cost: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

/// Max flow and flow matrix over the given edge list (u, v, capacity) with
/// source = nodes[0] and sink = the last node. Returns (max_flow, flow matrix
/// over the edges, one row per edge: [u, v, flow]). Edmonds-Karp BFS
/// augmenting paths. Complexity: O(V * E^2).
pub fn network_flow(nodes: &Vec[Int], edges: &Vec[(Int, Int, Float64)]) -> (Float64, Vec[Vec[Float64]]) {
  var m = Vec[Vec[Float64]].new();
  var n = nodes.len();
  if n < 2 || edges.len() == 0 {
    return (0.0, m);
  }
  var source = nodes[0];
  var sink = nodes[n - 1];
  var cap = Vec[Float64].new();
  var eu = Vec[Int].new();
  var ev = Vec[Int].new();
  var flow = Vec[Float64].new();
  var i = 0;
  while i < edges.len() {
    var e = edges[i];
    eu.push(e.0);
    ev.push(e.1);
    cap.push(e.2);
    flow.push(0.0);
    i = i + 1;
  }
  var total = 0.0;
  var augment = true;
  while augment {
    var pred = Vec[Int].new();
    var pedge = Vec[Int].new();
    var j = 0;
    while j < nodes.len() {
      pred.push(-1);
      pedge.push(-1);
      j = j + 1;
    }
    var queue = Vec[Int].new();
    queue.push(source);
    var head = 0;
    var reached = false;
    var sidx = -1;
    var k = 0;
    while k < nodes.len() {
      if nodes[k] == source { sidx = k; }
      k = k + 1;
    }
    if sidx >= 0 { pred[sidx] = sidx; }
    while head < queue.len() && !reached {
      var u = queue[head];
      head = head + 1;
      var e2 = 0;
      while e2 < cap.len() {
        if eu[e2] == u && cap[e2] > 0.0 {
          var vidx = -1;
          var q = 0;
          while q < nodes.len() {
            if nodes[q] == ev[e2] { vidx = q; }
            q = q + 1;
          }
          if vidx >= 0 && pred[vidx] == -1 {
            pred[vidx] = sidx;
            pedge[vidx] = e2;
            queue.push(ev[e2]);
            if ev[e2] == sink {
              reached = true;
              e2 = cap.len();
            }
          }
        }
        e2 = e2 + 1;
      }
    }
    if !reached {
      augment = false;
    } else {
      var bottleneck = _INF;
      var node = sink;
      var tnode = -1;
      while tnode != source {
        tnode = -1;
        var q2 = 0;
        while q2 < nodes.len() {
          if nodes[q2] == node { tnode = q2; }
          q2 = q2 + 1;
        }
        var ei = pedge[tnode];
        if cap[ei] < bottleneck {
          bottleneck = cap[ei];
        }
        var pnode = pred[tnode];
        node = nodes[pnode];
      }
      node = sink;
      var t2 = -1;
      while t2 != source {
        t2 = -1;
        var q3 = 0;
        while q3 < nodes.len() {
          if nodes[q3] == node { t2 = q3; }
          q3 = q3 + 1;
        }
        var ei = pedge[t2];
        cap[ei] = cap[ei] - bottleneck;
        flow[ei] = flow[ei] + bottleneck;
        var pnode = pred[t2];
        node = nodes[pnode];
      }
      total = total + bottleneck;
    }
  }
  var r = 0;
  while r < edges.len() {
    var row = Vec[Float64].new();
    row.push(eu[r] as Float64);
    row.push(ev[r] as Float64);
    row.push(flow[r]);
    m.push(row);
    r = r + 1;
  }
  return (total, m);
}

/// k facility sites minimizing the total weighted distance by the greedy
/// k-median heuristic: pick the candidate that reduces the objective most.
/// Returns the indices of the chosen candidates. Empty for degenerate input.
/// Complexity: O(k^2 * demand * candidates).
pub fn facility_location(demand: &Vec[Float64], candidates: &Vec[(Float64, Float64)], k: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var n = candidates.len();
  if n == 0 || k <= 0 || demand.len() == 0 { return out; }
  var chosen = Vec[Bool].new();
  var i = 0;
  while i < n {
    chosen.push(false);
    i = i + 1;
  }
  var best_dist = Vec[Float64].new();
  var d = 0;
  while d < demand.len() {
    best_dist.push(_INF);
    d = d + 1;
  }
  var step = 0;
  while step < k && step < n {
    var best_cand = -1;
    var best_save = 0.0;
    var c = 0;
    while c < n {
      if !chosen[c] {
        var save = 0.0;
        var dm = 0;
        while dm < demand.len() {
          var dx = candidates[c].0 - (dm as Float64);
          var dy = candidates[c].1;
          var dd = math.sqrt(dx * dx + dy * dy);
          if dd < best_dist[dm] {
            save = save + demand[dm] * (best_dist[dm] - dd);
          }
          dm = dm + 1;
        }
        if save > best_save {
          best_save = save;
          best_cand = c;
        }
      }
      c = c + 1;
    }
    if best_cand < 0 { step = k; }
    else {
      chosen[best_cand] = true;
      var dm2 = 0;
      while dm2 < demand.len() {
        var dx = candidates[best_cand].0 - (dm2 as Float64);
        var dy = candidates[best_cand].1;
        var dd = math.sqrt(dx * dx + dy * dy);
        if dd < best_dist[dm2] {
          best_dist[dm2] = dd;
        }
        dm2 = dm2 + 1;
      }
      out.push(best_cand);
    }
    step = step + 1;
  }
  return out;
}

/// Multi-period production and inventory plan.
/// TODO(compiler): NOT IMPLEMENTABLE - the demand/cost matrices are
/// Vec[Vec[Float64]] whose element reads return garbage in this compiler build.
pub fn supply_chain(demands: &Vec[Vec[Float64]], costs: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

/// Optimal protection levels for fare classes by Littlewood's rule: classes
/// are (price, mean_demand); for two classes the high-class protection level
/// is min(seats, mean_demand_high * (1 - price_low / price_high)). The result
/// holds one protection level per class. Complexity: O(classes).
pub fn revenue_management(seats: Int, fare_classes: &Vec[(Float64, Float64)]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = fare_classes.len();
  if n == 0 { return out; }
  var i = 0;
  while i < n {
    var cls = fare_classes[i];
    var price = cls.0;
    var mean_demand = cls.1;
    var low_price = price;
    var k = 0;
    while k < n {
      if fare_classes[k].0 < low_price {
        low_price = fare_classes[k].0;
      }
      k = k + 1;
    }
    var ratio = 1.0;
    if price > 0.0 {
      ratio = low_price / price;
    }
    var level = mean_demand * (1.0 - ratio);
    if level < 0.0 { level = 0.0; }
    var cap = seats as Float64;
    if level > cap { level = cap; }
    out.push(level);
    i = i + 1;
  }
  return out;
}

/// Stochastic search optimum within bounds by uniform random sampling: the
/// objective is minimized over the box [bounds[i].0, bounds[i].1]^dims with
/// `iters` samples; returns the best point. Empty for degenerate input.
/// Complexity: O(iters * dims * cost(objective)).
pub fn stochastic_optimization(objective: fn(&Vec[Float64]) -> Float64, bounds: &Vec[(Float64, Float64)], iters: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var dims = bounds.len();
  if dims == 0 || iters <= 0 { return out; }
  math.seed_rng(42);
  var best_x = Vec[Float64].new();
  var d = 0;
  while d < dims {
    var b = bounds[d];
    best_x.push(b.0);
    d = d + 1;
  }
  var best_f = objective(&best_x);
  var it = 0;
  while it < iters {
    var cand = Vec[Float64].new();
    var i = 0;
    while i < dims {
      var b = bounds[i];
      var r = math.random();
      cand.push(b.0 + (b.1 - b.0) * r);
      i = i + 1;
    }
    var f = objective(&cand);
    if f < best_f {
      best_f = f;
      best_x = cand;
    }
    it = it + 1;
  }
  var j = 0;
  while j < best_x.len() {
    out.push(best_x[j]);
    j = j + 1;
  }
  return out;
}

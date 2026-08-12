// Smoke: xiom.math.topology (point-set topology over finite structures).
// Returns 0 on success.
use xiom.math;
use xiom.io;

// Euclidean distance on a line of integers (metric on the real line).
fn dline(a: Int, b: Int) -> Float64 {
  var d = a - b;
  if d < 0 { d = -d; }
  return d as Float64;
}

// Non-metric candidate: d(a, b) = a - b (violates symmetry and non-negativity).
fn dnon(a: Int, b: Int) -> Float64 {
  return (a - b) as Float64;
}

fn main() -> Int {
  // metric_space: |a - b| on {0, 1, 2, 3} is a metric.
  var pts = Vec[Int].new();
  pts.push(0);
  pts.push(1);
  pts.push(2);
  pts.push(3);
  if !math.topology.metric_space(dline, &pts) { io.println("metric-ok"); return 1; }
  if math.topology.metric_space(dnon, &pts) { io.println("metric-bad"); return 2; }

  // ball: points within distance 2.5 of 0 -> {0, 1, 2} (Vec[Int] reads work).
  var b1 = math.topology.ball(dline, 0, 2.5, &pts);
  if b1.len() != 3 { io.println("ball-len"); return 3; }
  if b1[0] != 0 || b1[1] != 1 || b1[2] != 2 { io.println("ball-elems"); return 4; }

  // open_set on an empty family: nothing is open.
  var tau_empty = Vec[Vec[Int]].new();
  var empty_set = Vec[Int].new();
  if math.topology.open_set(&tau_empty, &empty_set) { io.println("open-empty-family"); return 5; }

  // compactness of the empty set is vacuously true (no reads of tau needed).
  if !math.topology.compactness(&tau_empty, &empty_set) { io.println("compact-empty"); return 6; }

  // closed_set: with an empty open family the empty complement is not open,
  // so even the full set is not closed.
  var uni = Vec[Int].new();
  uni.push(0);
  uni.push(1);
  var full = Vec[Int].new();
  full.push(0);
  full.push(1);
  if math.topology.closed_set(&tau_empty, &full, &uni) { io.println("closed-full-empty"); return 7; }

  io.println("smoke_math_topology: OK");
  return 0;
}

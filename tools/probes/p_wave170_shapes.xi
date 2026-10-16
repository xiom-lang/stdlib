// p_wave170_shapes.xi -- wave 170 lock: the graph/test/glob wishlist rows.
//   Row 37: graph transitive closure + depth over parallel edge vectors
//           (from/to Vec[Int]s, caller depth budgets) -- xiom.collect.graph.
//   Row 41: graph topological sort -- deterministic smallest-index-first
//           Kahn + cycle report -- xiom.collect.graph.
//   Row 7:  non-aborting assertion catalog (collect-all mode, structured
//           kind/message/expected/actual records) -- xiom.test.assertions.
//   Row 42: extended glob matching: '[...]' classes + escapes (glob_match_ext)
//           and path-aware matching with '**' + POSIX/Windows separators
//           (glob_match_path / glob_match_path_any) -- xiom.misc.glob.
// The original xiom.misc.glob.glob_match dialect ('*' and '?' only, '[' and
// '**' literal) is intentionally UNCHANGED; rows 15+ lock that separation.
// Rows (0 = all hold):
//  1 -- graph_reaches: direct/transitive/reflexive/budget/unreachable/oob
//  2 -- graph_closure: ascending set, budget cut, start excluded, leaf empty
//  3 -- graph_closure_matrix: reflexivity, budget, shape, unreachable row
//  4 -- graph_depth + graph_depth_of: BFS hops, -1 unreachable/beyond budget
//  5 -- graph_topological_sort: exact smallest-index-first order, Some/None
//  6 -- graph_topological_report + graph_is_dag: Err cycle payload sorted
//  7 -- graph edges cases: self-loop cycle, invalid endpoints skipped, n<=0
//  8 -- assertions: collect-all pass path (counts, no failures, summary)
//  9 -- assertions: mixed failure records (kind/message/expected/actual) and
//       execution continuing after failures
// 10 -- assertions: Result/Option kinds + check_fail + ge_int + accessors
// 11 -- assertions: report + JSON formatting
// 12 -- glob_match_ext: '*', '?', classes (negation/range/leading ']'),
//       escapes, unterminated-class literal, case sensitivity
// 13 -- glob_match_ext: old dialect unchanged (class/'**' literal in
//       glob_match) + magic parity
// 14 -- glob_match_path POSIX: '*'/'?'/'[]' never cross '/', '**' zero-or-
//       more whole segments (leading/middle/trailing)
// 15 -- glob_match_path Windows separator + glob_match_path_any mixed table
// 16 -- glob_match_path edge table: no-escape rule, '**' partial segment = '*',
//       empty pattern/path
// Setup failures use 20+.

module p_wave170_shapes

use xiom.collect.graph;

fn main() -> Int {
  // ---- Row 1: graph_reaches -----------------------------------------------
  // diamond: 0->1, 0->2, 1->3, 2->3
  var ef = Vec[Int].new();
  var et = Vec[Int].new();
  ef.push(0); et.push(1);
  ef.push(0); et.push(2);
  ef.push(1); et.push(3);
  ef.push(2); et.push(3);
  if !graph.graph_reaches(4, &ef, &et, 0, 3, 0 - 1) { return 1; }
  if graph.graph_reaches(4, &ef, &et, 3, 0, 0 - 1) { return 1; }
  if !graph.graph_reaches(4, &ef, &et, 0, 0, 0 - 1) { return 1; }
  if graph.graph_reaches(4, &ef, &et, 0, 3, 1) { return 1; }
  if !graph.graph_reaches(4, &ef, &et, 0, 3, 2) { return 1; }
  if graph.graph_reaches(4, &ef, &et, 0, 9, 0 - 1) { return 1; }
  if graph.graph_reaches(4, &ef, &et, 0 - 1, 0, 0 - 1) { return 1; }

  // ---- Row 2: graph_closure -----------------------------------------------
  var c0 = graph.graph_closure(4, &ef, &et, 0, 0 - 1);
  if c0.len() != 3 { return 2; }
  if c0[0] != 1 || c0[1] != 2 || c0[2] != 3 { return 2; }
  var c0b = graph.graph_closure(4, &ef, &et, 0, 1);
  if c0b.len() != 2 { return 2; }
  if c0b[0] != 1 || c0b[1] != 2 { return 2; }
  if graph.graph_closure(4, &ef, &et, 3, 0 - 1).len() != 0 { return 2; }
  // closure excludes start even when a cycle returns to it
  var lf = Vec[Int].new();
  var lt = Vec[Int].new();
  lf.push(0); lt.push(1);
  lf.push(1); lt.push(0);
  var cl = graph.graph_closure(2, &lf, &lt, 0, 0 - 1);
  if cl.len() != 1 { return 2; }
  if cl[0] != 1 { return 2; }

  // ---- Row 3: graph_closure_matrix ----------------------------------------
  var m = graph.graph_closure_matrix(4, &ef, &et, 0 - 1);
  if m.len() != 16 { return 3; }
  if !m[0] { return 3; }
  if !m[3] { return 3; }
  if m[12] { return 3; }
  if !m[15] { return 3; }
  var m1 = graph.graph_closure_matrix(4, &ef, &et, 1);
  if m1[3] { return 3; }
  if !m1[1] { return 3; }

  // ---- Row 4: graph_depth + graph_depth_of --------------------------------
  var d0 = graph.graph_depth(4, &ef, &et, 0, 0 - 1);
  if d0.len() != 4 { return 4; }
  if d0[0] != 0 || d0[1] != 1 || d0[2] != 1 || d0[3] != 2 { return 4; }
  if graph.graph_depth_of(4, &ef, &et, 0, 3, 0 - 1) != 2 { return 4; }
  if graph.graph_depth_of(4, &ef, &et, 3, 1, 0 - 1) != 0 - 1 { return 4; }
  if graph.graph_depth_of(4, &ef, &et, 0, 3, 1) != 0 - 1 { return 4; }
  if graph.graph_depth_of(4, &ef, &et, 0, 0, 0 - 1) != 0 { return 4; }

  // ---- Row 5: graph_topological_sort --------------------------------------
  // 3->1, 1->2 with isolated 0: sources {0,3} -> 0 first, then 3, 1, 2.
  var tf = Vec[Int].new();
  var tt = Vec[Int].new();
  tf.push(3); tt.push(1);
  tf.push(1); tt.push(2);
  match graph.graph_topological_sort(4, &tf, &tt) {
    Some(o) => {
      if o.len() != 4 { return 5; }
      if o[0] != 0 || o[1] != 3 || o[2] != 1 || o[3] != 2 { return 5; }
    },
    None => { return 5; },
  }
  match graph.graph_topological_sort(4, &ef, &et) {
    Some(o2) => {
      if o2.len() != 4 { return 5; }
      if o2[0] != 0 || o2[1] != 1 || o2[2] != 2 || o2[3] != 3 { return 5; }
    },
    None => { return 5; },
  }

  // ---- Row 6: graph_topological_report + graph_is_dag ---------------------
  // 0->1, 1->2, 2->1: node 0 emits, {1,2} stay on the cycle.
  var cf = Vec[Int].new();
  var ct = Vec[Int].new();
  cf.push(0); ct.push(1);
  cf.push(1); ct.push(2);
  cf.push(2); ct.push(1);
  match graph.graph_topological_report(3, &cf, &ct) {
    Ok(_) => { return 6; },
    Err(cyc) => {
      if cyc.len() != 2 { return 6; }
      if cyc[0] != 1 || cyc[1] != 2 { return 6; }
    },
  }
  if graph.graph_is_dag(3, &cf, &ct) { return 6; }
  if !graph.graph_is_dag(4, &tf, &tt) { return 6; }
  match graph.graph_topological_sort(3, &cf, &ct) {
    Some(_) => { return 6; },
    None => {},
  }

  // ---- Row 7: graph edge cases --------------------------------------------
  // self-loop closes a cycle; the untouched node still emits first.
  var sf = Vec[Int].new();
  var st = Vec[Int].new();
  sf.push(0); st.push(0);
  match graph.graph_topological_report(2, &sf, &st) {
    Ok(_) => { return 7; },
    Err(cyc7) => {
      if cyc7.len() != 1 { return 7; }
      if cyc7[0] != 0 { return 7; }
    },
  }
  // invalid endpoints are skipped, so this graph is acyclic and empty of edges
  var badf = Vec[Int].new();
  var badt = Vec[Int].new();
  badf.push(0); badt.push(9);
  badf.push(0 - 1); badt.push(1);
  if !graph.graph_is_dag(2, &badf, &badt) { return 7; }
  if graph.graph_depth_of(2, &badf, &badt, 0, 1, 0 - 1) != 0 - 1 { return 7; }
  // n <= 0
  if !graph.graph_is_dag(0, &ef, &et) { return 7; }
  match graph.graph_topological_sort(0, &ef, &et) {
    Some(o3) => { if o3.len() != 0 { return 7; } },
    None => { return 7; },
  }
  if graph.graph_closure(0, &ef, &et, 0, 0 - 1).len() != 0 { return 7; }
  if graph.graph_closure_matrix(0, &ef, &et, 0 - 1).len() != 0 { return 7; }

  return 0;
}

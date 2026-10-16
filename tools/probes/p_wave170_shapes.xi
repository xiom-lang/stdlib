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
use xiom.test.assertions;
use xiom.misc.glob;
use xiom.string;

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

  // ---- Row 8: assertions pass path ----------------------------------------
  var a8 = assertions_new();
  check_eq_int(&mut a8, 3, 3, "three");
  check_eq_str(&mut a8, "x", "x", "sx");
  check_eq_bool(&mut a8, true, true, "btrue");
  check_true(&mut a8, true, "t");
  check_false(&mut a8, false, "f");
  check_ge_int(&mut a8, 5, 5, "ge5");
  if assertions_passed(&a8) != 6 { return 8; }
  if assertions_failed(&a8) != 0 { return 8; }
  if assertions_total(&a8) != 6 { return 8; }
  if assertions_has_failures(&a8) { return 8; }
  if assertions_summary(&a8) != "assertions: 6 passed, 0 failed" { return 8; }

  // ---- Row 9: mixed failure records, collect-all continues ----------------
  var a9 = assertions_new();
  check_eq_int(&mut a9, 1, 2, "int-msg");
  check_eq_str(&mut a9, "aa", "bb", "str-msg");
  check_true(&mut a9, false, "true-msg");
  // execution continues after the failures: this one still runs and passes
  check_eq_int(&mut a9, 9, 9, "after");
  check_ge_int(&mut a9, 3, 9, "ge-msg");
  if assertions_passed(&a9) != 1 { return 9; }
  if assertions_failed(&a9) != 4 { return 9; }
  if assertions_total(&a9) != 5 { return 9; }
  if assertion_kind(&a9, 0) != "eq_int" { return 9; }
  if assertion_message(&a9, 0) != "int-msg" { return 9; }
  if assertion_expected(&a9, 0) != "1" { return 9; }
  if assertion_actual(&a9, 0) != "2" { return 9; }
  if assertion_kind(&a9, 1) != "eq_str" { return 9; }
  if assertion_expected(&a9, 1) != "aa" { return 9; }
  if assertion_actual(&a9, 1) != "bb" { return 9; }
  if assertion_kind(&a9, 2) != "is_true" { return 9; }
  if assertion_actual(&a9, 2) != "false" { return 9; }
  if assertion_expected(&a9, 3) != ">= 9" { return 9; }
  if assertion_actual(&a9, 3) != "3" { return 9; }
  if assertion_kind(&a9, 99) != "" { return 9; }
  if assertion_message(&a9, 0 - 1) != "" { return 9; }

  // ---- Row 10: Result/Option kinds + check_fail ---------------------------
  var a10 = assertions_new();
  let rok: Result[Int, Str] = Ok(1);
  let rerr: Result[Int, Str] = Err("no");
  let osm: Option[Int] = Some(7);
  let ono: Option[Int] = None;
  check_ok(&mut a10, rok, "ok");
  check_err(&mut a10, rerr, "err");
  check_some(&mut a10, osm, "some");
  check_none(&mut a10, ono, "none");
  check_ok(&mut a10, rerr, "bad-ok");
  check_err(&mut a10, rok, "bad-err");
  check_some(&mut a10, ono, "bad-some");
  check_none(&mut a10, osm, "bad-none");
  check_fail(&mut a10, "explicit");
  if assertions_passed(&a10) != 4 { return 10; }
  if assertions_failed(&a10) != 5 { return 10; }
  if assertion_kind(&a10, 0) != "is_ok" { return 10; }
  if assertion_kind(&a10, 1) != "is_err" { return 10; }
  if assertion_kind(&a10, 2) != "is_some" { return 10; }
  if assertion_kind(&a10, 3) != "is_none" { return 10; }
  if assertion_actual(&a10, 0) != "Err" { return 10; }
  if assertion_expected(&a10, 3) != "None" { return 10; }
  if assertion_kind(&a10, 4) != "fail" { return 10; }
  if assertion_message(&a10, 4) != "explicit" { return 10; }

  // ---- Row 11: report + JSON formatting -----------------------------------
  var a11 = assertions_new();
  check_eq_int(&mut a11, 1, 2, "one");
  check_eq_str(&mut a11, "a", "b", "two");
  if assertions_summary(&a11) != "assertions: 0 passed, 2 failed" { return 11; }
  let rep = assertions_report(&a11);
  if !string.str_contains(rep, "FAIL [eq_int] one") { return 11; }
  if !string.str_contains(rep, "FAIL [eq_str] two") { return 11; }
  let js = assertions_to_json(&a11);
  if !string.str_contains(js, "\"failed\":2") { return 11; }
  if !string.str_contains(js, "\"kind\":\"eq_int\"") { return 11; }
  if !string.str_contains(js, "\"actual\":\"b\"") { return 11; }
  var a11b = assertions_new();
  check_eq_str(&mut a11b, "a\"b", "c", "esc");
  let js2 = assertions_to_json(&a11b);
  if !string.str_contains(js2, "\\\"") { return 11; }
  var a11c = assertions_new();
  check_eq_str(&mut a11c, "x", "y\\z", "esc2");
  let js3 = assertions_to_json(&a11c);
  if !string.str_contains(js3, "y\\\\z") { return 11; }

  // ---- Row 12: glob_match_ext ---------------------------------------------
  if !glob.glob_match_ext("*.xi", "main.xi") { return 12; }
  if glob.glob_match_ext("*.xi", "MAIN.XI") { return 12; }        // case-sensitive
  if !glob.glob_match_ext("a?c", "abc") { return 12; }
  if glob.glob_match_ext("a?c", "ac") { return 12; }
  if !glob.glob_match_ext("a**b", "ab") { return 12; }
  if !glob.glob_match_ext("[ab]c", "ac") { return 12; }
  if glob.glob_match_ext("[ab]c", "xc") { return 12; }
  if !glob.glob_match_ext("[!ab]c", "xc") { return 12; }
  if glob.glob_match_ext("[!ab]c", "ac") { return 12; }
  if !glob.glob_match_ext("[^ab]c", "xc") { return 12; }
  if !glob.glob_match_ext("file[0-9].txt", "file7.txt") { return 12; }
  if glob.glob_match_ext("file[0-9].txt", "filea.txt") { return 12; }
  if !glob.glob_match_ext("[]]x", "]x") { return 12; }            // leading ']' literal
  if glob.glob_match_ext("[]]x", "ax") { return 12; }
  if !glob.glob_match_ext("a\\*b", "a*b") { return 12; }          // '\' escapes '*'
  if glob.glob_match_ext("a\\*b", "axb") { return 12; }
  if !glob.glob_match_ext("\\[ab\\]", "[ab]") { return 12; }
  if !glob.glob_match_ext("a[b", "a[b") { return 12; }            // unterminated class = literal
  if glob.glob_match_ext("a[b", "axb") { return 12; }
  if !glob.glob_match_ext("", "") { return 12; }
  if glob.glob_match_ext("", "a") { return 12; }

  // ---- Row 13: frozen simple dialect unchanged (separation lock) ----------
  if !glob.glob_match("*.xi", "main.xi") { return 13; }
  if glob.glob_match("[ab]c", "ac") { return 13; }   // class literal in simple dialect
  if !glob.glob_match("a**b", "ab") { return 13; }   // simple dialect: '**' = two stars = any run
  if !glob.glob_match_ext("[ab]c", "ac") { return 13; }
  if !glob.glob_has_magic("[a]") { return 13; }

  // ---- Row 14: glob_match_path POSIX --------------------------------------
  if !glob.glob_match_path("src/*.xi", "src/main.xi", '/') { return 14; }
  if glob.glob_match_path("src/*.xi", "src/sub/main.xi", '/') { return 14; }
  if glob.glob_match_path("src/*.xi", "src\\main.xi", '/') { return 14; }   // '\' not a sep here
  if !glob.glob_match_path("*.xi", "main.xi", '/') { return 14; }
  if glob.glob_match_path("*.xi", "a/main.xi", '/') { return 14; }
  if glob.glob_match_path("a?b", "a/b", '/') { return 14; }
  if !glob.glob_match_path("/abs/*", "/abs/file", '/') { return 14; }
  if !glob.glob_match_path("a/b/", "a/b/", '/') { return 14; }
  if glob.glob_match_path("a/b/", "a/b", '/') { return 14; }
  // globstar: zero or more whole segments
  if !glob.glob_match_path("src/**/*.xi", "src/a.xi", '/') { return 14; }
  if !glob.glob_match_path("src/**/*.xi", "src/a/b.xi", '/') { return 14; }
  if !glob.glob_match_path("src/**/*.xi", "src/a/b/c.xi", '/') { return 14; }
  if glob.glob_match_path("src/**/*.xi", "src/b.xt", '/') { return 14; }
  if !glob.glob_match_path("**/*.xi", "main.xi", '/') { return 14; }
  if !glob.glob_match_path("**/*.xi", "a/b/main.xi", '/') { return 14; }
  if !glob.glob_match_path("a/**", "a", '/') { return 14; }
  if !glob.glob_match_path("a/**", "a/b", '/') { return 14; }
  if !glob.glob_match_path("a/**/b", "a/b", '/') { return 14; }
  if !glob.glob_match_path("a/**/b", "a/x/y/b", '/') { return 14; }
  if glob.glob_match_path("a/**/b", "a/xb", '/') { return 14; }  // globstar spans whole segments only

  // ---- Row 15: Windows separator + both-separator table -------------------
  if !glob.glob_match_path("src\\*.xi", "src\\main.xi", 92 as Char) { return 15; }
  if glob.glob_match_path("src\\*.xi", "src\\sub\\main.xi", 92 as Char) { return 15; }
  if !glob.glob_match_path("**\\*.xi", "a\\b\\main.xi", 92 as Char) { return 15; }
  if !glob.glob_match_path_any("src/*.xi", "src\\main.xi") { return 15; }
  if !glob.glob_match_path_any("src\\*.xi", "src/main.xi") { return 15; }
  if !glob.glob_match_path_any("C:\\*", "C:\\x") { return 15; }
  if !glob.glob_match_path_any("C:/*", "C:\\x") { return 15; }
  if glob.glob_match_path_any("*.xi", "src/main.xi") { return 15; }
  if glob.glob_match_path_any("src/*.xi", "SRC/main.xi") { return 15; }  // case-sensitive

  // ---- Row 16: path edge table --------------------------------------------
  if !glob.glob_match_path("", "", '/') { return 16; }
  if glob.glob_match_path("", "a", '/') { return 16; }
  if !glob.glob_match_path("**", "", '/') { return 16; }
  if !glob.glob_match_path("**", "a/b", '/') { return 16; }
  if !glob.glob_match_path("a**b", "axb", '/') { return 16; }    // partial-segment '**' = '*'
  if !glob.glob_match_path("[ab]x", "ax", '/') { return 16; }    // classes work per segment
  if glob.glob_match_path("[ab]x", "a/x", '/') { return 16; }
  if !glob.glob_match_path("a\\*b", "a\\*b", '/') { return 16; } // no escape: '\' literal
  if glob.glob_match_path("a\\*b", "axb", '/') { return 16; }
  if !glob.glob_match_path("a\\*b", "a\\xb", '/') { return 16; }
  if !glob.glob_match_path("a/b", "a/b", '/') { return 16; }
  if glob.glob_match_path("a/b", "a/b/c", '/') { return 16; }

  return 0;
}

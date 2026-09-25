// p_wave27_shapes.xi -- contract shape validation for wave 27 (test/test.xi).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 27 applies to xiom.test.test:
// 1. exact Boolean mirrors on a struct field:
//    `result.passed == (left < right)` and the int/Option/Str variants
// 2. count bounds: `result >= 0 && result <= results.len()`
// 3. Str length floors on formatted output: `result.len() >= N`
// 4. benchmark passthrough mirror: `result.passed == true`
// NOTE: only one xiom.test sibling may be imported per program (the second
// clobbers the first's exports in this build), so the assert module's
// panic-mirror clauses are exercised by smoke_test2 instead.
// main() drives the real functions with passing arguments; every call
// evaluates the new runtime clauses. Returns 0 when all hold.

module p_wave27_shapes

use xiom.test.test;

fn noop() {}

fn main() -> Int {
  // 1: TestResult field mirrors
  let r1 = test.assert_lt(1, 2, "lt");
  if !r1.passed { return 1; }
  let r2 = test.assert_ne(3, 4, "ne");
  if !r2.passed { return 2; }
  let r3 = test.assert_gt(5, 4, "gt");
  if !r3.passed { return 3; }
  let r4 = test.assert_eq_int(5, 5, "eq");
  if !r4.passed { return 4; }
  let r5 = test.assert_ne_int(5, 6, "nei");
  if !r5.passed { return 5; }
  let r6 = test.assert_gt_int(7, 4, "gti");
  if !r6.passed { return 6; }
  let r7 = test.assert_lt_int(4, 7, "lti");
  if !r7.passed { return 7; }
  let r8 = test.assert_ge_int(7, 7, "gei");
  if !r8.passed { return 8; }
  let r9 = test.assert_le_int(4, 4, "lei");
  if !r9.passed { return 9; }
  let r10 = test.assert_in_range(7, 5, 9, "range");
  if !r10.passed { return 10; }
  let r11 = test.assert_some(Some(3), "some");
  if !r11.passed { return 11; }
  let none_i: Option[Int] = None;
  let r12 = test.assert_none(none_i, "none");
  if !r12.passed { return 12; }
  let r13 = test.assert_contains("hello", "ell", "contains");
  if !r13.passed { return 13; }
  let r14 = test.assert_false(false, "false");
  if !r14.passed { return 14; }
  let r15 = test.bench("b", noop);
  if !r15.passed { return 15; }

  // 2+3: aggregation bounds and formatted-output floors
  var v1 = Vec[TestResult].new();
  v1.push(r1);
  v1.push(r2);
  if test.test_pass_count(v1) != 2 { return 31; }
  var v2 = Vec[TestResult].new();
  v2.push(r1);
  let rf = test.assert_gt(1, 2, "fail");
  v2.push(rf);
  if test.test_fail_count(v2) != 1 { return 32; }
  var v3 = Vec[TestResult].new();
  v3.push(r1);
  if test.test_count_failures(v3) != 0 { return 33; }
  var v4 = Vec[TestResult].new();
  v4.push(r1);
  v4.push(r2);
  let sum = test.test_summary(v4);
  if sum.len() < 17 { return 34; }
  var v5 = Vec[TestResult].new();
  v5.push(r1);
  let rep = test.test_report(v5);
  if rep.len() < 34 { return 35; }
  var v6 = Vec[TestResult].new();
  v6.push(r1);
  let fr = test.format_results(v6);
  if fr.len() < 37 { return 36; }
  var v7 = Vec[TestResult].new();
  let fj = test.format_results_json(v7);
  if fj.len() < 2 { return 37; }
  return 0;
}

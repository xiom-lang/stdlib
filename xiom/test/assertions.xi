// XIOM -- Non-aborting assertion catalog (collect-all mode)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Structured assertion helpers for packages' conformance suites: every
// check_* call RECORDS a failure and returns instead of aborting, so one run
// reports ALL failing checks rather than the first (xiom.test.assert panics;
// xiom.test's assert_* return a single TestResult per call).
//
// The collector keeps the failure records in parallel vectors (kind /
// message / expected / actual), deliberately not a Vec[struct] -- the
// module-struct-vector caution recorded by the packages' trap-safe dispatch
// workaround. Kind catalog (11):
//   eq_int   -- expected == actual over Int
//   eq_str   -- expected == actual over Str
//   eq_bool  -- expected == actual over Bool
//   is_true  -- condition true
//   is_false -- condition false
//   is_ok    -- Result is Ok
//   is_err   -- Result is Err
//   is_some  -- Option is Some
//   is_none  -- Option is None
//   ge_int   -- actual >= floor
//   fail     -- unconditional failure record
//
// Accessors return "" for an out-of-range record index. Formatting helpers
// produce a one-line-per-failure report and a JSON document; no global state,
// no module-level arrays.

module xiom.test.assertions

use xiom.string.builder;

/// Non-aborting assertion collector. `passed` counts the checks that held;
/// kinds/messages/expected/actual hold one record per failure, in call order.
pub type Assertions = {
  passed: Int;
  kinds: Vec[Str];
  messages: Vec[Str];
  expected: Vec[Str];
  actual: Vec<Str>;
}

/// Create an empty collector.
pub fn assertions_new() -> Assertions
  ensures: result.passed == 0
{
  return Assertions{
    passed: 0;
    kinds: Vec[Str].new();
    messages: Vec<Str>.new();
    expected: Vec<Str>.new();
    actual: Vec<Str>.new();
  };
}

/// Append one failure record (internal).
fn _a_record(a: &mut Assertions, kind: Str, message: Str, expected: Str, actual: Str) {
  a.kinds.push(kind);
  a.messages.push(message);
  a.expected.push(expected);
  a.actual.push(actual);
}

/// Decimal rendering of an Int (internal).
fn _a_int_str(v: Int) -> Str {
  var sb = Vec[UInt8].new();
  builder.sb_push_int(&mut sb, v);
  return builder.sb_to_str(&sb);
}

/// Rendering of a Bool (internal).
fn _a_bool_str(v: Bool) -> Str {
  if v { return "true"; }
  return "false";
}

/// Pass when expected == actual; otherwise record an "eq_int" failure.
pub fn check_eq_int(a: &mut Assertions, expected: Int, actual: Int, message: Str)
  ensures: a.passed >= 0
{
  if expected == actual {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "eq_int", message, _a_int_str(expected), _a_int_str(actual));
}

/// Pass when expected == actual; otherwise record an "eq_str" failure.
pub fn check_eq_str(a: &mut Assertions, expected: Str, actual: Str, message: Str)
  ensures: a.passed >= 0
{
  if expected == actual {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "eq_str", message, expected, actual);
}

/// Pass when expected == actual; otherwise record an "eq_bool" failure.
pub fn check_eq_bool(a: &mut Assertions, expected: Bool, actual: Bool, message: Str)
  ensures: a.passed >= 0
{
  if expected == actual {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "eq_bool", message, _a_bool_str(expected), _a_bool_str(actual));
}

/// Pass when the condition holds; otherwise record an "is_true" failure.
pub fn check_true(a: &mut Assertions, condition: Bool, message: Str)
  ensures: a.passed >= 0
{
  if condition {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_true", message, "true", "false");
}

/// Pass when the condition is false; otherwise record an "is_false" failure.
pub fn check_false(a: &mut Assertions, condition: Bool, message: Str)
  ensures: a.passed >= 0
{
  if !condition {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_false", message, "false", "true");
}

/// Pass when actual >= floor; otherwise record a "ge_int" failure.
pub fn check_ge_int(a: &mut Assertions, actual: Int, floor: Int, message: Str)
  ensures: a.passed >= 0
{
  if actual >= floor {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "ge_int", message, ">= " + _a_int_str(floor), _a_int_str(actual));
}

/// Pass when the Result is Ok; otherwise record an "is_ok" failure. The
/// payloads are never inspected (payload-read free).
pub fn check_ok[T, E](a: &mut Assertions, r: Result[T, E], message: Str)
  ensures: a.passed >= 0
{
  if r.is_ok {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_ok", message, "Ok", "Err");
}

/// Pass when the Result is Err; otherwise record an "is_err" failure.
pub fn check_err[T, E](a: &mut Assertions, r: Result[T, E], message: Str)
  ensures: a.passed >= 0
{
  if r.is_err {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_err", message, "Err", "Ok");
}

/// Pass when the Option is Some; otherwise record an "is_some" failure.
pub fn check_some[T](a: &mut Assertions, o: Option[T], message: Str)
  ensures: a.passed >= 0
{
  if o.is_some {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_some", message, "Some", "None");
}

/// Pass when the Option is None; otherwise record an "is_none" failure.
pub fn check_none[T](a: &mut Assertions, o: Option[T], message: Str)
  ensures: a.passed >= 0
{
  if !o.is_some {
    a.passed = a.passed + 1;
    return;
  }
  _a_record(a, "is_none", message, "None", "Some");
}

/// Always record a failure with the given message ("fail" kind) -- for
/// branches that should be unreachable in a conformance run.
pub fn check_fail(a: &mut Assertions, message: Str)
  ensures: a.passed >= 0
{
  _a_record(a, "fail", message, "", "");
}

/// Number of checks that held.
pub fn assertions_passed(a: &Assertions) -> Int
  ensures: result >= 0
  ensures: result == a.passed
{
  return a.passed;
}

/// Number of recorded failures (== record count).
pub fn assertions_failed(a: &Assertions) -> Int
  ensures: result >= 0
  ensures: result == a.kinds.len()
{
  return a.kinds.len();
}

/// Total number of checks run (passed + failed).
pub fn assertions_total(a: &Assertions) -> Int
  ensures: result >= 0
{
  return a.passed + a.kinds.len();
}

/// True when at least one failure was recorded.
pub fn assertions_has_failures(a: &Assertions) -> Bool
  ensures: a.kinds.len() == 0 => result == false
  ensures: a.kinds.len() > 0 => result == true
{
  return a.kinds.len() > 0;
}

/// Kind of failure record `i` ("" when out of range).
pub fn assertion_kind(a: &Assertions, i: Int) -> Str
  ensures: i < 0 || i >= a.kinds.len() => result == ""
{
  if i < 0 || i >= a.kinds.len() { return ""; }
  return a.kinds[i];
}

/// Caller message of failure record `i` ("" when out of range).
pub fn assertion_message(a: &Assertions, i: Int) -> Str
  ensures: i < 0 || i >= a.kinds.len() => result == ""
{
  if i < 0 || i >= a.kinds.len() { return ""; }
  return a.messages[i];
}

/// Expected rendering of failure record `i` ("" when out of range).
pub fn assertion_expected(a: &Assertions, i: Int) -> Str
  ensures: i < 0 || i >= a.kinds.len() => result == ""
{
  if i < 0 || i >= a.kinds.len() { return ""; }
  return a.expected[i];
}

/// Actual rendering of failure record `i` ("" when out of range).
pub fn assertion_actual(a: &Assertions, i: Int) -> Str
  ensures: i < 0 || i >= a.kinds.len() => result == ""
{
  if i < 0 || i >= a.kinds.len() { return ""; }
  return a.actual[i];
}

/// One-line summary: "assertions: N passed, M failed".
pub fn assertions_summary(a: &Assertions) -> Str {
  var sb = Vec[UInt8].new();
  builder.sb_push_str(&mut sb, "assertions: ");
  builder.sb_push_int(&mut sb, a.passed);
  builder.sb_push_str(&mut sb, " passed, ");
  builder.sb_push_int(&mut sb, a.kinds.len());
  builder.sb_push_str(&mut sb, " failed");
  return builder.sb_to_str(&sb);
}

/// Multi-line report: the summary line, then one line per failure
/// ("FAIL [kind] message -- expected: X, actual: Y").
pub fn assertions_report(a: &Assertions) -> Str {
  var sb = Vec[UInt8].new();
  builder.sb_push_str(&mut sb, assertions_summary(a));
  var i = 0;
  while i < a.kinds.len() {
    builder.sb_push_str(&mut sb, "\nFAIL [");
    builder.sb_push_str(&mut sb, a.kinds[i]);
    builder.sb_push_str(&mut sb, "] ");
    builder.sb_push_str(&mut sb, a.messages[i]);
    builder.sb_push_str(&mut sb, " -- expected: ");
    builder.sb_push_str(&mut sb, a.expected[i]);
    builder.sb_push_str(&mut sb, ", actual: ");
    builder.sb_push_str(&mut sb, a.actual[i]);
    i = i + 1;
  }
  return builder.sb_to_str(&sb);
}

/// JSON-escape a string (quotes, backslashes, newline/CR/tab) (internal).
fn _a_json_escape(sb: &mut Vec[UInt8], s: Str) {
  var i = 0;
  while i < s.len() {
    var c = s.char_at(i) as Int;
    if c == 34 {
      builder.sb_push_str(sb, "\\\"");
    } elif c == 92 {
      builder.sb_push_str(sb, "\\\\");
    } elif c == 10 {
      builder.sb_push_str(sb, "\\n");
    } elif c == 13 {
      builder.sb_push_str(sb, "\\r");
    } elif c == 9 {
      builder.sb_push_str(sb, "\\t");
    } else {
      builder.sb_push_byte(sb, c as UInt8);
    }
    i = i + 1;
  }
}

/// Structured JSON document:
/// {"passed":N,"failed":M,"failures":[{"kind":..,"message":..,
/// "expected":..,"actual":..}, ...]}.
pub fn assertions_to_json(a: &Assertions) -> Str {
  var sb = Vec[UInt8].new();
  builder.sb_push_str(&mut sb, "{\"passed\":");
  builder.sb_push_int(&mut sb, a.passed);
  builder.sb_push_str(&mut sb, ",\"failed\":");
  builder.sb_push_int(&mut sb, a.kinds.len());
  builder.sb_push_str(&mut sb, ",\"failures\":[");
  var i = 0;
  while i < a.kinds.len() {
    if i > 0 {
      builder.sb_push_str(&mut sb, ",");
    }
    builder.sb_push_str(&mut sb, "{\"kind\":\"");
    _a_json_escape(&mut sb, a.kinds[i]);
    builder.sb_push_str(&mut sb, "\",\"message\":\"");
    _a_json_escape(&mut sb, a.messages[i]);
    builder.sb_push_str(&mut sb, "\",\"expected\":\"");
    _a_json_escape(&mut sb, a.expected[i]);
    builder.sb_push_str(&mut sb, "\",\"actual\":\"");
    _a_json_escape(&mut sb, a.actual[i]);
    builder.sb_push_str(&mut sb, "\"}");
    i = i + 1;
  }
  builder.sb_push_str(&mut sb, "]}");
  return builder.sb_to_str(&sb);
}

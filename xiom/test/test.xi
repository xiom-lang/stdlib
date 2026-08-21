// XIOM -- Test Framework (Contract-Aware)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.test

use xiom.test.assert;
use xiom.test.harness;

use xiom.string;
use xiom.io;
use xiom.core;
use xiom.convert;
use xiom.time;

// Test result with contract details
pub type TestResult = {
  passed: Bool;
  name: Str;
  message: Str;
  contract_failures: Vec[ContractFailure];
  duration_ms: Int;
} derive[Clone]

pub type ContractFailure = {
  clause: Str;      // "requires", "ensures", "invariant"
  expression: Str;  // the contract text
  values: Str;      // actual values at violation
  location: Str;    // file:line
} derive[Clone]

pub fn assert(condition: Bool, name: Str) -> TestResult
  requires: name.len() > 0 {
  return TestResult{
    passed: condition;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_eq[T: Eq](expected: T, actual: T, name: Str) -> TestResult
  requires: name.len() > 0 {
  let passed = expected == actual;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_ne[T: Eq](expected: T, actual: T, name: Str) -> TestResult {
  let passed = expected != actual;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_lt[T: Ord](left: T, right: T, name: Str) -> TestResult {
  let passed = left < right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_gt[T: Ord](left: T, right: T, name: Str) -> TestResult {
  let passed = left > right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_contains(haystack: Str, needle: Str, name: Str) -> TestResult {
  var passed = string.str_contains(haystack, needle);
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_ok[T, E](result: Result[T, E], name: Str) -> TestResult {
  return TestResult{
    passed: result.is_ok;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_err[T, E](result: Result[T, E], name: Str) -> TestResult {
  return TestResult{
    passed: !result.is_ok;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_some[T](option: Option[T], name: Str) -> TestResult {
  return TestResult{
    passed: option.is_some;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_none[T](option: Option[T], name: Str) -> TestResult {
  return TestResult{
    passed: !option.is_some;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

pub fn assert_contract[T](value: T, predicate: fn(&T) -> Bool, name: Str) -> TestResult {
  let passed = predicate(&value);
  var failures = Vec[ContractFailure].new();
  if !passed {
    let cf = ContractFailure{
      clause: "contract";
      expression: "predicate";
      values: "<contract violation>";
      location: "<unknown>";
    };
    failures.push(cf);
  };
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: failures;
    duration_ms: 0;
  };
}

pub fn run(test: fn() -> TestResult) -> Int {
  let result = test();
  if result.passed { return 0; };
  return 1;
}

pub fn run_all(tests: Vec[fn() -> TestResult]) -> Int {
  var failures: Int = 0;
  var i: Int = 0;
  while i < tests.len() {
    let result = tests[i]();
    if !result.passed {
      failures = failures + 1;
    };
    i = i + 1;
  };
  return failures;
}

pub fn run_filtered(tests: Vec[fn() -> TestResult], filter: Str) -> Int {
  var failures: Int = 0;
  var i: Int = 0;
  while i < tests.len() {
    let result = tests[i]();
    if string.str_contains(result.name, filter) {
      if !result.passed {
        failures = failures + 1;
      };
    };
    i = i + 1;
  };
  return failures;
}

pub fn format_results(results: Vec[TestResult]) -> Str {
  var total: Int = 0;
  var passed: Int = 0;
  var failed: Int = 0;
  var output: Str = "";
  var i: Int = 0;
  while i < results.len() {
    let r = results[i];
    total = total + 1;
    if r.passed {
      passed = passed + 1;
      output = string.str_concat(output, string.str_concat("[PASS] ", string.str_concat(r.name, "\n")));
    } else {
      failed = failed + 1;
      output = string.str_concat(output, string.str_concat("[FAIL] ", string.str_concat(r.name, ": ")));
      output = string.str_concat(output, string.str_concat(r.message, "\n"));
    };
    i = i + 1;
  };
  output = string.str_concat(output, string.str_concat("\nResults: ", string.str_concat(core.to_string(passed), string.str_concat(" passed, ", string.str_concat(core.to_string(failed), string.str_concat(" failed, ", string.str_concat(core.to_string(total), " total")))))));
  return output;
}

pub fn format_results_json(results: Vec[TestResult]) -> Str {
  var json: Str = "[";
  var i: Int = 0;
  while i < results.len() {
    let r = results[i];
    if i > 0 {
      json = string.str_concat(json, ",");
    };
    json = string.str_concat(json, "{\"name\":\"");
    json = string.str_concat(json, r.name);
    json = string.str_concat(json, "\",\"passed\":");
    json = string.str_concat(json, convert.bool_to_string(r.passed));
    json = string.str_concat(json, ",\"message\":\"");
    json = string.str_concat(json, r.message);
    json = string.str_concat(json, "\",\"duration_ms\":");
    json = string.str_concat(json, core.to_string(r.duration_ms));
    json = string.str_concat(json, "}");
    i = i + 1;
  };
  json = string.str_concat(json, "]");
  return json;
}

pub fn bench(name: Str, f: fn()) -> TestResult {
  let start = time.Instant.now();
  f();
  let elapsed = start.elapsed();
  let ms = elapsed.as_millis();
  return TestResult{
    passed: true;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: ms;
  };
}

// -- Boolean Assertions ---------------------------------------------

/// Asserts that `cond` is false.
/// Complexity: O(1). Pure in test context.
pub fn assert_false(cond: Bool, name: Str) -> TestResult {
  return TestResult{
    passed: !cond;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

// -- Typed Numeric Assertions ---------------------------------------

/// Asserts that two `Int` values are equal.
/// Complexity: O(1). Pure in test context.
pub fn assert_eq_int(expected: Int, actual: Int, name: Str) -> TestResult {
  let passed = expected == actual;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that two `Int` values are not equal.
/// Complexity: O(1).
pub fn assert_ne_int(expected: Int, actual: Int, name: Str) -> TestResult {
  let passed = expected != actual;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that `left` is strictly greater than `right`.
/// Complexity: O(1).
pub fn assert_gt_int(left: Int, right: Int, name: Str) -> TestResult {
  let passed = left > right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that `left` is strictly less than `right`.
/// Complexity: O(1).
pub fn assert_lt_int(left: Int, right: Int, name: Str) -> TestResult {
  let passed = left < right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that `left` is greater than or equal to `right`.
/// Complexity: O(1).
pub fn assert_ge_int(left: Int, right: Int, name: Str) -> TestResult {
  let passed = left >= right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that `left` is less than or equal to `right`.
/// Complexity: O(1).
pub fn assert_le_int(left: Int, right: Int, name: Str) -> TestResult {
  let passed = left <= right;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

/// Asserts that `value` is within the inclusive range [`lo`, `hi`].
/// Complexity: O(1).
pub fn assert_in_range(value: Int, lo: Int, hi: Int, name: Str) -> TestResult {
  let passed = value >= lo && value <= hi;
  return TestResult{
    passed: passed;
    name: name;
    message: "";
    contract_failures: Vec[ContractFailure].new();
    duration_ms: 0;
  };
}

// -- Test Result Aggregation ----------------------------------------

/// Counts the number of failing test results in the vector.
/// Complexity: O(n). Consumes the vector.
pub fn test_count_failures(results: Vec[TestResult]) -> Int {
  var failures: Int = 0;
  var i: Int = 0;
  while i < results.len() {
    if !results[i].passed {
      failures = failures + 1;
    };
    i = i + 1;
  };
  return failures;
}

/// Counts the number of passing test results in the vector.
/// Complexity: O(n). Consumes the vector.
pub fn test_pass_count(results: Vec[TestResult]) -> Int {
  var passed: Int = 0;
  var i: Int = 0;
  while i < results.len() {
    if results[i].passed {
      passed = passed + 1;
    };
    i = i + 1;
  };
  return passed;
}

/// Counts the number of failing test results. Alias for `test_count_failures`.
/// Complexity: O(n). Consumes the vector.
pub fn test_fail_count(results: Vec[TestResult]) -> Int {
  return test_count_failures(results);
}

/// Returns a one-line summary string: `"P passed, F failed, T total"`.
/// Complexity: O(n). Consumes the vector.
pub fn test_summary(results: Vec[TestResult]) -> Str {
  let passed = test_pass_count(results);
  let total = passed;
  return core.to_string(passed) + " passed, " + core.to_string(total) + " total";
}

/// Generates a multi-line test report using `xiom.string.str_concat`.
/// Includes per-test results followed by a summary footer.
/// Complexity: O(n). Consumes the vector.
pub fn test_report(results: Vec[TestResult]) -> Str {
  var output: Str = "";
  var i: Int = 0;
  var passed: Int = 0;
  var failed: Int = 0;
  while i < results.len() {
    let r = results[i];
    if r.passed {
      passed = passed + 1;
      output = string.str_concat(output, string.str_concat("[PASS] ", string.str_concat(r.name, "\n")));
    } else {
      failed = failed + 1;
      output = string.str_concat(output, string.str_concat("[FAIL] ", string.str_concat(r.name, "\n")));
    };
    i = i + 1;
  };
  output = string.str_concat(output, "---\n");
  output = string.str_concat(output, string.str_concat("Passed: ", string.str_concat(core.to_string(passed), "\n")));
  output = string.str_concat(output, string.str_concat("Failed: ", string.str_concat(core.to_string(failed), "\n")));
  output = string.str_concat(output, string.str_concat("Total:  ", string.str_concat(core.to_string(results.len()), "\n")));
  return output;
}

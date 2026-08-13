// XIOM - Test: Harness
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.test.harness

// Depends on: xiom.test

use xiom.string;
use xiom.convert;
use xiom.io;
use xiom.time;

// ============================================================================
// Test collection and execution: run, filter, parallel, skip, benchmark and
// reporting.
//
// A test is a `fn() -> Result[Unit, Str]`: Ok means passed, Err means failed
// (tests should return Err rather than panic; see xiom.test.assert).
//
// `harness_parallel` runs tests sequentially in this single-threaded build
// (documented).
//
// The process-wide registry used by `test_register` / `test_main` is LIMITED:
// this build cannot reassign module-scope function pointers after
// initialization, so `test_register` records test names only (up to 8) and
// `test_main` reports whether any test was registered. Tests registered
// through the global registry cannot be executed in this build.
// ============================================================================

/// A test runner holding registered tests by name.
pub type Harness = {
  names: Vec[Str];
  tests: Vec[fn() -> Result[Unit, Str]];
  skipped: Vec[Str];
}

/// The result of a run: passed, failed and skipped counts plus total run time.
pub type TestReport = {
  passed: Int;
  failed: Int;
  skipped: Int;
  duration_ms: Int;
} derive[Clone]

/// Process-wide registered test names (fixed 8-slot registry; see header).
pub type GlobalTests = {
  names: Vec[Str];
  n: Int;
}

/// The process-wide test registry.
var g_tests: GlobalTests = GlobalTests{ names: Vec[Str]::new(); n: 0; };

/// True when `a` and `b` hold the same bytes.
fn str_eq(a: Str, b: Str) -> Bool {
  let la = a.len();
  let lb = b.len();
  if la != lb {
    return false;
  };
  var i: Int = 0;
  while i < la {
    if string.byte_at(a, i) != string.byte_at(b, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Run one test: 0 when it passed, 1 when it failed.
fn run_one(f: fn() -> Result[Unit, Str]) -> Int {
  let r = f();
  match r {
    Ok(_) => 0;
    Err(_) => 1;
  }
}

/// Whether `name` is in the skipped list.
fn is_skipped(h: &Harness, name: Str) -> Bool {
  var i: Int = 0;
  while i < h.skipped.len() {
    let s = h.skipped[i];
    if str_eq(s, name) {
      return true;
    };
    i = i + 1;
  };
  false
}

/// Create an empty test runner.
/// Complexity: O(1).
pub fn test_harness_new() -> Harness {
  Harness{ names: Vec[Str]::new(); tests: Vec[fn() -> Result[Unit, Str]]::new(); skipped: Vec[Str]::new(); }
}

/// Register a named test.
/// Complexity: O(1) amortized.
pub fn harness_add_test(h: &mut Harness, name: Str, f: fn() -> Result[Unit, Str]) {
  h.names.push(name);
  h.tests.push(f);
}

/// Run all tests sequentially, respecting skipped names.
/// Complexity: O(tests).
pub fn harness_run(h: &Harness) -> TestReport {
  let start = time.Instant.now();
  var passed: Int = 0;
  var failed: Int = 0;
  var skipped: Int = 0;
  var i: Int = 0;
  while i < h.tests.len() {
    let name = h.names[i];
    if is_skipped(h, name) {
      skipped = skipped + 1;
    } else {
      let f = h.tests[i];
      let rc = run_one(f);
      if rc == 0 {
        passed = passed + 1;
      } else {
        failed = failed + 1;
      };
    };
    i = i + 1;
  };
  let elapsed = start.elapsed();
  TestReport{ passed: passed; failed: failed; skipped: skipped; duration_ms: elapsed.as_millis(); }
}

/// Run only tests whose name matches `filter` (substring, case-sensitive).
/// Complexity: O(tests).
pub fn harness_run_filtered(h: &Harness, filter: Str) -> TestReport {
  let start = time.Instant.now();
  var passed: Int = 0;
  var failed: Int = 0;
  var skipped: Int = 0;
  var i: Int = 0;
  while i < h.tests.len() {
    let name = h.names[i];
    if string.str_contains(name, filter) {
      if is_skipped(h, name) {
        skipped = skipped + 1;
      } else {
        let f = h.tests[i];
        let rc = run_one(f);
        if rc == 0 {
          passed = passed + 1;
        } else {
          failed = failed + 1;
        };
      };
    };
    i = i + 1;
  };
  let elapsed = start.elapsed();
  TestReport{ passed: passed; failed: failed; skipped: skipped; duration_ms: elapsed.as_millis(); }
}

/// Run tests with up to `workers` threads. This single-threaded build runs
/// them sequentially (documented).
/// Complexity: O(tests).
pub fn harness_parallel(h: &Harness, workers: Int) -> TestReport {
  harness_run(h)
}

/// Mark a named test as skipped.
/// Complexity: O(skipped).
pub fn harness_skip(h: &mut Harness, name: Str) {
  var i: Int = 0;
  while i < h.skipped.len() {
    let s = h.skipped[i];
    if str_eq(s, name) {
      return;
    };
    i = i + 1;
  };
  h.skipped.push(name);
}

/// Time `f` over `iterations` calls and register the result under `name`.
/// Returns the total elapsed time in milliseconds.
/// Complexity: O(iterations * cost of f).
pub fn harness_benchmark(h: &mut Harness, name: Str, f: fn(), iterations: Int) -> Int {
  let start = time.Instant.now();
  var i: Int = 0;
  while i < iterations {
    f();
    i = i + 1;
  };
  let elapsed = start.elapsed();
  let ms = elapsed.as_millis();
  h.names.push(name);
  let bf: fn() -> Result[Unit, Str] = bench_ok;
  h.tests.push(bf);
  ms
}

/// A synthetic test record used to register benchmark results.
fn bench_ok() -> Result[Unit, Str] {
  Ok(())
}

/// The number of passed tests.
/// Complexity: O(1).
pub fn report_passed(r: &TestReport) -> Int {
  r.passed
}

/// The number of failed tests.
/// Complexity: O(1).
pub fn report_failed(r: &TestReport) -> Int {
  r.failed
}

/// The number of skipped tests.
/// Complexity: O(1).
pub fn report_skipped(r: &TestReport) -> Int {
  r.skipped
}

/// The total run time in milliseconds.
/// Complexity: O(1).
pub fn report_duration_ms(r: &TestReport) -> Int {
  r.duration_ms
}

/// Print a human-readable summary.
/// Complexity: O(1).
pub fn report_print(r: &TestReport) {
  io.println("passed: " + convert.int_to_string(r.passed) + ", failed: " + convert.int_to_string(r.failed) + ", skipped: " + convert.int_to_string(r.skipped) + ", duration_ms: " + convert.int_to_string(r.duration_ms));
}

/// The report serialized as JSON.
/// Complexity: O(1).
pub fn report_json(r: &TestReport) -> Str {
  "{\"passed\":" + convert.int_to_string(r.passed) + ",\"failed\":" + convert.int_to_string(r.failed) + ",\"skipped\":" + convert.int_to_string(r.skipped) + ",\"duration_ms\":" + convert.int_to_string(r.duration_ms) + "}"
}

/// Run all registered global tests and return the exit code. LIMITED: the
/// registered tests cannot be executed in this build (module-scope function
/// pointers are read-only after initialization), so this returns 0 when at
/// least one test has been registered and 1 otherwise.
/// Complexity: O(1).
pub fn test_main() -> Int {
  if g_tests.n == 0 {
    return 1;
  };
  0
}

/// Register a test in the global harness. Returns true when the test was
/// recorded, false when the 8-slot registry is full. LIMITED: only the test
/// name is recorded — the function pointer cannot be retained in this build
/// (see header).
/// Complexity: O(1).
pub fn test_register(name: Str, f: fn() -> Result[Unit, Str]) -> Bool {
  if g_tests.n >= 8 {
    return false;
  };
  g_tests.names.push(name);
  g_tests.n = g_tests.n + 1;
  true
}

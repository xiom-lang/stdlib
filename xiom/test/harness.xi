// XIOM - Test: Harness
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.test.harness

// Depends on: xiom.test

// ============================================================================
// Test collection and execution: run, filter, parallel, skip, benchmark and
// reporting. NOTE: current implementation lives in test.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Harness - a test runner holding registered tests by name.
// type TestReport - the result of a run: passed, failed and skipped counts plus duration.
// fn test_harness_new() -> Harness - create an empty test runner. TODO(compiler): implement.
// fn harness_add_test(h, name: Str, f: fn() -> Result[Unit, Str]) - register a named test. TODO(compiler): implement.
// fn harness_run(h) -> TestReport - run all tests sequentially. TODO(compiler): implement.
// fn harness_run_filtered(h, filter: Str) -> TestReport - run only tests whose name matches. TODO(compiler): implement.
// fn harness_parallel(h, workers: Int) -> TestReport - run tests with up to workers threads. TODO(compiler): implement.
// fn harness_skip(h, name: Str) - mark a named test as skipped. TODO(compiler): implement.
// fn harness_benchmark(h, name, f: fn(), iterations: Int) -> Int - time f over iterations and register the result. TODO(compiler): implement.
// fn report_passed(r: TestReport) -> Int - the number of passed tests. TODO(compiler): implement.
// fn report_failed(r) -> Int - the number of failed tests. TODO(compiler): implement.
// fn report_skipped(r) -> Int - the number of skipped tests. TODO(compiler): implement.
// fn report_duration_ms(r) -> Int - total run time in milliseconds. TODO(compiler): implement.
// fn report_print(r) - print a human-readable summary. TODO(compiler): implement.
// fn report_json(r) -> Str - the report serialized as JSON. TODO(compiler): implement.
// fn test_main() -> Int - run all registered tests and return the exit code. TODO(compiler): implement.
// fn test_register(name: Str, f: fn()) -> Bool - register a test in the global harness. TODO(compiler): implement.

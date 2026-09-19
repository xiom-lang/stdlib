// XIOM -- Benchmarking Framework
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.bench

use xiom.time;
use xiom.convert;
use xiom.string;

/// Timing result of one benchmark run.
pub type BenchResult = {
  name: Str;
  iterations: Int;
  total_ns: Int;
  mean_ns: Int;
  min_ns: Int;
  max_ns: Int;
  stddev_ns: Int;
} derive[Clone]

fn isqrt(n: Int) -> Int {
  if n <= 1 { return n; };
  var x = n;
  var y = (x + 1) / 2;
  while y < x {
    x = y;
    y = (x + n / x) / 2;
  };
  return x;
}

/// Time `f` once and return the result.
pub fn run_bench(name: Str, f: fn()) -> BenchResult
  requires: name.len() > 0 {
  let start = time.Instant.now();
  f();
  let ns = start.elapsed().as_nanos();
  return BenchResult{
    name: name;
    iterations: 1;
    total_ns: ns;
    mean_ns: ns;
    min_ns: ns;
    max_ns: ns;
    stddev_ns: 0;
  };
}

/// Time `f` over `iterations` runs; returns aggregate stats.
pub fn run_bench_n(name: Str, iterations: Int, f: fn()) -> BenchResult
  requires: name.len() > 0
  requires: iterations >= 0
  ensures:  result.iterations == iterations
{
  if iterations <= 0 {
    return BenchResult{
      name: name;
      iterations: 0;
      total_ns: 0;
      mean_ns: 0;
      min_ns: 0;
      max_ns: 0;
      stddev_ns: 0;
    };
  };

  var total = 0;
  var minimum = 0;
  var maximum = 0;
  var mean = 0;
  var m2 = 0;
  var i = 0;
  while i < iterations {
    let start = time.Instant.now();
    f();
    let ns = start.elapsed().as_nanos();
    total = total + ns;

    if i == 0 {
      minimum = ns;
      maximum = ns;
    } else {
      if ns < minimum { minimum = ns; };
      if ns > maximum { maximum = ns; };
    };

    let count = i + 1;
    let delta = ns - mean;
    mean = mean + delta / count;
    let delta2 = ns - mean;
    m2 = m2 + delta * delta2;

    i = i + 1;
  };

  let variance = m2 / iterations;
  let stddev = isqrt(variance);

  return BenchResult{
    name: name;
    iterations: iterations;
    total_ns: total;
    mean_ns: mean;
    min_ns: minimum;
    max_ns: maximum;
    stddev_ns: stddev;
  };
}

/// Human-readable comparison of two benchmark results.
pub fn compare(a: BenchResult, b: BenchResult) -> Str
  ensures: result.len() > 0
{
  if a.mean_ns < b.mean_ns {
    return a.name + " is faster than " + b.name;
  } elif b.mean_ns < a.mean_ns {
    return b.name + " is faster than " + a.name;
  } else {
    return a.name + " and " + b.name + " are equal";
  };
}

/// Opaque identity that prevents the optimizer from eliding the value.
pub fn black_box[T](value: T) -> T {
  return value;
}

// -- BenchResult Analytics ------------------------------------------

/// Returns operations per second based on `mean_ns`.
/// Returns 0 if `mean_ns` is 0 to avoid division by zero.
/// Complexity: O(1). Pure.
pub fn bench_ops_per_sec_ns(result: &BenchResult) -> Int {
  if result.mean_ns <= 0 {
    return 0;
  };
  return 1000000000 / result.mean_ns;
}

/// Returns how many percent `candidate` is faster than `baseline`.
/// Positive means candidate is faster. Formula: (base - cand) * 100 / base.
/// Returns 0 if `baseline.mean_ns` is 0.
/// Complexity: O(1). Pure.
pub fn bench_faster_percent(baseline: &BenchResult, candidate: &BenchResult) -> Int {
  if baseline.mean_ns <= 0 {
    return 0;
  };
  return ((baseline.mean_ns - candidate.mean_ns) * 100) / baseline.mean_ns;
}

/// Returns the minimum `mean_ns` across all benchmark results.
/// Returns 0 if the vector is empty.
/// Complexity: O(n).
pub fn bench_min_ns(results: Vec[BenchResult]) -> Int {
  if results.len() == 0 {
    return 0;
  };
  var min_val: Int = results[0].mean_ns;
  var i: Int = 1;
  while i < results.len() {
    if results[i].mean_ns < min_val {
      min_val = results[i].mean_ns;
    };
    i = i + 1;
  };
  return min_val;
}

/// Returns the maximum `mean_ns` across all benchmark results.
/// Returns 0 if the vector is empty.
/// Complexity: O(n).
pub fn bench_max_ns(results: Vec[BenchResult]) -> Int {
  if results.len() == 0 {
    return 0;
  };
  var max_val: Int = results[0].mean_ns;
  var i: Int = 1;
  while i < results.len() {
    if results[i].mean_ns > max_val {
      max_val = results[i].mean_ns;
    };
    i = i + 1;
  };
  return max_val;
}

/// Returns the sum of `total_ns` across all benchmark results.
/// Complexity: O(n).
pub fn bench_total_ns(results: Vec[BenchResult]) -> Int {
  var total: Int = 0;
  var i: Int = 0;
  while i < results.len() {
    total = total + results[i].total_ns;
    i = i + 1;
  };
  return total;
}

/// Returns the median `mean_ns` across results (middle element by position, unsorted).
/// Complexity: O(1) index access.
pub fn bench_median_ns(results: Vec[BenchResult]) -> Int {
  if results.len() == 0 {
    return 0;
  };
  return results[results.len() / 2].mean_ns;
}

/// Converts nanoseconds to a human-readable string ("1.23ms", "45us", "100ns").
/// Complexity: O(1).
pub fn bench_human_ns(ns: Int) -> Str {
  if ns >= 1000000000 {
    let sec = ns / 1000000000;
    let frac = (ns % 1000000000) / 100000000;
    return convert.int_to_string(sec) + "." + convert.int_to_string(frac) + "s";
  };
  if ns >= 1000000 {
    let ms = ns / 1000000;
    let frac = (ns % 1000000) / 100000;
    return convert.int_to_string(ms) + "." + convert.int_to_string(frac) + "ms";
  };
  if ns >= 1000 {
    let us = ns / 1000;
    let frac = (ns % 1000) / 100;
    return convert.int_to_string(us) + "." + convert.int_to_string(frac) + "us";
  };
  return convert.int_to_string(ns) + "ns";
}

/// Wraps `black_box` for `Int` values, preventing compiler optimisations from
/// eliminating benchmarked computations.
/// Complexity: O(1). Pure.
pub fn bench_black_box_int(n: Int) -> Int {
  return black_box(n);
}

/// Runs a benchmark with the given name and iteration count. Alias for `run_bench_n`.
/// Complexity: runs `f` exactly `iterations` times.
pub fn bench_run_avg(name: Str, iterations: Int, f: fn()) -> BenchResult {
  return run_bench_n(name, iterations, f);
}

/// Times a single invocation of `f` and returns the elapsed nanoseconds.
/// Complexity: runs `f` exactly once.
pub fn bench_time_fn(f: fn()) -> Int {
  let result = run_bench("", f);
  return result.mean_ns;
}

// -- BenchResult Reporting ------------------------------------------

/// Generates a table report with columns: name, mean, min, max, ops/s.
/// Complexity: O(n).
pub fn bench_report(results: Vec[BenchResult]) -> Str {
  var output: Str = "name               mean        min         max         ops/s\n";
  output = output + "--------------------------------------------------------------\n";
  var i: Int = 0;
  while i < results.len() {
    let r = results[i];
    output = output + r.name;
    var pad: Int = r.name.len();
    while pad < 20 {
      output = output + " ";
      pad = pad + 1;
    };
    output = output + bench_human_ns(r.mean_ns);
    output = output + "  ";
    output = output + bench_human_ns(r.min_ns);
    output = output + "  ";
    output = output + bench_human_ns(r.max_ns);
    output = output + "  ";
    output = output + convert.int_to_string(bench_ops_per_sec_ns(&r));
    output = output + "\n";
    i = i + 1;
  };
  return output;
}

/// Generates a compact one-line-per-result report.
/// Complexity: O(n).
pub fn bench_report_simple(results: Vec[BenchResult]) -> Str {
  var output: Str = "";
  var i: Int = 0;
  while i < results.len() {
    let r = results[i];
    if i > 0 {
      output = output + "\n";
    };
    output = output + r.name + ": " + bench_human_ns(r.mean_ns);
    output = output + " (" + convert.int_to_string(r.iterations) + " runs)";
    i = i + 1;
  };
  return output;
}

// XIOM — Benchmarking Framework
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.bench

use xiom.time;

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

pub fn run_bench(name: Str, f: fn()) -> BenchResult {
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

pub fn run_bench_n(name: Str, iterations: Int, f: fn()) -> BenchResult {
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

pub fn compare(a: BenchResult, b: BenchResult) -> Str {
  if a.mean_ns < b.mean_ns {
    return a.name + " is faster than " + b.name;
  } elif b.mean_ns < a.mean_ns {
    return b.name + " is faster than " + a.name;
  } else {
    return a.name + " and " + b.name + " are equal";
  };
}

pub fn black_box[T](value: T) -> T {
  return value;
}

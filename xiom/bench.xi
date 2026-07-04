// XIOM — Benchmarking Framework
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.bench

pub type BenchResult = {
  name: Str;
  iterations: Int;
  total_ns: Int;
  mean_ns: Int;
  min_ns: Int;
  max_ns: Int;
  stddev_ns: Int;
} derive[Clone]

pub fn run_bench(name: Str, f: fn()) -> BenchResult;
pub fn run_bench_n(name: Str, iterations: Int, f: fn()) -> BenchResult;
pub fn compare(a: BenchResult, b: BenchResult) -> Str;

// Black box (prevent compiler from optimizing away)
pub fn black_box[T](value: T) -> T;

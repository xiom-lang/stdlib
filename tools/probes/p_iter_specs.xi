// p_iter_specs.xi -- wave-6 contract validation for iter length/count specs.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_iter_specs
use xiom.iter.chain;
use xiom.iter.filter;
use xiom.iter.fold;
use xiom.io;

fn is_even(x: &Int) -> Bool {
  return *x % 2 == 0;
}

fn add(a: &Int, b: &Int) -> Int {
  return *a + *b;
}

fn add_acc(acc: Int, b: &Int) -> Int {
  return acc + *b;
}

fn check(v: &Vec[Int]) -> Int {
  let n = v.len();
  if chain.iter_count(v) != n { return 1; };
  let c = chain.iter_count_if(v, is_even);
  if c < 0 || c > n { return 2; };
  if filter.iter_filter(v, is_even).len() > n { return 3; };
  if filter.iter_take(v, 2).len() > n { return 4; };
  if filter.iter_take(v, -1).len() > n { return 5; };
  if filter.iter_take(v, 100).len() > n { return 6; };
  if filter.iter_skip(v, 2).len() > n { return 7; };
  if filter.iter_skip(v, -1).len() > n { return 8; };
  if filter.iter_skip(v, 100).len() > n { return 9; };
  if filter.iter_dedup(v).len() > n { return 10; };
  if filter.iter_unique(v).len() > n { return 11; };
  if fold.iter_scan(v, 0, add_acc).len() != n + 1 { return 12; };
  if fold.iter_reverse(v).len() != n { return 13; };
  if fold.iter_sort(v).len() != n { return 14; };
  if fold.iter_cycle(v, 3).len() != n * 3 { return 15; };
  if fold.iter_cycle(v, 0).len() != 0 { return 16; };
  if fold.iter_cycle(v, -2).len() != 0 { return 17; };
  if fold.iter_repeat(7, 4).len() != 4 { return 18; };
  if fold.iter_repeat(7, 0).len() != 0 { return 19; };
  if fold.iter_repeat(7, -3).len() != 0 { return 20; };
  let f1 = fold.iter_fold1(v, add);
  if n == 0 && f1.is_some { return 21; };
  if n > 0 && !f1.is_some { return 22; };
  0
}

fn main() -> Int {
  var e: Vec[Int] = Vec[Int].new();
  var one = Vec[Int].new();
  one.push(1);
  var dup = Vec[Int].new();
  dup.push(1); dup.push(2); dup.push(2); dup.push(3); dup.push(3); dup.push(3);
  var neg = Vec[Int].new();
  neg.push(-5); neg.push(-1); neg.push(0); neg.push(4);

  let r1 = check(&e);
  if r1 != 0 { io.println("iter empty failed"); return r1; };
  let r2 = check(&one);
  if r2 != 0 { io.println("iter one failed"); return r2; };
  let r3 = check(&dup);
  if r3 != 0 { io.println("iter dup failed"); return r3; };
  let r4 = check(&neg);
  if r4 != 0 { io.println("iter neg failed"); return r4; };

  io.println("P_ITER_SPECS OK");
  io.flush_stdout();
  0
}

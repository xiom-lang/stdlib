// p_iter_range_collect_forwardref.xi -- xiom.iter Range.collect codegen
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding (official v0.62.3, v0.61.3 and the m189 dev build): calling
// xiom.iter's Range.collect() breaks codegen:
//
//   clang: xiominput.ll:3014:3: error: instruction forward referenced with
//   type 'ptr'
//
// The loop-based Range methods (len/contains/sum/product) compile and their
// clauses are runtime-exercised by tools/probes/p_wave65_shapes.xi; the
// closure-delegating siblings (count/find/next/max/min/nth/last/all/any/
// enumerate/take/skip) share the lowering family -- adding any clause to
// Range.count (even `result >= 0`) makes the unrelated smoke_iter program
// fail with "use of undefined value" in a generated __closure_N. Found
// while landing the wave-65 iter clauses; those methods are clause-free and
// probe-excluded until the closure lowering is fixed.
// Expected: rc 0 once fixed; observes compile rc 1 while open.
module p_iter_range_collect_forwardref

use xiom.iter;

fn main() -> Int {
  let r = iter.range(1, 3);
  let c = r.collect();
  if c.len() != 2 {
    return 2;
  }
  return 0;
}

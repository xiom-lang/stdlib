// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_iter_fold
use xiom.iter;

fn main() -> Int {
  var r = iter.range(1, 6);
  var sum = r.fold(0, fn(acc: Int, x: Int) -> Int { return acc + x; });
  if sum != 15 { return 1; }

  var r2 = iter.range(1, 5);
  var prod = r2.fold(1, fn(acc: Int, x: Int) -> Int { return acc * x; });
  if prod != 24 { return 2; }

  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_iter_range_sum
use xiom.iter;

fn main() -> Int {
    var r = iter.range(1, 5);
    if r.sum() == 10 {
      return 0;
    }
    return 1;
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_iter_range_len
use xiom.iter;

fn main() -> Int {
    var r = iter.range(3, 7);
    if r.len() == 4 {
      return 0;
    }
    return 1;
}

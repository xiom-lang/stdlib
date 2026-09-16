// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_compress_compression_ratio
use xiom.compress;

fn main() -> Int {
    var ratio = compress.compression_ratio(100, 50);

    if ratio >= 0.0 {
      return 0;
    }
    return 1;}

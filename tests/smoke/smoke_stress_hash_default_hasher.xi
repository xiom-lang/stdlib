// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_hash_default_hasher
use xiom.hash;

fn main() -> Int {
    var hasher = hash.DefaultHasher.new();
    hasher.write_int(42);
    hasher.write_int(100);
    hasher.write_str("hello");
    var h = hasher.finish();
    if h > 0 {
      return 0;
    }
    return 1;
}

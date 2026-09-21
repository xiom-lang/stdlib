// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_num_endian
use xiom.num;

fn main() -> Int {
  if num.from_le(42) != 42 { return 1; }
  if num.to_le(42) != 42 { return 2; }
  if num.from_be(42) != num.to_be(42) { return 3; }

  var n = 0x01020304;
  var swapped = num.to_be(n);
  var back = num.from_be(swapped);

  return 0;
}

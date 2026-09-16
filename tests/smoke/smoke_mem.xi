// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_mem
use xiom.mem;

fn main() -> Int {
  var a = 1;
  var b = 2;
  mem.swap[Int](&mut a, &mut b);
  if a != 2 { return 1; }
  if b != 1 { return 2; }
  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_mem_manually_drop
use xiom.mem;

fn main() -> Int {
  var md = mem.ManuallyDrop.new(42);
  if md.into_inner() != 42 { return 1; }

  var md2 = mem.ManuallyDrop.new("hello");
  if md2.take() != "hello" { return 2; }

  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_alloc_zeroed
use xiom.alloc;
use xiom.ptr;

fn main() -> Int {
  var p = alloc.alloc_zeroed(64);
  if ptr.is_null(p) { return 1; }

  alloc.dealloc(p, 64);

  return 0;
}

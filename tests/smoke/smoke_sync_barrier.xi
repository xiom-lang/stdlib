// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_sync_barrier
use xiom.sync;

fn main() -> Int {
  var b = sync.Barrier.new(1);

  b.wait();

  return 0;
}

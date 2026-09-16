// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_sync_once
use xiom.sync;

fn main() -> Int {
  var once = sync.Once.new();
  if once.is_completed() { return 1; }

  var called: Int = 0;
  once.call_once(fn() { });
  if !once.is_completed() { return 2; }

  return 0;
}

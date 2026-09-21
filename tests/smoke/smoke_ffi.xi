// XIOM stdlib smoke test -- xiom.ffi
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_ffi
use xiom.ffi;

fn main() -> Int {
  var buf = ffi.alloc(64);
  ffi.free(buf);
  if ffi.extern_c("malloc") == 0 {
    return 0;
  }
  return 1;
}

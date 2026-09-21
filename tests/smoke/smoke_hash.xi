// XIOM stdlib smoke test -- xiom.hash
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_hash
use xiom.hash;

fn main() -> Int {
  if hash.hash(42) == hash.hash(42) && hash.hash(true) != hash.hash(false) {
    return 0;
  }
  return 1;
}

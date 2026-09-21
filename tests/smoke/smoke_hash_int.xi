// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_hash_int
use xiom.hash;

fn main() -> Int {
  if hash.hash(0) != hash.hash(0) { return 1; }
  if hash.hash(42) != hash.hash(42) { return 2; }
  if hash.hash(-1) == hash.hash(0) { return 3; }

  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_hash_tuple
use xiom.hash.farm;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(65);
  var d = farm.farmhash128(&v);
  if d.0 == 0u64 && d.1 == 0u64 { io.println("zero"); return 1; }
  var fp = farm.farmhash_fingerprint128(&v);
  if fp.0 != d.0 { io.println("fp mismatch"); return 2; }
  io.println("HASH TUPLE OK");
  return 0;
}

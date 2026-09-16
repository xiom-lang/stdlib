// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_generic_probe
use xiom.io;
use xiom.hash;

// A: cast a generic to Int.
fn cast_key[K](k: &K) -> Int {
  return *k as Int;
}

// B: interface-bound generic param.
fn bounded_hash[K: Hash](k: &K) -> Int {
  var h = DefaultHasher.new();
  k.hash(h);
  return 0;
}

fn main() -> Int {
  let x = 42;
  let v = cast_key(&x);
  if v != 42 { return 1; }
  let y = 7;
  let _ = bounded_hash(&y);
  io.println("GENERIC PROBE OK");
  return 0;
}

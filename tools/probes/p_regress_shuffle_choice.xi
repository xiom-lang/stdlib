// p_regress_shuffle_choice.xi -- regression lock: generic &mut Vec[T] shuffle
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Compiler ask 2026-10-05 (shuffle/choice codegen): the historical failure
// was "crypto_random_shuffle / crypto_random_choice generic &mut Vec[T]
// lowering is blocked in this build" (tests/smoke/smoke_crypto_kdf.xi).
// Not reproducible on v0.63.1 for T=Int or T=Str, with both functions in one
// program. Returns 0 when every case holds.

module p_regress_shuffle_choice

use xiom.crypto.rng_crypto;

fn main() -> Int {
  var vi = Vec[Int].new();
  vi.push(1);
  vi.push(2);
  vi.push(3);
  rng_crypto.crypto_random_shuffle(&mut vi);
  if vi.len() != 3 { return 2; }
  let ci = rng_crypto.crypto_random_choice(&vi);
  if !ci.is_some { return 3; }

  var vs = Vec[Str].new();
  vs.push("a");
  vs.push("b");
  vs.push("c");
  rng_crypto.crypto_random_shuffle(&mut vs);
  if vs.len() != 3 { return 4; }
  let cs = rng_crypto.crypto_random_choice(&vs);
  if !cs.is_some { return 5; }
  return 0;
}

// p_ref_tuple_mangle.xi -- reference-typed tuple elements mangle to an
// invalid LLVM identifier.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Compiling xiom.crypto.sign (or this minimal shape) fails codegen with:
//   xiom: warning: unknown type '&Vec' -- defaulting to i64
//   xiominput.ll:70:16: error: expected '=' after name
//     %struct.Tuple__&Vec__Vec = type { i64, %struct.Vec }
// The '&' of the reference parameter survives into the mangled tuple type
// name, so the emitted LLVM struct declaration is not a valid identifier.
// Reproduced from xiom.crypto.sign.ed25519_keypair_from_seed
// (`return (seed, Vec[UInt8].new())`), whose Ed25519/ECDSA/DSA family is
// stubbed until this class is fixed (module header note).
module p_ref_tuple_mangle

fn pair(seed: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  return (seed, Vec[UInt8].new());
}

fn main() -> Int {
  var v: Vec[UInt8] = Vec[UInt8].new();
  let p = pair(&v);
  return 0;
}

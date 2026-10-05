// p_regress_scrypt.xi -- regression lock: scrypt ROMix execution
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Compiler ask 2026-10-05 (scrypt codegen): the historical failure was
// "scrypt's ROMix re-enters function-returned Vecs into &Vec params; heap
// corruption" (see tests/smoke/smoke_crypto_kdf.xi). Not reproducible on
// v0.63.1 with these shapes: N=4/r=2/p=1/dkLen=32, then the RFC-7914-sized
// N=1024/r=8/p=1/dkLen=64 twice. Returns 0 when every call is length-valid
// and survives.

module p_regress_scrypt

use xiom.crypto.kdf;

fn main() -> Int {
  var pass = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    pass.push(112u8);
    i = i + 1;
  }
  var salt = Vec[UInt8].new();
  i = 0;
  while i < 8 {
    salt.push(115u8);
    i = i + 1;
  }
  let a = kdf.scrypt(&pass, &salt, 4, 2, 1, 32);
  if a.len() != 32 { return 2; }
  let b = kdf.scrypt(&pass, &salt, 1024, 8, 1, 64);
  if b.len() != 64 { return 3; }
  let c = kdf.scrypt(&pass, &salt, 1024, 8, 1, 64);
  if c.len() != 64 { return 4; }
  return 0;
}

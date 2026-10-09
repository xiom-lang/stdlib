// p_sibling_dup_fn_alias.xi -- triplicate sibling exports break alias calls
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`popcount.next_pow2(1)` resolves and returns 1).
// Observed on compiler v0.64.1: compile fails with
//   error[T001]: cannot call 'next_pow2' on this expression
// once THREE sibling submodules that export the same function name
// (`rotate_left`/`rotate_right` in xiom.bits.rotation, xiom.bits.popcount and
// xiom.bits.bitwise) are imported together. Two-module combinations
// (bitfield+popcount, rotation+popcount) compile and run; adding the third
// copy of the duplicate name poisons alias-qualified resolution (the failing
// calls are alias-qualified to a module that itself is fine alone).
// Found while building the wave-97 probe; the probe was split
// (p_wave97_shapes.xi + p_wave97_bitwise_shapes.xi) as the workaround.

module p_sibling_dup_fn_alias

use xiom.bits.rotation;
use xiom.bits.popcount;
use xiom.bits.bitwise;

fn main() -> Int {
  let c = popcount.next_pow2(1);
  if c != 1 { return 1; }
  return 0;
}

// p_generic_byref_option.xi -- generic &Option[T]/&Result[T,E] queries read wrong
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (the standalone queries forward the direct field reads).
// Observed on compiler v0.64.1: `core.option_is_some(&o)` returns false for
// `Some(4)` (direct `o.is_some` is true), so the program exits 2 before the
// result check; the same silent wrongness affects option_is_none,
// result_is_ok and result_is_err when called through the `&Option[T]` /
// `&Result[T, E]` generic parameters. Non-generic by-ref params and generic
// `&Vec[T]` params (cmp.min_of_vec/max_of_vec) are correct on the same pin.
// Found while probing the wave-94 core clauses; those four functions stay
// clause-free until this resolves.

module p_generic_byref_option

use xiom.core;

fn main() -> Int {
  var o: Option[Int] = Some(4);
  if o.is_some == false { return 1; }
  if core.option_is_some(&o) == false { return 2; }
  var r: Result[Int, Str] = Ok(4);
  if r.is_ok == false { return 3; }
  if core.result_is_ok(&r) == false { return 4; }
  return 0;
}

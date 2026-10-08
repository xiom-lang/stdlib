// p_slice_bound_generic_c001.xi -- bounded generic &Slice[T] calls fail codegen
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`is_sorted` over [1, 2, 3] is true).
// Observed on compiler v0.64.1: codegen fails with
//   error[C001]: codegen: type 'Slice' does not implement 'Ord':
//   missing method 'compare'
// i.e. the bound of `is_sorted[T: Ord](s: &Slice[T])` is applied to the
// argument's full type instead of the element type. The same C001 hits
// `core.contains` / `core.min_slice` / `core.max_slice` (`Eq`/`Ord`).
// Related slice-surface symptoms (same wave, same family):
//   - `let s: Slice[Int] = array.as_slice(&arr); s.len()` reads wrong
//     (the unannotated control is correct), and `core.slice_len(&s)` is
//     wrong or crashes; `slice_first`/`slice_get`/`slice_to_vec` on the
//     annotated local AV (0xC0000005).
//   - unannotated locals degrade to `Vec` at the `core.slice_len` call
//     site: clang `'%struct.Vec' but expected '%struct.Slice'`.
// Found while probing the wave-94 core clauses; the Slice helpers stay
// clause-free until this resolves.

module p_slice_bound_generic_c001

use xiom.core;
use xiom.array;

fn main() -> Int {
  let arr = [1, 2, 3];
  let s = array.as_slice(&arr);
  if core.is_sorted(&s) == false { return 1; }
  return 0;
}

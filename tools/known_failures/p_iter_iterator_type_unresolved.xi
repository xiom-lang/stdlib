// p_iter_iterator_type_unresolved.xi -- xiom.iter M7 adapters unreachable
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (the M7 `Iterator` adapters resolve and `step_by(2)` yields
// 0 as its first element).
//
// Observed on compiler v0.64.1:
//   (a) every `use xiom.iter;` consumer compile prints
//       `xiom: warning: unknown type 'Iterator' -- defaulting to i64. This
//        may produce incorrect code.` (3-4x), because the receiver type
//       `Iterator[T]` of the M7 adapters
//       (`Iterator[T].step_by/take_while/skip_while/inspect`) and the
//       `iter: Iterator[T]` fields of `StepByIter`/`TakeWhileIter`/
//       `SkipWhileIter`/`InspectIter` are not declared anywhere in `xiom/`;
//   (b) the only reachable call form, `r.step_by(2)` on a Range, fails
//       codegen with
//       `error[C001]: codegen: unresolved function symbol(s) called but never
//        defined or declared: 'Iterator.step_by' ...` (previously a silent
//       zero/default auto-stub).
//
// Found while probing the wave-93 iter remainder; the concrete
// Range/MapIter/FilterIter/EnumerateIter/TakeIter/ChainIter adapters are
// unaffected on the same pin. Stdlib impact: the four M7 adapters and the
// four M7 iterator types stay clause-free until this resolves.

module p_iter_iterator_type_unresolved

use xiom.iter;

fn main() -> Int {
  var r = iter.range(0, 10);
  var sb = r.step_by(2);
  let v = sb.next();
  match v {
    Some(x) => { if x != 0 { return 1; } },
    None => { return 2; },
  }
  return 0;
}

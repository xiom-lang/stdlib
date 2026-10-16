// p_tostring_import_breaks_adapters.xi -- importing tostring breaks predicates
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`filter(lt3)` over range(0,6) yields Some(0) and
// `take_while(lt3)` yields Some(0)).
// Observed on compiler v0.64.2: rc 1 -- the predicate never sees the
// values (filter returns None immediately; take_while returns None and
// marks done). Bisect notes (2026-10-09, wave-98 work):
//   - the trigger is the `use xiom.convert.tostring ...` import itself;
//     `iter` + `io`, `iter` + `array`, `iter` + `array.fixed as afix`
//     combinations all behave correctly;
//   - aliasing (`as tostring`, `as ts`) and the plain leaf import are all
//     affected;
//   - inline lambdas are affected exactly like named function pointers;
//   - `Range.step_by` (no predicate) is unaffected; `Range.filter` (this
//     repro's first half) is affected although it is untouched by the
//     wave-98 M7 rewrite, so the corruption is module-import driven.
// No corpus smoke mixes the tostring import with iter adapters, which is
// why the corpus is green. Found while building the wave-98 probe; the
// probe was split (p_wave98_shapes.xi + p_wave98_tostring_shapes.xi) as
// the workaround.

module p_tostring_import_breaks_adapters

use xiom.iter;
use xiom.io;
use xiom.convert.tostring as tostring;

fn lt3(x: &Int) -> Bool { return *x < 3; }

fn main() -> Int {
  var r = iter.range(0, 6);
  let fi = r.filter(lt3);
  let f0 = fi.next();
  if f0.is_none { return 1; }
  var r2 = iter.range(0, 6);
  let tw = r2.take_while(lt3);
  let t0 = tw.next();
  if t0.is_none { return 2; }
  return 0;
}

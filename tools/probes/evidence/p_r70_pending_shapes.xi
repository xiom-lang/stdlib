// p_r70_pending_shapes.xi -- EVIDENCE (pending pin), written 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Green on compiler main R66-R72 (verified 2026-09-24 with a local
// compiler-main build: compile 0, run 0); must stay OUT of the probe gate
// until the stdlib pin carries R70-R72, because on v0.61.3 the `for`-over-Vec
// lowering is broken (silent corruption) and the pin's probe corpus would
// either fail or misbehave.
//
// shapes locked here (R-number in the fix batch):
//   R70:  `for x in <Vec>` element iteration, element typing
//   R70:  `for i in 0..b` / `0..=b` (requires `use xiom.iter;` so the
//         `range` name resolves -- bare `0..3` without the import is a
//         T001 undefined-variable on R72)
//   R67:  Some/Ok ctor with a user struct named *Result* (leaf test)
//   R68:  nested `extern "C" { }` block inside a function body
//   R69:  generic `T.to_str()` (99 -> "99", no f64 denormal)
//   R72:  indexed call through a FIXED-ARRAY fn literal (`var fns = [...]`)
// still open on R72 (confirmed here 2026-09-24, NOT locked):
//   `let fns = [double, triple]` (Vec[fn]) indexed call -> 0xC0000005;
//   `Vec[fn].new()` + push -> 0xC0000005.
// PROMOTE this file to tools/probes/ in the commit that bumps the pin to a
// compiler tag carrying R66-R72.

module p_r70_pending_shapes

use xiom.string;
use xiom.iter;

type TestResult = { value: Int; }

fn make_tr() -> TestResult { return TestResult{ value: 42 }; }

fn double(x: Int) -> Int { return x * 2; }
fn triple(x: Int) -> Int { return x * 3; }

fn tostr[T](x: T) -> Str { return x.to_str(); }

fn nested_now() -> Int
  requires: true  // extern xiom_async_now_ms (T002/T007 confinement)
{
  extern "C" {
    fn xiom_async_now_ms() -> Int;
  }
  unsafe { return xiom_async_now_ms(); }
}

fn main() -> Int {
  // R70: for-in over Vec[Int]
  var v: Vec[Int] = Vec[Int].new();
  v.push(1); v.push(2); v.push(3);
  var sum = 0;
  for x in v { sum = sum + x; }
  if sum != 6 { return 1; }

  // R70: exclusive and inclusive ranges (need the iter import)
  var rsum = 0;
  for i in 0..3 { rsum = rsum + i; }
  if rsum != 3 { return 2; }
  var rsum2 = 0;
  for i in 0..=3 { rsum2 = rsum2 + i; }
  if rsum2 != 6 { return 3; }

  // R67: user struct named *Result* through Some
  let o = Some(make_tr());
  match o {
    Some(x) => { if x.value != 42 { return 4; } };
    None => { return 5; }
  }

  // R68: nested extern "C" block
  if nested_now() < 0 { return 6; }

  // R69: generic T.to_str()
  if str_compare(tostr(99), "99") != 0 { return 7; }

  // R72: indexed call through a fixed-array fn literal
  var fns = [double, triple];
  if fns[0](4) != 8 { return 8; }
  if fns[1](4) != 12 { return 9; }
  return 0;
}

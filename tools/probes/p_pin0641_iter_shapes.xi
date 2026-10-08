// p_pin0641_iter_shapes.xi -- v0.64.1 pin lock: iter closure-thunk clauses
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The wave-65 iter clause set was compiler-blocked: adding a clause to
// Range.count made the closure-thunk lowering emit clang "use of undefined
// value" (block 27/46). m203/v0.64.1 fixes it. This probe locks the empty
// range guards on the retried set (contains/sum/product/collect/count/max/
// min/find/all/any/nth/last) plus the non-empty behavior of the closure-
// delegating methods. Returns 0 when every case holds.

module p_pin0641_iter_shapes

use xiom.iter;

fn main() -> Int {
  // ---- contains
  let r1 = iter.range(5, 5);
  let c0 = r1.contains(5);
  if c0 { return 1; }
  let r2 = iter.range(0, 5);
  let c1 = r2.contains(2);
  if c1 == false { return 2; }
  let c2 = r2.contains(5);
  if c2 { return 3; }

  // ---- sum / product
  let s0 = iter.range(5, 5).sum();
  if s0 != 0 { return 4; }
  let s1 = iter.range(1, 5).sum();
  if s1 != 10 { return 5; }
  let p0 = iter.range(5, 5).product();
  if p0 != 1 { return 6; }
  let p1 = iter.range(1, 4).product();
  if p1 != 6 { return 7; }

  // ---- collect / count
  let col0 = iter.range(5, 5).collect();
  if col0.len() != 0 { return 8; }
  let col1 = iter.range(0, 3).collect();
  if col1.len() != 3 { return 9; }
  let col1a = col1[0];
  if col1a != 0 { return 10; }
  let col1c = col1[2];
  if col1c != 2 { return 11; }
  let cnt0 = iter.range(5, 5).count();
  if cnt0 != 0 { return 12; }
  let cnt1 = iter.range(0, 3).count();
  if cnt1 != 3 { return 13; }

  // ---- max / min
  let mx0 = iter.range(5, 5).max();
  if mx0.is_some { return 14; }
  let mx1 = iter.range(0, 3).max();
  match mx1 {
    Some(mv) => { if mv != 2 { return 15; } },
    None => { return 16; },
  }
  let mn0 = iter.range(5, 5).min();
  if mn0.is_some { return 17; }
  let mn1 = iter.range(1, 4).min();
  match mn1 {
    Some(mv2) => { if mv2 != 1 { return 18; } },
    None => { return 19; },
  }

  // ---- find / all / any
  let fd0 = iter.range(5, 5).find(fn(x: &Int) -> Bool { return *x > 0; });
  if fd0.is_some { return 20; }
  let fd1 = iter.range(1, 10).find(fn(x: &Int) -> Bool { return *x > 5; });
  match fd1 {
    Some(fv) => { if fv != 6 { return 21; } },
    None => { return 22; },
  }
  let al0 = iter.range(5, 5).all(fn(x: &Int) -> Bool { return *x > 0; });
  if al0 == false { return 23; }
  let al1 = iter.range(1, 6).all(fn(x: &Int) -> Bool { return *x > 0; });
  if al1 == false { return 24; }
  let an0 = iter.range(5, 5).any(fn(x: &Int) -> Bool { return *x > 0; });
  if an0 { return 25; }
  let an1 = iter.range(1, 6).any(fn(x: &Int) -> Bool { return *x > 3; });
  if an1 == false { return 26; }

  // ---- nth / last
  let nth0 = iter.range(5, 5).nth(0);
  if nth0.is_some { return 27; }
  let nth1 = iter.range(0, 5).nth(2);
  match nth1 {
    Some(nv) => { if nv != 2 { return 28; } },
    None => { return 29; },
  }
  let last0 = iter.range(5, 5).last();
  if last0.is_some { return 30; }
  let last1 = iter.range(0, 3).last();
  match last1 {
    Some(lv) => { if lv != 2 { return 31; } },
    None => { return 32; },
  }

  return 0;
}

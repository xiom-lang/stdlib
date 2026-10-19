// p_wave195_iter_core.xi -- wave 195: iter/core contract-clause lock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-195 clauses that carry real information:
// 1. Range.next Option payload + cursor advance; RangeInclusive.next payload.
// 2. Range length/count/collect exact size laws, empty-fold seed, max/min/
//    last/nth payloads.
// 3. EnumerateIter index state, TakeIter count bound, SkipWhileIter
//    skipped transition.
// 4. iter.filter_mut shrink bound and take/skip_while length bounds.
// 5. core numeric/string conversion range laws (truncation, sign, Bool maps).
// Every call also re-evaluates the new runtime ensures; a violation aborts.
// Returns 0 when every case holds.

module p_wave195_iter_core

use xiom.iter;
use xiom.core;
use xiom.convert;

fn add(a: Int, b: Int) -> Int {
  return a + b;
}

fn keep_positive(x: &Int) -> Bool {
  return *x > 0;
}

fn is_small(x: &Int) -> Bool {
  return *x < 3;
}

fn main() -> Int {
  // 1: Range.next payload and cursor advance.
  var r = iter.range(3, 6);
  var n0 = r.next();
  if !n0.is_some { return 1; }
  if n0.value != 3 { return 2; }
  if r.start != 4 { return 3; }
  if r.len() != 2 { return 4; }

  // 2: length/count/collect/fold laws and terminal payloads.
  if iter.range(0, 5).collect().len() != 5 { return 5; }
  if iter.range(0, 5).count() != 5 { return 6; }
  if iter.range(7, 7).fold(11, add) != 11 { return 7; }
  var mx = iter.range(2, 9).max();
  if !mx.is_some || mx.value != 8 { return 8; }
  var mn = iter.range(2, 9).min();
  if !mn.is_some || mn.value != 2 { return 9; }
  var lst = iter.range(2, 9).last();
  if !lst.is_some || lst.value != 8 { return 10; }
  var nz = iter.range(2, 9).nth(0);
  if !nz.is_some || nz.value != 2 { return 11; }

  // RangeInclusive.next payload and inclusive cursor state.
  var ri = iter.range_inclusive(4, 5);
  var i0 = ri.next();
  if !i0.is_some || i0.value != 4 { return 12; }
  if ri.current != 5 || ri.done { return 13; }
  var i1 = ri.next();
  if !i1.is_some || i1.value != 5 { return 14; }
  if !ri.done { return 15; }

  // 3: enumerate index state, take count bound, skip_while transition.
  var e = iter.range(10, 13).enumerate();
  var e0 = e.next();
  if !e0.is_some { return 16; }
  if e0.value.0 != 0 || e.index != 1 { return 17; }
  var e1 = e.next();
  if e1.value.0 != 1 || e.index != 2 { return 18; }
  var tk = iter.range(0, 10).take(3);
  if tk.count() > 3 { return 19; }
  var sw = iter.range(1, 6).skip_while(is_small);
  var s0 = sw.next();
  if !s0.is_some || s0.value != 3 { return 20; }
  if !sw.skipped { return 21; }

  // 4: filter_mut shrink bound and take/skip_while length bounds.
  var v = Vec[Int].new();
  v.push(1);
  v.push(-2);
  v.push(3);
  var before = v.len();
  xiom.iter.filter.iter_filter_mut(&mut v, keep_positive);
  if v.len() > before { return 22; }
  if v.len() != 2 { return 23; }
  var tw = xiom.iter.filter.iter_take_while(&v, keep_positive);
  if tw.len() > v.len() { return 24; }
  var skw = xiom.iter.filter.iter_skip_while(&v, keep_positive);
  if skw.len() > v.len() { return 25; }

  // 5: core conversion range laws.
  if core.to_int(3.75) != 3 { return 26; }
  if core.to_int(-0.5) != 0 { return 27; }
  if core.to_float(5) < 0.0 { return 28; }
  if core.to_float(-5) >= 0.0 { return 29; }
  if core.bool_to_int(true) != 1 { return 30; }
  if core.bool_to_int(false) != 0 { return 31; }
  if convert.bool_to_string(true) != "true" { return 32; }
  if convert.bool_to_string(false) != "false" { return 33; }
  if core.to_string(0) != "0" { return 34; }

  return 0;
}

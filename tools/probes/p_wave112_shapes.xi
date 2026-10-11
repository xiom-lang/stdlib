// p_wave112_shapes.xi -- wave 112 shape validation: the core Option/Result
// standalone queries and the Slice-param helper set, unblocked by the
// compiler v0.64.3 generic by-reference fix (REL-20261010-1548-stdlib-5).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Non-empty Int slices come from array.as_slice (N > 0 on the pin); there
// is no constructible empty-slice literal on v0.64.3 (`Str.as_bytes` does
// not resolve and `[0]`/`[]` arrays lose the const N, M33), so the
// zero-length clause branches stay compile-validated and structurally
// true but run-unexercised. The Option/Result queries cover all four
// variant combinations.
// Returns 0 when every case holds.

module p_wave112_shapes

use xiom.core;
use xiom.array;

fn main() -> Int {
  // ---- non-empty Int slice
  let arr = [3, 1, 4, 1, 5];
  var s = array.as_slice(&arr);
  if core.slice_len(&s) != 5 { return 1; }
  if core.slice_is_empty(&s) { return 2; }
  if core.is_sorted(&s) { return 3; }
  match core.slice_first(&s) {
    Some(v) => { if v != 3 { return 4; } },
    None => { return 4; }
  }
  match core.slice_get(&s, 2) {
    Some(v2) => { if v2 != 4 { return 5; } },
    None => { return 5; }
  }
  match core.slice_get(&s, 5) {
    Some(_) => { return 6; },
    None => {}
  }
  match core.slice_get(&s, -1) {
    Some(_) => { return 7; },
    None => {}
  }
  var copied = core.slice_to_vec(&s);
  if copied.len() != 5 { return 8; }
  if copied[0] != 3 || copied[4] != 5 { return 9; }
  match core.min_slice(&s) {
    Some(mn) => { if mn != 1 { return 10; } },
    None => { return 10; }
  }
  match core.max_slice(&s) {
    Some(mx) => { if mx != 5 { return 11; } },
    None => { return 11; }
  }
  if core.sum_slice(&s) != 14 { return 12; }
  if !core.contains(&s, 4) { return 13; }
  if core.contains(&s, 99) { return 14; }
  if !core.all(&s, fn(x: Int) -> Bool { return x > 0; }) { return 15; }
  if core.all(&s, fn(x: Int) -> Bool { return x > 1; }) { return 16; }
  if !core.none(&s, fn(x: Int) -> Bool { return x > 100; }) { return 17; }
  if core.none(&s, fn(x: Int) -> Bool { return x > 0; }) { return 18; }

  // ---- sorted second slice
  let arr2 = [1, 2, 3];
  var s2 = array.as_slice(&arr2);
  if !core.is_sorted(&s2) { return 19; }

  // ---- Option / Result standalone queries
  let so = Some(7);
  let no: Option[Int] = None;
  if !core.option_is_some(&so) { return 20; }
  if core.option_is_none(&so) { return 21; }
  if core.option_is_some(&no) { return 22; }
  if !core.option_is_none(&no) { return 23; }
  let okv: Result[Int, Str] = Ok(7);
  let errv: Result[Int, Str] = Err("e");
  if !core.result_is_ok(&okv) { return 24; }
  if core.result_is_err(&okv) { return 25; }
  if core.result_is_ok(&errv) { return 26; }
  if !core.result_is_err(&errv) { return 27; }

  return 0;
}

// p_wave25_shapes.xi -- contract shape validation for wave 25 (collections).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 25 applies to xiom.collections:
// 1. length preservation on a &mut parameter through the pre-state:
//    `v.len() == v.len()@pre`; monotone shrink `v.len() <= v.len()@pre`;
//    exact removal count `result == v.len()@pre - v.len()`
// 2. post-state reset: `m.len() == 0` for a &mut map
// 3. empty/one-element guarded identities, including Str equality:
//    `items.len() == 1 => result == items[0]`
// 4. Option presence mirrors: `v.len() == 0 => result is None` /
//    `v.len() > 0 => result is Some`
// 5. aggregate bounds: `result >= 0 && result <= v.len()`,
//    `result.len() >= a.len()`, `result.len() <= a.len() + b.len()`,
//    `result.len() == s.len()` (Set -> Vec), `result.len() == v.len()`
// 6. sliding-window exact counts:
//    `k > 0 && k <= v.len() => result.len() == v.len() - k + 1`,
//    `k > v.len() && v.len() > 0 => result.len() == 1`
// 7. parity and arithmetic on result lengths:
//    `result.len() % 2 == 0`, `result.len() == (v.len() + 1) / 2`
// 8. Boolean exact mirrors: `result == (v.len() == 0)`
// main() drives the real functions; every call evaluates the new runtime
// clauses. Returns 0 when every shape compiles and holds.

module p_wave25_shapes

use xiom.collections;

fn pred_true(x: &Int) -> Bool { return true; }
fn is_even_pred(x: &Int) -> Bool { return *x % 2 == 0; }

fn main() -> Int {
  // 6: sliding windows
  var v: Vec[Int] = Vec[Int].new();
  v.push(1); v.push(3); v.push(2);
  let w2 = vec_window_max(&v, 2);
  if w2.len() != 2 { return 1; }
  if w2[0] != 3 { return 2; }
  let w1 = vec_window_max(&v, 5);
  if w1.len() != 1 { return 3; }
  let w0 = vec_window_max(&v, 0);
  if w0.len() != 0 { return 4; }
  let m2 = vec_window_min(&v, 2);
  if m2.len() != 2 { return 5; }
  let m1 = vec_window_min(&v, 5);
  if m1.len() != 1 { return 6; }

  // 7: unzip/zip lengths
  var u: Vec[Int] = Vec[Int].new();
  u.push(1); u.push(2); u.push(3); u.push(4); u.push(5);
  let ev = vec_unzip_evens(&u);
  if ev.len() != 3 { return 7; }
  let od = vec_unzip_odds(&u);
  if od.len() != 2 { return 8; }
  let z = vec_zip_int(&v, &u);
  if z.len() % 2 != 0 { return 9; }
  if z.len() > 2 * 3 { return 10; }

  // 5: aggregates
  let cs = vec_cumsum(&u);
  if cs.len() != 5 { return 11; }
  let fk = vec_frequency_keys(&u);
  if fk.len() > u.len() { return 12; }
  let fc = vec_frequency_counts(&u);
  if fc.len() > u.len() { return 13; }
  let fa = vec_find_all(&u, 3);
  if fa.len() > u.len() { return 14; }
  if vec_count_if(&u, pred_true) != 5 { return 15; }
  if vec_left(&u, 2).len() != 2 { return 16; }
  if vec_left(&u, -1).len() != 0 { return 17; }
  if vec_right(&u, 2).len() != 3 { return 18; }
  if vec_right(&u, 99).len() != 0 { return 19; }

  // 1: @pre length shapes
  var r: Vec[Int] = Vec[Int].new();
  r.push(1); r.push(2); r.push(3);
  vec_reverse(&mut r);
  if r.len() != 3 { return 20; }
  if r[0] != 3 { return 21; }
  vec_rotate_left(&mut r, 1);
  if r.len() != 3 { return 22; }
  vec_fill(&mut r, 7);
  if r.len() != 3 { return 23; }
  if r[0] != 7 { return 24; }
  vec_swap_elems(&mut r, 0, 1);
  if r.len() != 3 { return 25; }
  var d: Vec[Int] = Vec[Int].new();
  d.push(1); d.push(1); d.push(2); d.push(2); d.push(2);
  vec_dedup(&mut d);
  if d.len() != 2 { return 26; }
  var ra: Vec[Int] = Vec[Int].new();
  ra.push(1); ra.push(2); ra.push(1);
  vec_remove_all(&mut ra, 1);
  if ra.len() != 1 { return 27; }
  var rem: Vec[Int] = Vec[Int].new();
  rem.push(5); rem.push(5); rem.push(6);
  let removed = vec_retain(&mut rem, is_even_pred);
  if removed != 2 { return 28; }
  if rem.len() != 1 { return 29; }

  // 2: post-state reset
  var mm = Map[Int, Int].new();
  mm.insert(1, 1);
  map_clear(&mut mm);
  if mm.len() != 0 { return 30; }

  // 3+4+8: empty/short guards, Option mirrors, Boolean mirrors
  var e: Vec[Int] = Vec[Int].new();
  if vec_sum(&e) != 0 { return 31; }
  if vec_avg(&e) != 0 { return 32; }
  if vec_product(&e) != 1 { return 33; }
  if vec_any(&e, pred_true) { return 34; }
  if !vec_all(&e, pred_true) { return 35; }
  if !vec_is_sorted(&e) { return 36; }
  if !vec_is_empty(&e) { return 37; }
  if !vec_min(&e).is_none { return 38; }
  if !vec_max(&e).is_none { return 39; }
  if vec_min(&u).is_none { return 40; }
  if !vec_max(&u).is_some { return 41; }
  var med_empty: Vec[Int] = Vec[Int].new();
  if !vec_median(&mut med_empty).is_none { return 42; }
  var p_empty: Vec[Int] = Vec[Int].new();
  if !vec_percentile(&mut p_empty, 50).is_none { return 43; }
  if !vec_percentile(&mut u, 200).is_none { return 44; }
  if vec_dot(&v, &u).is_some { return 45; }

  // 3: join identities
  var items: Vec[Str] = Vec[Str].new();
  if vec_str_join(&items, "-").len() != 0 { return 46; }
  items.push("a");
  if vec_str_join(&items, "-") != "a" { return 47; }

  // 5: Set/Map bounds
  var sa = Set[Int].new();
  set_insert(&mut sa, 1);
  set_insert(&mut sa, 2);
  var sb = Set[Int].new();
  set_insert(&mut sb, 2);
  if set_len(&sa) < 0 { return 48; }
  let su = set_union(&sa, &sb);
  if su.len() < sa.len() { return 49; }
  if su.len() > sa.len() + sb.len() { return 50; }
  let si = set_intersection(&sa, &sb);
  if si.len() > sa.len() { return 51; }
  let sd = set_difference(&sa, &sb);
  if sd.len() > sa.len() { return 52; }
  let sv = set_to_vec(&sa);
  if sv.len() != sa.len() { return 53; }
  let sf = set_from_vec(&u);
  if sf.len() > u.len() { return 54; }
  if set_is_empty(&sa) != (sa.len() == 0) { return 55; }
  var ma = Map[Int, Int].new();
  ma.insert(1, 10);
  ma.insert(2, 20);
  var mb = Map[Int, Int].new();
  mb.insert(2, 99);
  mb.insert(3, 30);
  if map_len(ma) < 0 { return 56; }
  let mmg = map_merge(&ma, &mb);
  if mmg.len() < ma.len() { return 57; }
  if mmg.len() > ma.len() + mb.len() { return 58; }
  return 0;
}

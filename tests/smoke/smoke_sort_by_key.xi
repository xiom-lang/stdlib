// XIOM stdlib smoke test - xiom.sort.sort_by_key
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).
//
// Covers the instantiations that are correct on compiler v0.61.3:
// same-type key (Int -> Int) and the working cross-type pair (Str -> Int).
// The broken cross-type pair (Int -> Str) is filed as a compiler finding in
// tools/known_failures/p_generic_typechanging_sortbykey.xi; when that is
// fixed, extend this smoke with the Str-key case.

module smoke_sort_by_key
use xiom.sort;

fn neg(x: &Int) -> Int { return 0 - *x; }
fn len_key(x: &Str) -> Int { return x.len(); }

fn main() -> Int {
  // same-type key: descending Ints
  var v: Vec[Int] = Vec[Int].new();
  v.push(1); v.push(3); v.push(2);
  sort.sort_by_key(&v, neg);
  if v[0] != 3 { return 1; }
  if v[1] != 2 { return 2; }
  if v[2] != 1 { return 3; }

  // cross-type key that works: Vec[Str] by byte length
  var s: Vec[Str] = Vec[Str].new();
  s.push("ccc"); s.push("a"); s.push("bb");
  sort.sort_by_key(&s, len_key);
  if s[0] != "a" { return 4; }
  if s[1] != "bb" { return 5; }
  if s[2] != "ccc" { return 6; }

  // empty and single-element inputs are no-ops
  var e: Vec[Int] = Vec[Int].new();
  sort.sort_by_key(&e, neg);
  if e.len() != 0 { return 7; }
  var one: Vec[Int] = Vec[Int].new();
  one.push(9);
  sort.sort_by_key(&one, neg);
  if one[0] != 9 { return 8; }

  return 0;
}

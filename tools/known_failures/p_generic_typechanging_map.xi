// p_generic_typechanging_map.xi -- KNOWN FAILURE (compiler), filed 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// By-value [T, U] Vec map with a type-changing callback (fn(T) -> U),
// U = Str: silently wrong element values on compiler v0.61.3.
// Same cross-type generic-callback defect as p_generic_typechanging_fnptr.xi,
// different callback ABI (by-value instead of by-reference).
//
//   xiom --force -o out.exe p_generic_typechanging_map.xi
//   expected: run exits 0 (["1", "2"])
//   observed: compile 0, run 41 (w[0] != "1"); the Int leg of the same map
//             (U = Int) is correct, and Int->Float64 is also wrong (exit 100).
//
// Stays in tools/known_failures/ until fixed.

module p_generic_typechanging_map

use xiom.string;
use xiom.convert;

fn mapv[T, U](v: &Vec[T], f: fn(T) -> U) -> Vec[U] {
  var out = Vec[U].new();
  var i = 0;
  while i < v.len() {
    out.push(f(v[i]));
    i = i + 1;
  }
  return out;
}

fn to_s(x: Int) -> Str { return convert.int_to_string(x); }

fn main() -> Int {
  var v: Vec[Int] = Vec[Int].new();
  v.push(1); v.push(2);
  let ws = mapv(&v, to_s);
  if ws.len() != 2 { return 40; }
  if str_compare(ws[0], "1") != 0 { return 41; }
  if str_compare(ws[1], "2") != 0 { return 42; }
  return 0;
}

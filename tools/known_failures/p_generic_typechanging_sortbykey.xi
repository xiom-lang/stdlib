// p_generic_typechanging_sortbykey.xi -- KNOWN FAILURE (compiler), filed 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// STDLIB EXPOSURE of the cross-type generic-callback defect:
// `xiom.sort.sort_by_key[T, K: Ord](arr: &mut Vec[T], key: fn(&T) -> K)`
// silently mis-sorts for the type-changing instantiation T = Int, K = Str.
//
//   xiom --force -o out.exe p_generic_typechanging_sortbykey.xi
//   expected: run exits 0 (lexicographic Str keys: "1" < "10" < "2")
//   observed: compile 0, run 1 (v[0] is not 1; the array is left in a wrong
//             order -- no crash, no diagnostic).
//
// Related instantiations on v0.61.3: T = Str, K = Int works (sorting
// Vec[Str] by length); T = Int, K = Int works; concrete comparators work.
// `sort_by_key` has NO smoke coverage today (smoke_array_sort_by covers
// array.sort_by only), so the corpus cannot see this.
// Stays in tools/known_failures/ until fixed; then promote to tools/probes/.

module p_generic_typechanging_sortbykey

use xiom.sort;
use xiom.convert;

fn key_str(x: &Int) -> Str { return convert.int_to_string(*x); }

fn main() -> Int {
  var v: Vec[Int] = Vec[Int].new();
  v.push(2); v.push(10); v.push(1);
  sort.sort_by_key(&v, key_str);
  if v[0] != 1 { return 1; }
  if v[1] != 10 { return 2; }
  if v[2] != 2 { return 3; }
  return 0;
}

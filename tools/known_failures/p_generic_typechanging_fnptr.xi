// p_generic_typechanging_fnptr.xi -- KNOWN FAILURE (compiler), filed 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// [T, U] generic with a type-changing fn-pointer callback (fn(&T) -> U)
// returns a wrong value when U is not the same runtime type as T.
//
// Packages-lane reproduction, confirmed on stdlib compiler v0.61.3
// (`%TEMP%\kilo\stdlib_ws\xiom_v0613.exe`):
//   xiom --force -o out.exe p_generic_typechanging_fnptr.xi
//   expected: run exits 0 (the mapped Str equals "7")
//   observed: compile 0, run 23 = 21 + str_len(result); the returned Str is
//             NOT "7" (a 2-byte wrong value). The packages lane observed the
//             same shape exiting 21.
//
// Matrix reproduced on v0.61.3 (same root cause unless noted):
//   fn(&T) -> U   Int->Str    BROKEN (this file, exit 23)
//   fn(T)   -> U  Int->Str    BROKEN (see p_generic_typechanging_map.xi, 41)
//   fn(T)   -> U  Int->Float64 BROKEN (wrong value, exit 100)
//   fn(T)   -> U  Int->Int    works
//   fn(&T) -> K   Str->Int    works (xiom.sort.sort_by_key[Str, Int])
//   fn(&T) -> K   Int->Str    BROKEN (see p_generic_typechanging_sortbykey.xi)
//   concrete fn(&Int) -> Str  works (control)
// So: concrete callback types are correct; same-type generic callbacks are
// correct; a cross-type generic callback result is miscompiled.
//
// Stays in tools/known_failures/ until the compiler lane fixes it; then
// promote to tools/probes/ (expected run exit 0).

module p_generic_typechanging_fnptr

use xiom.string;
use xiom.convert;

pub fn conv[T, U](x: T, f: fn(&T) -> U) -> U { return f(&x); }

fn to_s(x: &Int) -> Str { return convert.int_to_string(*x); }

fn main() -> Int {
  let a = conv(7, to_s);
  if str_compare(a, "7") == 0 { return 0; }
  return 21 + str_len(a);
}

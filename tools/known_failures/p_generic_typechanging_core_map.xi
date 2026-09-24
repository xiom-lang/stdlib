// p_generic_typechanging_core_map.xi -- KNOWN FAILURE (compiler), filed 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Core `Option[T].map[U]` / `Result[T, E].map[U]` with a type-changing
// callback returning Str silently produce a wrong value on compiler v0.61.3.
// This is the same cross-type generic-callback defect as
// p_generic_typechanging_fnptr.xi, reaching the core methods.
//
//   xiom --force -o out.exe p_generic_typechanging_core_map.xi
//   expected: run exits 0
//   observed: compile 0, run 41 (Some arm taken, but the Str != "7").
// The Result leg (Ok(5).map(to_s) != "5") fails the same way (exit 51) when
// reached.
//
// Corpus impact: the shipped smokes only exercise same-type maps
// (smoke_core_option_map / smoke_core_result_map map Int -> Int), so the
// corpus is green while this shape is silently wrong.
// Stays in tools/known_failures/ until fixed.

module p_generic_typechanging_core_map

use xiom.string;
use xiom.convert;

fn to_s(x: Int) -> Str { return convert.int_to_string(x); }

fn main() -> Int {
  let o = Some(7);
  match o.map(to_s) {
    Some(s) => {
      if str_compare(s, "7") != 0 { return 41; }
    };
    None => { return 40; }
  }
  return 0;
}

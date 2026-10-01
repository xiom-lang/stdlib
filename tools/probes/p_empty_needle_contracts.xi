// p_empty_needle_contracts.xi -- packages defect lock (2026-10-01)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The packages lane reported a runtime contract violation for
// xiom.string.index_of / str_contains with an empty needle: both bodies and
// their docs promise empty-needle semantics (Some(0) / true), but
// index_of's `requires: substr.len() > 0` aborted before the body ran. The
// same contradiction existed on str_index_of (doc: "For an empty needle,
// returns Some(0)") and str_replace_all (doc: "If from is empty, returns s
// unchanged"). This probe calls every affected path with an empty needle;
// before the fix it aborts on index_of's precondition, after the fix it
// returns 0.
// Returns 0 when every case holds.

module p_empty_needle_contracts

use xiom.string;
use xiom.string.search;

fn main() -> Int {
  // xiom.string
  var c1 = string.str_contains("hello", "");
  if !c1 { return 1; }
  var i1 = string.index_of("hello", "");
  if !i1.is_some { return 2; }
  if i1.unwrap() != 0 { return 3; }
  var si = string.str_index_of("hello", "");
  if !si.is_some { return 4; }
  if si.unwrap() != 0 { return 5; }
  var r1 = string.str_replace_all("aaa", "", "b");
  if r1.len() != 3 { return 6; }
  var c2 = string.str_contains("", "");
  if !c2 { return 7; }
  var i2 = string.index_of("", "");
  if !i2.is_some { return 8; }
  if i2.unwrap() != 0 { return 9; }

  // xiom.string.search wrappers (empty needle handled explicitly)
  var c3 = search.str_contains("hello", "");
  if !c3 { return 10; }
  var i3 = search.str_index_of("hello", "");
  if !i3.is_some { return 11; }
  if i3.unwrap() != 0 { return 12; }
  var l3 = search.str_last_index_of("hello", "");
  if !l3.is_some { return 13; }
  if l3.unwrap() != 5 { return 14; }
  return 0;
}

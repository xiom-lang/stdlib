// p_regress_bug18_combo.xi -- regression lock: BUG 18 module combination
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Compiler ask 2026-10-05 (BUG 18 combinations): the historical failure was
// "string + text.similarity + time in one program crashes at startup"
// (tests/smoke/smoke_str2.xi / smoke_time2.xi headers; the strptime `%Q`
// early-return path was also reported to miscompile at -O2 in combination).
// Not reproducible on v0.63.1 with the documented module set and sampled
// entry points (rot13/translate, jaccard, strftime/strptime). Note: the `%Q`
// format path is no longer present in xiom/time/time.xi, so that face cannot
// be re-tested without restoring the code. Returns 0 when every case holds.

module p_regress_bug18_combo

use xiom.io;
use xiom.string;
use xiom.text.similarity;
use xiom.time;

fn main() -> Int {
  if xiom.string.str_rot13("Hello") != "Uryyb" { return 1; }
  if xiom.string.str_translate("hello", "aeiou", "AEIOU") != "hEllO" { return 2; }
  let s = similarity.jaccard_similarity("abc", "abd", 2);
  if s < 0.0 { return 3; }
  var d = xiom.time.date_new(2026, 8, 11);
  if xiom.time.strftime("%Y-%m-%d", &d) != "2026-08-11" { return 4; }
  var p = xiom.time.strptime("2026-08-11", "%Y-%m-%d");
  if !p.is_ok { return 5; }
  if p.date.year != 2026 { return 6; }
  return 0;
}

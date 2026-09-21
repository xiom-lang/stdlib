// p_wave6p3_specs.xi -- wave 6 part 3 validation: natural-order sign bounds +
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// unicode wrapper specs.
module p_wave6p3_specs
use xiom.misc.natural;
use xiom.string.unicode as uni;
use xiom.io;

fn main() -> Int {
  // The ensures clauses self-validate on every call; the checks below only
  // pin the expected signs.
  if natural.natural_compare("x2", "x10") != -1 { return 1; };
  if natural.natural_compare("x10", "x2") != 1 { return 2; };
  if natural.natural_compare("a", "a") != 0 { return 3; };
  if natural.natural_compare_ignore_case("A2", "a10") != -1 { return 4; };
  if natural.natural_compare_ignore_case("a10", "A2") != 1 { return 5; };
  if natural.natural_compare_numeric("007", "7") != 0 { return 6; };
  if natural.natural_compare_numeric("7", "8") != -1 { return 7; };
  if natural.natural_compare_numeric("8", "7") != 1 { return 8; };

  let ascii = "\u{0041}".char_at(0);
  match ascii {
    Some(ca) => {
      if uni.unicode_is_wide(ca) { io.println("ascii wide"); return 9; };
      if uni.unicode_is_emoji(ca) { io.println("ascii emoji"); return 10; };
    },
    None => { return 11; }
  };

  var wide = "\u{4E2D}".char_at(0);
  match wide {
    Some(cw) => {
      if !uni.unicode_is_wide(cw) { io.println("cjk not wide"); return 12; };
    },
    None => { return 13; }
  };

  var emo = "\u{1F600}".char_at(0);
  match emo {
    Some(ce) => {
      if !uni.unicode_is_emoji(ce) { io.println("emoji not emoji"); return 14; };
    },
    None => { return 15; }
  };

  // quick checks: NFC of "e" + combining acute is single-codepoint e-acute.
  if !uni.unicode_nfc_quick_check("abc") { io.println("abc not nfc"); return 16; };
  if !uni.unicode_nfkc_quick_check("abc") { io.println("abc not nfkc"); return 17; };

  io.println("P_WAVE6P3_SPECS OK");
  io.flush_stdout();
  0
}

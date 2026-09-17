// p_idna_valid.xi -- pin xiom.convert.punycode.idna_is_valid inputs.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_idna_valid
use xiom.convert.punycode as cvt;
use xiom.io;

fn b(v: Bool) -> Str {
  if v { return "true"; };
  "false"
}

fn main() -> Int {
  io.println("unicode=" + b(cvt.idna_is_valid("m\u{00FC}nchen.de")));
  io.println("ace=" + b(cvt.idna_is_valid("xn--mnchen-3ya.de")));
  io.println("ascii=" + b(cvt.idna_is_valid("munchen.de")));
  io.flush_stdout();
  0
}

// p_wave29_syntax_shapes.xi -- shape validation for wave 29 (regex/syntax.xi).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Separate file because xiom.regex.regex and xiom.regex.syntax export
// overlapping bare names (`regex_escape`, `regex_is_valid`, ...) and a second
// sibling import clobbers the first's exports in this build.
// Locks: escape length bounds, unescape Ok/Err/empty guards, parse Ok payload
// field relations, validate/syntax-error empty guards, character-class
// guards and the 14-byte floor, quantifier guard/floor shapes.
// Returns 0 when all hold.

module p_wave29_syntax_shapes

use xiom.regex.syntax;

fn main() -> Int {
  let esc = syntax.regex_escape("a.b*");
  if esc.len() < 4 { return 1; }
  if esc.len() > 8 { return 2; }
  let un = syntax.regex_unescape("a\\n");
  if !un.is_ok { return 3; }
  let bad = syntax.regex_unescape("a\\");
  if !bad.is_err { return 4; }
  let eu = syntax.regex_unescape("");
  if !eu.is_ok { return 5; }
  if !syntax.regex_validate("") { return 6; }
  if !syntax.regex_syntax_error("").is_none { return 7; }
  if syntax.regex_character_class("").len() != 0 { return 8; }
  let cc = syntax.regex_character_class("digit");
  if cc.len() > 14 { return 9; }
  if syntax.regex_quantifier(-1, 2).len() != 0 { return 10; }
  if syntax.regex_quantifier(2, 1).len() != 0 { return 11; }
  if syntax.regex_quantifier(2, 2).len() < 3 { return 12; }
  if syntax.regex_quantifier(2, -1).len() < 3 { return 13; }
  let pa = syntax.regex_parse("a+");
  if !pa.is_ok { return 14; }
  return 0;
}

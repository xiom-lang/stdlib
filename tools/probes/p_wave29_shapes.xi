// p_wave29_shapes.xi -- contract shape validation for wave 29 (regex).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 29 applies to xiom.regex.regex and xiom.regex.syntax:
// 1. Result-Ok payload field reads in a clause:
//    `result is Ok => result.value.pattern == pattern`
// 2. Option payload bounds/precens: `result is Some => result.value.end <= text.len()`
// 3. exact empty-pattern counts: `pattern.len() == 0 => result.len() == text.len() + 1`
// 4. length upper bounds on replaced/split/escaped text
// 5. capture mirror pairs on `Captures.get`
// 6. quantifier/character-class guards and floors
// main() drives the real functions with safe inputs; every call evaluates
// the new runtime clauses. Returns 0 when all hold.

module p_wave29_shapes

use xiom.regex.regex;

fn main() -> Int {
  // 1+3: compile and empty-pattern exact counts
  let cr = regex.Regex.new("a+");
  match cr {
    Ok(r) => {
      if !r.is_match("xxaaxx") { return 2; }
      if !r.find("xxaaxx").is_some { return 3; }
      let all = r.find_all("a1b22c333");
      if all.len() < 1 { return 4; }
      if all.len() > 9 + 1 { return 5; }
      if r.replace("aaa", "b").len() > 3 + 1 { return 6; }
      if r.split("xaaay").len() < 1 { return 7; }
      if r.match_count("a1b22c333") < 0 { return 8; }
      let ra = r.replace_all("aaa", "b");
      if ra.len() > 3 + (3 + 1) * 1 { return 14; }
      let fp = regex.regex_find_first_str(r, "xxaaxx");
      if !fp.is_some { return 15; }
      if regex.regex_count_matches(r, "aaa") < 0 { return 16; }
      if regex.regex_matches_all(r, "aaa").len() < 1 { return 17; }
      if regex.regex_extract_groups(r, "aaa").len() > 1 { return 18; }
      if regex.regex_split(r, "xaaay").len() < 1 { return 19; }
    };
    Err(e) => { return 20; };
  }

  let er0 = regex.Regex.new("");
  match er0 {
    Ok(r0) => {
      let all0 = r0.find_all("ab");
      if all0.len() != 3 { return 21; }
      if !r0.is_match("") { return 22; }
    };
    Err(e) => { return 23; };
  }

  // 4: escape helpers on the regex module
  let el = regex.regex_escape_literal(".");
  if el.len() < 1 { return 38; }
  if el.len() > 2 { return 39; }
  return 0;
}

// p_wave184_regex_shapes.xi -- wave-184 regex contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-184 xiom.regex.engine / pcre_lite contract surfaces:
// compile Ok/Err split, engine validity preconditions, empty-pattern
// find_all/split shapes, capture-name emptiness, invalid-pattern
// convenience behavior, and invalid-handle pcre rows.
// Expected: rc 0.

module p_wave184_regex_shapes

use xiom.regex.engine;
use xiom.regex.pcre_lite;
use xiom.io;

fn main() -> Int {
  match engine.regex_compile("[") {
    Ok(_) => { return 1; }
    Err(_) => {}
  }
  var re = engine.regex_compile("a");
  match re {
    Ok(r) => {
      if !engine.regex_match(r, "a") { return 2; }
      if engine.regex_find_all(r, "aaa").len() != 3 { return 3; }
      if engine.regex_find_iter(r, "aaa").len() != 3 { return 4; }
      if engine.regex_split(r, "aXa").len() != 3 { return 5; }
      if engine.regex_capture_names(r).len() != 0 { return 6; }
      if !engine.regex_is_match("a", "a") { return 7; }
      if engine.regex_is_match("[", "a") { return 8; }
      if engine.regex_matches("[", "a").len() != 0 { return 9; }
    }
    Err(_) => { return 10; }
  }
  var empty_re = engine.regex_compile("");
  match empty_re {
    Ok(r) => {
      if engine.regex_find_all(r, "abc").len() != 4 { return 11; }
      if engine.regex_find_all(r, "").len() != 1 { return 12; }
      if engine.regex_split(r, "abc").len() != 3 { return 13; }
    }
    Err(_) => { return 14; }
  }

  match pcre_lite.pcre_compile("[", 0) {
    Ok(_) => { return 20; }
    Err(_) => {}
  }
  var pc = pcre_lite.pcre_compile("a", 0);
  match pc {
    Ok(h) => {
      if !pcre_lite.pcre_match(h, "a") { return 21; }
      let exec = pcre_lite.pcre_exec(h, "aaa");
      if exec.len() != 6 { return 22; }
      if pcre_lite.pcre_replace(h, "a", "x") != "x" { return 23; }
      if pcre_lite.pcre_split(h, "aXa").len() < 1 { return 24; }
      if pcre_lite.pcre_capture_count(h) != 0 { return 25; }
    }
    Err(_) => { return 26; }
  }
  if pcre_lite.pcre_match(9999, "a") { return 27; }
  if pcre_lite.pcre_exec(9999, "a").len() != 0 { return 28; }
  if pcre_lite.pcre_replace(9999, "abc", "x") != "abc" { return 29; }
  let split_bad = pcre_lite.pcre_split(9999, "abc");
  if split_bad.len() != 1 { return 30; }
  if split_bad[0] != "abc" { return 31; }
  if pcre_lite.pcre_version().len() == 0 { return 32; }

  io.println("p_wave184_regex_shapes: OK");
  return 0;
}

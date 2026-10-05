// p_wave68_shapes.xi -- wave 68 shape validation: misc (glob/soundex/natural/levenshtein)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-68 clauses on xiom.misc.{glob (9), soundex (6),
// natural (6 uncovered), levenshtein (8)} = 29 fns; 54 checks; returns 0
// when every case holds. levenshtein_align stays clause-free (tuple
// result); no network or socket I/O.

module p_wave68_shapes

use xiom.misc.glob;
use xiom.misc.soundex;
use xiom.misc.natural;
use xiom.misc.levenshtein;

fn _id(s: Str) -> Str {
  s
}

fn main() -> Int {
  // ---- glob
  if !glob.glob_match("", "") { return 1; }
  if glob.glob_match("", "a") { return 2; }
  if !glob.glob_match("*", "anything") { return 3; }
  if glob.glob_match("*", "x") == false { return 4; }
  if !glob.glob_match_case_insensitive("", "") { return 5; }
  if glob.glob_match_case_insensitive("", "a") { return 6; }
  if !glob.glob_match_case_insensitive("*", "AbC") { return 7; }
  if !(glob.glob_escape("abc") == "abc") { return 8; }
  if glob.glob_escape("").len() != 0 { return 9; }
  if !(glob.glob_unescape("") == "") { return 10; }
  if glob.glob_has_magic("") { return 11; }
  if !glob.glob_has_magic("a*b") { return 12; }
  if glob.glob_has_magic("abc") { return 13; }
  if !(glob.glob_quote("abc") == "abc") { return 14; }
  if glob.glob_translate("").len() != 0 { return 15; }
  if glob.glob_compile("").is_ok { return 16; }
  if glob.glob_compile("*.xi").is_err { return 17; }
  if !glob.glob_compile("*.xi").is_ok { return 18; }
  if glob.glob_compile_match(0, "x") { return 19; }

  // ---- soundex
  if xiom.misc.soundex.soundex("").len() != 0 { return 20; }
  if !soundex_compare("Robert", "Robert") { return 21; }
  if soundex_encode("").len() != 0 { return 22; }
  if soundex_key("").len() != 0 { return 23; }
  if !(soundex_similarity("", "") == 1.0) { return 24; }
  if !(soundex_similarity("", "x") == 0.0) { return 25; }
  if soundex_variants("Robert").len() != 2 { return 26; }
  if !(xiom.misc.soundex.soundex("Robert") == "R163") { return 27; }

  // ---- natural
  var words = Vec[Str].new();
  words.push("file10");
  words.push("file2");
  if natural.natural_sort(&words).len() != 2 { return 28; }
  if natural.natural_sort_by(&words, _id).len() != 2 { return 29; }
  if natural.natural_sort_desc(&words).len() != 2 { return 30; }
  if natural.natural_key("").len() != 0 { return 31; }
  if natural.natural_key("a1").len() < 1 { return 32; }
  if natural.natural_chunk("").len() != 0 { return 33; }
  if natural.natural_chunk("a1").len() < 1 { return 34; }
  if natural.natural_is_digit_run("abc", 0 - 1) { return 35; }
  if natural.natural_is_digit_run("abc", 3) { return 36; }
  if !natural.natural_is_digit_run("a1", 1) { return 37; }
  let sorted = natural.natural_sort(&words);
  if !(sorted[0] == "file2") { return 38; }

  // ---- levenshtein
  if levenshtein.levenshtein_distance("", "abc") != 3 { return 39; }
  if levenshtein.levenshtein_distance("abc", "") != 3 { return 40; }
  if levenshtein.levenshtein_distance("same", "same") != 0 { return 41; }
  if levenshtein.levenshtein_distance_limited("", "abc", 5) != 3 { return 42; }
  if levenshtein.levenshtein_distance_limited("abcdef", "ab", 1) != 2 { return 43; }
  if !(levenshtein.levenshtein_similarity("same", "same") == 1.0) { return 44; }
  if !(levenshtein.levenshtein_similarity("", "") == 1.0) { return 45; }
  if levenshtein.levenshtein_matrix("", "abc").len() != 1 { return 46; }
  if levenshtein.levenshtein_edit_script("", "").len() != 0 { return 47; }
  if levenshtein.levenshtein_edit_script("", "ab").len() != 2 { return 48; }
  if levenshtein.damerau_levenshtein("", "abc") != 3 { return 49; }
  if levenshtein.damerau_levenshtein("abc", "") != 3 { return 50; }
  if levenshtein.osa_distance("", "abc") != 3 { return 51; }
  if levenshtein.osa_distance("abc", "") != 3 { return 52; }
  if levenshtein.wagner_fischer("", "abc") != 3 { return 53; }
  if levenshtein.wagner_fischer("abc", "") != 3 { return 54; }

  return 0;
}

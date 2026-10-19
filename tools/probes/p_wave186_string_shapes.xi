// p_wave186_string_shapes.xi -- wave 186 string contract-shape validation
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-186 clauses on the fourteen xiom.string contract targets:
// format (3), printf (3), scanf (3), glob (2), repeat (2), rotate (3), jaro
// (2), jaccard (1), metaphone (2), soundex (2), ngram (2), ngram_similarity
// (1), fold (2), casefold (2). Returns 0 when every case holds.
//
// Deliberate path limits (compiler BUG 20, see smoke_string_jaro and
// smoke_string_cosine_jaccard): the non-empty matching loops in jaro and the
// n-gram loop paths are avoided; only early-return/zero rows are exercised for
// those. No network or socket I/O.

module p_wave186_string_shapes

use xiom.string.format;
use xiom.string.printf;
use xiom.string.scanf;
use xiom.string.glob;
use xiom.string.repeat;
use xiom.string.rotate;
use xiom.string.jaro;
use xiom.string.jaccard;
use xiom.string.metaphone;
use xiom.string.soundex;
use xiom.string.ngram;
use xiom.string.ngram_similarity;
use xiom.string.fold;
use xiom.string.casefold;

fn main() -> Int {
  // ---- format: result.is_ok ----
  if !xiom.string.format.str_format1("Hello {}", 42).is_ok { return 1; }
  if !xiom.string.format.str_format2("{} and {}", 1, 2).is_ok { return 2; }
  if !xiom.string.format.str_format3("{} {} {}", 1, 2, 3).is_ok { return 3; }
  if !xiom.string.format.str_format1("plain", 7).is_ok { return 4; }

  // ---- printf: empty spec -> Ok ----
  if !xiom.string.printf.str_printf_i1("", 0).is_ok { return 5; }
  if !xiom.string.printf.str_printf_f1("", 0.0).is_ok { return 6; }
  if !xiom.string.printf.str_printf_s1("", "").is_ok { return 7; }
  if !xiom.string.printf.str_printf_i1("%d", 42).is_ok { return 8; }
  if !xiom.string.printf.str_printf_s1("%s", "hi").is_ok { return 9; }

  // ---- scanf: empty-spec Ok, empty-input Err, FloatScan counts ----
  if !xiom.string.scanf.str_scanf("", "").is_ok { return 10; }
  if !xiom.string.scanf.str_scanf("", "%d").is_err { return 11; }
  if !xiom.string.scanf.str_scanf_ints("", "").is_ok { return 12; }
  if !xiom.string.scanf.str_scanf_ints("42", "%d").is_ok { return 13; }
  let r0 = xiom.string.scanf.str_scanf_floats("", "");
  if !r0.is_ok { return 14; }
  if r0.count != 0 { return 15; }
  let r1 = xiom.string.scanf.str_scanf_floats("", "%d");
  if r1.is_ok { return 16; }
  if r1.count != 0 { return 17; }
  let r2 = xiom.string.scanf.str_scanf_floats("1.5 2.5", "%f %f");
  if !r2.is_ok { return 18; }
  if r2.count != 2 { return 19; }

  // ---- glob: empty-pattern and "*" rows ----
  if !xiom.string.glob.glob_match("", "") { return 20; }
  if xiom.string.glob.glob_match("", "a") { return 21; }
  if !xiom.string.glob.glob_match("*", "abc") { return 22; }
  if !xiom.string.glob.glob_match_case_insensitive("", "") { return 23; }
  if xiom.string.glob.glob_match_case_insensitive("", "a") { return 24; }
  if !xiom.string.glob.glob_match_case_insensitive("*", "AbC") { return 25; }

  // ---- repeat: zero/negative rows and length law ----
  if xiom.string.repeat.str_repeat("ab", 3) != "ababab" { return 26; }
  if xiom.string.repeat.str_repeat("ab", 0) != "" { return 27; }
  if xiom.string.repeat.str_repeat("ab", 0 - 2) != "" { return 28; }
  if xiom.string.repeat.str_repeat_char('a', 3) != "aaa" { return 29; }
  if xiom.string.repeat.str_repeat_char('x', 0) != "" { return 30; }
  if xiom.string.repeat.str_repeat_char('a', 0 - 1) != "" { return 31; }

  // ---- rotate: length preservation and n == 0 identity ----
  if xiom.string.rotate.str_rotate("abcde", 2) != "deabc" { return 32; }
  if xiom.string.rotate.str_rotate("abcde", 0) != "abcde" { return 33; }
  if xiom.string.rotate.str_rotate("abcde", 5) != "abcde" { return 34; }
  if xiom.string.rotate.str_rotate("", 3) != "" { return 35; }
  if xiom.string.rotate.str_rotate_left("abcde", 2) != "cdeab" { return 36; }
  if xiom.string.rotate.str_rotate_left("abcde", 0) != "abcde" { return 37; }
  if xiom.string.rotate.str_rotate_right("abcde", 2) != "deabc" { return 38; }
  if xiom.string.rotate.str_rotate_right("abcde", 0) != "abcde" { return 39; }

  // ---- jaro: range and equality pins on early-return paths ----
  if xiom.string.jaro.jaro_similarity("", "") != 1.0 { return 40; }
  if xiom.string.jaro.jaro_similarity("abc", "") != 0.0 { return 41; }
  if xiom.string.jaro.jaro_similarity("", "abc") != 0.0 { return 42; }
  if xiom.string.jaro.jaro_winkler_similarity("", "") != 1.0 { return 43; }
  if xiom.string.jaro.jaro_winkler_similarity("abc", "") != 0.0 { return 44; }

  // ---- jaccard: zero rows, plus the identical-set pin ----
  if xiom.string.jaccard.jaccard_similarity("abc", "abc", 4) != 0.0 { return 45; }
  if xiom.string.jaccard.jaccard_similarity("abc", "abd", 0) != 0.0 { return 46; }
  if xiom.string.jaccard.jaccard_similarity("", "abc", 2) != 0.0 { return 47; }
  if xiom.string.jaccard.jaccard_similarity("hello", "hello", 2) != 1.0 { return 48; }

  // ---- metaphone: empty row, length bound, equality compare ----
  if xiom.string.metaphone.metaphone("") != "" { return 49; }
  if xiom.string.metaphone.metaphone("Robert").len() > 12 { return 50; }
  if !xiom.string.metaphone.metaphone_compare("Robert", "Robert") { return 51; }

  // ---- soundex: empty/non-empty length rows and compare ----
  if xiom.string.soundex.soundex("") != "" { return 52; }
  if xiom.string.soundex.soundex("Robert").len() != 4 { return 53; }
  if xiom.string.soundex.soundex("Robert") != "R163" { return 54; }
  if !xiom.string.soundex.soundex_compare("Robert", "Robert") { return 55; }

  // ---- ngram: extract/count length domains ----
  if xiom.string.ngram.ngram_extract("hello", 2).len() != 4 { return 56; }
  if xiom.string.ngram.ngram_extract("", 2).len() != 0 { return 57; }
  if xiom.string.ngram.ngram_extract("ab", 3).len() != 0 { return 58; }
  if xiom.string.ngram.ngram_extract("abc", 3).len() != 1 { return 59; }
  if xiom.string.ngram.ngram_count("hello", 2) != 4 { return 60; }
  if xiom.string.ngram.ngram_count("", 2) != 0 { return 61; }
  if xiom.string.ngram.ngram_count("abc", 3) != 1 { return 62; }

  // ---- ngram_similarity: zero rows only (BUG 20 loop path avoided) ----
  if xiom.string.ngram_similarity.ngram_similarity("ab", "ab", 3) != 0.0 { return 63; }
  if xiom.string.ngram_similarity.ngram_similarity("abc", "abc", 0) != 0.0 { return 64; }

  // ---- fold: empty pins and ASCII fold identity ----
  if xiom.string.fold.unicode_casefold("") != "" { return 65; }
  if xiom.string.fold.unicode_fold_full("") != "" { return 66; }
  if xiom.string.fold.unicode_casefold("ABC") != "abc" { return 67; }
  if xiom.string.fold.unicode_fold_full("ABC") != "abc" { return 68; }

  // ---- casefold: empty pins, ASCII fold, output byte bound ----
  if xiom.string.casefold.str_casefold("") != "" { return 69; }
  if xiom.string.casefold.str_casefold_ascii("") != "" { return 70; }
  if xiom.string.casefold.str_casefold("Strasse") != "strasse" { return 71; }
  if xiom.string.casefold.str_casefold("ABC") != "abc" { return 72; }
  if xiom.string.casefold.str_casefold_ascii("HeLLo") != "hello" { return 73; }
  if xiom.string.casefold.str_casefold("ABC").len() > 12 { return 74; }
  if xiom.string.casefold.str_casefold_ascii("HeLLo").len() > 20 { return 75; }

  return 0;
}

// p_wave26_shapes.xi -- contract shape validation for wave 26 (text).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 26 applies to xiom.text.{transliterate,similarity,diff}:
// 1. empty guard plus byte-ratio upper bound on transliteration:
//    `s.len() == 0 => result.len() == 0`, `result.len() <= K * s.len()`
// 2. custom-table pass-through bound: `table.len() == 0 => result.len() <= s.len()`
// 3. non-negative / bounded integer results: `result >= 0`,
//    `result >= 0 && result <= a.len() && result <= b.len()`
// 4. exact n-gram count: `result.len() == s.len() - n + 1` (guarded)
// 5. exact 4-byte code normalization: `word.len() > 0 => result.len() == 4`
// 6. float similarity ranges: `result >= 0.0 && result <= 1.0`
// 7. Option presence mirrors for hamming
// 8. diff op bounds `result.len() <= a.len() + b.len()` and the constant
//    unified-diff header floor `result.len() >= 18`
// 9. clause indexing of a Vec param guarded by a precondition
//    (`i >= 0 && i < ops.len()` / `result.len() <= ops[i].data.len()`)
// main() drives the real functions; every call evaluates the new runtime
// clauses. Returns 0 when every shape compiles and holds.

module p_wave26_shapes

use xiom.text.transliterate;
use xiom.text.similarity;
use xiom.text.diff;

fn main() -> Int {
  // 1+2: transliteration values and byte-ratio bounds
  let g = transliterate.transliterate_greek("αβγ");
  if g != "abg" { return 1; }
  let a = transliterate.transliterate_accented("café");
  if a != "cafe" { return 2; }
  let e = transliterate.transliterate("");
  if e.len() != 0 { return 3; }
  let cy = transliterate.transliterate_cyrillic("Привет");
  if cy.len() > 24 { return 4; }
  let empty_table = Vec[(Char, Str)].new();
  if transliterate.transliterate_custom("abc", &empty_table) != "abc" { return 5; }

  // 3+4+5+6+7: similarity families
  if similarity.levenshtein("kitten", "sitting") != 3 { return 6; }
  var j = similarity.jaro("martha", "marhta");
  if j < 0.0 || j > 1.0 { return 7; }
  if similarity.soundex("").len() != 0 { return 8; }
  if similarity.soundex("Robert").len() != 4 { return 9; }
  let ng = similarity.ngram_extract("abc", 2);
  if ng.len() != 2 { return 10; }
  if similarity.ngram_extract("a", 2).len() != 0 { return 11; }
  let hs = similarity.hamming("ab", "ab");
  if !hs.is_some { return 12; }
  let hn = similarity.hamming("a", "ab");
  if !hn.is_none { return 13; }
  if similarity.longest_common_subsequence("abc", "ac") != 2 { return 14; }
  if similarity.longest_common_substring("abc", "xbc") != 2 { return 15; }
  var cu = similarity.cosine_similarity("abc", "abc");
  if cu < 0.999 { return 16; }
  var mw = similarity.jaro_winkler("dwayne", "duane");
  if mw < 0.0 || mw > 1.0 { return 17; }
  var ns = similarity.ngram_similarity("abcd", "abce", 2);
  if ns < 0.0 || ns > 1.0 { return 18; }
  var jc = similarity.jaccard_similarity("abc", "abd", 2);
  if jc < 0.0 { return 19; }
  if similarity.longest_common_prefix("abc", "abd") > 3 { return 20; }
  if similarity.longest_common_suffix("xbc", "abc") > 3 { return 21; }

  // 8+9: diff families
  var d1: Vec[Str] = Vec[Str].new();
  d1.push("a"); d1.push("b");
  var d2: Vec[Str] = Vec[Str].new();
  d2.push("a"); d2.push("c");
  let ops = diff.diff_myers(&d1, &d2);
  if ops.len() < 1 || ops.len() > 4 { return 22; }
  let k0 = diff.diffop_kind_at(&ops, 0);
  if k0 != "eq" && k0 != "ins" && k0 != "del" { return 23; }
  let t0 = diff.diffop_text_at(&ops, 0);
  if t0.len() > 4 { return 24; }
  let lops = diff.diff_lcs(&d1, &d2);
  if lops.len() > 4 { return 25; }
  let u = diff.diff_unified("x", "y", 1);
  if u.len() < 18 { return 26; }
  var ds = diff.diff_similarity("abc", "abd");
  if ds < 0.0 || ds > 1.0 { return 27; }
  var dr = diff.diff_ratio("abc", "abd");
  if dr < 0.0 || dr > 1.0 { return 28; }
  let wops = diff.diff_word_level("a b", "a c");
  if wops.len() > 6 { return 29; }
  var bytes1: Vec[UInt8] = Vec[UInt8].new();
  bytes1.push(65);
  var bytes2: Vec[UInt8] = Vec[UInt8].new();
  bytes2.push(66);
  let bops = diff.diff_byte_level(&bytes1, &bytes2);
  if bops.len() > 2 { return 30; }
  return 0;
}

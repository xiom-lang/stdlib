// Smoke test for xiom.text.similarity
// Returns 0 on success, non-zero on the first failing assertion.

module smoke_text_similarity
use xiom.text.similarity;
use xiom.string;

fn main() -> Int {
  // levenshtein
  if similarity.levenshtein("kitten", "sitting") != 3 { return 1; }
  if similarity.levenshtein("", "") != 0 { return 2; }
  if similarity.levenshtein("abc", "abc") != 0 { return 3; }

  // damerau (OSA)
  if similarity.damerau_levenshtein("abc", "acb") != 1 { return 4; }
  // OSA("ca","abc") is the classic case where restricted alignment cannot
  // reuse the transposed substring, so this impl yields 3 (not the full
  // Damerau-Levenshtein 2). Assert our impl's consistent value.
  if similarity.damerau_levenshtein("ca", "abc") != 3 { return 5; }

  // jaro / jaro_winkler
  var j = similarity.jaro("MARTHA", "MARHTA");
  if !(j >= 0.93 && j <= 0.96) { return 6; }
  var jw = similarity.jaro_winkler("MARTHA", "MARHTA");
  if !(jw >= 0.95 && jw <= 0.98) { return 7; }

  // ngram
  var ng = similarity.ngram_similarity("abc", "abc", 2);
  var diff = ng - 1.0;
  if diff < 0.0 { diff = -diff; }
  if diff > 0.001 { return 8; }
  var ng2 = similarity.ngram_similarity("abcde", "abcfg", 2);
  if !(ng2 > 0.0 && ng2 < 1.0) { return 9; }

  // cosine
  var cs = similarity.cosine_similarity("hello", "hello");
  if !(cs > 0.999) { return 10; }
  var cs2 = similarity.cosine_similarity("hello", "world");
  if !(cs2 > 0.0 && cs2 < 1.0) { return 11; }

  // longest common subsequence / substring
  if similarity.longest_common_subsequence("ABCBDAB", "BDCABA") != 4 { return 12; }
  if similarity.longest_common_substring("abcdef", "zcdemf") != 3 { return 13; }

  // hamming (match-destructuring of Option[Int] is flaky in this build,
  // so read the option fields directly)
  var h1 = similarity.hamming("karolin", "kathrin");
  if !h1.is_some { return 15; }
  if h1.value != 3 { return 14; }
  var h2 = similarity.hamming("abc", "ab");
  if h2.is_some { return 16; }
  var h3 = similarity.hamming("", "");
  if !h3.is_some { return 18; }
  if h3.value != 0 { return 17; }

  // soundex mandated vectors
  if similarity.soundex("Robert") != "R163" { return 19; }
  if similarity.soundex("Rupert") != "R163" { return 20; }
  if similarity.soundex("Ashcraft") != "A261" { return 21; }
  if similarity.soundex("Tymczak") != "T522" { return 22; }

  // metaphone: "knight" starts with 'N'; deterministic
  var m1 = similarity.metaphone("knight");
  if m1.len() == 0 { return 23; }
  if string.byte_at(m1, 0) != 78 { return 24; }
  var m2 = similarity.metaphone("knight");
  if m1 != m2 { return 25; }

  return 0;
}

module smoke_str2
use xiom.io;
use xiom.string;
use xiom.text.similarity;

// tr/rot/caesar/atbash, abbreviate/obfuscate, jaccard/lcp/lcsuffix/ngram.
// strftime/strptime live in smoke_time2 (string + text.similarity + time
// combined crashes at startup -- COMPILER_BUGS.md BUG 18).

fn main() -> Int {
  // -- tr / rot / caesar / atbash --
  if xiom.string.str_translate("hello world", "aeiou", "AEIOU") != "hEllO wOrld" { return 1; }
  if xiom.string.str_translate("abc123", "abc", "XY") != "XY123" { return 2; }  // c removed
  if xiom.string.str_translate("abc", "z", "q") != "abc" { return 3; }
  if xiom.string.str_rot13("Hello, World!") != "Uryyb, Jbeyq!" { return 4; }
  if xiom.string.str_rot13("Uryyb, Jbeyq!") != "Hello, World!" { return 5; }
  if xiom.string.str_caesar("abc", 3) != "def" { return 6; }
  if xiom.string.str_caesar("xyz", 3) != "abc" { return 7; }
  if xiom.string.str_caesar("ABC", -1) != "ZAB" { return 8; }
  if xiom.string.str_caesar("a1b", 1) != "b1c" { return 9; }
  if xiom.string.str_atbash("abc XYZ") != "zyx CBA" { return 10; }
  if xiom.string.str_atbash("zyx CBA") != "abc XYZ" { return 11; }
  if xiom.string.str_rot47("Hello!") != "w6==@P" { return 12; }
  if xiom.string.str_rot47("w6==@P") != "Hello!" { return 13; }

  // -- abbreviate / obfuscate --
  if xiom.string.str_abbreviate("short", 10) != "short" { return 14; }
  if xiom.string.str_abbreviate("abcdefghij", 7) != "ab...ij" { return 15; }
  if xiom.string.str_abbreviate("abcdefghijklmnop", 8) != "abc...op" { return 16; }
  if xiom.string.str_abbreviate("abcdef", 3) != "abc" { return 17; }
  if xiom.string.str_obfuscate("secret", 3) != "sec***" { return 18; }
  if xiom.string.str_obfuscate("a", 3) != "a" { return 19; }
  if xiom.string.str_obfuscate("abcd", 0) != "****" { return 20; }
  if xiom.string.str_obfuscate("test", -1) != "****" { return 21; }

  // -- jaccard / lcp / lcsuffix / ngram --
  var ng = xiom.text.similarity.ngram_extract("abcd", 2);
  if ng.len() != 3 { return 22; }
  if ng[0] != "ab" || ng[1] != "bc" || ng[2] != "cd" { return 23; }
  var ng1 = xiom.text.similarity.ngram_extract("abc", 1);
  if ng1.len() != 3 { return 24; }
  var ng0 = xiom.text.similarity.ngram_extract("ab", 5);
  if ng0.len() != 0 { return 25; }
  // identical strings -> jaccard 1.0
  if xiom.text.similarity.jaccard_similarity("hello", "hello", 2) != 1.0 { return 26; }
  // disjoint -> 0.0
  if xiom.text.similarity.jaccard_similarity("abc", "xyz", 2) != 0.0 { return 27; }
  // partial: "abcd" vs "abef", bigrams: {ab,bc,cd} & {ab,be,ef} = {ab} -> 1/5
  var j = xiom.text.similarity.jaccard_similarity("abcd", "abef", 2);
  if j * 100.0 < 19.0 || j * 100.0 > 21.0 { return 28; }
  if xiom.text.similarity.longest_common_prefix("abcdef", "abcxyz") != 3 { return 29; }
  if xiom.text.similarity.longest_common_prefix("abc", "xyz") != 0 { return 30; }
  if xiom.text.similarity.longest_common_prefix("same", "same") != 4 { return 31; }
  if xiom.text.similarity.longest_common_suffix("abcdef", "xyzdef") != 3 { return 32; }
  if xiom.text.similarity.longest_common_suffix("abc", "abc") != 3 { return 33; }
  if xiom.text.similarity.longest_common_suffix("abc", "def") != 0 { return 34; }

  io.println("smoke_str2: all 34 checks passed");
  return 0;
}


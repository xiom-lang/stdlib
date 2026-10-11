// p_wave109_shapes.xi -- wave 109 shape validation: xiom.misc (misc.xi +
// semver.xi): string metrics, glob, natural order, roman, case conversion,
// ordinals/plurals, unit conversions, human sizes, semver parse/compare/
// match/inc/serialize.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave109_shapes

use xiom.misc as mm;
use xiom.misc.semver;

fn main() -> Int {
  // ---- glob / natural / palindrome
  if mm.glob_match("", "abc") != false { return 1; }
  if mm.glob_match("*", "") != true { return 2; }
  if mm.glob_match("*", "abc") != true { return 2; }
  if mm.glob_match("a*c", "abbbc") != true { return 3; }
  if mm.glob_match("a?c", "abc") != true { return 3; }
  if mm.glob_match("a?c", "abbc") != false { return 3; }
  if mm.natural_compare("", "") != 0 { return 4; }
  if mm.natural_compare("", "a") != -1 { return 4; }
  if mm.natural_compare("file2", "file10") != -1 { return 5; }
  if mm.is_palindrome("") != true { return 6; }
  if mm.is_palindrome("aba") != true { return 6; }
  if mm.is_palindrome("ab") != false { return 6; }

  // ---- distances / similarity
  if mm.damerau_levenshtein_distance("", "abc") != 3 { return 7; }
  if mm.damerau_levenshtein_distance("abc", "") != 3 { return 7; }
  if mm.damerau_levenshtein_distance("ab", "ba") != 1 { return 8; }
  if mm.jaro_similarity("", "") != 1.0 { return 9; }
  if mm.jaro_similarity("", "a") != 0.0 { return 9; }
  if mm.jaro_winkler_similarity("", "") != 1.0 { return 10; }
  if mm.hamming_distance("ab", "abc") != -1 { return 11; }
  if mm.hamming_distance("abc", "abd") != 1 { return 11; }
  let lcs = mm.longest_common_subsequence("", "abc");
  if lcs.len() != 0 { return 12; }
  if mm.from_roman("") != 0 { return 13; }
  if mm.from_roman("MCMXCIV") != 1994 { return 14; }

  // ---- case conversion / ordinals / plurals / anagram
  let cc0 = mm.to_camel_case("");
  if cc0.len() != 0 { return 15; }
  let pc0 = mm.to_pascal_case("");
  if pc0.len() != 0 { return 15; }
  let sc0 = mm.to_snake_case("");
  if sc0.len() != 0 { return 15; }
  let kc0 = mm.to_kebab_case("");
  if kc0.len() != 0 { return 15; }
  if mm.ordinal(1) != "1st" { return 16; }
  if mm.ordinal(11) != "11th" { return 16; }
  if mm.ordinal(21) != "21st" { return 16; }
  if mm.pluralize("cat", 1) != "cat" { return 17; }
  if mm.pluralize("cat", 2) != "cats" { return 17; }
  if mm.pluralize("", 2) != "" { return 17; }
  if mm.is_anagram("", "") != true { return 18; }

  // ---- units / human size
  if mm.celsius_to_fahrenheit(0.0) != 32.0 { return 19; }
  if mm.fahrenheit_to_celsius(32.0) != 0.0 { return 19; }
  if mm.celsius_to_kelvin(0.0) != 273.15 { return 20; }
  if mm.kelvin_to_celsius(273.15) != 0.0 { return 20; }
  if mm.fahrenheit_to_kelvin(-459.67) != 0.0 { return 21; }
  if mm.kelvin_to_fahrenheit(0.0) != -459.67 { return 21; }
  if mm.miles_to_km(1.0) != 1.609344 { return 22; }
  if mm.km_to_miles(1.609344) != 1.0 { return 22; }
  if mm.human_size(0) != "0 B" { return 23; }
  if mm.human_size(-5) != "0 B" { return 23; }
  if mm.human_size(512) != "512 B" { return 24; }
  if mm.human_size(2048) != "2.0 KB" { return 24; }

  // ---- semver
  let p1 = semver.semver_parse("1.2.3");
  if p1.is_some != true { return 25; }
  let p0 = semver.semver_parse("");
  if p0.is_none != true { return 26; }
  let p1c = semver.semver_parse("1");
  if p1c.is_none != true { return 26; }
  if semver.semver_valid("") != false { return 27; }
  if semver.semver_valid("1.2.3") != true { return 27; }
  if semver.semver_matches("", "1.2.3") != false { return 28; }
  if semver.semver_satisfies("", "1.x") != false { return 29; }
  let inc0 = semver.semver_inc("", "major");
  if inc0.is_none != true { return 30; }
  let inc1 = semver.semver_inc("1.2.3", "patch");
  match inc1 {
    Some(v1) => { if v1 != "1.2.4" { return 31; } },
    None => { return 31; }
  }
  let s123 = SemVer{ major: 1; minor: 2; patch: 3; prerelease: ""; build: ""; };
  if semver.semver_to_string(s123) != "1.2.3" { return 32; }
  if semver.semver_prerelease(s123).is_none != true { return 33; }
  let spre = SemVer{ major: 1; minor: 2; patch: 3; prerelease: "alpha.1"; build: "b.5"; };
  if semver.semver_prerelease(spre).is_some != true { return 33; }
  if semver.semver_build(spre).is_some != true { return 34; }
  if semver.semver_build(s123).is_none != true { return 34; }
  let a123 = SemVer{ major: 1; minor: 2; patch: 3; prerelease: ""; build: ""; };
  let b200 = SemVer{ major: 2; minor: 0; patch: 0; prerelease: ""; build: ""; };
  let b150 = SemVer{ major: 1; minor: 5; patch: 0; prerelease: ""; build: ""; };
  if semver.semver_caret(a123, b200) != false { return 35; }
  if semver.semver_caret(a123, b150) != true { return 35; }
  if semver.semver_tilde(a123, b200) != false { return 36; }
  let b129 = SemVer{ major: 1; minor: 2; patch: 9; prerelease: ""; build: ""; };
  if semver.semver_tilde(a123, b129) != true { return 36; }
  let b130 = SemVer{ major: 1; minor: 3; patch: 0; prerelease: ""; build: ""; };
  if semver.semver_gt(b130, b129) != true { return 37; }
  if semver.semver_lt(b129, b130) != true { return 37; }
  if semver.semver_compare(s123, b200) != -1 { return 38; }
  if semver.semver_compare(s123, s123) != 0 { return 38; }
  let pfull = semver.semver_parse("1.2.3-alpha.1+build.5");
  match pfull {
    Some(vf) => {
      if vf.prerelease != "alpha.1" { return 39; }
      if vf.build != "build.5" { return 39; }
    },
    None => { return 39; }
  }

  return 0;
}

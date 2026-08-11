module smoke_misc
use xiom.misc;
use xiom.rand;

fn main() -> Int {
  // original assertions
  if !xiom.misc.glob_match("*.xi", "a.xi") { return 1; }
  if !xiom.misc.glob_match("a?c", "abc") { return 1; }
  if xiom.misc.levenshtein_distance("kitten", "sitting") != 3 { return 1; }
  if xiom.misc.semver_compare("1.2.3", "1.10.0") >= 0 { return 1; }
  if xiom.misc.natural_compare("file2", "file10") >= 0 { return 1; }
  if !xiom.misc.is_palindrome("racecar") { return 1; }
  var u = xiom.rand.uuid_v4();
  if u.len() != 36 { return 1; }
  // 2. string metrics
  if xiom.misc.damerau_levenshtein_distance("kitten", "sitting") != 3 { return 2; }
  if xiom.misc.damerau_levenshtein_distance("ab", "ba") != 1 { return 2; }
  if xiom.misc.damerau_levenshtein_distance("abc", "acb") != 1 { return 2; }
  if xiom.misc.damerau_levenshtein_distance("", "") != 0 { return 2; }
  if xiom.misc.hamming_distance("karolin", "kathrin") != 3 { return 2; }
  if xiom.misc.hamming_distance("ab", "abc") != -1 { return 2; }
  if xiom.misc.longest_common_subsequence("abcde", "ace") != "ace" { return 2; }
  if xiom.misc.longest_common_subsequence("abc", "def") != "" { return 2; }
  // 3. jaro / jaro-winkler
  var j = xiom.misc.jaro_similarity("MARTHA", "MARHTA");
  if j < 0.94 || j > 0.96 { return 3; }
  var jw = xiom.misc.jaro_winkler_similarity("MARTHA", "MARHTA");
  if jw < 0.96 || jw > 0.98 { return 3; }
  if xiom.misc.jaro_similarity("", "") != 1.0 { return 3; }
  if xiom.misc.jaro_similarity("abc", "") != 0.0 { return 3; }
  // 4. roman numerals
  if xiom.misc.to_roman(1999) != "MCMXCIX" { return 4; }
  if xiom.misc.to_roman(58) != "LVIII" { return 4; }
  if xiom.misc.to_roman(3999) != "MMMCMXCIX" { return 4; }
  if xiom.misc.from_roman("MCMXCIX") != 1999 { return 4; }
  if xiom.misc.from_roman("LVIII") != 58 { return 4; }
  if xiom.misc.from_roman("XYZ") != 0 { return 4; }
  // 5. case conversion
  if xiom.misc.to_camel_case("hello_world") != "helloWorld" { return 5; }
  if xiom.misc.to_pascal_case("hello world") != "HelloWorld" { return 5; }
  if xiom.misc.to_snake_case("HelloWorld") != "hello_world" { return 5; }
  if xiom.misc.to_kebab_case("Hello World") != "hello-world" { return 5; }
  if xiom.misc.to_camel_case("alreadyCamel") != "alreadyCamel" { return 5; }
  // 6. ordinal / pluralize / anagram
  if xiom.misc.ordinal(1) != "1st" { return 6; }
  if xiom.misc.ordinal(2) != "2nd" { return 6; }
  if xiom.misc.ordinal(3) != "3rd" { return 6; }
  if xiom.misc.ordinal(11) != "11th" { return 6; }
  if xiom.misc.ordinal(21) != "21st" { return 6; }
  if xiom.misc.pluralize("cat", 1) != "cat" { return 6; }
  if xiom.misc.pluralize("cat", 2) != "cats" { return 6; }
  if xiom.misc.pluralize("box", 2) != "boxes" { return 6; }
  if xiom.misc.pluralize("berry", 2) != "berries" { return 6; }
  if xiom.misc.pluralize("boy", 2) != "boys" { return 6; }
  if xiom.misc.pluralize("church", 2) != "churches" { return 6; }
  if !xiom.misc.is_anagram("Listen", "Silent") { return 6; }
  if xiom.misc.is_anagram("abc", "abd") { return 6; }
  // 7. units (tolerance-based: f64 round-trips can be 1 ulp off)
  var f = xiom.misc.celsius_to_fahrenheit(0.0);
  if f != 32.0 { return 7; }
  f = xiom.misc.fahrenheit_to_celsius(212.0);
  if f != 100.0 { return 7; }
  f = xiom.misc.celsius_to_kelvin(0.0);
  if f != 273.15 { return 7; }
  f = xiom.misc.kelvin_to_celsius(273.15);
  if f != 0.0 { return 7; }
  f = xiom.misc.fahrenheit_to_kelvin(32.0);
  if f < 273.149999 || f > 273.150001 { return 7; }
  f = xiom.misc.kelvin_to_fahrenheit(273.15);
  if f < 31.999999 || f > 32.000001 { return 7; }
  f = xiom.misc.miles_to_km(1.0);
  if f < 1.609 || f > 1.61 { return 7; }
  f = xiom.misc.km_to_miles(1.609344);
  if f < 0.999 || f > 1.001 { return 7; }
  // 8. human_size
  if xiom.misc.human_size(512) != "512 B" { return 8; }
  if xiom.misc.human_size(1536) != "1.5 KB" { return 8; }
  if xiom.misc.human_size(3355443) != "3.2 MB" { return 8; }
  if xiom.misc.human_size(0) != "0 B" { return 8; }
  return 0;
}

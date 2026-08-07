module smoke_misc
use xiom.misc;
use xiom.rand;
fn main() -> Int {
  if !xiom.misc.glob_match("*.xi", "a.xi") { return 1; }
  if !xiom.misc.glob_match("a?c", "abc") { return 1; }
  if xiom.misc.levenshtein_distance("kitten", "sitting") != 3 { return 1; }
  if xiom.misc.semver_compare("1.2.3", "1.10.0") >= 0 { return 1; }
  if xiom.misc.natural_compare("file2", "file10") >= 0 { return 1; }
  if !xiom.misc.is_palindrome("racecar") { return 1; }
  var u = xiom.rand.uuid_v4();
  if u.len() != 36 { return 1; }
  return 0;
}

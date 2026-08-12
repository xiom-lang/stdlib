// Smoke test for xiom.string.damerau
// Returns 0 on success, non-zero on the first failing assertion.
//
// NOTE: damerau_levenshtein_distance delegates to misc.damerau_levenshtein_
// distance, whose full-matrix DP loop shape is miscompiled by the -O2
// vectorizer on this machine (compiler BUG 20): ANY call traps at runtime with
// 0xC000001D before any output. Only osa_distance (two-row DP) is exercised
// here; the misc path is documented as blocked by BUG 20.

module smoke_string_damerau
use xiom.string.damerau;
use xiom.io;

fn main() -> Int {
  if damerau.osa_distance("abc", "acb") != 1 { io.println("osa trans"); return 1; }
  if damerau.osa_distance("ab", "ba") != 1 { io.println("osa swap"); return 2; }
  if damerau.osa_distance("ca", "abc") != 3 { io.println("osa ca"); return 3; }
  if damerau.osa_distance("kitten", "sitting") != 3 { io.println("osa kitten"); return 4; }
  if damerau.osa_distance("", "") != 0 { io.println("osa empty"); return 5; }
  io.println("smoke_string_damerau: OK");
  return 0;
}

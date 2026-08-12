// Smoke test for xiom.string.levenshtein
// Returns 0 on success, non-zero on the first failing assertion.

module smoke_string_levenshtein
use xiom.string.levenshtein;
use xiom.io;

fn main() -> Int {
  if levenshtein.levenshtein_distance("kitten", "sitting") != 3 { io.println("lev kitten"); return 1; }
  if levenshtein.levenshtein_distance("", "") != 0 { io.println("lev empty"); return 2; }
  if levenshtein.levenshtein_distance("abc", "abc") != 0 { io.println("lev equal"); return 3; }
  if levenshtein.levenshtein_distance("", "abc") != 3 { io.println("lev insert"); return 4; }
  if levenshtein.levenshtein_distance("abc", "") != 3 { io.println("lev delete"); return 5; }
  // normalized: distance / max(len) in 0.0..1.0. NOTE: calling
  // levenshtein_normalized with inputs that run the DP loop (both lengths
  // > 0) traps at runtime with 0xC000001D on this machine - compiler BUG 20
  // (the -O2 vectorizer emits AVX-512 instructions for the inlined DP loop
  // combined with float code). The early-return paths below are verified.
  var n3 = levenshtein.levenshtein_normalized("", "xyz");
  if n3 != 1.0 { io.println("lev norm3"); return 6; }
  var n4 = levenshtein.levenshtein_normalized("", "");
  if n4 != 0.0 { io.println("lev norm4"); return 7; }
  io.println("smoke_string_levenshtein: OK");
  return 0;
}

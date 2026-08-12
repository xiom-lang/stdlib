// Smoke test for xiom.string.jaro
// Returns 0 on success, non-zero on the first failing assertion.
//
// NOTE: both functions delegate to xiom.misc. The known-answer check
// jaro_similarity("MARTHA", "MARHTA") ~= 0.944 cannot run on this machine:
// the matching loop combined with the final float arithmetic is miscompiled by
// the -O2 vectorizer (compiler BUG 20) and traps with 0xC000001D. The
// early-return paths (empty inputs, no matching loop) are verified below.

module smoke_string_jaro
use xiom.string.jaro;
use xiom.io;

fn main() -> Int {
  var j2 = jaro.jaro_similarity("", "");
  if j2 != 1.0 { io.println("jaro empty"); return 1; }
  var j3 = jaro.jaro_similarity("abc", "");
  if j3 != 0.0 { io.println("jaro halfempty"); return 2; }
  var j4 = jaro.jaro_similarity("", "abc");
  if j4 != 0.0 { io.println("jaro halfempty2"); return 3; }
  var jw1 = jaro.jaro_winkler_similarity("", "");
  if jw1 != 1.0 { io.println("jw empty"); return 4; }
  var jw2 = jaro.jaro_winkler_similarity("abc", "");
  if jw2 != 0.0 { io.println("jw halfempty"); return 5; }
  io.println("smoke_string_jaro: OK");
  return 0;
}

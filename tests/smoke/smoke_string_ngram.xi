// Smoke test for xiom.string.ngram + xiom.string.ngram_similarity
// Returns 0 on success, non-zero on the first failing assertion.
//
// NOTE: ngram_similarity delegates to text.similarity.ngram_similarity; float
// arithmetic on its loop-derived value is miscompiled by the -O2 vectorizer on
// this machine (compiler BUG 20) and traps with 0xC000001D. Only the
// short-input early-return path is verified here. ngram_extract/ngram_count
// are fully exercised.

module smoke_string_ngram
use xiom.string.ngram;
use xiom.string.ngram_similarity;
use xiom.io;

fn main() -> Int {
  var g1 = ngram.ngram_extract("hello", 2);
  if g1.len() != 4 { io.println("ngram len"); return 1; }
  var g0 = g1[0];
  if g0 != "he" { io.println("ngram first"); return 2; }
  var g3 = g1[3];
  if g3 != "lo" { io.println("ngram last"); return 3; }
  var g2 = ngram.ngram_extract("abc", 1);
  if g2.len() != 3 { io.println("ngram uni"); return 4; }
  var g3b = ngram.ngram_extract("", 2);
  if g3b.len() != 0 { io.println("ngram empty"); return 5; }
  var g4 = ngram.ngram_extract("ab", 3);
  if g4.len() != 0 { io.println("ngram short"); return 6; }
  if ngram.ngram_count("hello", 2) != 4 { io.println("ngram cnt2"); return 7; }
  if ngram.ngram_count("hello", 1) != 5 { io.println("ngram cnt1"); return 8; }
  if ngram.ngram_count("hello", 6) != 0 { io.println("ngram cntbig"); return 9; }
  if ngram.ngram_count("", 2) != 0 { io.println("ngram cntempty"); return 10; }
  if ngram.ngram_count("abc", 0) != 0 { io.println("ngram cntzero"); return 11; }
  // ngram_similarity: short-input early-return path only (BUG 20)
  var s3 = ngram_similarity.ngram_similarity("ab", "ab", 3);
  if s3 != 0.0 { io.println("ngramsim short"); return 12; }
  io.println("smoke_string_ngram: OK");
  return 0;
}

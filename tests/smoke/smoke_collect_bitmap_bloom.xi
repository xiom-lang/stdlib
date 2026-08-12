// XIOM stdlib smoke test - xiom.collect.bitmap + bloom
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_bitmap_bloom
use xiom.collect.bitmap;
use xiom.collect.bloom;
use xiom.io;

fn main() -> Int {
  // ===================== Bitmap =====================
  var b = bitmap_new(16);
  if bitmap_test(&b, 0) { io.println("bm:init0"); return 1; }
  if bitmap_test(&b, 15) { io.println("bm:init15"); return 2; }
  bitmap_set(&mut b, 0);
  bitmap_set(&mut b, 3);
  bitmap_set(&mut b, 15);
  if !bitmap_test(&b, 0) { io.println("bm:set0"); return 3; }
  if !bitmap_test(&b, 3) { io.println("bm:set3"); return 4; }
  if !bitmap_test(&b, 15) { io.println("bm:set15"); return 5; }
  if bitmap_test(&b, 1) { io.println("bm:set1"); return 6; }
  if bitmap_count(&b) != 3 { io.println("bm:count"); return 7; }
  var fs = bitmap_first_set(&b);
  if !fs.is_some || fs.value != 0 { io.println("bm:first"); return 8; }
  bitmap_clear(&mut b, 0);
  if bitmap_test(&b, 0) { io.println("bm:clear"); return 9; }
  if bitmap_count(&b) != 2 { io.println("bm:count2"); return 10; }
  var fs2 = bitmap_first_set(&b);
  if !fs2.is_some || fs2.value != 3 { io.println("bm:first2"); return 11; }
  bitmap_flip(&mut b, 5);
  if !bitmap_test(&b, 5) { io.println("bm:flip"); return 12; }
  bitmap_flip(&mut b, 5);
  if bitmap_test(&b, 5) { io.println("bm:flip2"); return 13; }
  // out-of-range ops are no-ops / false
  bitmap_set(&mut b, 16);
  bitmap_set(&mut b, -1);
  if bitmap_test(&b, 16) { io.println("bm:oob"); return 14; }
  if bitmap_count(&b) != 2 { io.println("bm:oobcount"); return 15; }
  bitmap_flip(&mut b, 99);
  if bitmap_count(&b) != 2 { io.println("bm:oobflip"); return 16; }
  // zero-sized bitmap
  var b0 = bitmap_new(0);
  if bitmap_count(&b0) != 0 { io.println("bm:zero"); return 17; }
  var f0 = bitmap_first_set(&b0);
  if f0.is_some { io.println("bm:zerofirst"); return 18; }

  // ===================== Bloom Filter =====================
  var bf = bloom_new(64, 3);
  if bloom_may_contain(&bf, 42) { io.println("bf:init"); return 19; }
  bloom_insert(&mut bf, 42);
  bloom_insert(&mut bf, 7);
  bloom_insert(&mut bf, 999);
  if !bloom_may_contain(&bf, 42) { io.println("bf:in42"); return 20; }
  if !bloom_may_contain(&bf, 7) { io.println("bf:in7"); return 21; }
  if !bloom_may_contain(&bf, 999) { io.println("bf:in999"); return 22; }
  // no false negatives across a batch
  var bf2 = bloom_new(256, 4);
  var i: Int = 0;
  while i < 100 {
    bloom_insert(&mut bf2, i * 13 + 1);
    i = i + 1;
  }
  i = 0;
  while i < 100 {
    if !bloom_may_contain(&bf2, i * 13 + 1) { io.println("bf:false-neg"); return 23; }
    i = i + 1;
  }
  bloom_clear(&mut bf2);
  if bloom_may_contain(&bf2, 1) { io.println("bf:clear"); return 24; }
  var fpr = bloom_false_positive_rate(&bf);
  if fpr <= 0.0 { io.println("bf:fpr"); return 25; }
  if fpr >= 1.0 { io.println("bf:fpr-high"); return 26; }
  var bf3 = bloom_new(8, 1);
  bloom_insert(&mut bf3, 5);
  if !bloom_may_contain(&bf3, 5) { io.println("bf:tiny"); return 27; }

  io.println("smoke_collect_bitmap_bloom: OK");
  return 0;
}

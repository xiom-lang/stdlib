// XIOM stdlib smoke -- xiom.collect.tinylfu
// Count-min sketch primitives + TinyLFU admission decisions and reset.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_tinylfu
use xiom.collect.tinylfu;
use xiom.io;

fn main() -> Int {
  // --- CMS primitives: exact counts for a single key, monotonicity under load ---
  var s = count_min_sketch_new(64, 4);
  var i: Int = 0;
  while i < 3 {
    cms_add(&mut s, 1);
    i = i + 1;
  }
  if cms_estimate(&s, 1) != 3 { io.println("cms single"); return 1; }
  i = 0;
  while i < 50 {
    cms_add(&mut s, 100 + i);
    i = i + 1;
  }
  if cms_estimate(&s, 1) < 3 { io.println("cms never underestimates"); return 2; }
  if cms_estimate(&s, 123) < 1 { io.println("cms collided key estimate"); return 3; }
  cms_clear(&mut s);
  if cms_estimate(&s, 1) != 0 { io.println("cms clear"); return 4; }

  // --- TinyLFU filter ---
  var f = tinylfu_new(4);
  i = 0;
  while i < 3 {
    tinylfu_increment(&mut f, 100);
    i = i + 1;
  }
  tinylfu_increment(&mut f, 200);
  if tinylfu_estimate(&f, 100) != 3 { io.println("tinylfu estimate"); return 5; }
  if tinylfu_estimate(&f, 200) != 1 { io.println("tinylfu fresh estimate"); return 6; }
  if !tinylfu_admit(&f, 100, 2) { io.println("tinylfu admit hot"); return 7; }
  if tinylfu_admit(&f, 100, 5) { io.println("tinylfu reject hotter"); return 8; }
  if tinylfu_admit(&f, 200, 2) { io.println("tinylfu reject cold at capacity"); return 9; }
  tinylfu_reset(&mut f);
  if tinylfu_estimate(&f, 100) != 1 { io.println("tinylfu reset halve"); return 10; }
  if tinylfu_estimate(&f, 200) != 0 { io.println("tinylfu reset cold"); return 11; }

  io.println("OK");
  return 0;
}

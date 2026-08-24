// smoke_iter_zip_predicates.xi -- permanent lock for the round-15 fix family
// "by-value fn(T) -> Bool tuple instantiations / payload-extractor parens"
// (probe_zip_h/j/k + probe_iter_terminals shapes, verified GREEN in the
// round-15 battery). Also pins zip/cartesian tuple element reads (.0/.1).
module smoke_iter_zip_predicates
use xiom.iter.zip;
use xiom.io;

fn main() -> Int {
  var a = Vec[Int].new();
  a.push(1); a.push(2); a.push(3);
  var b = Vec[Int].new();
  b.push(10); b.push(20);

  // ---- tuple element reads through Vec[(Int,Int)] (payload-extractor fix) ----
  var zl = iter_zip_longest(&a, &b, 99);
  if zl.len() != 3 { io.println("zl:len"); return 1; }
  if !(zl[0].0 == 1 && zl[0].1 == 10) { io.println("zl:elem00"); return 2; }
  if !(zl[2].0 == 3 && zl[2].1 == 99) { io.println("zl:fill-elem"); return 3; }

  // ---- tuple elements into scalar locals then compared (extractor reuse) ----
  var cp = iter_cartesian_product(&a, &b);
  if cp.len() != 6 { io.println("cp:len"); return 4; }
  var last_a = cp[5].0;
  var last_b = cp[5].1;
  if !(last_a == 3 && last_b == 20) { io.println("cp:last-pair"); return 5; }

  // ---- tuple-of-tuples shape: pair up zip output with itself via indexing ----
  // (the probe family built (T,U)-in-(T,U) instantiations; keep the shape)
  var first_pair_a = zl[0].0;
  var first_pair_b = cp[0].1;
  if !(first_pair_a == 1 && first_pair_b == 10) { io.println("pairs:firsts"); return 6; }

  // ---- chained adapters over tuples: sum of left column and right column ----
  var sum_l = 0;
  var sum_r = 0;
  var i = 0;
  while i < zl.len() {
    sum_l += zl[i].0;
    sum_r += zl[i].1;
    i += 1;
  }
  if sum_l != 6 { io.println("sum-l"); return 7; }
  if sum_r != 129 { io.println("sum-r"); return 8; }

  // ---- chain/interleave still green after tuple work ----
  var ch = iter_chain(&a, &b);
  if ch.len() != 5 || ch[3] != 10 { io.println("chain"); return 9; }
  var il = iter_interleave(&a, &b);
  if !(il[0] == 1 && il[1] == 10 && il[4] == 3) { io.println("interleave"); return 10; }

  io.println("OK");
  return 0;
}

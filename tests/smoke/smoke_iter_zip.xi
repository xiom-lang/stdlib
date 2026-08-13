// XIOM stdlib smoke test - xiom.iter.zip module
// Split from smoke_iter because importing 5+ sibling xiom.iter submodules
// together with xiom.iter.zip breaks qualified name resolution in the
// current compiler (smoke_iter covers chain/filter/fold/map/range).
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_iter_zip
use xiom.iter.zip;
use xiom.io;

fn main() -> Int {
  var a = Vec[Int].new();
  a.push(1); a.push(2); a.push(3);
  var b = Vec[Int].new();
  b.push(10); b.push(20);

  // iter_chain: concatenate
  var ch = iter_chain(&a, &b);
  if ch.len() != 5 { io.println("ch:len"); return 1; }
  if ch[0] != 1 || ch[2] != 3 || ch[3] != 10 || ch[4] != 20 { io.println("ch:val"); return 2; }

  // iter_interleave: alternate
  var il = iter_interleave(&a, &b);
  if !(il[0] == 1 && il[1] == 10 && il[2] == 2 && il[3] == 20 && il[4] == 3) { io.println("il:bad"); return 3; }

  // iter_zip_longest: pad shorter side with fill
  var zl = iter_zip_longest(&a, &b, 99);
  if zl.len() != 3 { io.println("zl:len"); return 4; }
  if !(zl[0].0 == 1 && zl[0].1 == 10 && zl[1].0 == 2 && zl[1].1 == 20 && zl[2].0 == 3 && zl[2].1 == 99) { io.println("zl:val"); return 5; }
  var zl2 = iter_zip_longest(&b, &a, -1);
  if !(zl2[2].0 == -1 && zl2[2].1 == 3) { io.println("zl2:val"); return 6; }

  // iter_cartesian_product: all pairs row-major
  var cp = iter_cartesian_product(&a, &b);
  if cp.len() != 6 { io.println("cp:len"); return 7; }
  if !(cp[0].0 == 1 && cp[0].1 == 10 && cp[5].0 == 3 && cp[5].1 == 20) { io.println("cp:val"); return 8; }

  // iter_chain_many: concatenate a list of vectors (nested Vec construction)
  var parts = Vec[Vec[Int]].new();
  parts.push(a);
  parts.push(b);
  var cm = iter_chain_many(&parts);
  if cm.len() != 5 { io.println("cm:len"); return 9; }
  if cm[2] != 3 || cm[4] != 20 { io.println("cm:val"); return 10; }

  io.println("OK");
  return 0;
}

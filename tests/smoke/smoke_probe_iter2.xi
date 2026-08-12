module smoke_probe_iter2
use xiom.iter.chain;
use xiom.iter.filter;
use xiom.iter.fold;
use xiom.iter.map;
use xiom.iter.range;
use xiom.iter.zip;
use xiom.io;

fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}
fn is_odd(x: &Int) -> Bool {
  *x % 2 == 1
}
fn double(x: &Int) -> Int {
  *x * 2
}
fn add(a: Int, b: &Int) -> Int {
  a + *b
}
fn addr(a: &Int, b: &Int) -> Int {
  *a + *b
}
fn key_mod3(x: &Int) -> Int {
  *x % 3
}

fn main() -> Int {
  var r = xiom.iter.range.range(1, 5);
  if r.len() != 4 { io.println("r:len"); return 1; }
  if r[0] != 1 || r[3] != 4 { io.println("r:val"); return 2; }
  var m = xiom.iter.map.iter_map(&r, double);
  if !(m[0] == 2 && m[1] == 4 && m[2] == 6 && m[3] == 8) { io.println("m:bad"); return 3; }
  var f = xiom.iter.filter.iter_filter(&r, is_even);
  if !(f[0] == 2 && f[1] == 4 && f.len() == 2) { io.println("f:bad"); return 4; }
  var s = xiom.iter.chain.iter_sum(&r);
  if s != 10 { io.println("s:bad"); return 5; }
  var folded = xiom.iter.chain.iter_fold(&r, 0, add);
  if folded != 10 { io.println("fold:bad"); return 6; }
  var z = xiom.iter.map.iter_zip(&r, &m);
  if z.len() != 4 { io.println("z:len"); return 7; }
  if z[0].0 != 1 || z[0].1 != 2 { io.println("z:val"); return 8; }
  var mx = xiom.iter.chain.iter_max(&r);
  match mx {
    Some(x) => { if x != 4 { io.println("mx:bad"); return 9; } },
    None => { io.println("mx:none"); return 10; },
  }
  var any = xiom.iter.chain.iter_any(&r, is_odd);
  if !any { io.println("any:bad"); return 11; }
  var sorted = xiom.iter.fold.iter_sort(&r);
  if sorted[0] != 1 || sorted[3] != 4 { io.println("sort:bad"); return 12; }
  var g = xiom.iter.chain.iter_group_by(&r, key_mod3);
  if g.len() != 3 { io.println("g:len"); return 13; }
  var ch = xiom.iter.fold.iter_chunks(&r, 2);
  if ch.len() != 2 { io.println("ch:len"); return 14; }
  io.println("OK");
  return 0;
}

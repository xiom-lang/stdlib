// XIOM stdlib smoke test - xiom.iter submodules
// chain + filter + fold + map + range + zip
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_iter
use xiom.iter.chain;
use xiom.iter.filter;
use xiom.iter.fold;
use xiom.iter.map;
use xiom.iter.range;
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
fn add_ref(a: &Int, b: &Int) -> Int {
  *a + *b
}
fn key_mod3(x: &Int) -> Int {
  *x % 3
}
fn find_big(x: &Int) -> Option[Int] {
  if *x > 3 {
    Some(*x)
  } else {
    None
  }
}

fn main() -> Int {
  // range(1,5) yields 1..4
  var r = xiom.iter.range.range(1, 5);
  if r.len() != 4 { io.println("r:len"); return 1; }
  if r[0] != 1 || r[3] != 4 { io.println("r:val"); return 2; }

  // map doubling
  var m = xiom.iter.map.iter_map(&r, double);
  if !(m[0] == 2 && m[1] == 4 && m[2] == 6 && m[3] == 8) { io.println("m:bad"); return 3; }

  // filter evens
  var f = xiom.iter.filter.iter_filter(&r, is_even);
  if !(f[0] == 2 && f[1] == 4 && f.len() == 2) { io.println("f:bad"); return 4; }

  // fold sum
  var sum = xiom.iter.chain.iter_fold(&r, 0, add);
  if sum != 10 { io.println("fold:bad"); return 5; }
  if xiom.iter.chain.iter_sum(&r) != 10 { io.println("sum:bad"); return 6; }
  var reduced = xiom.iter.chain.iter_reduce(&r, add_ref);
  match reduced {
    Some(v) => { if v != 10 { io.println("red:bad"); return 7; } },
    None => { io.println("red:none"); return 8; },
  }

  // zip pairs
  var z = xiom.iter.map.iter_zip(&r, &m);
  if z.len() != 4 { io.println("z:len"); return 9; }
  if z[0].0 != 1 || z[0].1 != 2 { io.println("z:val"); return 10; }
  if z[3].0 != 4 || z[3].1 != 8 { io.println("z:val2"); return 11; }

  // fold module: iter_fold1, iter_scan, iter_find, iter_find_map
  var f1 = xiom.iter.fold.iter_fold1(&r, add_ref);
  match f1 {
    Some(v) => { if v != 10 { io.println("f1:bad"); return 15; } },
    None => { io.println("f1:none"); return 16; },
  }
  var scan = xiom.iter.fold.iter_scan(&r, 0, add);
  if scan.len() != 5 || scan[4] != 10 { io.println("scan:bad"); return 17; }
  var found = xiom.iter.fold.iter_find(&r, is_odd);
  match found {
    Some(v) => { if v != 1 { io.println("find:bad"); return 18; } },
    None => { io.println("find:none"); return 19; },
  }
  var fm = xiom.iter.fold.iter_find_map(&r, find_big);
  match fm {
    Some(v) => { if v != 4 { io.println("fm:bad"); return 20; } },
    None => { io.println("fm:none"); return 21; },
  }

  // quantifiers / positions
  if !xiom.iter.chain.iter_any(&r, is_odd) { io.println("any:bad"); return 22; }
  if xiom.iter.chain.iter_all(&r, is_even) { io.println("all:bad"); return 23; }
  if xiom.iter.chain.iter_count_if(&r, is_even) != 2 { io.println("cnt:bad"); return 24; }
  var pos = xiom.iter.chain.iter_position(&r, is_odd);
  match pos {
    Some(i) => { if i != 0 { io.println("pos:bad"); return 25; } },
    None => { io.println("pos:none"); return 26; },
  }

  // range module extras
  var ri = xiom.iter.range.range_inclusive(2, 4);
  if ri.len() != 3 || ri[0] != 2 || ri[2] != 4 { io.println("ri:bad"); return 27; }
  var rs = xiom.iter.range.range_step(0, 10, 3);
  if !(rs.len() == 4 && rs[0] == 0 && rs[3] == 9) { io.println("rs:bad"); return 28; }
  var rc = xiom.iter.range.range_count(3);
  if rc.len() != 3 || rc[2] != 2 { io.println("rc:bad"); return 29; }

  // filter module extras
  var take = xiom.iter.filter.iter_take(&r, 2);
  if take.len() != 2 || take[1] != 2 { io.println("take:bad"); return 30; }
  var skip = xiom.iter.filter.iter_skip(&r, 2);
  if skip.len() != 2 || skip[0] != 3 { io.println("skip:bad"); return 31; }
  var tw = xiom.iter.filter.iter_take_while(&r, is_odd);
  if tw.len() != 1 { io.println("tw:bad"); return 32; }
  var sw = xiom.iter.filter.iter_skip_while(&r, is_odd);
  if sw.len() != 3 || sw[0] != 2 { io.println("sw:bad"); return 33; }

  // fold extras: sort, eq, cmp, reverse, contains
  var un = Vec[Int].new();
  un.push(3); un.push(1); un.push(2);
  var sorted = xiom.iter.fold.iter_sort(&un);
  if !(sorted[0] == 1 && sorted[1] == 2 && sorted[2] == 3) { io.println("sort:bad"); return 34; }
  if !xiom.iter.fold.iter_eq(&sorted, &sorted) { io.println("eq:bad"); return 35; }
  if xiom.iter.fold.iter_cmp(&sorted, &r) >= 0 { io.println("cmp:bad"); return 36; }
  var rev = xiom.iter.fold.iter_reverse(&r);
  if rev[0] != 4 || rev[3] != 1 { io.println("rev:bad"); return 37; }
  if !xiom.iter.fold.iter_contains(&r, 3) { io.println("contains:bad"); return 38; }
  var dedup = xiom.iter.filter.iter_dedup(&un);
  if dedup.len() != 3 { io.println("dedup:bad"); return 39; }
  var part = xiom.iter.chain.iter_partition(&r, is_even);
  if part.0.len() != 2 || part.1.len() != 2 { io.println("part:bad"); return 40; }
  var g = xiom.iter.chain.iter_group_by(&r, key_mod3);
  if g.len() != 4 { io.println("g:len"); return 41; }
  var prod = xiom.iter.chain.iter_product(&r);
  if prod != 24 { io.println("prod:bad"); return 42; }
  var mx = xiom.iter.chain.iter_max(&r);
  match mx {
    Some(v) => { if v != 4 { io.println("mx:bad"); return 43; } },
    None => { io.println("mx:none"); return 44; },
  }
  io.println("OK");
  return 0;
}

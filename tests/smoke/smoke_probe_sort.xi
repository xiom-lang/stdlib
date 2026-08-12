module smoke_probe_sort
use xiom.sort.quick;
use xiom.sort.heap;
use xiom.sort.merge;
use xiom.sort.intro;
use xiom.sort.radix;
use xiom.io;

fn cmp_int(a: &Int, b: &Int) -> Int {
  if *a < *b { return -1; }
  if *a > *b { return 1; }
  0
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3); v.push(1); v.push(2);
  quick_sort(&mut v);
  if !(v[0] == 1 && v[1] == 2 && v[2] == 3) { io.println("q:bad"); return 1; }

  var h = Vec[Int].new();
  h.push(5); h.push(2); h.push(4); h.push(1); h.push(3);
  heap_sort(&mut h);
  if !(h[0] == 1 && h[1] == 2 && h[2] == 3 && h[3] == 4 && h[4] == 5) { io.println("h:bad"); return 2; }

  var m = Vec[Int].new();
  m.push(9); m.push(8); m.push(7);
  merge_sort(&mut m);
  if !(m[0] == 7 && m[1] == 8 && m[2] == 9) { io.println("m:bad"); return 3; }

  var i = Vec[Int].new();
  i.push(4); i.push(2); i.push(5); i.push(1); i.push(3);
  intro_sort(&mut i);
  if !(i[0] == 1 && i[4] == 5) { io.println("i:bad"); return 4; }

  var r = Vec[Int].new();
  r.push(3); r.push(1); r.push(2);
  radix_sort(&mut r);
  if !(r[0] == 1 && r[1] == 2 && r[2] == 3) { io.println("r:bad"); return 5; }

  var sm = Vec[Int].new();
  sm.push(2); sm.push(1); sm.push(3);
  quick_sort_by(&mut sm, cmp_int);
  if !(sm[0] == 1 && sm[1] == 2 && sm[2] == 3) { io.println("qb:bad"); return 6; }
  if !is_sorted(&sm) { io.println("is:bad"); return 7; }
  var sel = quick_select(&mut sm, 1);
  if sel != 2 { io.println("qs:bad"); return 8; }
  io.println("OK");
  return 0;
}

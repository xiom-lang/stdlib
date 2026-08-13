// XIOM stdlib smoke test - xiom.sort submodules
// heap + intro + merge + quick + radix
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_sort
use xiom.sort.heap;
use xiom.sort.intro;
use xiom.sort.merge;
use xiom.sort.quick;
use xiom.sort.radix;
use xiom.io;

fn cmp_int(a: &Int, b: &Int) -> Int {
  if *a < *b { return -1; }
  if *a > *b { return 1; }
  0
}
fn cmp_desc(a: &Int, b: &Int) -> Int {
  if *a > *b { return -1; }
  if *a < *b { return 1; }
  0
}

fn main() -> Int {
  // quick_sort [3,1,2] -> [1,2,3]
  var v = Vec[Int].new();
  v.push(3); v.push(1); v.push(2);
  quick_sort(&mut v);
  if !(v[0] == 1 && v[1] == 2 && v[2] == 3) { io.println("q:bad"); return 1; }

  // heap_sort
  var h = Vec[Int].new();
  h.push(5); h.push(2); h.push(4); h.push(1); h.push(3);
  heap_sort(&mut h);
  if !(h[0] == 1 && h[1] == 2 && h[2] == 3 && h[3] == 4 && h[4] == 5) { io.println("h:bad"); return 2; }

  // heapify + heap_sort_by
  var hb = Vec[Int].new();
  hb.push(4); hb.push(1); hb.push(3); hb.push(2);
  heapify(&mut hb);
  if !(hb[0] == 4) { io.println("hf:bad"); return 3; }
  heap_sort_by(&mut hb, cmp_int);
  if !(hb[0] == 1 && hb[3] == 4) { io.println("hsb:bad"); return 4; }

  // merge_sort (stable)
  var m = Vec[Int].new();
  m.push(9); m.push(8); m.push(7);
  merge_sort(&mut m);
  if !(m[0] == 7 && m[1] == 8 && m[2] == 9) { io.println("m:bad"); return 5; }

  // merge two sorted vectors
  var a = Vec[Int].new();
  a.push(1); a.push(3); a.push(5);
  var b = Vec[Int].new();
  b.push(2); b.push(4); b.push(6);
  var mg = merge(&a, &b);
  if !(mg[0] == 1 && mg[1] == 2 && mg[2] == 3 && mg[3] == 4 && mg[4] == 5 && mg[5] == 6) { io.println("mg:bad"); return 6; }

  // merge_sort_stable with comparator
  var ms = Vec[Int].new();
  ms.push(1); ms.push(3); ms.push(2);
  merge_sort_stable(&mut ms, cmp_int);
  if !(ms[0] == 1 && ms[2] == 3) { io.println("msb:bad"); return 7; }

  // natural_merge_sort
  var nm = Vec[Int].new();
  nm.push(3); nm.push(1); nm.push(2);
  natural_merge_sort(&mut nm);
  if !(nm[0] == 1 && nm[2] == 3) { io.println("nm:bad"); return 8; }

  // intro_sort
  var i = Vec[Int].new();
  i.push(4); i.push(2); i.push(5); i.push(1); i.push(3);
  intro_sort(&mut i);
  if !(i[0] == 1 && i[4] == 5) { io.println("i:bad"); return 9; }

  // insertion_sort
  var ins = Vec[Int].new();
  ins.push(3); ins.push(1); ins.push(2);
  insertion_sort(&mut ins);
  if !(ins[0] == 1 && ins[2] == 3) { io.println("ins:bad"); return 10; }

  // shell_sort
  var sh = Vec[Int].new();
  sh.push(5); sh.push(2); sh.push(4); sh.push(1); sh.push(3);
  shell_sort(&mut sh);
  if !(sh[0] == 1 && sh[4] == 5) { io.println("sh:bad"); return 11; }

  // selection_sort
  var sel = Vec[Int].new();
  sel.push(3); sel.push(1); sel.push(2);
  selection_sort(&mut sel);
  if !(sel[0] == 1 && sel[2] == 3) { io.println("sel:bad"); return 12; }

  // bubble_sort
  var bu = Vec[Int].new();
  bu.push(3); bu.push(1); bu.push(2);
  bubble_sort(&mut bu);
  if !(bu[0] == 1 && bu[2] == 3) { io.println("bu:bad"); return 13; }

  // tim_sort
  var ts = Vec[Int].new();
  ts.push(6); ts.push(5); ts.push(4); ts.push(3); ts.push(2); ts.push(1);
  tim_sort(&mut ts);
  if !(ts[0] == 1 && ts[5] == 6) { io.println("ts:bad"); return 14; }

  // is_sorted + is_sorted_by
  if !xiom.sort.intro.is_sorted(&v) { io.println("is:bad"); return 15; }
  if !xiom.sort.intro.is_sorted_by(&v, cmp_int) { io.println("isb:bad"); return 16; }

  // quick_sort_by (named comparator)
  var qb = Vec[Int].new();
  qb.push(2); qb.push(1); qb.push(3);
  quick_sort_by(&mut qb, cmp_desc);
  if !(qb[0] == 3 && qb[1] == 2 && qb[2] == 1) { io.println("qb:bad"); return 17; }

  // quick_sort_3way (duplicates)
  var q3 = Vec[Int].new();
  q3.push(2); q3.push(1); q3.push(2); q3.push(3); q3.push(2);
  quick_sort_3way(&mut q3);
  if !(q3[0] == 1 && q3[1] == 2 && q3[2] == 2 && q3[3] == 2 && q3[4] == 3) { io.println("q3:bad"); return 18; }

  // quick_select: 2nd smallest (0-based 1) of [3,1,2] is 2
  var qs = Vec[Int].new();
  qs.push(3); qs.push(1); qs.push(2);
  if quick_select(&mut qs, 1) != 2 { io.println("qs:bad"); return 19; }

  // partial_sort: smallest 2 at front
  var ps = Vec[Int].new();
  ps.push(3); ps.push(1); ps.push(2);
  xiom.sort.intro.partial_sort(&mut ps, 2);
  if !(ps[0] == 1 && ps[1] == 2) { io.println("ps:bad"); return 20; }

  // nth_element: element at index 1 in sorted order
  var ne = Vec[Int].new();
  ne.push(3); ne.push(1); ne.push(2);
  if xiom.sort.intro.nth_element(&mut ne, 1) != 2 { io.println("ne:bad"); return 21; }

  // sort_stable
  var st = Vec[Int].new();
  st.push(3); st.push(1); st.push(2);
  sort_stable(&mut st);
  if !(st[0] == 1 && st[2] == 3) { io.println("st:bad"); return 22; }

  // radix_sort
  var r = Vec[Int].new();
  r.push(3); r.push(1); r.push(2);
  radix_sort(&mut r);
  if !(r[0] == 1 && r[1] == 2 && r[2] == 3) { io.println("r:bad"); return 23; }

  // radix_sort_u64
  var ru = Vec[UInt64].new();
  ru.push(3 as UInt64); ru.push(1 as UInt64); ru.push(2 as UInt64);
  radix_sort_u64(&mut ru);
  if !(ru[0] == 1 as UInt64 && ru[2] == 3 as UInt64) { io.println("ru:bad"); return 24; }

  // radix_sort_by_bytes
  var rb = Vec[Int].new();
  rb.push(5); rb.push(4); rb.push(3);
  radix_sort_by_bytes(&mut rb);
  if !(rb[0] == 3 && rb[2] == 5) { io.println("rb:bad"); return 25; }

  // counting_sort
  var cs = Vec[Int].new();
  cs.push(3); cs.push(1); cs.push(2); cs.push(1);
  counting_sort(&mut cs, 5);
  if !(cs[0] == 1 && cs[1] == 1 && cs[2] == 2 && cs[3] == 3) { io.println("cs:bad"); return 26; }

  io.println("OK");
  return 0;
}


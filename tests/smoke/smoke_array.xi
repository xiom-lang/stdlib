// XIOM stdlib smoke test - xiom.array submodules
// dynamic (Vec[Int]) + fixed ([N]Int)
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_array
use xiom.array.dynamic;
use xiom.array.fixed;
use xiom.io;

fn main() -> Int {
  // ---- dynamic ----
  var v = Vec[Int].new();
  if array_is_empty(&v) == false { io.println("em:bad"); return 1; }

  array_push(&mut v, 3);
  array_push(&mut v, 1);
  array_push(&mut v, 2);
  if v.len() != 3 { io.println("p:len"); return 2; }
  if array_is_empty(&v) { io.println("em2:bad"); return 3; }

  var popped = array_pop(&mut v);
  match popped {
    Some(x) => { if x != 2 { io.println("p:val"); return 4; } },
    None => { io.println("p:none"); return 5; },
  }

  array_insert(&mut v, 1, 5);
  if !(v[0] == 3 && v[1] == 5 && v[2] == 1) { io.println("i:bad"); return 6; }
  array_insert(&mut v, 9, 7);
  if v.len() != 3 { io.println("i:oob"); return 7; }

  var removed = array_remove(&mut v, 1);
  match removed {
    Some(x) => { if x != 5 { io.println("r:val"); return 8; } },
    None => { io.println("r:none"); return 9; },
  }
  var rem_oob = array_remove(&mut v, 99);
  match rem_oob {
    Some(_) => { io.println("r:oob"); return 10; },
    None => {},
  }

  // growth + fill
  array_resize(&mut v, 5, 9);
  if v.len() != 5 { io.println("rz:len"); return 11; }
  if v[3] != 9 || v[4] != 9 { io.println("rz:fill"); return 12; }
  array_resize(&mut v, 2, 9);
  if v.len() != 2 { io.println("rz:shrink"); return 13; }

  // concat + extend
  var w = Vec[Int].new();
  w.push(7); w.push(8);
  var c = array_concat(&v, &w);
  if c.len() != 4 { io.println("cc:len"); return 14; }
  if c[2] != 7 || c[3] != 8 { io.println("cc:val"); return 15; }
  array_extend(&mut v, &w);
  if v.len() != 4 { io.println("ex:len"); return 16; }

  // sort + search
  array_sort(&mut v);
  if !(v[0] == 1 && v[1] == 3 && v[2] == 7 && v[3] == 8) { io.println("so:bad"); return 17; }
  var found = array_search(&v, 7);
  match found {
    Some(i) => { if i != 2 { io.println("se:idx"); return 18; } },
    None => { io.println("se:none"); return 19; },
  }
  var notfound = array_search(&v, 100);
  match notfound {
    Some(_) => { io.println("se:found"); return 20; },
    None => {},
  }

  // ---- fixed ----
  var arr = [10, 20, 30, 40];
  if array_len(&arr) != 4 { io.println("f:len"); return 21; }

  var g = array_get(&arr, 1);
  match g {
    Some(x) => { if x != 20 { io.println("f:get"); return 22; } },
    None => { io.println("f:getnone"); return 23; },
  }
  var go = array_get(&arr, 9);
  match go {
    Some(_) => { io.println("f:oob"); return 24; },
    None => {},
  }

  var f = array_first(&arr);
  match f {
    Some(x) => { if x != 10 { io.println("f:first"); return 25; } },
    None => { io.println("f:firstnone"); return 26; },
  }
  var l = array_last(&arr);
  match l {
    Some(x) => { if x != 40 { io.println("f:last"); return 27; } },
    None => { io.println("f:lastnone"); return 28; },
  }

  var sl = array_slice(&arr, 1, 3);
  if sl.len() != 2 || sl[0] != 20 || sl[1] != 30 { io.println("f:slice"); return 29; }
  var sl2 = array_slice(&arr, -1, 99);
  if sl2.len() != 4 { io.println("f:slice2"); return 30; }

  var short_arr = [1, 2, 3];
  var z = array_zip(&short_arr, &arr);
  if z.len() != 3 { io.println("f:zip"); return 31; }
  if z[0].0 != 1 || z[0].1 != 10 { io.println("f:zipv"); return 32; }
  if z[2].1 != 30 { io.println("f:zipv2"); return 33; }

  io.println("OK");
  return 0;
}

module smoke_probe_search
use xiom.search.binary;
use xiom.search.linear;
use xiom.search.interpolation;
use xiom.search.kmp;
use xiom.search.boyer;
use xiom.io;

fn cmp_int(a: &Int, b: &Int) -> Int {
  if *a < *b { return -1; }
  if *a > *b { return 1; }
  0
}
fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}
fn unimodal(x: Int) -> Int {
  -(x - 5) * (x - 5)
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5); v.push(7);
  var r = binary_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("b:idx"); return 1; } },
    None => { io.println("b:none"); return 2; },
  }
  var nf = binary_search(&v, 6);
  match nf {
    Some(_) => { io.println("b:found"); return 3; },
    None => {},
  }
  if lower_bound(&v, 5) != 2 { io.println("lb:bad"); return 4; }
  if upper_bound(&v, 5) != 3 { io.println("ub:bad"); return 5; }
  var rr = search_range(&v, 3);
  if rr.0 != 1 || rr.1 != 2 { io.println("sr:bad"); return 6; }
  var rb = binary_search_range(&v, 5, 0, 2);
  match rb {
    Some(i) => { if i != 2 { io.println("br:idx"); return 7; } },
    None => { io.println("br:none"); return 8; },
  }
  var rb2 = binary_search_range(&v, 5, 0, 1);
  match rb2 {
    Some(_) => { io.println("br2:found"); return 9; },
    None => {},
  }
  var ls = linear_search(&v, 3);
  match ls {
    Some(i) => { if i != 1 { io.println("ls:idx"); return 10; } },
    None => { io.println("ls:none"); return 11; },
  }
  var all = linear_search_all(&v, 7);
  if all.len() != 1 || all[0] != 3 { io.println("la:bad"); return 12; }
  var by = linear_search_by(&v, is_even);
  match by {
    Some(_) => { io.println("lb2:found"); return 13; },
    None => {},
  }
  var ip = interpolation_search(&v, 5);
  match ip {
    Some(i) => { if i != 2 { io.println("ip:idx"); return 14; } },
    None => { io.println("ip:none"); return 15; },
  }
  var ip2 = interpolation_search_sorted(&v, 7);
  match ip2 {
    Some(i) => { if i != 3 { io.println("ip2:idx"); return 16; } },
    None => { io.println("ip2:none"); return 17; },
  }
  var ex = exponential_search(&v, 1);
  match ex {
    Some(i) => { if i != 0 { io.println("ex:idx"); return 18; } },
    None => { io.println("ex:none"); return 19; },
  }
  var jp = jump_search(&v, 5);
  match jp {
    Some(i) => { if i != 2 { io.println("jp:idx"); return 20; } },
    None => { io.println("jp:none"); return 21; },
  }
  var ts = ternary_search(unimodal, 0, 10);
  if ts != 5 { io.println("ts:bad"); return 22; }
  var fb = fibonacci_search(&v, 5);
  match fb {
    Some(i) => { if i != 2 { io.println("fb:idx"); return 23; } },
    None => { io.println("fb:none"); return 24; },
  }
  var k1 = kmp_search("abababc", "ababc");
  match k1 {
    Some(i) => { if i != 2 { io.println("k1:idx"); return 25; } },
    None => { io.println("k1:none"); return 26; },
  }
  var ka = kmp_search_all("aaaa", "aa");
  if ka.len() != 3 { io.println("ka:len"); return 27; }
  var kc = kmp_count("aaaa", "aa");
  if kc != 2 { io.println("kc:cnt"); return 28; }
  if !kmp_contains("hello", "ell") { io.println("kmpc:bad"); return 29; }
  var bm = boyer_moore_search("abababc", "ababc");
  match bm {
    Some(i) => { if i != 2 { io.println("bm:idx"); return 30; } },
    None => { io.println("bm:none"); return 31; },
  }
  var ba = boyer_moore_search_all("aaaa", "aa");
  if ba.len() < 1 { io.println("ba:len"); return 32; }
  var hs = boyer_moore_horspool("hello world", "world");
  match hs {
    Some(i) => { if i != 6 { io.println("hs:idx"); return 33; } },
    None => { io.println("hs:none"); return 34; },
  }
  var rk = xiom.search.boyer.rabin_karp_search("hello world", "world");
  match rk {
    Some(i) => { if i != 6 { io.println("rk:idx"); return 35; } },
    None => { io.println("rk:none"); return 36; },
  }
  var bbb = boyer_moore_bad_char("pattern");
  if bbb.len() != 256 { io.println("bc:len"); return 37; }
  io.println("OK");
  return 0;
}

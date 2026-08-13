// XIOM stdlib smoke test - xiom.search submodules
// binary + boyer + interpolation + kmp + linear
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_search
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

  // binary_search([1,3,5,7], 5) == 2
  var r = xiom.search.binary.binary_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("b:idx"); return 1; } },
    None => { io.println("b:none"); return 2; },
  }
  // not found
  var nf = xiom.search.binary.binary_search(&v, 6);
  match nf {
    Some(_) => { io.println("b:found"); return 3; },
    None => {},
  }

  // lower_bound / upper_bound / search_range
  if xiom.search.binary.lower_bound(&v, 5) != 2 { io.println("lb:bad"); return 4; }
  if xiom.search.binary.upper_bound(&v, 5) != 3 { io.println("ub:bad"); return 5; }
  var sr = search_range(&v, 3);
  if sr.0 != 1 || sr.1 != 2 { io.println("sr:bad"); return 6; }
  var sr2 = search_range(&v, 6);
  if sr2.0 != sr2.1 { io.println("sr2:bad"); return 7; }

  // binary_search_range restricted to [0,2]
  var br = xiom.search.binary.binary_search_range(&v, 5, 0, 2);
  match br {
    Some(i) => { if i != 2 { io.println("br:idx"); return 8; } },
    None => { io.println("br:none"); return 9; },
  }
  var br2 = xiom.search.binary.binary_search_range(&v, 5, 0, 1);
  match br2 {
    Some(_) => { io.println("br2:found"); return 10; },
    None => {},
  }

  // binary_search_by with named comparator
  var bby = binary_search_by(&v, 5, cmp_int);
  match bby {
    Some(i) => { if i != 2 { io.println("bby:idx"); return 11; } },
    None => { io.println("bby:none"); return 12; },
  }

  // linear family
  var ls = xiom.search.linear.linear_search(&v, 3);
  match ls {
    Some(i) => { if i != 1 { io.println("ls:idx"); return 13; } },
    None => { io.println("ls:none"); return 14; },
  }
  var la = linear_search_all(&v, 7);
  if la.len() != 1 || la[0] != 3 { io.println("la:bad"); return 15; }
  var lf = linear_search_from(&v, 5, 1);
  match lf {
    Some(i) => { if i != 2 { io.println("lf:idx"); return 16; } },
    None => { io.println("lf:none"); return 17; },
  }
  var lb = linear_search_by(&v, is_even);
  match lb {
    Some(_) => { io.println("lb2:found"); return 18; },
    None => {},
  }

  // interpolation family
  var ip = xiom.search.interpolation.interpolation_search(&v, 5);
  match ip {
    Some(i) => { if i != 2 { io.println("ip:idx"); return 19; } },
    None => { io.println("ip:none"); return 20; },
  }
  var ips = interpolation_search_sorted(&v, 7);
  match ips {
    Some(i) => { if i != 3 { io.println("ips:idx"); return 21; } },
    None => { io.println("ips:none"); return 22; },
  }
  var ex = xiom.search.interpolation.exponential_search(&v, 1);
  match ex {
    Some(i) => { if i != 0 { io.println("ex:idx"); return 23; } },
    None => { io.println("ex:none"); return 24; },
  }
  var jp = xiom.search.interpolation.jump_search(&v, 5);
  match jp {
    Some(i) => { if i != 2 { io.println("jp:idx"); return 25; } },
    None => { io.println("jp:none"); return 26; },
  }
  var ts = ternary_search(unimodal, 0, 10);
  if ts != 5 { io.println("ts:bad"); return 27; }
  var fb = fibonacci_search(&v, 5);
  match fb {
    Some(i) => { if i != 2 { io.println("fb:idx"); return 28; } },
    None => { io.println("fb:none"); return 29; },
  }

  // kmp family
  var k1 = kmp_search("abababc", "ababc");
  match k1 {
    Some(i) => { if i != 2 { io.println("k1:idx"); return 30; } },
    None => { io.println("k1:none"); return 31; },
  }
  var ka = kmp_search_all("aaaa", "aa");
  if ka.len() != 3 { io.println("ka:len"); return 32; }
  var kc = kmp_count("aaaa", "aa");
  if kc != 2 { io.println("kc:cnt"); return 33; }
  if !kmp_contains("hello", "ell") { io.println("kmpc:bad"); return 34; }
  var kpt = kmp_prefix_table("ababaca");
  if kpt.len() != 7 { io.println("kpt:len"); return 35; }
  var knf = kmp_search("abc", "xyz");
  match knf {
    Some(_) => { io.println("knf:found"); return 36; },
    None => {},
  }

  // boyer-moore family
  var bm = boyer_moore_search("abababc", "ababc");
  match bm {
    Some(i) => { if i != 2 { io.println("bm:idx"); return 37; } },
    None => { io.println("bm:none"); return 38; },
  }
  var ba = boyer_moore_search_all("aaaa", "aa");
  if ba.len() < 1 { io.println("ba:len"); return 39; }
  var hs = boyer_moore_horspool("hello world", "world");
  match hs {
    Some(i) => { if i != 6 { io.println("hs:idx"); return 40; } },
    None => { io.println("hs:none"); return 41; },
  }
  var bc = boyer_moore_bad_char("pattern");
  if bc.len() != 256 { io.println("bc:len"); return 42; }
  var gs = boyer_moore_good_suffix("ababc");
  if gs.len() != 5 { io.println("gs:len"); return 43; }
  var rk = rabin_karp_search("hello world", "world");
  match rk {
    Some(i) => { if i != 6 { io.println("rk:idx"); return 44; } },
    None => { io.println("rk:none"); return 45; },
  }
  var rk2 = rabin_karp_search("aaa", "aa");
  match rk2 {
    Some(i) => { if i != 0 { io.println("rk2:idx"); return 46; } },
    None => { io.println("rk2:none"); return 47; },
  }
  var rh = rabin_karp_hash("abc");
  if rh <= 0 { io.println("rh:bad"); return 48; }
  var bmnf = boyer_moore_search("hello", "world");
  match bmnf {
    Some(_) => { io.println("bmnf:found"); return 49; },
    None => {},
  }

  io.println("OK");
  return 0;
}

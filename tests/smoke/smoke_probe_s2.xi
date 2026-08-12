module smoke_probe_s2
use xiom.search.boyer;
use xiom.search.kmp;
use xiom.io;

fn main() -> Int {
  var rk = rabin_karp_search("hello world", "world");
  match rk {
    Some(i) => { if i != 6 { io.println("rk:idx"); return 1; } },
    None => { io.println("rk:none"); return 2; },
  }
  var ka = kmp_search_all("aaaa", "aa");
  if ka.len() != 3 { io.println("ka:len"); return 3; }
  io.println("OK");
  return 0;
}


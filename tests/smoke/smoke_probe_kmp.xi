module smoke_probe_kmp
use xiom.search.kmp;
use xiom.io;

fn main() -> Int {
  var r = kmp_search("abababc", "ababc");
  match r {
    Some(i) => { if i != 2 { io.println("k:idx"); return 1; } },
    None => { io.println("k:none"); return 2; },
  }
  io.println("OK");
  return 0;
}


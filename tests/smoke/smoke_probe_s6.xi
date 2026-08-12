module smoke_probe_s6
use xiom.search.boyer;
use xiom.io;

fn main() -> Int {
  var rk = xiom.search.boyer.rabin_karp_search("hello world", "world");
  match rk {
    Some(i) => { if i != 6 { io.println("rk:idx"); return 1; } },
    None => { io.println("rk:none"); return 2; },
  }
  io.println("OK");
  return 0;
}

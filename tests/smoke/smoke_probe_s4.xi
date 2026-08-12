module smoke_probe_s4
use xiom.search.boyer;
use xiom.io;

fn main() -> Int {
  var bm = boyer_moore_search("abababc", "ababc");
  match bm {
    Some(i) => { if i != 2 { io.println("bm:idx"); return 1; } },
    None => { io.println("bm:none"); return 2; },
  }
  io.println("OK");
  return 0;
}

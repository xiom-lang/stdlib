module smoke_probe_s3
use xiom.search.boyer;
use xiom.io;

fn main() -> Int {
  var rk = rabin_karp_search("hello world", "world");
  match rk {
    Some(i) => { if i != 6 { io.println("rk:idx"); return 1; } },
    None => { io.println("rk:none"); return 2; },
  }
  var h = rabin_karp_hash("abc");
  if h <= 0 { io.println("rh:bad"); return 3; }
  io.println("OK");
  return 0;
}

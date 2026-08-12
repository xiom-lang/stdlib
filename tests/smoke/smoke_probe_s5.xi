module smoke_probe_s5
use xiom.search.boyer;
use xiom.io;

fn main() -> Int {
  var h = rabin_karp_hash("abc");
  if h <= 0 { io.println("rh:bad"); return 1; }
  io.println("OK");
  return 0;
}

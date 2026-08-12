module smoke_probe_charat4
use xiom.string;
use xiom.io;

fn main() -> Int {
  var parts = xiom.string.str_split("ab12cd", ".");
  var part = parts[0];
  var j = 0;
  var n = xiom.string.str_len(part);
  while j < n {
    var b = xiom.string.byte_at(part, j);
    if b == 0 { io.println("b0"); return 1; }
    j = j + 1;
  }
  io.println("OK");
  return 0;
}

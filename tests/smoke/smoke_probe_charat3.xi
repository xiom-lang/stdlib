module smoke_probe_charat3
use xiom.string;
use xiom.io;

fn main() -> Int {
  var parts = xiom.string.str_split("ab12cd", ".");
  var part = parts[0];
  var j = 0;
  while j < part.len() {
    var c = part.char_at(j);
    if (c as Int) == 0 { io.println("c0"); return 1; }
    j = j + 1;
  }
  io.println("OK");
  return 0;
}

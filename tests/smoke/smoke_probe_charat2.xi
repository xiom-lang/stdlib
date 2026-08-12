module smoke_probe_charat2
use xiom.string;
use xiom.io;

fn is_digits(s: Str) -> Bool {
  var i = 0;
  while i < s.len() {
    var v = s.char_at(i) as Int;
    if v < 48 || v > 57 { return false; }
    i = i + 1;
  }
  true
}

fn main() -> Int {
  var parts = xiom.string.str_split("1.2.3", ".");
  var maj = parts[0];
  if !is_digits(maj) { io.println("dig"); return 1; }
  io.println("OK");
  return 0;
}

module smoke_probe_charat
use xiom.string;
use xiom.io;

fn first_char(s: Str) -> Int {
  var c = s.char_at(0);
  c as Int
}

fn main() -> Int {
  var v = first_char("abc");
  if v != 97 { io.println("fc"); return 1; }
  io.println("OK");
  return 0;
}

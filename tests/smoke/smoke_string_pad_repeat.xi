module smoke_string_pad_repeat
use xiom.string.pad;
use xiom.string.repeat;
use xiom.io;

fn main() -> Int {
  if pad.str_pad_left("5", 3, '0') != "005" { io.println("pad_left"); return 1; }
  if pad.str_pad_right("5", 3, '0') != "500" { io.println("pad_right"); return 2; }
  if pad.str_pad_both("ab", 5, '-') != "-ab--" { io.println("pad_both"); return 3; }
  if pad.str_center("ab", 5, '-') != "-ab--" { io.println("center"); return 4; }
  if pad.str_pad_start("5", 3, '0') != "005" { io.println("pad_start"); return 5; }
  if pad.str_pad_end("5", 3, '0') != "500" { io.println("pad_end"); return 6; }
  if pad.str_pad_left("12345", 3, '0') != "12345" { io.println("pad already wide"); return 7; }

  if repeat.str_repeat("ab", 3) != "ababab" { io.println("repeat"); return 8; }
  if repeat.str_repeat("ab", 0) != "" { io.println("repeat zero"); return 9; }
  if repeat.str_repeat_char('a', 3) != "aaa" { io.println("repeat_char"); return 10; }
  if repeat.str_repeat_char('x', 0) != "" { io.println("repeat_char zero"); return 11; }

  io.println("smoke_string_pad_repeat: OK");
  return 0;
}

module smoke_string_lines_words
use xiom.string;

fn main() -> Int {
  var ls = string.lines("line1\nline2\nline3");
  if ls.len() != 3 { return 1; }
  match ls.get(0) {
    Some(s) => { if s != "line1" { return 2; } },
    None => { return 3; },
  };

  var ls2 = string.lines("single");
  if ls2.len() != 1 { return 4; }

  var ls3 = string.lines("");
  if ls3.len() != 1 { return 5; }

  var ws = string.words("hello world foo bar");
  if ws.len() != 4 { return 6; }
  match ws.get(0) {
    Some(s) => { if s != "hello" { return 7; } },
    None => { return 8; },
  };

  var ws2 = string.words("  hello    world  ");
  if ws2.len() != 2 { return 9; }

  var ws3 = string.words("");
  if ws3.len() != 0 { return 10; }

  return 0;
}

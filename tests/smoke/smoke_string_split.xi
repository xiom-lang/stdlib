module smoke_string_split
use xiom.string;

fn main() -> Int {
  var parts1 = string.str_split("a,b,c", ",");
  if parts1.len() != 3 { return 1; }
  match parts1.get(0) {
    Some(s) => { if s != "a" { return 2; } },
    None => { return 3; },
  };
  match parts1.get(2) {
    Some(s) => { if s != "c" { return 4; } },
    None => { return 5; },
  };

  var parts2 = string.str_split("hello world", " ");
  if parts2.len() != 2 { return 6; }
  match parts2.get(0) {
    Some(s) => { if s != "hello" { return 7; } },
    None => { return 8; },
  };

  var parts3 = string.str_split("no-delimiter", ",");
  if parts3.len() != 1 { return 9; }
  match parts3.get(0) {
    Some(s) => { if s != "no-delimiter" { return 10; } },
    None => { return 11; },
  };

  var parts4 = string.str_split("a::b::c", "::");
  if parts4.len() != 3 { return 12; }

  return 0;
}

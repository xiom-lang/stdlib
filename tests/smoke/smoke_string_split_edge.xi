module smoke_string_split_edge
use xiom.string;

fn main() -> Int {
  var p = string.str_split(",", ",");
  if p.len() != 2 { return 1; }

  var p2 = string.str_split("a,,b", ",");
  if p2.len() != 3 { return 2; }

  var p3 = string.str_split(",a,b,", ",");
  if p3.len() != 4 { return 3; }

  var p4 = string.str_split("aaa", "aa");
  if p4.len() != 2 { return 4; }

  return 0;
}

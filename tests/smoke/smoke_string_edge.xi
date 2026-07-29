module smoke_string_edge
use xiom.string;

fn main() -> Int {
  var s = "abcdefghijklmnopqrstuvwxyz";
  if string.str_len(s) != 26 { return 1; }

  var concat_all = "";
  var i: Int = 0;
  while i < 10 {
    concat_all = string.str_concat(concat_all, string.str_slice(s, i, i + 1));
    i = i + 1;
  }
  if concat_all != "abcdefghij" { return 2; }

  if !string.str_starts_with(s, "abc") { return 3; }
  if !string.str_ends_with(s, "xyz") { return 4; }

  match string.index_of(s, "z") {
    Some(i) => { if i != 25 { return 5; } },
    None => { return 6; },
  };

  var split_all = string.str_split(s, "");
  if split_all.len() != 26 { return 7; }

  if string.str_slice(s, 10, 15) != "klmno" { return 8; }

  return 0;
}

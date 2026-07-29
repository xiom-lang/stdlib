module smoke_string_index_of
use xiom.string;

fn main() -> Int {
  match string.index_of("hello", "h") {
    Some(i) => { if i != 0 { return 1; } },
    None => { return 2; },
  };
  match string.index_of("hello", "o") {
    Some(i) => { if i != 4 { return 3; } },
    None => { return 4; },
  };
  match string.index_of("hello", "ell") {
    Some(i) => { if i != 1 { return 5; } },
    None => { return 6; },
  };
  match string.index_of("hello", "world") {
    Some(_) => { return 7; },
    None => {},
  };
  match string.index_of("abcabc", "c") {
    Some(i) => { if i != 2 { return 8; } },
    None => { return 9; },
  };

  match string.last_index_of("abcabc", "c") {
    Some(i) => { if i != 5 { return 10; } },
    None => { return 11; },
  };
  match string.last_index_of("hello", "l") {
    Some(i) => { if i != 3 { return 12; } },
    None => { return 13; },
  };
  match string.last_index_of("hello", "world") {
    Some(_) => { return 14; },
    None => {},
  };

  return 0;
}

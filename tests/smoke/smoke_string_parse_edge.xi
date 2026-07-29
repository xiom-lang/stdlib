module smoke_string_parse_edge
use xiom.string;
use xiom.core;

fn main() -> Int {
  match string.str_to_int("9223372036854775807") {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  match string.str_to_int("-9223372036854775807") {
    Ok(_) => {},
    Err(_) => { return 0; },
  };
  match string.str_to_int("") {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  match string.str_to_int("abc") {
    Ok(_) => { return 3; },
    Err(_) => {},
  };
  match string.str_to_int("12a") {
    Ok(_) => { return 4; },
    Err(_) => {},
  };

  return 0;
}

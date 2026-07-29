module smoke_string_parse
use xiom.string;

fn main() -> Int {
  match string.str_to_int("42") {
    Ok(n) => { if n != 42 { return 1; } },
    Err(_) => { return 2; },
  };
  match string.str_to_int("-10") {
    Ok(n) => { if n != -10 { return 3; } },
    Err(_) => { return 4; },
  };
  match string.str_to_int("0") {
    Ok(n) => { if n != 0 { return 5; } },
    Err(_) => { return 6; },
  };
  match string.str_to_int("+5") {
    Ok(n) => { if n != 5 { return 7; } },
    Err(_) => { return 8; },
  };
  match string.str_to_int("") {
    Ok(_) => { return 9; },
    Err(_) => {},
  };

  match string.str_to_float("3.14") {
    Ok(_) => {},
    Err(_) => { return 10; },
  };
  match string.str_to_float("1e5") {
    Ok(_) => {},
    Err(_) => { return 11; },
  };
  match string.str_to_float("") {
    Ok(_) => { return 12; },
    Err(_) => {},
  };

  return 0;
}

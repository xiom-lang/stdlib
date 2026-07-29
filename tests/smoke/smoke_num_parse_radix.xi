module smoke_num_parse_radix
use xiom.num;

fn main() -> Int {
  match num.parse_int("42") {
    Ok(n) => { if n != 42 { return 1; } },
    Err(_) => { return 2; },
  };
  match num.parse_int("0") {
    Ok(n) => { if n != 0 { return 3; } },
    Err(_) => { return 4; },
  };
  match num.parse_int("-10") {
    Ok(n) => { if n != -10 { return 5; } },
    Err(_) => { return 6; },
  };

  match num.parse_int_radix("FF", 16) {
    Ok(n) => { if n != 255 { return 7; } },
    Err(_) => { return 8; },
  };
  match num.parse_int_radix("1010", 2) {
    Ok(n) => { if n != 10 { return 9; } },
    Err(_) => { return 10; },
  };
  match num.parse_int_radix("77", 8) {
    Ok(n) => { if n != 63 { return 11; } },
    Err(_) => { return 12; },
  };
  match num.parse_int_radix("Z", 36) {
    Ok(n) => { if n != 35 { return 13; } },
    Err(_) => { return 14; },
  };
  match num.parse_int_radix("ff", 16) {
    Ok(n) => { if n != 255 { return 15; } },
    Err(_) => { return 16; },
  };
  match num.parse_int_radix("0", 2) {
    Ok(n) => { if n != 0 { return 17; } },
    Err(_) => { return 18; },
  };
  match num.parse_int_radix("xyz", 10) {
    Ok(_) => { return 19; },
    Err(_) => {},
  };

  return 0;
}

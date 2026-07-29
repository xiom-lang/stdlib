module smoke_num_checked
use xiom.num;

fn main() -> Int {
  match num.checked_add(10, 20) {
    Some(v) => { if v != 30 { return 1; } },
    None => { return 2; },
  };
  match num.checked_add(0, 0) {
    Some(v) => { if v != 0 { return 3; } },
    None => { return 4; },
  };

  match num.checked_sub(50, 20) {
    Some(v) => { if v != 30 { return 5; } },
    None => { return 6; },
  };

  match num.checked_mul(5, 6) {
    Some(v) => { if v != 30 { return 7; } },
    None => { return 8; },
  };
  match num.checked_mul(0, 100) {
    Some(v) => { if v != 0 { return 9; } },
    None => { return 10; },
  };

  match num.checked_div(10, 2) {
    Some(v) => { if v != 5 { return 11; } },
    None => { return 12; },
  };
  match num.checked_div(10, 0) {
    Some(_) => { return 13; },
    None => {},
  };

  return 0;
}

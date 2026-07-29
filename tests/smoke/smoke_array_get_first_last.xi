module smoke_array_get_first_last
use xiom.array;

fn main() -> Int {
  let arr = [10, 20, 30, 40, 50];

  match array.get(&arr, 0) {
    Some(v) => { if *v != 10 { return 1; } },
    None => { return 2; },
  };
  match array.get(&arr, 4) {
    Some(v) => { if *v != 50 { return 3; } },
    None => { return 4; },
  };
  match array.get(&arr, -1) {
    Some(_) => { return 5; },
    None => {},
  };
  match array.get(&arr, 99) {
    Some(_) => { return 6; },
    None => {},
  };

  match array.first(&arr) {
    Some(v) => { if *v != 10 { return 7; } },
    None => { return 8; },
  };
  match array.last(&arr) {
    Some(v) => { if *v != 50 { return 9; } },
    None => { return 10; },
  };

  return 0;
}

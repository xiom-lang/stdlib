module smoke_array_binary_search
use xiom.array;

fn main() -> Int {
  let arr = [1, 3, 5, 7, 9];

  match array.binary_search(&arr, &5) {
    Ok(i) => { if i != 2 { return 1; } },
    Err(_) => { return 2; },
  };

  match array.binary_search(&arr, &1) {
    Ok(i) => { if i != 0 { return 3; } },
    Err(_) => { return 4; },
  };

  match array.binary_search(&arr, &9) {
    Ok(i) => { if i != 4 { return 5; } },
    Err(_) => { return 6; },
  };

  match array.binary_search(&arr, &4) {
    Ok(_) => { return 7; },
    Err(_) => {},
  };

  return 0;
}

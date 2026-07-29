module smoke_array_everything
use xiom.array;
use xiom.cmp;
use xiom.core;

fn main() -> Int {
  var arr = [9, 3, 7, 1, 5];
  array.sort(&mut arr);
  if !core.is_sorted(arr) { return 1; }

  if arr[0] != 1 { return 2; }
  if arr[4] != 9 { return 3; }

  match array.binary_search(&arr, &5) {
    Ok(i) => { if i != 2 { return 4; } },
    Err(_) => { return 5; },
  };

  if !array.contains(&arr, &7) { return 6; }

  return 0;
}

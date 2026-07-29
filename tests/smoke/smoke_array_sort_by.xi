module smoke_array_sort_by
use xiom.array;
use xiom.cmp;

fn main() -> Int {
  var arr = [5, 3, 1, 4, 2];
  array.sort_by(&mut arr, fn(a: &Int, b: &Int) -> cmp.Ordering {
    if *a < *b { return cmp.Less; };
    if *a > *b { return cmp.Greater; };
    return cmp.Equal;
  });
  if arr[0] != 1 { return 1; }
  if arr[4] != 5 { return 2; }

  return 0;
}

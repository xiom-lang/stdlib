module smoke_array_map
use xiom.array;

fn main() -> Int {
  // VAR array literals are fixed arrays (LET literals convert to Vec --
  // M33 -- which the array module's [N]T fns can't consume).
  var arr = [1, 2, 3, 4, 5];
  var doubled = array.map(arr, fn(x: Int) -> Int { return x * 2; });
  if doubled[0] != 2 { return 1; }
  if doubled[4] != 10 { return 2; }

  return 0;
}

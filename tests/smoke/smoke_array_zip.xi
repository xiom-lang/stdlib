module smoke_array_zip
use xiom.array;

fn main() -> Int {
  let a = [1, 2, 3];
  let b = [10, 20, 30];
  var zipped = array.zip(a, b);
  if zipped[0].0 != 1 { return 1; }
  if zipped[0].1 != 10 { return 2; }
  if zipped[2].0 != 3 { return 3; }
  if zipped[2].1 != 30 { return 4; }

  return 0;
}

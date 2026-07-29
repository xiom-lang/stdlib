module smoke_rand_shuffle
use xiom.rand;

fn main() -> Int {
  var items = Vec[Int].new();
  items.push(1); items.push(2); items.push(3); items.push(4); items.push(5);

  rand.shuffle(&mut items);
  if items.len() != 5 { return 1; }

  return 0;
}

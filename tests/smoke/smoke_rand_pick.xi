module smoke_rand_pick
use xiom.rand;

fn main() -> Int {
  var items = Vec[Int].new();
  items.push(10); items.push(20); items.push(30);

  match rand.pick(&items) {
    Some(_) => {},
    None => { return 1; },
  };

  var empty: Vec[Int] = Vec[Int].new();
  match rand.pick(&empty) {
    Some(_) => { return 2; },
    None => {},
  };

  var picked = rand.pick_n(&items, 2);
  if picked.len() != 2 { return 3; }

  return 0;
}

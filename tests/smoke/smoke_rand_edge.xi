module smoke_rand_edge
use xiom.rand;

fn main() -> Int {
  rand.seed_from_value(42);
  var r1 = rand.random();

  rand.seed_from_value(0);
  var r2 = rand.random();

  if r1 == r2 { return 0; }

  var ri = rand.random_int(-100, 100);
  if ri < -100 || ri > 100 { return 1; }

  var empty: Vec[Int] = Vec[Int].new();
  match rand.pick(&empty) {
    Some(_) => { return 2; },
    None => {},
  };

  return 0;
}

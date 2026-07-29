module smoke_cross_rand_collections
use xiom.rand;
use xiom.collections;

fn main() -> Int {
  rand.seed_from_value(42);

  var v = Vec[Int].new();
  var i: Int = 0;
  while i < 50 {
    v.push(rand.random_int(1, 100));
    i = i + 1;
  }
  if v.len() != 50 { return 1; }

  var m = Map[Int, Bool].new();
  var j: Int = 0;
  while j < v.len() {
    match v.get(j) {
      Some(x) => { m.insert(x, true); },
      None => {},
    };
    j = j + 1;
  }

  if m.len() <= 0 { return 2; }

  rand.shuffle(&mut v);
  if v.len() != 50 { return 3; }

  return 0;
}

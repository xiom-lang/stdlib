module smoke_rand_weighted
use xiom.rand;

fn main() -> Int {
  var items = Vec[Str].new();
  items.push("a"); items.push("b"); items.push("c");

  var weights = Vec[Float64].new();
  weights.push(1.0); weights.push(2.0); weights.push(3.0);

  match rand.weighted_pick(&items, &weights) {
    Some(s) => {
      if s != "a" && s != "b" && s != "c" { return 1; }
    },
    None => { return 2; },
  };

  return 0;
}

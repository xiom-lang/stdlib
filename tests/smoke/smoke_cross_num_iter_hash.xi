module smoke_cross_num_iter_hash
use xiom.num;
use xiom.iter;
use xiom.hash;

fn main() -> Int {
  var squares = iter.range(1, 11)
    .map(fn(x: Int) -> Int { return x * x; })
    .collect();

  var i: Int = 0;
  while i < squares.len() {
    match squares.get(i) {
      Some(x) => {
        var h = hash.hash(x);
        if h == 0 { }
      },
      None => {},
    };
    i = i + 1;
  }

  if squares.len() != 10 { return 1; }

  return 0;
}

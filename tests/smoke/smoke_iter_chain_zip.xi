module smoke_iter_chain_zip
use xiom.iter;

fn main() -> Int {
  var r1 = iter.range(1, 4);
  var r2 = iter.range(10, 13);
  var chained = r1.chain(r2).collect();
  if chained.len() != 5 { return 1; }

  var a = iter.range(100, 103);
  var b = iter.range(200, 203);
  var zipped = a.zip(b).collect();
  if zipped.len() != 2 { return 2; }
  match zipped.get(0) {
    Some((x, y)) => { if x != 100 { return 3; }; if y != 200 { return 4; }; },
    None => { return 5; },
  };

  return 0;
}

module smoke_iter_take_skip
use xiom.iter;

fn main() -> Int {
  var taken = iter.range(1, 10).take(3).collect();
  if taken.len() != 3 { return 1; }
  match taken.get(0) { Some(v) => { if v != 1 { return 2; } }, None => { return 3; }, };
  match taken.get(2) { Some(v) => { if v != 3 { return 4; } }, None => { return 5; }, };

  var skipped = iter.range(1, 6).skip(3).collect();
  if skipped.len() != 2 { return 6; }
  match skipped.get(0) { Some(v) => { if v != 4 { return 7; } }, None => { return 8; }, };

  var overskip = iter.range(1, 3).skip(10).collect();
  if overskip.len() != 0 { return 9; }

  var overtake = iter.range(1, 3).take(10).collect();
  if overtake.len() != 2 { return 10; }

  return 0;
}

// XIOM stdlib stress -- Vec len tracking
// Verifies len grows and shrinks with push/pop/clear.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_len
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  if v.len() != 0 { return 1; }
  var i = 0;
  while i < 50 {
    v.push(i);
    i = i + 1;
  }
  if v.len() != 50 { return 2; }
  i = 0;
  while i < 25 {
    var _ = v.pop();
    i = i + 1;
  }
  if v.len() != 25 { return 3; }
  v.clear();
  if v.len() != 0 { return 4; }
  return 0;
}

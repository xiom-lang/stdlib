// XIOM stdlib smoke test — xiom.collections
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collections
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  if v.len() == 3 && v.pop() == Some(3) {
    return 0;
  }
  return 1;
}

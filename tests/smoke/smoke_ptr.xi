// XIOM stdlib smoke test -- xiom.ptr
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_ptr
use xiom.ptr;

fn main() -> Int {
  var p = ptr.null[Int]();
  var d = ptr.dangling[Int]();
  if ptr.is_null(p) && not ptr.is_null(d) {
    return 0;
  }
  return 1;
}

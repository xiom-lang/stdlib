// XIOM stdlib smoke test — xiom.ptr
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_ptr
use xiom.ptr;

fn main() -> Int {
  let p = ptr.null[Int]();
  let d = ptr.dangling[Int]();
  if ptr.is_null(p) && !ptr.is_null(d) {
    return 0;
  }
  return 1;
}

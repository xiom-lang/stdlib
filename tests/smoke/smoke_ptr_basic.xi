module smoke_ptr_basic
use xiom.ptr;

fn main() -> Int {
  var n = ptr.null[Int]();
  if !ptr.is_null(n) { return 1; }

  var nm = ptr.null_mut[Int]();
  if !ptr.is_null(nm) { return 2; }

  var d = ptr.dangling[Int]();
  if ptr.is_null(d) { return 3; }

  if !ptr.eq(n, nm) { return 4; }

  return 0;
}

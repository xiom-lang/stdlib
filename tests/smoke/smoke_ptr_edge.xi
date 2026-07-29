module smoke_ptr_edge
use xiom.ptr;

fn main() -> Int {
  var n = ptr.null[Int]();
  if !ptr.is_null(n) { return 1; }

  var n2 = ptr.null_mut[Int]();
  if !ptr.is_null(n2) { return 2; }

  var d = ptr.dangling[Int]();
  if ptr.is_null(d) { return 3; }

  var x: Int = 1;
  var rx = ptr.from_ref(&x);
  if ptr.is_null(rx) { return 4; }

  return 0;
}

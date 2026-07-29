module smoke_ptr_narrow
use xiom.ptr;

fn main() -> Int {
  var n8 = ptr.null[Int8]();
  if !ptr.is_null(n8) { return 1; }

  var n16 = ptr.null[Int16]();
  if !ptr.is_null(n16) { return 2; }

  var n32 = ptr.null[Int32]();
  if !ptr.is_null(n32) { return 3; }

  var x: Int8 = 1 as Int8;
  var px = ptr.from_ref(&x);
  if ptr.is_null(px) { return 4; }

  return 0;
}

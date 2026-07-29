module smoke_ptr_ref_convert
use xiom.ptr;

fn main() -> Int {
  var x: Int = 42;
  var px = ptr.from_ref(&x);
  if ptr.is_null(px) { return 1; }

  var y: Int = 99;
  var py = ptr.from_mut(&mut y);
  if ptr.is_null(py) { return 2; }

  if ptr.eq(px, py) { return 3; }

  return 0;
}

module smoke_ptr_offset
use xiom.ptr;

fn main() -> Int {
  var d = ptr.dangling[Int]();
  var o = ptr.offset(d, 0);
  if o != d { return 1; }

  var a = ptr.add(d, 5);
  var s = ptr.sub(a, 5);
  if s != d { return 2; }

  return 0;
}

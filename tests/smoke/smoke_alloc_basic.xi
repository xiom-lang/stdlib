module smoke_alloc_basic
use xiom.alloc;
use xiom.ptr;

fn main() -> Int {
  var p = alloc.alloc(64);
  var n = ptr.is_null(p);
  if n { return 1; }

  alloc.dealloc(p, 64);

  return 0;
}

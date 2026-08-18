module smoke_alloc_edge
use xiom.alloc;
use xiom.ptr;

fn main() -> Int {
  var ga = alloc.global_alloc();
  var l = alloc.Layout.new(256);

  match ga.allocate(l) {
    Ok(p) => {
      if ptr.is_null(p) { return 1; }
      ga.deallocate(p, l);
    },
    Err(_) => { return 2; },
  };

  match ga.allocate_zeroed(l) {
    Ok(p) => {
      if ptr.is_null(p) { return 3; }
      ga.deallocate(p, l);
    },
    Err(_) => { return 4; },
  };

  return 0;
}

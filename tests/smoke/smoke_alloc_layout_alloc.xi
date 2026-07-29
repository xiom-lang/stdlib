module smoke_alloc_layout_alloc
use xiom.alloc;

fn main() -> Int {
  var l = alloc.Layout.new(128);
  var p = alloc.alloc_layout(l);
  if ptr.is_null(p) { return 1; }

  alloc.dealloc_layout(p, l);

  return 0;
}

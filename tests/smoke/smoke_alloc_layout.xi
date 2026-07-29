module smoke_alloc_layout
use xiom.alloc;

fn main() -> Int {
  var l = alloc.Layout.new(64);
  if l.size != 64 { return 1; }
  if l.align != 8 { return 2; }

  var l2 = l.with_align(16);
  if l2.align != 16 { return 3; }

  var ps = l.padded_size();
  if ps != 64 { return 4; }

  return 0;
}

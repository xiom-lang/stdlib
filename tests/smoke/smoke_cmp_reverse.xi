module smoke_cmp_reverse
use xiom.cmp;

fn main() -> Int {
  var r = cmp.Reverse.new(10);
  if r.value != 10 { return 1; }

  return 0;
}

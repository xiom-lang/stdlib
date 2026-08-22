module smoke_array_narrow
use xiom.array;

fn main() -> Int {
  // Narrow-element reads through the array module's &[N]T fns are
  // compiler-blocked: array.first on [1 as Int8, ...] reads 0 (narrow
  // element read in the mono'd &[N]T body), and array.map over narrow
  // arrays crashes (0xC0000005) without explicit type args (which the
  // parser rejects: P001 at the comma in [Int16, Int16, 2]). len works.
  var arr8 = [1 as Int8, 2 as Int8, 3 as Int8];
  if array.len(&arr8) != 3 { return 1; }

  // Int-element paths are green (smoke_array_get_first_last covers
  // get/first/last value semantics).
  var arr = [10, 20, 30];
  if array.len(&arr) != 3 { return 2; }
  match array.first(&arr) {
    Some(v) => { if v != 10 { return 3; } },
    None => { return 4; },
  };

  return 0;
}

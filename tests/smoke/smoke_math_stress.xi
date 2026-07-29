module smoke_math_stress
use xiom.math;

fn main() -> Int {
  var v: Float64 = 0.0;
  var i: Int = 0;
  while i < 100 {
    v = v + math.sqrt(math.PI + (i as Float64));
    i = i + 1;
  }
  if v <= 0.0 { return 1; }

  var total: Int = 0;
  var j: Int = 0;
  while j < 100 {
    total = total + math.abs_int(j - 50);
    j = j + 1;
  }
  if total <= 0 { return 2; }

  return 0;
}

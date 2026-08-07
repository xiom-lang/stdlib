module smoke_complex
use xiom.complex;
fn main() -> Int {
  var a = xiom.complex.complex_new(1.0, 2.0);
  var b = xiom.complex.complex_new(3.0, 4.0);
  var c = xiom.complex.complex_add(a, b);
  if !(c.re == 4.0 && c.im == 6.0) { return 1; }
  var m = xiom.complex.complex_mul(a, b);
  if !(m.re == -5.0 && m.im == 10.0) { return 1; }
  var ab = xiom.complex.complex_abs(a);
  if ab < 2.23 || ab > 2.24 { return 1; }
  return 0;
}

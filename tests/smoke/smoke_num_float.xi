module smoke_num_float
use xiom.num.float;
use xiom.io;

fn main() -> Int {
  // is_nan (f != f; NaN cannot be produced today — BUG 19)
  if float.float_is_nan(0.0) { io.println("float: is_nan(0.0)"); return 1; }
  if float.float_is_nan(1.0) { io.println("float: is_nan(1.0)"); return 1; }
  if float.float_is_nan(1.0 / 0.0) { io.println("float: is_nan(inf)"); return 1; }
  // is_infinite
  if !float.float_is_infinite(1.0 / 0.0) { io.println("float: is_infinite(inf)"); return 2; }
  if !float.float_is_infinite(-1.0 / 0.0) { io.println("float: is_infinite(-inf)"); return 2; }
  if float.float_is_infinite(1.5) { io.println("float: is_infinite(1.5)"); return 2; }
  if float.float_is_infinite(0.0) { io.println("float: is_infinite(0.0)"); return 2; }
  // exponent
  if float.float_exponent(1.0) != 0 { io.println("float: exponent(1.0)"); return 3; }
  if float.float_exponent(2.0) != 1 { io.println("float: exponent(2.0)"); return 3; }
  if float.float_exponent(4.0) != 2 { io.println("float: exponent(4.0)"); return 3; }
  if float.float_exponent(0.5) != -1 { io.println("float: exponent(0.5)"); return 3; }
  if float.float_exponent(0.25) != -2 { io.println("float: exponent(0.25)"); return 3; }
  if float.float_exponent(1.5) != 0 { io.println("float: exponent(1.5)"); return 3; }
  if float.float_exponent(0.0) != 0 { io.println("float: exponent(0.0)"); return 3; }
  if float.float_exponent(-8.0) != 3 { io.println("float: exponent(-8.0)"); return 3; }
  // mantissa (implicit bit included for normals)
  if float.float_mantissa(1.0) != 4503599627370496 { io.println("float: mantissa(1.0)"); return 4; }
  if float.float_mantissa(2.0) != 4503599627370496 { io.println("float: mantissa(2.0)"); return 4; }
  if float.float_mantissa(1.5) != 6755399441055744 { io.println("float: mantissa(1.5)"); return 4; }
  if float.float_mantissa(0.5) != 4503599627370496 { io.println("float: mantissa(0.5)"); return 4; }
  if float.float_mantissa(0.0) != 0 { io.println("float: mantissa(0.0)"); return 4; }
  if float.float_mantissa(1.0 / 0.0) != 0 { io.println("float: mantissa(inf)"); return 4; }
  if float.float_mantissa(-1.5) != 6755399441055744 { io.println("float: mantissa(-1.5)"); return 4; }
  // is_subnormal
  if !float.float_is_subnormal(5.0e-324) { io.println("float: is_subnormal(5e-324)"); return 5; }
  if float.float_is_subnormal(1.0) { io.println("float: is_subnormal(1.0)"); return 5; }
  if float.float_is_subnormal(0.0) { io.println("float: is_subnormal(0.0)"); return 5; }
  if float.float_is_subnormal(1.0e-300) { io.println("float: is_subnormal(1e-300)"); return 5; }
  if float.float_is_subnormal(1.0 / 0.0) { io.println("float: is_subnormal(inf)"); return 5; }
  // classify
  if float.float_classify(0.0) != "zero" { io.println("float: classify(0.0)"); return 6; }
  if float.float_classify(1.0) != "normal" { io.println("float: classify(1.0)"); return 6; }
  if float.float_classify(-1.5) != "normal" { io.println("float: classify(-1.5)"); return 6; }
  if float.float_classify(1.0 / 0.0) != "inf" { io.println("float: classify(inf)"); return 6; }
  if float.float_classify(-1.0 / 0.0) != "-inf" { io.println("float: classify(-inf)"); return 6; }
  if float.float_classify(5.0e-324) != "subnormal" { io.println("float: classify(5e-324)"); return 6; }
  io.println("smoke_num_float: OK");
  return 0;
}

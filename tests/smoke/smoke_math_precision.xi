// Smoke: xiom.math.precision (generic type-level precision queries).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // Int
  if math.precision.min_value[Int]() != -9223372036854775808 { io.println("int-min"); return 1; }
  if math.precision.max_value[Int]() != 9223372036854775807 { io.println("int-max"); return 2; }
  if math.precision.epsilon[Int]() != 1 { io.println("int-eps"); return 3; }
  if math.precision.digits[Int]() != 19 { io.println("int-digits"); return 4; }
  if math.precision.mantissa_digits[Int]() != 63 { io.println("int-mant"); return 5; }
  if math.precision.is_signed[Int]() != true { io.println("int-signed"); return 6; }
  if math.precision.bit_width[Int]() != 64 { io.println("int-bits"); return 7; }
  if math.precision.byte_width[Int]() != 8 { io.println("int-bytes"); return 8; }

  // Int32
  if math.precision.min_value[Int32]() != ((-2147483648) as Int32) { io.println("i32-min"); return 9; }
  if math.precision.max_value[Int32]() != (2147483647 as Int32) { io.println("i32-max"); return 10; }
  if math.precision.bit_width[Int32]() != 32 { io.println("i32-bits"); return 11; }
  if math.precision.byte_width[Int32]() != 4 { io.println("i32-bytes"); return 12; }

  // UInt64
  if math.precision.is_signed[UInt64]() != false { io.println("u64-signed"); return 13; }
  var u64_max = math.precision.max_value[UInt64]();
  var u64_expect = (9223372036854775807 as UInt64) * 2 + 1;
  if u64_max != u64_expect { io.println("u64-max"); return 14; }
  if math.precision.min_value[UInt64]() != (0 as UInt64) { io.println("u64-min"); return 15; }

  // Float64
  var eps = math.precision.epsilon[Float64]();
  if 1.0 + eps == 1.0 { io.println("f64-eps-small"); return 16; }
  if 1.0 + eps / 2.0 != 1.0 { io.println("f64-eps-big"); return 17; }
  if math.precision.digits[Float64]() != 15 { io.println("f64-digits"); return 18; }
  if math.precision.mantissa_digits[Float64]() != 53 { io.println("f64-mant"); return 19; }
  if math.precision.exponent_bias[Float64]() != 1023 { io.println("f64-bias"); return 20; }
  if math.precision.min_exponent[Float64]() != -1022 { io.println("f64-minexp"); return 21; }
  if math.precision.max_exponent[Float64]() != 1023 { io.println("f64-maxexp"); return 22; }
  if math.precision.is_signed[Float64]() != true { io.println("f64-signed"); return 23; }
  if math.precision.bit_width[Float64]() != 64 { io.println("f64-bits"); return 24; }
  if math.precision.byte_width[Float64]() != 8 { io.println("f64-bytes"); return 25; }
  var f64_min = math.precision.min_value[Float64]();
  if f64_min > -1.7e308 { io.println("f64-min"); return 26; }
  var f64_max = math.precision.max_value[Float64]();
  if f64_max < 1.7e308 { io.println("f64-max"); return 27; }

  // Float32
  var eps32 = math.precision.epsilon[Float32]();
  var one32 = 1.0 as Float32;
  if one32 + eps32 == one32 { io.println("f32-eps-small"); return 28; }
  var half32 = eps32 * (0.5 as Float32);
  if one32 + half32 != one32 { io.println("f32-eps-big"); return 29; }
  if math.precision.digits[Float32]() != 6 { io.println("f32-digits"); return 30; }
  if math.precision.mantissa_digits[Float32]() != 24 { io.println("f32-mant"); return 31; }
  if math.precision.exponent_bias[Float32]() != 127 { io.println("f32-bias"); return 32; }
  if math.precision.min_exponent[Float32]() != -126 { io.println("f32-minexp"); return 33; }
  if math.precision.max_exponent[Float32]() != 127 { io.println("f32-maxexp"); return 34; }
  if math.precision.bit_width[Float32]() != 32 { io.println("f32-bits"); return 35; }
  if math.precision.byte_width[Float32]() != 4 { io.println("f32-bytes"); return 36; }
  var f32_min = math.precision.min_value[Float32]();
  if f32_min > -3.4e38 { io.println("f32-min"); return 37; }
  var f32_max = math.precision.max_value[Float32]();
  if f32_max < 3.4e38 { io.println("f32-max"); return 38; }

  io.println("smoke_math_precision: OK");
  return 0;
}

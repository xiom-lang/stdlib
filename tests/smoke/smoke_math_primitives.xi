// Smoke: xiom.math.primitives (scalar float primitives, pure XIOM).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // min / max
  if math.primitives.min(1.5, 2.5) != (1.5 as Float64) { io.println("min-bad"); return 1; }
  if math.primitives.max(1.5, 2.5) != (2.5 as Float64) { io.println("max-bad"); return 2; }

  // clamp
  if math.primitives.clamp(5.0, 0.0, 3.0) != (3.0 as Float64) { io.println("clamp-hi"); return 3; }
  if math.primitives.clamp(-5.0, 0.0, 3.0) != (0.0 as Float64) { io.println("clamp-lo"); return 4; }
  if math.primitives.clamp(2.0, 0.0, 3.0) != (2.0 as Float64) { io.println("clamp-mid"); return 5; }

  // abs / signum
  if math.primitives.abs(-2.5) != (2.5 as Float64) { io.println("abs-neg"); return 6; }
  if math.primitives.abs(2.5) != (2.5 as Float64) { io.println("abs-pos"); return 7; }
  if math.primitives.signum(-2.5) != -1 { io.println("sign-neg"); return 8; }
  if math.primitives.signum(0.0) != 0 { io.println("sign-zero"); return 9; }
  if math.primitives.signum(2.5) != 1 { io.println("sign-pos"); return 10; }

  // lerp
  if math.primitives.lerp(0.0, 10.0, 0.5) != (5.0 as Float64) { io.println("lerp-bad"); return 11; }

  // step / smoothstep
  if math.primitives.step(2.0, 1.0) != (0.0 as Float64) { io.println("step-lo"); return 12; }
  if math.primitives.step(2.0, 3.0) != (1.0 as Float64) { io.println("step-hi"); return 13; }
  if math.primitives.smoothstep(0.0, 1.0, 0.5) != (0.5 as Float64) { io.println("smooth-bad"); return 14; }

  // fract
  if math.primitives.fract(2.5) != (0.5 as Float64) { io.println("fract-pos"); return 15; }
  if math.primitives.fract(-2.5) != (-0.5 as Float64) { io.println("fract-neg"); return 16; }

  // modf
  var m1 = math.primitives.modf(2.5);
  if m1.0 != 2 { io.println("modf-i"); return 17; }
  if m1.1 != (0.5 as Float64) { io.println("modf-f"); return 18; }
  var m2 = math.primitives.modf(-2.5);
  if m2.0 != -2 { io.println("modf-i2"); return 19; }
  if m2.1 != (-0.5 as Float64) { io.println("modf-f2"); return 20; }

  // copysign
  if math.primitives.copysign(3.5, -1.0) != (-3.5 as Float64) { io.println("copysign-neg"); return 21; }
  if math.primitives.copysign(-3.5, 1.0) != (3.5 as Float64) { io.println("copysign-pos"); return 22; }

  // nextafter: direction checks + 1-ulp distance
  var na = math.primitives.nextafter(1.0, 2.0);
  if !(na > 1.0) { io.println("next-up"); return 23; }
  var na_diff = na - 1.0;
  if na_diff < 0.0 { na_diff = -na_diff; }
  if na_diff > 1e-15 { io.println("next-ulp"); return 24; }
  var nb = math.primitives.nextafter(1.0, 0.0);
  if !(nb < 1.0) { io.println("next-dn"); return 25; }
  if !(math.primitives.nextafter(0.0, 1.0) > 0.0) { io.println("next-zero"); return 26; }
  if math.primitives.nextafter(3.0, 3.0) != (3.0 as Float64) { io.println("next-eq"); return 27; }

  // fma: exact known values + the exact-product property
  if math.primitives.fma(2.0, 3.0, 4.0) != (10.0 as Float64) { io.println("fma-1"); return 28; }
  if math.primitives.fma(-2.0, 3.0, 1.0) != (-5.0 as Float64) { io.println("fma-2"); return 29; }
  if math.primitives.fma(0.0, 5.0, 7.0) != (7.0 as Float64) { io.println("fma-3"); return 30; }
  var fma_a = 1.0000000000000002;
  var fma_c = -1.0000000000000004;
  var fma_exact = math.primitives.fma(fma_a, fma_a, fma_c);
  var fma_naive = fma_a * fma_a + fma_c;
  if fma_naive != (0.0 as Float64) { io.println("fma-naive-ref"); return 31; }
  if !(fma_exact > 0.0) { io.println("fma-exact-pos"); return 32; }
  if !(fma_exact < 1e-31) { io.println("fma-exact-mag"); return 33; }

  // frexp: x == mantissa * 2^exp
  var f1 = math.primitives.frexp(8.0);
  if f1.0 != (0.5 as Float64) { io.println("frexp-m"); return 34; }
  if f1.1 != 4 { io.println("frexp-e"); return 35; }
  var f2 = math.primitives.frexp(-8.0);
  if f2.0 != (-0.5 as Float64) { io.println("frexp-m2"); return 36; }
  if f2.1 != 4 { io.println("frexp-e2"); return 37; }
  var f3 = math.primitives.frexp(0.0);
  if f3.0 != (0.0 as Float64) || f3.1 != 0 { io.println("frexp-zero"); return 38; }

  // ldexp: x * 2^exp
  if math.primitives.ldexp(1.0, 10) != (1024.0 as Float64) { io.println("ldexp-1"); return 39; }
  if math.primitives.ldexp(2.5, 2) != (10.0 as Float64) { io.println("ldexp-2"); return 40; }
  if math.primitives.ldexp(1.0, -2) != (0.25 as Float64) { io.println("ldexp-3"); return 41; }

  // hypot
  if math.primitives.hypot(3.0, 4.0) != (5.0 as Float64) { io.println("hypot-bad"); return 42; }
  if math.primitives.hypot(0.0, 0.0) != (0.0 as Float64) { io.println("hypot-zero"); return 43; }

  // cbrt
  if math.primitives.cbrt(27.0) != (3.0 as Float64) { io.println("cbrt-pos"); return 44; }
  if math.primitives.cbrt(-27.0) != (-3.0 as Float64) { io.println("cbrt-neg"); return 45; }
  if math.primitives.cbrt(0.0) != (0.0 as Float64) { io.println("cbrt-zero"); return 46; }

  // classification
  if math.primitives.is_nan(1.0) { io.println("isnan-f"); return 47; }
  if !math.primitives.is_inf(1.0 / 0.0) { io.println("isinf-p"); return 48; }
  if !math.primitives.is_inf(-1.0 / 0.0) { io.println("isinf-n"); return 49; }
  if math.primitives.is_inf(3.5) { io.println("isinf-f"); return 50; }
  if !math.primitives.is_finite(3.5) { io.println("isfinite-t"); return 51; }
  if math.primitives.is_finite(1.0 / 0.0) { io.println("isfinite-inf"); return 52; }

  io.println("smoke_math_primitives: OK");
  return 0;
}

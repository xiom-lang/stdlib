// Smoke: xiom.math.decompose (IEEE-754 decomposition + classification).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // frexp
  var f1 = math.decompose.frexp(8.0);
  if f1.0 != (0.5 as Float64) { io.println("frexp-m"); return 1; }
  if f1.1 != 4 { io.println("frexp-e"); return 2; }
  var f2 = math.decompose.frexp(-8.0);
  if f2.0 != (-0.5 as Float64) { io.println("frexp-m2"); return 3; }
  if f2.1 != 4 { io.println("frexp-e2"); return 4; }
  var f3 = math.decompose.frexp(0.0);
  if f3.0 != (0.0 as Float64) || f3.1 != 0 { io.println("frexp-zero"); return 5; }
  var f4 = math.decompose.frexp(1.0);
  if f4.0 != (0.5 as Float64) || f4.1 != 1 { io.println("frexp-1"); return 6; }

  // ldexp
  if math.decompose.ldexp(1.0, 10) != (1024.0 as Float64) { io.println("ldexp-1"); return 7; }
  if math.decompose.ldexp(2.5, 2) != (10.0 as Float64) { io.println("ldexp-2"); return 8; }
  if math.decompose.ldexp(1.0, -2) != (0.25 as Float64) { io.println("ldexp-3"); return 9; }
  if math.decompose.ldexp(0.0, 100) != (0.0 as Float64) { io.println("ldexp-zero"); return 10; }

  // ilogb
  if math.decompose.ilogb(8.0) != 3 { io.println("ilogb-8"); return 11; }
  if math.decompose.ilogb(0.5) != -1 { io.println("ilogb-0.5"); return 12; }
  if math.decompose.ilogb(1.0) != 0 { io.println("ilogb-1"); return 13; }
  if math.decompose.ilogb(1024.0) != 10 { io.println("ilogb-1024"); return 14; }

  // logb
  if math.decompose.logb(8.0) != (3.0 as Float64) { io.println("logb"); return 15; }

  // scalbn / scalbln
  if math.decompose.scalbn(3.0, 2) != (12.0 as Float64) { io.println("scalbn"); return 16; }
  if math.decompose.scalbln(3.0, 2 as Int64) != (12.0 as Float64) { io.println("scalbln"); return 17; }

  // significand
  if math.decompose.significand(8.0) != (0.5 as Float64) { io.println("significand"); return 18; }

  // exponent
  if math.decompose.exponent(8.0) != 3 { io.println("exponent"); return 19; }

  // pure variants agree
  var p1 = math.decompose.frexp_pure(16.0);
  if p1.0 != (0.5 as Float64) || p1.1 != 5 { io.println("frexp_pure"); return 20; }
  if math.decompose.ldexp_pure(1.0, 3) != (8.0 as Float64) { io.println("ldexp_pure"); return 21; }

  // is_normal / is_subnormal
  if !math.decompose.is_normal(1.0) { io.println("norm-1"); return 22; }
  if !math.decompose.is_normal(1e-300) { io.println("norm-1e-300"); return 23; }
  if math.decompose.is_normal(1e-310) { io.println("norm-sub"); return 24; }
  if math.decompose.is_normal(0.0) { io.println("norm-zero"); return 25; }
  if math.decompose.is_normal(1.0 / 0.0) { io.println("norm-inf"); return 26; }
  if !math.decompose.is_subnormal(1e-310) { io.println("sub-1e-310"); return 27; }
  if math.decompose.is_subnormal(1.0) { io.println("sub-1"); return 28; }
  if math.decompose.is_subnormal(0.0) { io.println("sub-zero"); return 29; }

  // classify
  if math.decompose.classify(1.0) != math.decompose.FloatClass.Normal { io.println("cls-normal"); return 30; }
  if math.decompose.classify(-2.5) != math.decompose.FloatClass.Normal { io.println("cls-normal2"); return 31; }
  if math.decompose.classify(1.0 / 0.0) != math.decompose.FloatClass.Infinity { io.println("cls-inf"); return 32; }
  if math.decompose.classify(-1.0 / 0.0) != math.decompose.FloatClass.Infinity { io.println("cls-neginf"); return 33; }
  if math.decompose.classify(0.0) != math.decompose.FloatClass.Zero { io.println("cls-zero"); return 34; }
  if math.decompose.classify(-0.0) != math.decompose.FloatClass.Zero { io.println("cls-negzero"); return 35; }
  if math.decompose.classify(1e-310) != math.decompose.FloatClass.Subnormal { io.println("cls-sub"); return 36; }

  // nextafter / nexttoward
  if !(math.decompose.nextafter(1.0, 2.0) > 1.0) { io.println("next-up"); return 37; }
  if !(math.decompose.nextafter(1.0, 0.0) < 1.0) { io.println("next-dn"); return 38; }
  if !(math.decompose.nextafter(0.0, 1.0) > 0.0) { io.println("next-zero"); return 39; }
  if math.decompose.nextafter(3.0, 3.0) != (3.0 as Float64) { io.println("next-eq"); return 40; }
  if !(math.decompose.nexttoward(1.0, 2.0) > 1.0) { io.println("nexttoward"); return 41; }

  io.println("smoke_math_decompose: OK");
  return 0;
}

// Smoke: xiom.math.arithmetic (integer number-theoretic helpers).
// Returns 0 on success.
use xiom.math;
use xiom.io;

// NOTE: cross-module access to a 3-tuple's .1/.2 fields in ARITHMETIC is a
// compiler bug (type resolves to <error>); comparison and return contexts
// work. Known answers are therefore checked via equality on the fields.
fn egcd_eq(t: (Int, Int, Int), g: Int, x: Int, y: Int) -> Bool {
  return t.0 == g && t.1 == x && t.2 == y;
}

fn main() -> Int {
  // gcd
  if math.arithmetic.gcd(12, 18) != 6 { io.println("gcd-1"); return 1; }
  if math.arithmetic.gcd(-12, 18) != 6 { io.println("gcd-neg"); return 2; }
  if math.arithmetic.gcd(7, 0) != 7 { io.println("gcd-zero"); return 3; }
  if math.arithmetic.gcd(0, 0) != 0 { io.println("gcd-00"); return 4; }

  // lcm
  if math.arithmetic.lcm(4, 6) != 12 { io.println("lcm-1"); return 5; }
  if math.arithmetic.lcm(-4, 6) != 12 { io.println("lcm-neg"); return 6; }
  if math.arithmetic.lcm(0, 5) != 0 { io.println("lcm-zero"); return 7; }
  if math.arithmetic.lcm(21, 6) != 42 { io.println("lcm-2"); return 8; }

  // is_power_of_two
  if !math.arithmetic.is_power_of_two(1) { io.println("pot-1"); return 9; }
  if !math.arithmetic.is_power_of_two(1024) { io.println("pot-1024"); return 10; }
  if math.arithmetic.is_power_of_two(0) { io.println("pot-0"); return 11; }
  if math.arithmetic.is_power_of_two(100) { io.println("pot-100"); return 12; }
  if math.arithmetic.is_power_of_two(-8) { io.println("pot-neg"); return 13; }

  // next/prev power of two
  if math.arithmetic.next_power_of_two(5) != 8 { io.println("npot-5"); return 14; }
  if math.arithmetic.next_power_of_two(8) != 8 { io.println("npot-8"); return 15; }
  if math.arithmetic.next_power_of_two(0) != 1 { io.println("npot-0"); return 16; }
  if math.arithmetic.next_power_of_two(-3) != 1 { io.println("npot-neg"); return 17; }
  if math.arithmetic.prev_power_of_two(9) != 8 { io.println("ppot-9"); return 18; }
  if math.arithmetic.prev_power_of_two(8) != 8 { io.println("ppot-8"); return 19; }
  if math.arithmetic.prev_power_of_two(0) != 0 { io.println("ppot-0"); return 20; }
  if math.arithmetic.prev_power_of_two(1) != 1 { io.println("ppot-1"); return 21; }

  // gcd_extended: known answers (g, x, y) with a*x + b*y == g.
  var eg = math.arithmetic.gcd_extended(240, 46);
  if !egcd_eq(eg, 2, -9, 47) { io.println("egcd-240"); return 22; }
  var eg2 = math.arithmetic.gcd_extended(18, 84);
  if !egcd_eq(eg2, 6, 5, -1) { io.println("egcd-18"); return 23; }

  // mod_inverse. NOTE: `match` on a cross-module Option[Int] binds the
  // payload to a wrong value (compiler bug); is_some()/unwrap() is exact.
  var inv1 = math.arithmetic.mod_inverse(3, 7);
  if !inv1.is_some() { io.println("modinv-none1"); return 24; }
  if inv1.unwrap() != 5 { io.println("modinv-1"); return 25; }
  if (3 * inv1.unwrap()) % 7 != 1 { io.println("modinv-check"); return 26; }
  if math.arithmetic.mod_inverse(2, 4).is_some() { io.println("modinv-bad"); return 27; }
  if math.arithmetic.mod_inverse(0, 5).is_some() { io.println("modinv-zero"); return 28; }

  // pow_mod
  if math.arithmetic.pow_mod(2, 10, 1000) != 24 { io.println("powmod-1"); return 29; }
  if math.arithmetic.pow_mod(3, 4, 100) != 81 { io.println("powmod-2"); return 30; }
  if math.arithmetic.pow_mod(2, 0, 7) != 1 { io.println("powmod-exp0"); return 31; }
  if math.arithmetic.pow_mod(5, 3, 1) != 0 { io.println("powmod-m1"); return 32; }
  if math.arithmetic.pow_mod(-3, 3, 100) != 73 { io.println("powmod-neg"); return 33; }

  // is_odd / is_even
  if !math.arithmetic.is_odd(3) { io.println("odd-3"); return 34; }
  if !math.arithmetic.is_odd(-3) { io.println("odd-neg"); return 35; }
  if math.arithmetic.is_odd(0) { io.println("odd-0"); return 36; }
  if !math.arithmetic.is_even(4) { io.println("even-4"); return 37; }
  if !math.arithmetic.is_even(-4) { io.println("even-neg"); return 38; }
  if math.arithmetic.is_even(3) { io.println("even-3"); return 39; }

  // div_ceil / div_floor / div_trunc
  if math.arithmetic.div_ceil(7, 2) != 4 { io.println("ceil-1"); return 40; }
  if math.arithmetic.div_ceil(-7, 2) != -3 { io.println("ceil-neg"); return 41; }
  if math.arithmetic.div_floor(7, 2) != 3 { io.println("floor-1"); return 42; }
  if math.arithmetic.div_floor(-7, 2) != -4 { io.println("floor-neg"); return 43; }
  if math.arithmetic.div_trunc(7, 2) != 3 { io.println("trunc-1"); return 44; }
  if math.arithmetic.div_trunc(-7, 2) != -3 { io.println("trunc-neg"); return 45; }
  if math.arithmetic.div_ceil(8, 4) != 2 { io.println("ceil-exact"); return 46; }
  if math.arithmetic.div_floor(8, 4) != 2 { io.println("floor-exact"); return 47; }

  // mod_floor / mod_trunc
  if math.arithmetic.mod_floor(-7, 2) != 1 { io.println("mfloor-1"); return 48; }
  if math.arithmetic.mod_floor(7, -2) != -1 { io.println("mfloor-2"); return 49; }
  if math.arithmetic.mod_floor(7, 2) != 1 { io.println("mfloor-3"); return 50; }
  if math.arithmetic.mod_trunc(-7, 2) != -1 { io.println("mtrunc-1"); return 51; }
  if math.arithmetic.mod_trunc(7, -2) != 1 { io.println("mtrunc-2"); return 52; }
  if math.arithmetic.mod_trunc(7, 2) != 1 { io.println("mtrunc-3"); return 53; }

  io.println("smoke_math_arithmetic: OK");
  return 0;
}

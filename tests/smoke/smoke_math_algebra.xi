// Smoke: xiom.math.algebra (number-theoretic and combinatorial integer algebra).
// Returns 0 on success.
use xiom.math;
use xiom.io;

// NOTE: cross-module 3-tuple .1/.2 field access is unreliable (BUG 22 #3);
// validate through a local parameter function instead.
fn egcd_eq(t: (Int, Int, Int), g: Int, x: Int, y: Int) -> Bool {
  return t.0 == g && t.1 == x && t.2 == y;
}

fn main() -> Int {
  // gcd
  if math.algebra.gcd(12, 18) != 6 { io.println("gcd-1"); return 1; }
  if math.algebra.gcd(-12, 18) != 6 { io.println("gcd-neg"); return 2; }
  if math.algebra.gcd(7, 0) != 7 { io.println("gcd-zero"); return 3; }
  if math.algebra.gcd(0, 0) != 0 { io.println("gcd-00"); return 4; }

  // lcm
  if math.algebra.lcm(4, 6) != 12 { io.println("lcm-1"); return 5; }
  if math.algebra.lcm(-4, 6) != 12 { io.println("lcm-neg"); return 6; }
  if math.algebra.lcm(0, 5) != 0 { io.println("lcm-zero"); return 7; }
  if math.algebra.lcm(21, 6) != 42 { io.println("lcm-2"); return 8; }

  // egcd: known answers (g, x, y) with a*x + b*y == g, compared through a
  // local fn (tuple field arithmetic is unreliable across modules).
  var eg = math.algebra.egcd(240, 46);
  if !egcd_eq(eg, 2, -9, 47) { io.println("egcd-240"); return 9; }
  var eg2 = math.algebra.egcd(18, 84);
  if !egcd_eq(eg2, 6, 5, -1) { io.println("egcd-18"); return 10; }

  // mod_inverse (is_some()/unwrap() -- BUG 22 #4 safe path)
  var inv1 = math.algebra.mod_inverse(3, 7);
  if !inv1.is_some() { io.println("modinv-none1"); return 12; }
  if inv1.unwrap() != 5 { io.println("modinv-1"); return 13; }
  if (3 * inv1.unwrap()) % 7 != 1 { io.println("modinv-check"); return 14; }
  if math.algebra.mod_inverse(2, 4).is_some() { io.println("modinv-bad"); return 15; }
  if math.algebra.mod_inverse(0, 5).is_some() { io.println("modinv-zero"); return 16; }

  // crt: x = 11 satisfies 11 % 3 == 2, 11 % 4 == 3, 11 % 5 == 1.
  var rems = Vec[Int].new();
  rems.push(2);
  rems.push(3);
  rems.push(1);
  var mods = Vec[Int].new();
  mods.push(3);
  mods.push(4);
  mods.push(5);
  var cr = math.algebra.crt(&rems, &mods);
  if !cr.is_some() { io.println("crt-none"); return 17; }
  if cr.unwrap() != 11 { io.println("crt-val"); return 18; }
  var mods_bad = Vec[Int].new();
  mods_bad.push(2);
  mods_bad.push(4);
  if math.algebra.crt(&rems, &mods_bad).is_some() { io.println("crt-bad"); return 19; }
  var rems_short = Vec[Int].new();
  rems_short.push(1);
  if math.algebra.crt(&rems_short, &mods).is_some() { io.println("crt-len"); return 20; }

  // legendre_symbol
  if math.algebra.legendre_symbol(1, 3) != 1 { io.println("leg-1"); return 21; }
  if math.algebra.legendre_symbol(2, 3) != -1 { io.println("leg-2"); return 22; }
  if math.algebra.legendre_symbol(0, 5) != 0 { io.println("leg-0"); return 23; }
  if math.algebra.legendre_symbol(4, 5) != 1 { io.println("leg-4"); return 24; }
  if math.algebra.legendre_symbol(2, 5) != -1 { io.println("leg-2-5"); return 25; }

  // jacobi_symbol
  if math.algebra.jacobi_symbol(1, 5) != 1 { io.println("jac-1"); return 26; }
  if math.algebra.jacobi_symbol(2, 5) != -1 { io.println("jac-2-5"); return 27; }
  if math.algebra.jacobi_symbol(0, 5) != 0 { io.println("jac-0"); return 28; }
  if math.algebra.jacobi_symbol(2, 9) != 1 { io.println("jac-2-9"); return 29; }
  if math.algebra.jacobi_symbol(7, 8) != 0 { io.println("jac-even"); return 30; }

  // binomial
  if math.algebra.binomial(5, 2) != 10 { io.println("bin-5-2"); return 31; }
  if math.algebra.binomial(10, 3) != 120 { io.println("bin-10-3"); return 32; }
  if math.algebra.binomial(20, 10) != 184756 { io.println("bin-20-10"); return 33; }
  if math.algebra.binomial(0, 0) != 1 { io.println("bin-00"); return 34; }
  if math.algebra.binomial(2, 5) != 0 { io.println("bin-invalid"); return 35; }
  if math.algebra.binomial(100, 50) != 0 { io.println("bin-overflow"); return 36; }

  // factorial
  if math.algebra.factorial(5) != 120 { io.println("fact-5"); return 37; }
  if math.algebra.factorial(0) != 1 { io.println("fact-0"); return 38; }
  if math.algebra.factorial(20) != 2432902008176640000 { io.println("fact-20"); return 39; }
  if math.algebra.factorial(21) != 0 { io.println("fact-overflow"); return 40; }
  if math.algebra.factorial(-3) != 0 { io.println("fact-neg"); return 41; }

  // primorial
  if math.algebra.primorial(1) != 2 { io.println("prim-1"); return 42; }
  if math.algebra.primorial(3) != 30 { io.println("prim-3"); return 43; }
  if math.algebra.primorial(5) != 2310 { io.println("prim-5"); return 44; }
  if math.algebra.primorial(0) != 0 { io.println("prim-0"); return 45; }
  if math.algebra.primorial(100) != 0 { io.println("prim-overflow"); return 46; }

  // nth_prime
  if math.algebra.nth_prime(1) != 2 { io.println("np-1"); return 47; }
  if math.algebra.nth_prime(2) != 3 { io.println("np-2"); return 48; }
  if math.algebra.nth_prime(5) != 11 { io.println("np-5"); return 49; }
  if math.algebra.nth_prime(10) != 29 { io.println("np-10"); return 50; }
  if math.algebra.nth_prime(0) != 0 { io.println("np-0"); return 51; }

  // integer_sqrt
  if math.algebra.integer_sqrt(16) != 4 { io.println("isqrt-16"); return 52; }
  if math.algebra.integer_sqrt(17) != 4 { io.println("isqrt-17"); return 53; }
  if math.algebra.integer_sqrt(0) != 0 { io.println("isqrt-0"); return 54; }
  if math.algebra.integer_sqrt(9223372036854775807) != 3037000499 { io.println("isqrt-max"); return 55; }
  if math.algebra.integer_sqrt(-5) != -1 { io.println("isqrt-neg"); return 56; }

  // next_power_of_two / is_power_of_two
  if math.algebra.next_power_of_two(5) != 8 { io.println("npot-5"); return 57; }
  if math.algebra.next_power_of_two(8) != 8 { io.println("npot-8"); return 58; }
  if math.algebra.next_power_of_two(0) != 1 { io.println("npot-0"); return 59; }
  if !math.algebra.is_power_of_two(1) { io.println("pot-1"); return 60; }
  if !math.algebra.is_power_of_two(1024) { io.println("pot-1024"); return 61; }
  if math.algebra.is_power_of_two(0) { io.println("pot-0"); return 62; }
  if math.algebra.is_power_of_two(100) { io.println("pot-100"); return 63; }

  // is_perfect_square
  if !math.algebra.is_perfect_square(0) { io.println("psq-0"); return 64; }
  if !math.algebra.is_perfect_square(16) { io.println("psq-16"); return 65; }
  if math.algebra.is_perfect_square(17) { io.println("psq-17"); return 66; }
  if math.algebra.is_perfect_square(-4) { io.println("psq-neg"); return 67; }

  io.println("smoke_math_algebra: OK");
  return 0;
}

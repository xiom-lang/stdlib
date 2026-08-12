// Smoke: xiom.math.number_theory (primality, factorization, symbols, divisors).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // primality
  if !math.number_theory.is_prime(17) { io.println("isprime-17"); return 1; }
  if math.number_theory.is_prime(15) { io.println("isprime-15"); return 2; }
  if !math.number_theory.is_prime(2) { io.println("isprime-2"); return 3; }
  if math.number_theory.is_prime(1) { io.println("isprime-1"); return 4; }
  if !math.number_theory.is_prime_deterministic(97) { io.println("isprimed-97"); return 5; }
  if math.number_theory.is_prime_deterministic(91) { io.println("isprimed-91"); return 6; }

  // next / prev prime
  if math.number_theory.next_prime(17) != 19 { io.println("nextp-17"); return 7; }
  if math.number_theory.next_prime(1) != 2 { io.println("nextp-1"); return 8; }
  if math.number_theory.prev_prime(17) != 13 { io.println("prevp-17"); return 9; }
  if math.number_theory.prev_prime(2) != 0 { io.println("prevp-2"); return 10; }

  // factorization
  var f12 = math.number_theory.factor(12);
  if f12.len() != 3 { io.println("factor-12-len"); return 11; }
  if math.number_theory.factor(1).len() != 0 { io.println("factor-1"); return 12; }

  // pseudoprime / fermat / miller-rabin
  if !math.number_theory.is_pseudoprime(341, 2) { io.println("pseudo-341"); return 13; }
  if math.number_theory.is_pseudoprime(15, 2) { io.println("pseudo-15"); return 14; }
  if !math.number_theory.fermat_test(561, 2) { io.println("fermat-561"); return 15; }
  var bases = Vec[Int].new();
  bases.push(2);
  bases.push(3);
  if !math.number_theory.miller_rabin(101, &bases) { io.println("mr-101"); return 16; }
  if math.number_theory.miller_rabin(341, &bases) { io.println("mr-341"); return 17; }

  // mersenne / lucas-lehmer
  if !math.number_theory.lucas_lehmer(5) { io.println("ll-5"); return 18; }
  if math.number_theory.lucas_lehmer(11) { io.println("ll-11"); return 19; }
  if !math.number_theory.mersenne_prime_p(5) { io.println("mersenne-5"); return 20; }

  // pollard rho / p-1
  var r = math.number_theory.pollard_rho(91);
  if r <= 1 || r >= 91 { io.println("rho-91"); return 21; }
  var r2 = math.number_theory.p_1_factor(91);
  if r2 <= 1 || r2 >= 91 { io.println("p1-91"); return 22; }

  // totient / mobius / jordan / carmichael
  if math.number_theory.euler_phi(10) != 4 { io.println("phi-10"); return 23; }
  if math.number_theory.euler_phi(1) != 1 { io.println("phi-1"); return 24; }
  if math.number_theory.euler_phi(7) != 6 { io.println("phi-7"); return 25; }
  if math.number_theory.mobius(30) != -1 { io.println("mobius-30"); return 26; }
  if math.number_theory.mobius(4) != 0 { io.println("mobius-4"); return 27; }
  if math.number_theory.mobius(1) != 1 { io.println("mobius-1"); return 28; }
  if math.number_theory.jordan_totient(10, 2) != 72 { io.println("jordan-10-2"); return 29; }
  if math.number_theory.carmichael(15) != 4 { io.println("carmichael-15"); return 30; }
  if math.number_theory.carmichael(1) != 1 { io.println("carmichael-1"); return 31; }

  // prime counting
  if math.number_theory.prime_pi(10) != 4 { io.println("pi-10"); return 32; }
  if math.number_theory.prime_pi(100) != 25 { io.println("pi-100"); return 33; }
  if math.number_theory.nth_prime(5) != 11 { io.println("nthp-5"); return 34; }
  if math.number_theory.nth_prime(1) != 2 { io.println("nthp-1"); return 35; }
  if math.number_theory.primorial(4) != 210 { io.println("primorial-4"); return 36; }

  // integer properties
  if !math.number_theory.is_composite(4) { io.println("iscomp-4"); return 37; }
  if math.number_theory.is_composite(7) { io.println("iscomp-7"); return 38; }
  if !math.number_theory.is_semiprime(6) { io.println("semiprime-6"); return 39; }
  if math.number_theory.is_semiprime(8) { io.println("semiprime-8"); return 40; }
  if !math.number_theory.is_power(64) { io.println("ispower-64"); return 41; }
  if math.number_theory.is_power(12) { io.println("ispower-12"); return 42; }
  if !math.number_theory.is_power_of(8, 2) { io.println("ispowof-8-2"); return 43; }
  if !math.number_theory.is_power_of(9, 3) { io.println("ispowof-9-3"); return 44; }
  if math.number_theory.is_power_of(10, 2) { io.println("ispowof-10-2"); return 45; }

  // radicals and smoothness
  if math.number_theory.radical(12) != 6 { io.println("radical-12"); return 46; }
  if math.number_theory.radical(18) != 6 { io.println("radical-18"); return 47; }
  if !math.number_theory.smooth(24, 3) { io.println("smooth-24-3"); return 48; }
  if math.number_theory.smooth(25, 3) { io.println("smooth-25-3"); return 49; }
  if !math.number_theory.rough(25, 3) { io.println("rough-25-3"); return 50; }
  if math.number_theory.rough(24, 3) { io.println("rough-24-3"); return 51; }

  // symbols
  if math.number_theory.legendre_symbol(2, 7) != 1 { io.println("legendre-2-7"); return 52; }
  if math.number_theory.legendre_symbol(3, 7) != -1 { io.println("legendre-3-7"); return 53; }
  if math.number_theory.legendre_symbol(7, 7) != 0 { io.println("legendre-7-7"); return 54; }
  if math.number_theory.jacobi_symbol(2, 15) != 1 { io.println("jacobi-2-15"); return 55; }
  if math.number_theory.jacobi_symbol(4, 9) != 1 { io.println("jacobi-4-9"); return 56; }
  if math.number_theory.kronecker_symbol(2, 8) != 0 { io.println("kronecker-2-8"); return 57; }
  if math.number_theory.kronecker_symbol(3, 8) != -1 { io.println("kronecker-3-8"); return 58; }
  if math.number_theory.kronecker_symbol(1, 1) != 1 { io.println("kronecker-1-1"); return 59; }

  // divisors
  if math.number_theory.divisor_sum(6, 1) != 12 { io.println("ds-6-1"); return 60; }
  if math.number_theory.divisor_sum(6, 0) != 4 { io.println("ds-6-0"); return 61; }
  if math.number_theory.divisor_sum(10, 2) != 130 { io.println("ds-10-2"); return 62; }
  if math.number_theory.divisor_count(12) != 6 { io.println("dc-12"); return 63; }
  var pd = math.number_theory.proper_divisors(12);
  if pd.len() != 5 { io.println("pd-12"); return 64; }

  io.println("smoke_math_number_theory: OK");
  return 0;
}

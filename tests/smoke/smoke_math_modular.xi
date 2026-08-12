// Smoke: xiom.math.modular (modular arithmetic, CRT, roots, symbols).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // basic modular arithmetic
  if math.modular.mod_add(7, 5, 11) != 1 { io.println("modadd"); return 1; }
  if math.modular.mod_add(5, 5, 11) != 10 { io.println("modadd2"); return 2; }
  if math.modular.mod_sub(7, 9, 11) != 9 { io.println("modsub"); return 3; }
  if math.modular.mod_mul(3, 5, 11) != 4 { io.println("modmul"); return 4; }
  if math.modular.mod_pow(2, 10, 11) != 1 { io.println("modpow-2-10"); return 5; }
  if math.modular.mod_pow(3, 5, 13) != 9 { io.println("modpow-3-5"); return 6; }
  if math.modular.pow_mod_fast(3, 5, 13) != 9 { io.println("modpowfast"); return 7; }

  // modular inverse
  if math.modular.mod_inverse(3, 11) != 4 { io.println("inv-3-11"); return 8; }
  if math.modular.mod_inverse(6, 10) != 0 { io.println("inv-noncoprime"); return 9; }
  var invopt = math.arithmetic.mod_inverse(3, 11);
  if !invopt.is_some() { io.println("invopt-none"); return 10; }
  if invopt.unwrap() != 4 { io.println("invopt-val"); return 11; }
  var invnone = math.arithmetic.mod_inverse(6, 10);
  if invnone.is_some() { io.println("invopt-expected-none"); return 12; }

  // division / lcm
  if math.modular.mod_div(4, 3, 11) != 5 { io.println("moddiv"); return 13; }
  if math.modular.mod_div(1, 2, 10) != 0 { io.println("moddiv-none"); return 14; }
  if math.modular.mod_lcm(4, 6, 100) != 12 { io.println("modlcm"); return 15; }
  if math.modular.mod_lcm(3, 7, 100) != 21 { io.println("modlcm2"); return 16; }

  // CRT
  var rems = Vec[Int].new();
  rems.push(2);
  rems.push(3);
  var mods = Vec[Int].new();
  mods.push(3);
  mods.push(5);
  if math.modular.crt(&rems, &mods) != 8 { io.println("crt"); return 17; }
  var cons = Vec[(Int, Int)].new();
  cons.push((2, 3));
  cons.push((3, 5));
  if math.modular.crt_solve(&cons) != 8 { io.println("crtsolve"); return 18; }
  var badmods = Vec[Int].new();
  badmods.push(2);
  badmods.push(4);
  if math.modular.crt(&rems, &badmods) != 0 { io.println("crt-bad"); return 19; }

  // linear congruence
  if math.modular.linear_congruence(3, 4, 7) != 6 { io.println("lc-3-4-7"); return 20; }
  if math.modular.linear_congruence(2, 3, 6) != 0 { io.println("lc-none"); return 21; }

  // quadratic residuosity and roots
  if !math.modular.quadratic_residue(4, 7) { io.println("qr-4-7"); return 22; }
  if math.modular.quadratic_residue(3, 7) { io.println("qr-3-7"); return 23; }
  if math.modular.mod_sqrt(4, 7) != 2 { io.println("modsqrt-4-7"); return 24; }
  if math.modular.mod_sqrt(2, 7) != 3 { io.println("modsqrt-2-7"); return 25; }
  if math.modular.mod_sqrt(5, 7) != 0 { io.println("modsqrt-5-7"); return 26; }
  if math.modular.tonelli_shanks(2, 7) != 3 { io.println("tonelli-2-7"); return 27; }
  if math.modular.tonelli_shanks(5, 7) != 0 { io.println("tonelli-5-7"); return 28; }
  if math.modular.cipolla(2, 7) != 3 { io.println("cipolla-2-7"); return 29; }
  if math.modular.cipolla(5, 7) != 0 { io.println("cipolla-5-7"); return 30; }

  // cube root
  if math.modular.mod_cbrt(1, 11) != 1 { io.println("cbrt-1-11"); return 31; }
  if math.modular.mod_cbrt(3, 11) != 9 { io.println("cbrt-3-11"); return 32; }

  // cornacchia: x^2 + y^2 = 13 with sqrt(-1) mod 13 = 5 -> (3, 2)
  var cc = math.modular.cornacchia(1, 5, 13);
  if cc != (3, 2) { io.println("cornacchia-13"); return 33; }
  // x^2 + y^2 = 5 with sqrt(-1) mod 5 = 2 -> (2, 1)
  var cc2 = math.modular.cornacchia(1, 2, 5);
  if cc2 != (2, 1) { io.println("cornacchia-5"); return 34; }

  // hilbert symbol
  if math.modular.hilbert_symbol(2, 2, 2) != 1 { io.println("hilbert-2-2"); return 35; }
  if math.modular.hilbert_symbol(3, 3, 2) != -1 { io.println("hilbert-3-3"); return 36; }
  if math.modular.hilbert_symbol(1, 2, 5) != 1 { io.println("hilbert-1-2-5"); return 37; }
  if math.modular.hilbert_symbol(0, 3, 5) != 0 { io.println("hilbert-zero"); return 38; }

  io.println("smoke_math_modular: OK");
  return 0;
}

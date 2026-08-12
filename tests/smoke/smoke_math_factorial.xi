// Smoke: xiom.math.factorial (factorial variants + counting-number families).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // factorial
  if math.factorial.factorial(5) != 120 { io.println("fact-5"); return 1; }
  if math.factorial.factorial(0) != 1 { io.println("fact-0"); return 2; }
  if math.factorial.factorial(1) != 1 { io.println("fact-1"); return 3; }
  if math.factorial.factorial(-3) != 0 { io.println("fact-neg"); return 4; }
  if math.factorial.factorial(21) != 0 { io.println("fact-ovf"); return 5; }

  // double factorial
  if math.factorial.double_factorial(5) != 15 { io.println("dblfact-5"); return 6; }
  if math.factorial.double_factorial(6) != 48 { io.println("dblfact-6"); return 7; }
  if math.factorial.double_factorial(0) != 1 { io.println("dblfact-0"); return 8; }

  // subfactorial / derangements
  if math.factorial.subfactorial(4) != 9 { io.println("subfact-4"); return 9; }
  if math.factorial.subfactorial(0) != 1 { io.println("subfact-0"); return 10; }
  if math.factorial.subfactorial(5) != 44 { io.println("subfact-5"); return 11; }
  if math.factorial.derangements(4) != 9 { io.println("derang-4"); return 12; }

  // multifactorial
  if math.factorial.multifactorial(5, 2) != 15 { io.println("mfact-52"); return 13; }
  if math.factorial.multifactorial(6, 3) != 18 { io.println("mfact-63"); return 14; }

  // binomial
  if math.factorial.binomial(5, 2) != 10 { io.println("binom-52"); return 15; }
  if math.factorial.binomial(0, 0) != 1 { io.println("binom-00"); return 16; }
  if math.factorial.binomial(10, 3) != 120 { io.println("binom-103"); return 17; }
  if math.factorial.binomial(5, 6) != 0 { io.println("binom-invalid"); return 18; }
  if math.factorial.binomial_coeff(5, 2) != 10 { io.println("binomc-52"); return 19; }

  // multinomial
  var ks = Vec[Int].new();
  ks.push(2);
  ks.push(2);
  ks.push(2);
  if math.factorial.multinomial(6, &ks) != 90 { io.println("multi-222"); return 20; }

  // falling / rising factorial
  if math.factorial.falling_factorial(5, 3) != 60 { io.println("falling-53"); return 21; }
  if math.factorial.falling_factorial(5, 0) != 1 { io.println("falling-0"); return 22; }
  if math.factorial.rising_factorial(2, 3) != 24 { io.println("rising-23"); return 23; }
  if math.factorial.rising_factorial(5, 1) != 5 { io.println("rising-1"); return 24; }

  // Stirling, Bell, Catalan, Eulerian
  if math.factorial.stirling_first(4, 2) != 11 { io.println("stir1-42"); return 25; }
  if math.factorial.stirling_first(0, 0) != 1 { io.println("stir1-00"); return 26; }
  if math.factorial.stirling_second(5, 2) != 15 { io.println("stir2-52"); return 27; }
  if math.factorial.stirling_second(3, 1) != 1 { io.println("stir2-31"); return 28; }
  if math.factorial.bell(5) != 52 { io.println("bell-5"); return 29; }
  if math.factorial.bell(0) != 1 { io.println("bell-0"); return 30; }
  if math.factorial.catalan(5) != 42 { io.println("catalan-5"); return 31; }
  if math.factorial.catalan(0) != 1 { io.println("catalan-0"); return 32; }
  if math.factorial.eulerian(4, 1) != 11 { io.println("eulerian-41"); return 33; }
  if math.factorial.eulerian(3, 1) != 4 { io.println("eulerian-31"); return 34; }

  // Narayana, Lah, Motzkin, Schroder
  if math.factorial.narayana(4, 2) != 6 { io.println("narayana-42"); return 35; }
  if math.factorial.narayana(4, 1) != 1 { io.println("narayana-41"); return 36; }
  if math.factorial.lah(4, 2) != 36 { io.println("lah-42"); return 37; }
  if math.factorial.lah(4, 1) != 24 { io.println("lah-41"); return 38; }
  if math.factorial.motzkin(4) != 9 { io.println("motzkin-4"); return 39; }
  if math.factorial.motzkin(0) != 1 { io.println("motzkin-0"); return 40; }
  if math.factorial.schroeder(3) != 22 { io.println("schroeder-3"); return 41; }
  if math.factorial.schroeder(0) != 1 { io.println("schroeder-0"); return 42; }

  // partitions
  if math.factorial.partition_count(5) != 7 { io.println("pcount-5"); return 43; }
  if math.factorial.partition_count(4) != 5 { io.println("pcount-4"); return 44; }
  if math.factorial.partition_count(0) != 1 { io.println("pcount-0"); return 45; }

  // integer partitions enumeration: p(4) = 5 lists
  var parts = math.factorial.integer_partitions(4);
  if parts.len() != 5 { io.println("iparts-4"); return 46; }

  // bell triangle: 5 rows for n = 0..4
  var bt = math.factorial.bell_triangle(4);
  if bt.len() != 5 { io.println("bt-rows"); return 47; }

  io.println("smoke_math_factorial: OK");
  return 0;
}

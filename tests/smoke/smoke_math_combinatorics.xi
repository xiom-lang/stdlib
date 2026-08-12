// Smoke: xiom.math.combinatorics (counting + enumeration).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // counting
  if math.combinatorics.permutations(5, 2) != 20 { io.println("perm-52"); return 1; }
  if math.combinatorics.combinations(5, 2) != 10 { io.println("comb-52"); return 2; }
  if math.combinatorics.permutations_with_repetition(3, 2) != 9 { io.println("pwr-32"); return 3; }
  if math.combinatorics.combinations_with_repetition(5, 2) != 15 { io.println("cwr-52"); return 4; }
  if math.combinatorics.derangements(4) != 9 { io.println("derang-4"); return 5; }
  if math.combinatorics.bell_numbers(4) != 15 { io.println("bell-4"); return 6; }
  if math.combinatorics.catalan_numbers(4) != 14 { io.println("catalan-4"); return 7; }
  if math.combinatorics.eulerian_numbers(4, 1) != 11 { io.println("euler-41"); return 8; }
  if math.combinatorics.stirling_numbers_1(4, 2) != 11 { io.println("stir1-42"); return 9; }
  if math.combinatorics.stirling_numbers_2(5, 2) != 15 { io.println("stir2-52"); return 10; }
  if math.combinatorics.lah_numbers(4, 2) != 36 { io.println("lah-42"); return 11; }
  if math.combinatorics.narayana_numbers(4, 2) != 6 { io.println("nara-42"); return 12; }

  // sequences
  if math.combinatorics.fibonacci(10) != 55 { io.println("fib-10"); return 13; }
  if math.combinatorics.fibonacci(0) != 0 { io.println("fib-0"); return 14; }
  if math.combinatorics.fibonacci_start(2, 3, 4) != 13 { io.println("fibstart"); return 15; }
  if math.combinatorics.lucas(5) != 11 { io.println("lucas-5"); return 16; }
  if math.combinatorics.tribonacci(7) != 13 { io.println("trib-7"); return 17; }
  if math.combinatorics.tetranacci(7) != 8 { io.println("tetra-7"); return 18; }
  if math.combinatorics.partitions(5) != 7 { io.println("part-5"); return 19; }
  if math.combinatorics.compositions(5, 2) != 4 { io.println("comp-52"); return 20; }
  if math.combinatorics.compositions_all(4) != 8 { io.println("compall-4"); return 21; }
  if math.combinatorics.surjections(5, 2) != 30 { io.println("surj-52"); return 22; }
  if math.combinatorics.involutions(4) != 10 { io.println("invol-4"); return 23; }

  // enumeration
  var iparts = math.combinatorics.integer_partitions(4);
  if iparts.len() != 5 { io.println("iparts-4"); return 24; }
  var dnum = math.combinatorics.derangements_enum(4);
  if dnum.len() != 9 { io.println("denum-4"); return 25; }
  var elems = Vec[Int].new();
  elems.push(1);
  elems.push(2);
  elems.push(3);
  var perms = math.combinatorics.permutations_enum(&elems);
  if perms.len() != 6 { io.println("penum-3"); return 26; }
  var elems4 = Vec[Int].new();
  elems4.push(1);
  elems4.push(2);
  elems4.push(3);
  elems4.push(4);
  var combs = math.combinatorics.combinations_enum(&elems4, 2);
  if combs.len() != 6 { io.println("cenum-42"); return 27; }
  var subs = math.combinatorics.subsets_enum(&elems, 2);
  if subs.len() != 3 { io.println("senum-32"); return 28; }
  var powers = math.combinatorics.powerset_enum(&elems);
  if powers.len() != 8 { io.println("pset-3"); return 29; }

  io.println("smoke_math_combinatorics: OK");
  return 0;
}

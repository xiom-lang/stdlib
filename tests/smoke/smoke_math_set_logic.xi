// Smoke: xiom.math.set_theory + xiom.math.logic.
// Returns 0 on success.
use xiom.math;
use xiom.io;

// Predicate: even integers (for set comprehension).
fn is_even(n: Int) -> Bool {
  return n % 2 == 0;
}

fn main() -> Int {
  // set ops on Vec[Int]
  var a = Vec[Int].new();
  a.push(1);
  a.push(2);
  a.push(3);
  var b = Vec[Int].new();
  b.push(2);
  b.push(3);
  b.push(4);

  var un = math.set_theory.set_union(&a, &b);
  if un.len() != 4 { io.println("union-len"); return 1; }
  var inter = math.set_theory.set_intersection(&a, &b);
  if inter.len() != 2 { io.println("inter-len"); return 2; }
  var diff = math.set_theory.set_difference(&a, &b);
  if diff.len() != 1 { io.println("diff-len"); return 3; }
  var sdiff = math.set_theory.set_symmetric_difference(&a, &b);
  if sdiff.len() != 2 { io.println("sdiff-len"); return 4; }
  if !math.set_theory.set_subset(&a, &a) { io.println("subset-self"); return 5; }
  if math.set_theory.set_subset(&b, &a) { io.println("subset-b-a"); return 6; }
  if !math.set_theory.set_superset(&a, &a) { io.println("superset-self"); return 7; }
  if math.set_theory.set_proper_subset(&a, &a) { io.println("propsubset-self"); return 8; }
  var sub1 = Vec[Int].new();
  sub1.push(1);
  sub1.push(2);
  if !math.set_theory.set_proper_subset(&sub1, &a) { io.println("propsubset"); return 9; }
  var c1 = Vec[Int].new();
  c1.push(1);
  c1.push(2);
  var d1 = Vec[Int].new();
  d1.push(3);
  d1.push(4);
  if !math.set_theory.set_disjoint(&c1, &d1) { io.println("disjoint"); return 10; }
  var e1 = Vec[Int].new();
  e1.push(1);
  e1.push(1);
  e1.push(2);
  e1.push(3);
  e1.push(3);
  if math.set_theory.set_cardinality(&e1) != 3 { io.println("cardinality"); return 11; }
  var univ = Vec[Int].new();
  univ.push(1);
  univ.push(2);
  univ.push(3);
  univ.push(4);
  var comp = math.set_theory.set_complement(&c1, &univ);
  if comp.len() != 2 { io.println("complement-len"); return 12; }
  var pset = math.set_theory.set_power_set(&c1);
  if pset.len() != 4 { io.println("powerset-len"); return 13; }
  var cart = math.set_theory.set_cartesian_product(&c1, &c1);
  if cart.len() != 4 { io.println("cart-len"); return 14; }
  var filtered = math.set_theory.set_comprehension(is_even, &univ);
  if filtered.len() != 2 { io.println("comprehension-len"); return 17; }

  // logic: boolean operators
  if math.logic.boolean_expression("and", true, false) { io.println("be-and"); return 19; }
  if !math.logic.boolean_expression("or", true, false) { io.println("be-or"); return 20; }
  if math.logic.boolean_expression("xor", true, true) { io.println("be-xor"); return 21; }
  if math.logic.boolean_expression("nand", true, true) { io.println("be-nand"); return 22; }
  if !math.logic.boolean_expression("nor", false, false) { io.println("be-nor"); return 23; }
  if math.logic.boolean_expression("implies", true, false) { io.println("be-implies"); return 24; }
  if !math.logic.boolean_expression("iff", true, true) { io.println("be-iff"); return 25; }

  // logic: connectives
  if !math.logic.iff(true, true) { io.println("iff"); return 26; }
  if math.logic.implies(true, false) { io.println("implies"); return 27; }
  if math.logic.xor(true, true) { io.println("xor"); return 28; }
  if math.logic.nand(true, true) { io.println("nand"); return 29; }
  if !math.logic.nor(false, false) { io.println("nor"); return 30; }

  io.println("smoke_math_set_logic: OK");
  return 0;
}

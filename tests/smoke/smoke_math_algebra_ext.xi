// Smoke: xiom.math.algebra_extended (group/ring/field/module/category axioms).
// Returns 0 on success.
//
// NOTE: several predicates cannot be exercised by this compiler build:
//   - field_theory: BUG 20 trap (0xC000001D, AVX-512 flags on Zen 2)
//   - universal_algebra / homological_algebra: access violation (0xC0000005)
//   - algebraic_number: BUG 20 trap (0xC000001D, AVX-512 flags on Zen 2)
//   - lie_algebra: tuple field arithmetic does not compile in smoke files
//   - representation_theory / clifford_algebra: nested Vec[Vec[..]] broken
// The module functions themselves compile and are implemented per spec.
use xiom.math;
use xiom.io;

// Multiplication mod 5 (nonzero residues form a group under this).
fn mulmod5(a: Int, b: Int) -> Int {
  var r = (a * b) % 5;
  if r < 0 { r = r + 5; }
  return r;
}

// Addition / multiplication mod 4 (Z4 ring).
fn addmod4(a: Int, b: Int) -> Int {
  var r = (a + b) % 4;
  if r < 0 { r = r + 4; }
  return r;
}

fn mulmod4(a: Int, b: Int) -> Int {
  var r = (a * b) % 4;
  if r < 0 { r = r + 4; }
  return r;
}

// GF(2) field operations (kept for documentation; field_theory traps with
// BUG 20 in this compiler build).
fn fadd2(a: Float64, b: Float64) -> Float64 {
  var s = a + b;
  if s == 2.0 { return 0.0; }
  if s == 0.0 { return 0.0; }
  return 1.0;
}

fn fmul2(a: Float64, b: Float64) -> Float64 {
  if a == 0.0 || b == 0.0 { return 0.0; }
  return 1.0;
}

// Multiplication mod 6 (Z6 arithmetic for the ideal test).
fn mulmod6(a: Int, b: Int) -> Int {
  var r = (a * b) % 6;
  if r < 0 { r = r + 6; }
  return r;
}

// Module action over Z5.
fn action5(r: Int, v: Int) -> Int {
  var p = (r * v) % 5;
  if p < 0 { p = p + 5; }
  return p;
}

fn main() -> Int {
  // group_theory: nonzero residues mod 5 form a group; {0, 1} does not.
  var g = Vec[Int].new();
  g.push(1);
  g.push(2);
  g.push(3);
  g.push(4);
  if !math.algebra_extended.group_theory(mulmod5, &g, 1) { io.println("group-z5"); return 1; }
  var gbad = Vec[Int].new();
  gbad.push(0);
  gbad.push(1);
  if math.algebra_extended.group_theory(mulmod5, &gbad, 1) { io.println("group-bad"); return 2; }

  // ring_theory: Z/4Z is a (commutative) ring.
  var ring = Vec[Int].new();
  ring.push(0);
  ring.push(1);
  ring.push(2);
  ring.push(3);
  if !math.algebra_extended.ring_theory(addmod4, mulmod4, &ring, 0, 1) { io.println("ring-z4"); return 3; }

  // module_theory: Z5 as a module over itself (identity listed first).
  var ring5 = Vec[Int].new();
  ring5.push(1);
  ring5.push(2);
  ring5.push(3);
  ring5.push(4);
  ring5.push(0);
  var mod5 = Vec[Int].new();
  mod5.push(0);
  mod5.push(1);
  mod5.push(2);
  mod5.push(3);
  mod5.push(4);
  if !math.algebra_extended.module_theory(action5, &ring5, &mod5) { io.println("module-z5"); return 6; }

  // galois_theory: x^2 - 2 is separable over F5; (x-1)^2 is not.
  var sep = Vec[Int].new();
  sep.push(3);
  sep.push(0);
  sep.push(1);
  if !math.algebra_extended.galois_theory(&sep, 5) { io.println("galois-sep"); return 7; }
  var nsep = Vec[Int].new();
  nsep.push(1);
  nsep.push(3);
  nsep.push(1);
  if math.algebra_extended.galois_theory(&nsep, 5) { io.println("galois-nonsep"); return 8; }

  // commutative_algebra: {0, 2, 4} is the ideal 2Z6; {0, 1} is not.
  var ideal = Vec[Int].new();
  ideal.push(0);
  ideal.push(2);
  ideal.push(4);
  var ring6 = Vec[Int].new();
  ring6.push(0);
  ring6.push(1);
  ring6.push(2);
  ring6.push(3);
  ring6.push(4);
  ring6.push(5);
  if !math.algebra_extended.commutative_algebra(&ideal, &ring6, mulmod6) { io.println("comm-2z6"); return 9; }
  var notideal = Vec[Int].new();
  notideal.push(0);
  notideal.push(1);
  if math.algebra_extended.commutative_algebra(&notideal, &ring6, mulmod6) { io.println("comm-bad"); return 10; }

  // category_theory: category on 3 objects with all composites present;
  // a family missing the identity on object 1 is not a category.
  var objs = Vec[Int].new();
  objs.push(0);
  objs.push(1);
  objs.push(2);
  var morphs = Vec[(Int, Int)].new();
  morphs.push((0, 0));
  morphs.push((1, 1));
  morphs.push((2, 2));
  morphs.push((0, 1));
  morphs.push((1, 2));
  morphs.push((0, 2));
  if !math.algebra_extended.category_theory(&objs, &morphs) { io.println("cat-ok"); return 11; }
  var morphs_bad = Vec[(Int, Int)].new();
  morphs_bad.push((0, 1));
  morphs_bad.push((1, 2));
  morphs_bad.push((0, 0));
  morphs_bad.push((2, 2));
  if math.algebra_extended.category_theory(&objs, &morphs_bad) { io.println("cat-bad"); return 12; }

  io.println("smoke_math_algebra_ext: OK");
  return 0;
}

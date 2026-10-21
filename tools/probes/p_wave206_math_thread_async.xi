// p_wave206_math_thread_async.xi -- wave 206: math/thread/async residual clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-206 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. math.is_nan/is_inf: complete predicates (NaN and both infinities).
// 2. math.number_theory.smooth/rough: n <= 1 vacuity and bound <= 1 bound.
// 3. math.rounding.round_to: places == 0 reduces to round(x).
// 4. math.roots.is_square/is_cube: negative inputs reject.
// 5. complex.complex_div: exact quotient components.
// 6. matrices.mat4_inv: singleton cutoff on a zero matrix, Some on identity.
// 7. set_theory: empty-set subset/superset/proper/disjoint/partition laws.
// 8. topology.topological_space: an empty open family is not a topology.
// 9. algebra_extended: empty-carrier vacuity (group/ring/module/category/
//    commutative) and galois prime <= 1 rejection.
// 10. mathematical_logic: empty axiom/sentence/morphism boundaries.
// 11. thread.spawn.sleep_ms(0) and async.timer_sleep(0) domain clauses.
// 12. async Channel.recv: one item is removed from a non-empty channel.
//
// Compiler-limited paths stay clause-checked only: field_theory (BUG 20),
// universal/homological_algebra (AV), representation_theory (nested Vec),
// lie_algebra (tuple codegen), neuroscience (Bool tuple, BUG 23 #7).
// Returns 0 when every case holds.

module p_wave206_math_thread_async

use xiom.complex;
use xiom.math;
use xiom.async;
use xiom.async.timer;
use xiom.thread.spawn;

fn add_i(a: Int, b: Int) -> Int {
  return a + b;
}

fn mul_i(a: Int, b: Int) -> Int {
  return a * b;
}

fn act_i(a: Int, b: Int) -> Int {
  return a * b;
}

fn s_false(x: &Vec[Int]) -> Bool {
  return false;
}

fn main() -> Int {
  // 1: NaN / infinity predicates.
  if !math.is_nan(0.0 / 0.0) { return 1; }
  if math.is_nan(1.0) { return 2; }
  if !math.is_inf(1.0 / 0.0) { return 3; }
  if !math.is_inf(-1.0 / 0.0) { return 4; }
  if math.is_inf(0.0) { return 5; }
  var cot0 = math.trig.cot(0.0);
  if !(cot0 == 1.0 / 0.0 || cot0 == -1.0 / 0.0 || cot0 != cot0) { return 41; }

  // 2: smooth / rough boundaries.
  if !math.number_theory.smooth(1, 0) { return 6; }
  if !math.number_theory.smooth(12, 3) { return 7; }
  if math.number_theory.smooth(12, 2) { return 8; }
  if math.number_theory.smooth(7, 1) { return 9; }
  if !math.number_theory.rough(1, 100) { return 10; }
  if !math.number_theory.rough(49, 5) { return 11; }
  if math.number_theory.rough(35, 5) { return 12; }

  // 3: places == 0 is round().
  if math.rounding.round_to(2.345, 0) != math.rounding.round(2.345) { return 13; }
  if math.rounding.round_to(-2.5, 0) != math.rounding.round(-2.5) { return 14; }

  // 4: negative square/cube rejection.
  if math.roots.is_square(-4) { return 15; }
  if !math.roots.is_square(16) { return 16; }
  if math.roots.is_cube(-27) { return 17; }
  if !math.roots.is_cube(27) { return 18; }

  // 5: complex division components.
  var a = complex.complex_new(1.0, 2.0);
  var b = complex.complex_new(3.0, 4.0);
  var q = complex.complex_div(a, b);
  if q.re < 0.4399 || q.re > 0.4401 { return 19; }
  if q.im < 0.0799 || q.im > 0.0801 { return 20; }

  // 6: mat4_inv singularity cutoff and a real inverse.
  var zero = math.matrices.mat4_new(0.0, 0.0, 0.0, 0.0,
                                     0.0, 0.0, 0.0, 0.0,
                                     0.0, 0.0, 0.0, 0.0,
                                     0.0, 0.0, 0.0, 0.0);
  if math.matrices.mat4_inv(zero).is_some { return 21; }
  var ident = math.matrices.mat4_new(1.0, 0.0, 0.0, 0.0,
                                     0.0, 1.0, 0.0, 0.0,
                                     0.0, 0.0, 1.0, 0.0,
                                     0.0, 0.0, 0.0, 1.0);
  if !math.matrices.mat4_inv(ident).is_some { return 22; }

  // 7: empty-set relation laws.
  var empty = Vec[Int].new();
  var one = Vec[Int].new();
  one.push(1);
  if !math.set_theory.set_subset(&empty, &one) { return 23; }
  if !math.set_theory.set_superset(&one, &empty) { return 24; }
  if !math.set_theory.set_proper_subset(&empty, &one) { return 25; }
  if !math.set_theory.set_disjoint(&empty, &one) { return 26; }
  var no_blocks = Vec[Vec[Int]].new();
  if !math.set_theory.set_partition(&empty, &no_blocks) { return 27; }
  var no_pairs = Vec[(Int, Int)].new();
  var no_triples = Vec[(Str, Str, Str)].new();
  var no_sentences = Vec[Str].new();

  // 8: empty open family is not a topology.
  var no_sets = Vec[Vec[Int]].new();
  if math.topology.topological_space(&empty, &no_sets) { return 28; }

  // 9: algebra empty-carrier vacuity and galois prime rejection.
  if !math.algebra_extended.group_theory(add_i, &empty, 0) { return 29; }
  if !math.algebra_extended.ring_theory(add_i, mul_i, &empty, 0, 1) { return 30; }
  if !math.algebra_extended.module_theory(act_i, &empty, &empty) { return 31; }
  if !math.algebra_extended.commutative_algebra(&empty, &empty, mul_i) { return 32; }
  if !math.algebra_extended.category_theory(&empty, &no_pairs) { return 33; }
  if math.algebra_extended.galois_theory(&empty, 1) { return 34; }

  // 10: empty logic boundaries.
  var no_axioms = Vec[Str].new();
  if math.mathematical_logic.provability(&no_axioms, "p") { return 35; }
  if !math.mathematical_logic.model_theory(&no_sentences, s_false) { return 36; }
  if !math.mathematical_logic.category_theory("obj", &no_triples) { return 37; }

  // 11: sleep domain clauses at zero.
  spawn.sleep_ms(0);
  timer.timer_sleep(0);

  // 12: Channel.recv removes one item from a non-empty channel.
  var ch = async.Channel.bounded(2);
  async.Channel.send[Int](&mut ch, 7);
  async.Channel.send[Int](&mut ch, 8);
  if ch.items.len() != 2 { return 38; }
  var got = async.Channel.recv[Int](&mut ch);
  if got != 7 { return 39; }
  if ch.items.len() != 1 { return 40; }

  return 0;
}

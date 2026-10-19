// p_wave194_math_bits.xi -- wave 194: math/bits contract invariants.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-194 clauses on the remaining math and bits modules. Every
// call below also re-evaluates the new requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. algebra_extended: Clifford basis size 2^dim and the dim < 0 empty guard.
// 2. mathematical_biology: population/chemotherapy positivity, Hardy-Weinberg
//    shape and probability bounds, evolution length.
// 3. mathematical_economics: utility/production positivity, market bracket,
//    auction winner bounds, bundle length laws.
// 4. mathematical_logic: proof_theory seed monotonicity.
// 5. mathematical_physics: Pauli/Gamma matrix shapes.
// 6. operations_research: DP/inventory length plus scheduler and facility
//    result bounds.
// 7. topology: ball/interior cardinality bounds.
// 8. control_theory: PID integral law and Routh input domain.
// 9. finance: IRR/bond bracket, option Greeks' ranges and NaN domains.
// 10. math: min/max, shift saturation, clamp/lerp, pure floor/ceil, pure
//     transcendental boundary values.
// 11. bitarray: packed length, binary-op max length, complement/to-bytes shape.
// 12. endianness: byte-swap bounds and round-trip identities.
// Returns 0 when every case holds.

module p_wave194_math_bits

use xiom.math;
use xiom.bits;

fn one_action(s: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  out.push(s);
  return out;
}

fn zero_reward(a: Int, b: Int) -> Float64 {
  return 0.0;
}

fn unit_cost(v: &Vec[Float64]) -> Float64 {
  return 0.0;
}

fn unit_utility(v: &Vec[Float64]) -> Float64 {
  return 1.0;
}

fn unit_value(i: Int) -> Float64 {
  return 1.0;
}

fn unit_valuation(i: Int, t: Float64) -> Float64 {
  return 1.0;
}

fn dist(a: Int, b: Int) -> Float64 {
  var d = a - b;
  if d < 0 { d = -d; }
  return d as Float64;
}

fn no_rules(axioms: &Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  return out;
}

fn lin(x: Float64) -> Float64 {
  return x;
}

fn lin_scalar(v: &Vec[Float64]) -> Float64 {
  if v.len() == 0 { return 0.0; }
  return v[0];
}

fn demand_line(p: Float64) -> Float64 {
  return 100.0 - p;
}

fn supply_line(p: Float64) -> Float64 {
  return p;
}

fn main() -> Int {
  // ---- 1: Clifford basis shape ----
  var metric = Vec[Vec[Float64]].new();
  var c0 = math.algebra_extended.clifford_algebra(&metric, 0);
  if c0.len() != 1 { return 1; }
  var cneg = math.algebra_extended.clifford_algebra(&metric, -1);
  if cneg.len() != 0 { return 2; }

  // ---- 2: mathematical biology ----
  if math.mathematical_biology.population_growth(0.1, 100.0, 2.0) < 0.0 { return 3; }
  var lg = math.mathematical_biology.logistic_growth(0.1, 1000.0, 10.0, 2.0);
  if lg != lg { return 4; }
  if math.mathematical_biology.chemotherapy(1.0, 1.0, 50.0, 0.5, 1.0) < 0.0 { return 5; }
  var hw = math.mathematical_biology.genetics(0.5, 0.5, 0.0);
  if hw.len() != 3 { return 6; }
  if hw[0] < 0.0 || hw[0] > 1.0 || hw[1] < 0.0 || hw[1] > 1.0 || hw[2] < 0.0 || hw[2] > 1.0 { return 7; }
  var hw_bad = math.mathematical_biology.genetics(0.0, 0.0, 0.0);
  if hw_bad.len() != 0 { return 8; }
  var fit = Vec[Float64].new();
  fit.push(1.0);
  fit.push(1.0);
  var pop = Vec[Float64].new();
  pop.push(0.5);
  pop.push(0.5);
  if math.mathematical_biology.evolution(&fit, &pop, 0.01).len() != 2 { return 9; }

  // ---- 3: mathematical economics ----
  var bundle = Vec[Float64].new();
  bundle.push(2.0);
  bundle.push(3.0);
  var weights = Vec[Float64].new();
  weights.push(1.0);
  weights.push(1.0);
  if math.mathematical_economics.utility(&bundle, &weights) <= 0.0 { return 10; }
  if math.mathematical_economics.production_cobb_douglas(2.0, 1.0, 1.0, 3.0, 4.0) <= 0.0 { return 11; }
  if math.mathematical_economics.demand(2.0, 100.0, 1.0) <= 0.0 { return 12; }
  if math.mathematical_economics.supply(2.0, 5.0, 1.0) <= 0.0 { return 13; }
  var eq = math.mathematical_economics.market_equilibrium(demand_line, supply_line);
  if eq.0 < 0.0 || eq.0 > 1000.0 { return 14; }
  if math.mathematical_economics.elasticity(10.0, 20.0, 1.0, 2.0) != 1.0 { return 15; }
  var mg = math.mathematical_economics.marginal(lin, 2.0, 0.001);
  if mg != mg { return 16; }
  var prices = Vec[Float64].new();
  prices.push(1.0);
  prices.push(2.0);
  if math.mathematical_economics.consumer_theory(&prices, 10.0, unit_utility).len() != 2 { return 17; }
  if math.mathematical_economics.producer_theory(&prices, unit_cost).len() != 2 { return 18; }
  var bidders = Vec[Float64].new();
  bidders.push(10.0);
  bidders.push(20.0);
  var values = Vec[Float64].new();
  values.push(5.0);
  values.push(10.0);
  var auc = math.mathematical_economics.auction_theory(&bidders, &values);
  if auc.1 != 1 || auc.0 != 5.0 { return 19; }
  if math.mathematical_economics.mechanism_design(&prices, unit_valuation).len() != 2 { return 20; }

  // ---- 4: mathematical logic ----
  var ax = Vec[Str].new();
  ax.push("p");
  ax.push("p>q");
  var derived = math.mathematical_logic.proof_theory(&ax, no_rules);
  if derived.len() < 2 { return 21; }

  // ---- 5: mathematical physics shapes ----
  if math.mathematical_physics.pauli_matrices(1).len() != 2 { return 22; }
  if math.mathematical_physics.pauli_matrices(9).len() != 0 { return 23; }
  if math.mathematical_physics.gamma_matrices(2).len() != 4 { return 24; }
  if math.mathematical_physics.gamma_matrices(3).len() != 0 { return 25; }

  // ---- 6: operations research ----
  var states = Vec[Int].new();
  states.push(1);
  states.push(2);
  var dp = math.operations_research.dynamic_programming(&states, one_action, zero_reward);
  if dp.len() != 2 { return 26; }
  var demand = Vec[Float64].new();
  demand.push(1.0);
  demand.push(2.0);
  demand.push(3.0);
  if math.operations_research.inventory(&demand, 1.0, 1.0).len() != 3 { return 27; }
  var jobs = Vec[(Int, Int, Int)].new();
  jobs.push((0, 3, 1));
  jobs.push((1, 2, 1));
  jobs.push((2, 1, 1));
  if math.operations_research.scheduling(&jobs, 2).len() != 3 { return 28; }
  if math.operations_research.scheduling(&jobs, 0).len() != 0 { return 29; }
  var cands = Vec[(Float64, Float64)].new();
  cands.push((0.0, 0.0));
  cands.push((1.0, 1.0));
  var site = math.operations_research.facility_location(&demand, &cands, 1);
  if site.len() > 2 { return 30; }
  var fcs = Vec[(Float64, Float64)].new();
  fcs.push((300.0, 10.0));
  fcs.push((100.0, 50.0));
  if math.operations_research.revenue_management(100, &fcs).len() != 2 { return 31; }
  var bounds = Vec[(Float64, Float64)].new();
  bounds.push((-1.0, 1.0));
  var so = math.operations_research.stochastic_optimization(lin_scalar, &bounds, 20);
  if so.len() != 1 { return 32; }

  // ---- 7: topology cardinality bounds ----
  var pts = Vec[Int].new();
  pts.push(1);
  pts.push(2);
  var bl = math.topology.ball(dist, 1, 1.5, &pts);
  if bl.len() > pts.len() { return 33; }
  var tau = Vec[Vec[Int]].new();
  var open1 = Vec[Int].new();
  open1.push(1);
  tau.push(open1);
  var s = Vec[Int].new();
  s.push(1);
  s.push(2);
  var inside = math.topology.interior(&tau, &s);
  if inside.len() > s.len() { return 34; }

  // ---- 8: control theory ----
  var pid = math.control_theory.pid_controller(1.0, 2.0, 0.0, 0.5, 0.1, 1.0);
  if pid.1 != 1.0 + 0.5 * 0.1 { return 35; }
  var den = Vec[Float64].new();
  den.push(1.0);
  den.push(3.0);
  den.push(2.0);
  if !math.control_theory.stability_routh_hurwitz(&den) { return 36; }
  var num = Vec[Float64].new();
  num.push(1.0);
  var tf = math.control_theory.transfer_function(&num, &den, 1.0);
  if tf != 1.0 / 6.0 { return 37; }

  // ---- 9: finance ----
  var cf = Vec[Float64].new();
  cf.push(-100.0);
  cf.push(60.0);
  cf.push(60.0);
  var rr = math.finance.irr(&cf);
  if rr != rr { return 38; }
  if rr < -0.99 || rr > 10.0 { return 39; }
  var cd = math.finance.option_call_delta(100.0, 100.0, 1.0, 0.05, 0.2);
  if cd < 0.0 || cd > 1.0 { return 40; }
  var pd = math.finance.option_put_delta(100.0, 100.0, 1.0, 0.05, 0.2);
  if pd < -1.0 || pd > 0.0 { return 41; }
  if math.finance.option_gamma(100.0, 100.0, 1.0, 0.05, 0.2) < 0.0 { return 42; }
  if math.finance.option_vega(100.0, 100.0, 1.0, 0.05, 0.2) < 0.0 { return 43; }
  if math.finance.option_rho(100.0, 100.0, 1.0, 0.05, 0.2) < 0.0 { return 44; }
  var bad_dur = math.finance.duration(0.0, 0.05, 0.05, 5, 2);
  if bad_dur == bad_dur { return 45; }
  if math.finance.annuity(0.0, 10.0, 5.0) != 50.0 { return 46; }

  // ---- 10: core math ----
  if math.abs_int(-7) != 7 { return 47; }
  if math.min_int(3, 5) != 3 || math.max_int(3, 5) != 5 { return 48; }
  if math.min_float(1.0, 2.0) != 1.0 || math.max_float(1.0, 2.0) != 2.0 { return 49; }
  if math.shl(1, 4) != 16 { return 50; }
  if math.shl(1, 64) != 0 { return 51; }
  if math.shr(-8, 1) != -4 { return 52; }
  if math.shr(-1, 64) != -1 { return 53; }
  var rf = math.random_float();
  if rf < 0.0 || rf >= 1.0 { return 54; }
  if math.clamp(5.0, 0.0, 3.0) != 3.0 { return 55; }
  if math.lerp(2.0, 4.0, 0.5) != 3.0 { return 56; }
  if math.lerp(2.0, 4.0, 0.0) != 2.0 { return 57; }
  if math.lerp(2.0, 4.0, 1.0) != 4.0 { return 58; }
  if math.floor_pure(2.75) != 2.0 { return 59; }
  if math.ceil_pure(2.25) != 3.0 { return 60; }
  if math.sin_pure(0.0) != 0.0 { return 61; }
  if math.cos_pure(0.0) != 1.0 { return 62; }
  if math.exp_pure(0.0) != 1.0 { return 63; }
  var at = math.atan_pure(1.0);
  if at < -1.5707963267948966 || at > 1.5707963267948966 { return 64; }

  // ---- 11: bitarray shape ----
  var ba = bits.bitarray.bit_array_new(10);
  if ba.len != 10 { return 65; }
  if ba.bits.len() != 2 { return 66; }
  if bits.bitarray.bit_array_test(ba, -1) { return 67; }
  if bits.bitarray.bit_array_test(ba, 10) { return 68; }
  var neg = bits.bitarray.bit_array_new(-5);
  if neg.len != 0 || neg.bits.len() != 0 { return 69; }
  var short = bits.bitarray.bit_array_new(3);
  var band = bits.bitarray.bit_array_and(ba, short);
  if band.len != 10 || band.bits.len() != 2 { return 70; }
  var bor = bits.bitarray.bit_array_or(short, ba);
  if bor.len != 10 { return 71; }
  var bxor = bits.bitarray.bit_array_xor(ba, short);
  if bxor.len != 10 { return 72; }
  var bnot = bits.bitarray.bit_array_not(short);
  if bnot.len != 3 || bnot.bits.len() != 1 { return 73; }
  if bits.bitarray.bit_array_to_bytes(ba).len() != 2 { return 74; }

  // ---- 12: endianness ----
  if bits.endianness.is_big_endian() { return 75; }
  if !bits.endianness.is_little_endian() { return 76; }
  if bits.endianness.bswap_16(4660) != 13330 { return 77; }
  if bits.endianness.bswap_32(1) != 16777216 { return 78; }
  if bits.endianness.to_be(4660, 2) != 13330 { return 79; }
  if bits.endianness.from_be(13330, 2) != 4660 { return 80; }
  if bits.endianness.from_be(bits.endianness.to_be(4660, 2), 2) != 4660 { return 81; }
  if bits.endianness.to_le(7, 4) != 7 { return 82; }
  if bits.endianness.from_le(7, 4) != 7 { return 83; }
  if bits.endianness.native_to_le(42) != 42 { return 84; }
  if bits.endianness.le_to_native(42) != 42 { return 85; }
  if bits.endianness.swap_endian(1) != 72057594037927936 { return 86; }
  if bits.endianness.native_to_be(1) != 72057594037927936 { return 87; }
  if bits.endianness.be_to_native(1) != 72057594037927936 { return 88; }
  if bits.endianness.bswap_64(0) != 0 { return 89; }
  if bits.endianness.bswap_128(1) != bits.endianness.bswap_64(1) { return 90; }
  if bits.endianness.bswap_256(1) != bits.endianness.bswap_64(1) { return 91; }

  return 0;
}

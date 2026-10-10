// p_wave102_shapes.xi -- wave 102 shape validation: json depth cap,
// decompose, fuzzy, game_theory, chaos.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-102 clause guards:
//   (a) xiom.serialize.json: the 128-level nesting cap (Err beyond, no
//       stack death) plus the deep-60000 case;
//   (b) xiom.math.decompose: the frexp/ldexp/ilogb/logb/scalbn/scalbln/
//       significand/exponent/frexp_pure/ldexp_pure pins, the normal/
//       subnormal predicates, classify and the nextafter/nexttoward
//       direction claims;
//   (c) xiom.math.fuzzy: the logic op mirrors, the length guards, the
//       defuzzification/sugeno NaN guards, the control zero pin and the
//       decision range/guard;
//   (d) xiom.math.game_theory: cooperative_game/shapley/game_core/
//       auction/mechanism_design/prisoner pins;
//   (e) xiom.math.chaos: the map length guards, the lorenz/rossler shape,
//       lyapunov/fractal NaN guards, the escape-count bands and the
//       zero-origin pins.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave102_shapes

use xiom.serialize.json as json;
use xiom.string as string;
use xiom.math.decompose as decompose;
use xiom.math.fuzzy as fuzzy;
use xiom.math.game_theory as game;
use xiom.math.chaos as chaos;

fn membership_fn(i: Int) -> Float64 {
  return (i as Float64) / 10.0;
}

fn v_coal(c: &Vec[Int]) -> Float64 {
  return (c.len() as Float64) * 2.0;
}

fn v_scalar(i: Int) -> Float64 {
  return (i as Float64) + 1.0;
}

fn dyn_shift(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < x.len() {
    out.push(x[i] + 0.1);
    i = i + 1;
  }
  return out;
}

fn main() -> Int {
  // ---- json: nesting cap (128 levels; Err beyond, never a stack death)
  let j1 = json.json_parse("[]");
  if j1.is_ok != true { return 1; }
  let deep_ok = string.str_repeat("[", 128) + string.str_repeat("]", 128);
  let j2 = json.json_parse(deep_ok);
  if j2.is_ok != true { return 2; }
  let deep_over = string.str_repeat("[", 129);
  let j3 = json.json_parse(deep_over);
  if j3.is_err != true { return 3; }
  let deep_huge = string.str_repeat("[", 60000);
  let j4 = json.json_parse(deep_huge);
  if j4.is_err != true { return 4; }

  // ---- decompose: frexp/ldexp/ilogb/logb pins
  let fr0 = decompose.frexp(0.0);
  if fr0.0 != 0.0 { return 5; }
  if fr0.1 != 0 { return 6; }
  let fr8 = decompose.frexp(8.0);
  if fr8.0 != 0.5 { return 7; }
  if fr8.1 != 4 { return 8; }
  let ld0 = decompose.ldexp(0.0, 5);
  if ld0 != 0.0 { return 9; }
  let ldinf = decompose.ldexp(1.0, 2000);
  if ldinf < 1.0e308 { return 10; }
  let ldninf = decompose.ldexp(-1.0, 2000);
  if ldninf > -1.0e308 { return 11; }
  let ldzero = decompose.ldexp(1.0, -2000);
  if ldzero != 0.0 { return 12; }
  let il0 = decompose.ilogb(0.0);
  if il0 != -9223372036854775807 - 1 { return 13; }
  let il8 = decompose.ilogb(8.0);
  if il8 != 3 { return 14; }
  let ilh = decompose.ilogb(0.5);
  if ilh != -1 { return 15; }
  let lg0 = decompose.logb(0.0);
  if lg0 > -1.0e308 { return 16; }
  let lg8 = decompose.logb(8.0);
  if lg8 != 3.0 { return 17; }
  let sc1 = decompose.scalbn(1.5, 1);
  if sc1 != 3.0 { return 18; }
  let sc0 = decompose.scalbn(0.0, 5);
  if sc0 != 0.0 { return 19; }
  let sb1 = decompose.scalbln(1.5, 1);
  if sb1 != 3.0 { return 20; }
  let sb0 = decompose.scalbln(0.0, 5);
  if sb0 != 0.0 { return 21; }
  let sg0 = decompose.significand(0.0);
  if sg0 != 0.0 { return 22; }
  let sg8 = decompose.significand(8.0);
  if sg8 != 0.5 { return 23; }
  let ex8 = decompose.exponent(8.0);
  if ex8 != 3 { return 24; }
  let fp8 = decompose.frexp_pure(8.0);
  if fp8.0 != 0.5 { return 25; }
  if fp8.1 != 4 { return 26; }
  let fp0 = decompose.frexp_pure(0.0);
  if fp0.0 != 0.0 { return 27; }
  if fp0.1 != 0 { return 28; }
  let lp0 = decompose.ldexp_pure(0.0, 5);
  if lp0 != 0.0 { return 29; }
  let lpinf = decompose.ldexp_pure(1.0, 2000);
  if lpinf < 1.0e308 { return 30; }
  let lpz = decompose.ldexp_pure(1.0, -2000);
  if lpz != 0.0 { return 31; }
  let lp15 = decompose.ldexp_pure(1.5, 1);
  if lp15 != 3.0 { return 32; }

  // ---- decompose: predicates / classify / nextafter
  let nrm0 = decompose.is_normal(0.0);
  if nrm0 != false { return 33; }
  let nrm1 = decompose.is_normal(1.0);
  if nrm1 != true { return 34; }
  let nrmt = decompose.is_normal(1.0e-310);
  if nrmt != false { return 35; }
  let sub0 = decompose.is_subnormal(0.0);
  if sub0 != false { return 36; }
  let sub1 = decompose.is_subnormal(1.0);
  if sub1 != false { return 37; }
  let subt = decompose.is_subnormal(1.0e-310);
  if subt != true { return 38; }
  let cl0 = decompose.classify(0.0);
  match cl0 {
    decompose.FloatClass.Zero => { },
    _ => { return 39; }
  }
  let na1 = decompose.nextafter(1.0, 1.0);
  if na1 != 1.0 { return 40; }
  let na2 = decompose.nextafter(1.0, 2.0);
  if na2 <= 1.0 { return 41; }
  let na3 = decompose.nextafter(1.0, 0.0);
  if na3 >= 1.0 { return 42; }
  let nt1 = decompose.nexttoward(1.0, 1.0);
  if nt1 != 1.0 { return 43; }
  let nt2 = decompose.nexttoward(1.0, 2.0);
  if nt2 <= 1.0 { return 44; }

  // ---- fuzzy: sets / logic
  var uni = Vec[Int].new();
  uni.push(0);
  uni.push(1);
  uni.push(2);
  let fs = fuzzy.fuzzy_set(&uni, membership_fn);
  if fs.len() != 3 { return 45; }
  let mm0 = fuzzy.membership(&fs, -1);
  if mm0 != 0.0 { return 46; }
  let mm1 = fuzzy.membership(&fs, 9);
  if mm1 != 0.0 { return 47; }
  let fl_and = fuzzy.fuzzy_logic(0.3, 0.7, "and");
  if fl_and != 0.3 { return 48; }
  let fl_or = fuzzy.fuzzy_logic(0.3, 0.7, "or");
  if fl_or != 0.7 { return 49; }
  let fl_not = fuzzy.fuzzy_logic(0.3, 0.7, "not");
  if fl_not != 0.7 { return 50; }
  let fl_prod = fuzzy.fuzzy_logic(0.3, 0.7, "prod");
  if fl_prod != 0.3 * 0.7 { return 51; }
  let fl_sum = fuzzy.fuzzy_logic(0.3, 0.7, "sum");
  if fl_sum != 0.3 + 0.7 - 0.3 * 0.7 { return 52; }

  // ---- fuzzy: set algebra / defuzz / inference
  var fa = Vec[Float64].new();
  fa.push(0.2);
  fa.push(0.8);
  var fb = Vec[Float64].new();
  fb.push(0.5);
  fb.push(0.5);
  var fc = Vec[Float64].new();
  fc.push(0.1);
  let fi0 = fuzzy.fuzzy_intersection(&fa, &fc);
  if fi0.len() != 0 { return 53; }
  let fi1 = fuzzy.fuzzy_intersection(&fa, &fb);
  if fi1.len() != 2 { return 54; }
  let fu0 = fuzzy.fuzzy_union(&fa, &fc);
  if fu0.len() != 0 { return 55; }
  let fu1 = fuzzy.fuzzy_union(&fa, &fb);
  if fu1.len() != 2 { return 56; }
  let fcm = fuzzy.fuzzy_complement(&fa);
  if fcm.len() != 2 { return 57; }
  let dfm = fuzzy.defuzzification(&fa, &fc);
  if dfm == dfm { return 58; }
  var e0 = Vec[Float64].new();
  let dfe = fuzzy.defuzzification(&e0, &e0);
  if dfe == dfe { return 59; }
  var rules = Vec[Str].new();
  rules.push("0:1:1.0");
  var e_rules = Vec[Str].new();
  let inf0 = fuzzy.fuzzy_inference(&e_rules, &fa);
  if inf0.len() != 0 { return 60; }
  let inf1 = fuzzy.fuzzy_inference(&rules, &fa);
  if inf1.len() != 2 { return 61; }
  let mam0 = fuzzy.mamdani(&e_rules, &fa);
  if mam0.len() != 0 { return 62; }
  let mam1 = fuzzy.mamdani(&rules, &fa);
  if mam1.len() != 2 { return 63; }
  let sug0 = fuzzy.sugeno(&e_rules, &fa);
  if sug0 == sug0 { return 64; }
  let fc0 = fuzzy.fuzzy_control(5.0, 5.0, 2.0, 3.0);
  if fc0 != 0.0 { return 65; }
  let fd0 = fuzzy.fuzzy_decision(&fa, &fc);
  if fd0 != -1 { return 66; }
  let fd1 = fuzzy.fuzzy_decision(&e0, &e0);
  if fd1 != -1 { return 67; }
  let fd2 = fuzzy.fuzzy_decision(&fa, &fb);
  if fd2 < 0 || fd2 >= 2 { return 68; }

  // ---- game_theory
  let cg0 = game.cooperative_game(v_coal, 0);
  if cg0.1 != 0.0 { return 69; }
  let cg3 = game.cooperative_game(v_coal, 3);
  if cg3.1 != cg3.0 / 3.0 { return 70; }
  let sh0 = game.shapley_value(v_coal, -1);
  if sh0.len() != 0 { return 71; }
  let sh3 = game.shapley_value(v_coal, 3);
  if sh3.len() != 3 { return 72; }
  let gc0 = game.game_core(v_coal, 0);
  if gc0.len() != 0 { return 73; }
  let gc1 = game.game_core(v_coal, 1);
  if gc1.len() != 1 { return 74; }
  let gc2 = game.game_core(v_coal, 2);
  if gc2.len() != 2 { return 75; }
  let gc3 = game.game_core(v_coal, 3);
  if gc3.len() != 1 { return 76; }
  var e_bids = Vec[Float64].new();
  let au0 = game.auction(&e_bids, 1.0);
  if au0.0 != 0.0 { return 77; }
  if au0.1 != -1 { return 78; }
  var bids = Vec[Float64].new();
  bids.push(5.0);
  bids.push(7.0);
  let au1 = game.auction(&bids, 6.0);
  if au1.1 != 1 { return 79; }
  if au1.0 < 6.0 { return 80; }
  if au1.1 >= bids.len() { return 81; }
  let au2 = game.auction(&bids, 9.0);
  if au2.0 != 0.0 { return 82; }
  if au2.1 != -1 { return 83; }
  var e_ts = Vec[Float64].new();
  let md0 = game.mechanism_design(&e_ts, v_scalar);
  if md0.len() != 0 { return 84; }
  let md1 = game.mechanism_design(&fa, v_scalar);
  if md1.len() != 2 { return 85; }
  let pd = game.prisoner_dilemma(1.0, 2.0);
  if pd.0 != 2.0 { return 86; }
  if pd.1 != 1.0 { return 87; }

  // ---- chaos: maps
  let lm0 = chaos.logistic_map(3.5, 0.5, 0);
  if lm0.len() != 0 { return 88; }
  let lm1 = chaos.logistic_map(3.5, 0.5, 3);
  if lm1.len() != 3 { return 89; }
  var x3 = Vec[Float64].new();
  x3.push(1.0);
  x3.push(1.0);
  x3.push(1.0);
  let lz0 = chaos.lorenz_system(10.0, 28.0, 2.66, &x3, 0, 0.01);
  if lz0.len() != 0 { return 90; }
  let lz1 = chaos.lorenz_system(10.0, 28.0, 2.66, &x3, 2, 0.01);
  if lz1.len() != 3 { return 91; }
  let lzbad = chaos.lorenz_system(10.0, 28.0, 2.66, &fa, 2, 0.01);
  if lzbad.len() != 0 { return 92; }
  let rs1 = chaos.rossler_system(0.2, 0.2, 5.7, &x3, 2, 0.01);
  if rs1.len() != 3 { return 93; }
  let rsbad = chaos.rossler_system(0.2, 0.2, 5.7, &fa, 2, 0.01);
  if rsbad.len() != 0 { return 94; }
  let hm0 = chaos.henon_map(1.4, 0.3, 0.1, 0.1, 0);
  if hm0.len() != 0 { return 95; }
  let hm1 = chaos.henon_map(1.4, 0.3, 0.1, 0.1, 2);
  if hm1.len() != 2 { return 96; }
  let bd0 = chaos.bifurcation_diagram(2.0, 4.0, 0, 0);
  if bd0.len() != 0 { return 97; }
  let bd1 = chaos.bifurcation_diagram(4.0, 2.0, 2, 0);
  if bd1.len() != 0 { return 98; }
  let bd2 = chaos.bifurcation_diagram(2.5, 3.5, 2, 0);
  if bd2.len() != 20 { return 99; }
  var orb2 = Vec[Float64].new();
  orb2.push(0.1);
  orb2.push(0.2);
  let ly0 = chaos.lyapunov_exponent(&orb2);
  if ly0 == ly0 { return 100; }
  let sa0 = chaos.strange_attractor(dyn_shift, &fa, -1);
  if sa0.len() != 0 { return 101; }
  let sa1 = chaos.strange_attractor(dyn_shift, &fa, 2);
  if sa1.len() != 3 { return 102; }
  var pts1 = Vec[(Float64, Float64)].new();
  pts1.push((0.0, 0.0));
  let fdim = chaos.fractal_dimension(&pts1);
  if fdim == fdim { return 103; }
  let mb0 = chaos.mandelbrot_set(0.0, 0.0, 10);
  if mb0 != 10 { return 104; }
  let mb1 = chaos.mandelbrot_set(2.0, 2.0, 10);
  if mb1 < 0 || mb1 > 10 { return 105; }
  let jl0 = chaos.julia_set(0.0, 0.0, 0.0, 0.0, 10);
  if jl0 != 10 { return 106; }
  let jl1 = chaos.julia_set(0.0, 0.0, 2.0, 2.0, 10);
  if jl1 < 0 || jl1 > 10 { return 107; }
  let bs0 = chaos.burning_ship(0.0, 0.0, 10);
  if bs0 != 10 { return 108; }
  let bs1 = chaos.burning_ship(2.0, 2.0, 10);
  if bs1 < 0 || bs1 > 10 { return 109; }
  var e_c = Vec[Float64].new();
  let nf0 = chaos.newton_fractal(&e_c, 1.0, 10);
  if nf0 != 0 { return 110; }
  var quad = Vec[Float64].new();
  quad.push(1.0);
  quad.push(0.0);
  quad.push(-1.0);
  let nf1 = chaos.newton_fractal(&quad, 0.5, 10);
  if nf1 != 0 && nf1 != 1 { return 111; }
  let tm0 = chaos.tent_map(2.0, 0.3, 0);
  if tm0.len() != 0 { return 112; }
  let tm1 = chaos.tent_map(2.0, 0.3, 2);
  if tm1.len() != 2 { return 113; }

  // ---- Vec.with_len (bindings W-5): zeroed sized buffers
  var wl = Vec[UInt8].with_len(4);
  if wl.len() != 4 { return 114; }
  let wl0 = wl[0];
  if wl0 != 0 as UInt8 { return 115; }
  var wlz = Vec[UInt8].with_len(-1);
  if wlz.len() != 0 { return 116; }
  var wli = Vec[Int].with_len(3);
  if wli.len() != 3 { return 117; }
  let wli2 = wli[2];
  if wli2 != 0 { return 118; }

  return 0;
}

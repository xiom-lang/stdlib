// p_wave42_shapes.xi -- wave 42 verification: matrices + number_systems + queueing.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses. Cases: fixed-size
// Mat2/Mat3/Mat4 construction/arithmetic/transpose/det/inv, dynamic matrix
// shape claims, radix/numerals/fractions/surds/extended algebras, queueing
// formulas and their unstable/invalid guards. Returns 0 when every case
// holds.

module p_wave42_shapes

use xiom.math;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn is_nan(x: Float64) -> Bool {
  return x != x;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;
  var inf = 1.0 / 0.0;

  // ---- matrices: Mat2 ----
  var m2 = math.matrices.mat2_new(1.0, 2.0, 3.0, 4.0);
  if !near(m2.m00, 1.0, 1e-9) { return 1; }
  if !near(m2.m11, 4.0, 1e-9) { return 2; }
  if !near(math.matrices.mat2_det(m2), -2.0, 1e-9) { return 3; }
  var i2 = math.matrices.mat2_new(1.0, 0.0, 0.0, 1.0);
  var p2 = math.matrices.mat2_mul(m2, i2);
  if !near(p2.m01, 2.0, 1e-9) { return 4; }
  var t2 = math.matrices.mat2_transpose(m2);
  if !near(t2.m01, 3.0, 1e-9) { return 5; }
  if math.matrices.mat2_inv(math.matrices.mat2_new(1.0, 2.0, 2.0, 4.0)).is_some() { return 6; }
  var v2 = math.matrices.mat2_inv(math.matrices.mat2_new(2.0, 0.0, 0.0, 2.0));
  if !v2.is_some() { return 7; }
  var u2 = v2.unwrap();
  if !near(u2.m00, 0.5, 1e-9) { return 8; }

  // ---- matrices: Mat3 ----
  var m3 = math.matrices.mat3_new(1.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 4.0);
  if !near(m3.m22, 4.0, 1e-9) { return 9; }
  if !near(math.matrices.mat3_det(m3), 8.0, 1e-9) { return 10; }
  var p3 = math.matrices.mat3_mul(m3, m3);
  if !near(p3.m00, 1.0, 1e-9) { return 11; }
  if !near(p3.m11, 4.0, 1e-9) { return 12; }
  var t3 = math.matrices.mat3_transpose(m3);
  if !near(t3.m12, 0.0, 1e-9) { return 13; }
  if math.matrices.mat3_inv(math.matrices.mat3_new(1.0, 2.0, 3.0, 2.0, 4.0, 6.0, 7.0, 8.0, 9.0)).is_some() { return 14; }
  var v3 = math.matrices.mat3_inv(m3);
  if !v3.is_some() { return 15; }

  // ---- matrices: Mat4 ----
  var m4 = math.matrices.mat4_new(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
  if !near(m4.m33, 1.0, 1e-9) { return 16; }
  if !near(m4.m03, 0.0, 1e-9) { return 17; }
  var t4 = math.matrices.mat4_transpose(m4);
  if !near(t4.m30, 0.0, 1e-9) { return 18; }

  // ---- matrices: dynamic shape claims ----
  var id3 = math.matrices.mat_identity(3);
  if id3.len() != 3 { return 19; }
  if math.matrices.mat_identity(0).len() != 0 { return 20; }
  var da = Vec[Vec[Float64]].new();
  var da0 = Vec[Float64].new();
  da0.push(1.0);
  da0.push(2.0);
  da.push(da0);
  var da1 = Vec[Float64].new();
  da1.push(3.0);
  da1.push(4.0);
  da.push(da1);
  var db = Vec[Vec[Float64]].new();
  var db0 = Vec[Float64].new();
  db0.push(5.0);
  db0.push(6.0);
  db.push(db0);
  var db1 = Vec[Float64].new();
  db1.push(7.0);
  db1.push(8.0);
  db.push(db1);
  if math.matrices.mat_mul(&da, &db).len() != 2 { return 21; }
  var db2 = Vec[Vec[Float64]].new();
  var dc0 = Vec[Float64].new();
  dc0.push(1.0);
  dc0.push(2.0);
  db2.push(dc0);
  var dc1 = Vec[Float64].new();
  dc1.push(3.0);
  dc1.push(4.0);
  db2.push(dc1);
  var dc2 = Vec[Float64].new();
  dc2.push(5.0);
  dc2.push(6.0);
  db2.push(dc2);
  if math.matrices.mat_mul(&da, &db2).len() != 0 { return 22; }   // 2x2 * 3x2 -> empty
  var empty_m = Vec[Vec[Float64]].new();
  if !is_nan(math.matrices.mat_det(&empty_m)) { return 23; }
  if math.matrices.mat_inv(&empty_m).is_some() { return 24; }
  var id4 = math.matrices.mat_identity(4);
  if math.matrices.mat_translate(&id4, 1.0, 2.0, 3.0).len() != 4 { return 25; }
  if math.matrices.mat_translate(&da, 1.0, 2.0, 3.0).len() != 2 { return 26; }
  var axis = Vec[Float64].new();
  axis.push(0.0);
  axis.push(0.0);
  axis.push(1.0);
  if math.matrices.mat_rotate(&id4, 1.5707963267948966, &axis).len() != 4 { return 27; }
  if math.matrices.mat_rotate(&id4, 1.0, &da0).len() != 4 { return 28; }
  if math.matrices.mat_rotate(&da, 1.0, &axis).len() != 2 { return 29; }
  if math.matrices.mat_scale(&id4, 2.0, 2.0, 2.0).len() != 4 { return 30; }
  var eye = Vec[Float64].new();
  eye.push(0.0);
  eye.push(0.0);
  eye.push(0.0);
  var tgt = Vec[Float64].new();
  tgt.push(1.0);
  tgt.push(0.0);
  tgt.push(0.0);
  var up = Vec[Float64].new();
  up.push(0.0);
  up.push(1.0);
  up.push(0.0);
  if math.matrices.mat_look_at(&eye, &tgt, &up).len() != 4 { return 31; }
  if math.matrices.mat_look_at(&eye, &eye, &up).len() != 0 { return 32; }
  if math.matrices.mat_perspective(1.0, 1.0, 1.0, 2.0).len() != 4 { return 33; }
  if math.matrices.mat_perspective(0.0, 1.0, 1.0, 2.0).len() != 0 { return 34; }
  if math.matrices.mat_ortho(-1.0, 1.0, -1.0, 1.0, 1.0, 3.0).len() != 4 { return 35; }
  if math.matrices.mat_ortho(1.0, 1.0, -1.0, 1.0, 1.0, 3.0).len() != 0 { return 36; }

  // ---- number_systems: radix ----
  if math.number_systems.int_to_binary(5) != "101" { return 37; }
  if math.number_systems.int_to_binary(0) != "0" { return 38; }
  if math.number_systems.int_to_binary(-5) != "-101" { return 39; }
  if math.number_systems.int_to_octal(8) != "10" { return 40; }
  if math.number_systems.int_to_hex(255) != "FF" { return 41; }
  if math.number_systems.int_to_base_n(0, 16) != "0" { return 42; }
  if math.number_systems.int_to_base_n(5, 1) != "" { return 43; }
  if !math.number_systems.base_n_to_int("10", 2).is_ok { return 44; }
  if math.number_systems.base_n_to_int("10", 40).is_ok { return 45; }

  // ---- number_systems: numerals ----
  if math.number_systems.int_to_roman(1) != "I" { return 46; }
  if math.number_systems.int_to_roman(3999) != "MMMCMXCIX" { return 47; }
  if math.number_systems.int_to_roman(0) != "" { return 48; }
  if math.number_systems.chinese_numerals(0) == "" { return 49; }
  if math.number_systems.japanese_numerals(0) == "" { return 50; }
  if math.number_systems.egyptian_fractions(1, 0).len() != 0 { return 51; }
  if math.number_systems.egyptian_fractions(3, 4).len() == 0 { return 52; }
  if math.number_systems.babylonian_numerals(0) != "0" { return 53; }
  if math.number_systems.babylonian_numerals(61) == "" { return 54; }
  if math.number_systems.greek_numerals(0) != "" { return 55; }
  if math.number_systems.greek_numerals(1) == "" { return 56; }
  if math.number_systems.continued_fraction(1.5, 0).len() != 0 { return 57; }
  var cf = math.number_systems.continued_fraction(3.5, 5);
  if cf.len() != 2 { return 58; }
  if cf[0] != 3 { return 59; }
  if cf[1] != 2 { return 60; }

  // ---- number_systems: fractions, surds, algebras ----
  var f = math.number_systems.fraction_new(4, 6);
  if f.0 != 2 { return 61; }
  if f.1 != 3 { return 62; }
  var fz = math.number_systems.fraction_new(1, 0);
  if fz.0 != 0 { return 63; }
  if fz.1 != 1 { return 64; }
  var fa = math.number_systems.fraction_add((1, 2), (1, 3));
  if fa.0 != 5 { return 65; }
  if fa.1 != 6 { return 66; }
  var s0 = math.number_systems.surd_simplify(1, 0);
  if s0.0 != 1 { return 67; }
  if s0.1 != 1 { return 68; }
  var s1 = math.number_systems.surd_simplify(0, 5);
  if s1.0 != 0 { return 69; }
  if s1.1 != 1 { return 70; }
  var s2 = math.number_systems.surd_simplify(8, 1);
  if s2.0 != 2 { return 71; }
  if s2.1 != 2 { return 72; }
  var o8 = Vec[Float64].new();
  var k8 = 0;
  while k8 < 8 {
    o8.push(1.0);
    k8 = k8 + 1;
  }
  if math.number_systems.octonion_add(&o8, &o8).len() != 8 { return 73; }
  if math.number_systems.octonion_add(&o8, &da0).len() != 0 { return 74; }
  var s16 = Vec[Float64].new();
  var k16 = 0;
  while k16 < 16 {
    s16.push(1.0);
    k16 = k16 + 1;
  }
  if math.number_systems.sedenion_add(&s16, &s16).len() != 16 { return 75; }
  if math.number_systems.sedenion_add(&s16, &o8).len() != 0 { return 76; }

  // ---- queueing ----
  var mm1 = math.queueing.m_m_1(1.0, 2.0);
  if !near(mm1.0, 0.5, 1e-9) { return 77; }
  if !near(mm1.1, 0.5, 1e-9) { return 78; }
  var mm1u = math.queueing.m_m_1(3.0, 2.0);
  if mm1u.0 != inf { return 79; }
  var mm1n = math.queueing.m_m_1(0.0, 2.0);
  if !is_nan(mm1n.0) { return 80; }
  var mmc = math.queueing.m_m_c(2.0, 1.0, 4);
  if mmc.0 < 0.0 { return 81; }
  if math.queueing.m_m_c(5.0, 1.0, 2).0 != inf { return 82; }
  if !near(math.queueing.m_g_1(1.0, 0.5, 0.25), 0.5, 1e-9) { return 83; }
  if !near(math.queueing.g_g_1(2.0, 1.0, 1.0, 0.5), 0.375, 1e-9) { return 84; }
  if !near(math.queueing.erlang_b(1.0, 2), 0.2, 1e-9) { return 85; }
  if math.queueing.erlang_b(1.0, 0) != 1.0 { return 86; }
  var ec = math.queueing.erlang_c(1.0, 2);
  if ec < 0.0 || ec > 1.0 { return 87; }
  if !near(math.queueing.little_law(2.0, 3.0), 6.0, 1e-9) { return 88; }
  if !near(math.queueing.utilization(2.0, 1.0, 4), 0.5, 1e-9) { return 89; }
  if math.queueing.queue_length(5.0, 1.0, 2) != inf { return 90; }
  if math.queueing.waiting_time(5.0, 1.0, 2) != inf { return 91; }
  if !near(math.queueing.loss_probability(1.0, 1.0, 2), 0.2, 1e-9) { return 92; }
  if !near(math.queueing.blocking_probability(1.0, 1.0, 2), 0.2, 1e-9) { return 93; }
  if !near(math.queueing.heavy_traffic(2.0, 1.0, 4), 0.5, 1e-9) { return 94; }
  if !near(math.queueing.diffusion_approx(3.0, 1.0, 2.0), 4.0, 1e-9) { return 95; }
  if math.queueing.diffusion_approx(1.0, 3.0, 2.0) != 0.0 { return 96; }
  if !is_nan(math.queueing.diffusion_approx(1.0, 1.0, -1.0)) { return 97; }
  if !is_nan(nan) { return 98; }
  var s3 = math.number_systems.surd_simplify(2, 1);
  if s3.0 != 1 { return 99; }
  if s3.1 != 2 { return 100; }
  var s4 = math.number_systems.surd_simplify(18, 1);
  if s4.0 != 3 { return 101; }
  if s4.1 != 2 { return 102; }
  var s5 = math.number_systems.surd_simplify(12, 1);
  if s5.0 != 2 { return 103; }
  if s5.1 != 3 { return 104; }

  return 0;
}

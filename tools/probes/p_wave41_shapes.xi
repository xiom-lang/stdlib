// p_wave41_shapes.xi -- wave 41 verification: vectors.xi field/length clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (field equalities are
// NaN-tolerant). Cases: Vec2/Vec3/Vec4 construction, arithmetic, dot, cross,
// length, unit vector, distance, lerp; dynamic vec_dot/vec_norm/vec_scale.
// NaN is only passed to paths without a sqrt (hypot/len/norm abort on NaN via
// the math.sqrt requires, an open finding from wave 39). Returns 0 on success.

module p_wave41_shapes

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

  // Vec2.
  var a2 = math.vectors.vec2_new(3.0, 4.0);
  if !near(a2.x, 3.0, 1e-9) { return 1; }
  if !near(a2.y, 4.0, 1e-9) { return 2; }
  var b2 = math.vectors.vec2_new(1.0, -2.0);
  var s2 = math.vectors.vec2_add(a2, b2);
  if !near(s2.x, 4.0, 1e-9) { return 3; }
  if !near(s2.y, 2.0, 1e-9) { return 4; }
  var d2 = math.vectors.vec2_sub(a2, b2);
  if !near(d2.x, 2.0, 1e-9) { return 5; }
  if !near(d2.y, 6.0, 1e-9) { return 6; }
  var c2 = math.vectors.vec2_scale(a2, 2.0);
  if !near(c2.x, 6.0, 1e-9) { return 7; }
  if !near(c2.y, 8.0, 1e-9) { return 8; }
  if !near(math.vectors.vec2_dot(a2, b2), -5.0, 1e-9) { return 9; }
  if !near(math.vectors.vec2_len(a2), 5.0, 1e-9) { return 10; }
  var n2 = math.vectors.vec2_norm(a2);
  if !near(n2.x, 0.6, 1e-9) { return 11; }
  if !near(n2.y, 0.8, 1e-9) { return 12; }
  var z2 = math.vectors.vec2_norm(math.vectors.vec2_new(0.0, 0.0));
  if !near(z2.x, 0.0, 1e-9) { return 13; }
  if !near(z2.y, 0.0, 1e-9) { return 14; }
  if !near(math.vectors.vec2_dist(a2, b2), 6.324555320336759, 1e-9) { return 15; }
  var l2 = math.vectors.vec2_lerp(math.vectors.vec2_new(0.0, 0.0), math.vectors.vec2_new(2.0, 4.0), 0.5);
  if !near(l2.x, 1.0, 1e-9) { return 16; }
  if !near(l2.y, 2.0, 1e-9) { return 17; }

  // Vec3.
  var a3 = math.vectors.vec3_new(1.0, 2.0, 3.0);
  var b3 = math.vectors.vec3_new(4.0, 5.0, 6.0);
  var s3 = math.vectors.vec3_add(a3, b3);
  if !near(s3.x, 5.0, 1e-9) { return 18; }
  if !near(s3.z, 9.0, 1e-9) { return 19; }
  var d3 = math.vectors.vec3_sub(b3, a3);
  if !near(d3.x, 3.0, 1e-9) { return 20; }
  var c3 = math.vectors.vec3_scale(a3, -1.0);
  if !near(c3.y, -2.0, 1e-9) { return 21; }
  if !near(math.vectors.vec3_dot(a3, b3), 32.0, 1e-9) { return 22; }
  var x3 = math.vectors.vec3_cross(math.vectors.vec3_new(1.0, 0.0, 0.0), math.vectors.vec3_new(0.0, 1.0, 0.0));
  if !near(x3.x, 0.0, 1e-9) { return 23; }
  if !near(x3.y, 0.0, 1e-9) { return 24; }
  if !near(x3.z, 1.0, 1e-9) { return 25; }
  if !near(math.vectors.vec3_len(math.vectors.vec3_new(3.0, 4.0, 0.0)), 5.0, 1e-9) { return 26; }
  var n3 = math.vectors.vec3_norm(math.vectors.vec3_new(0.0, 3.0, 4.0));
  if !near(n3.x, 0.0, 1e-9) { return 27; }
  if !near(n3.y, 0.6, 1e-9) { return 28; }
  if !near(n3.z, 0.8, 1e-9) { return 29; }

  // Vec4.
  var a4 = math.vectors.vec4_new(1.0, 2.0, 3.0, 4.0);
  var b4 = math.vectors.vec4_new(4.0, 3.0, 2.0, 1.0);
  var s4 = math.vectors.vec4_add(a4, b4);
  if !near(s4.w, 5.0, 1e-9) { return 30; }
  var d4 = math.vectors.vec4_sub(a4, b4);
  if !near(d4.x, -3.0, 1e-9) { return 31; }
  var c4 = math.vectors.vec4_scale(a4, 0.5);
  if !near(c4.z, 1.5, 1e-9) { return 32; }
  if !near(math.vectors.vec4_dot(a4, b4), 20.0, 1e-9) { return 33; }
  if !near(math.vectors.vec4_len(math.vectors.vec4_new(1.0, 2.0, 2.0, 4.0)), 5.0, 1e-9) { return 34; }
  var n4 = math.vectors.vec4_norm(math.vectors.vec4_new(0.0, 0.0, 3.0, 4.0));
  if !near(n4.z, 0.6, 1e-9) { return 35; }
  if !near(n4.w, 0.8, 1e-9) { return 36; }
  var z4 = math.vectors.vec4_norm(math.vectors.vec4_new(0.0, 0.0, 0.0, 0.0));
  if !near(z4.x, 0.0, 1e-9) { return 37; }

  // Dynamic vectors.
  var v1 = Vec[Float64].new();
  v1.push(1.0);
  v1.push(2.0);
  v1.push(3.0);
  var v2 = Vec[Float64].new();
  v2.push(4.0);
  v2.push(5.0);
  v2.push(6.0);
  if !near(math.vectors.vec_dot(&v1, &v2), 32.0, 1e-9) { return 38; }
  var v3 = Vec[Float64].new();
  v3.push(1.0);
  if !is_nan(math.vectors.vec_dot(&v1, &v3)) { return 39; }
  var nv = Vec[Float64].new();
  nv.push(3.0);
  nv.push(4.0);
  if !near(math.vectors.vec_norm(&nv), 5.0, 1e-9) { return 40; }
  var sv = math.vectors.vec_scale(&v1, 3.0);
  if sv.len() != 3 { return 41; }
  if !near(sv[0], 3.0, 1e-9) { return 42; }
  var ev = Vec[Float64].new();
  var sev = math.vectors.vec_scale(&ev, 3.0);
  if sev.len() != 0 { return 43; }

  // NaN tolerance on the non-sqrt paths.
  var nan2 = math.vectors.vec2_new(nan, nan);
  if !is_nan(nan2.x) { return 44; }
  var na = math.vectors.vec2_add(nan2, a2);
  if !is_nan(na.x) { return 45; }
  if !is_nan(math.vectors.vec2_dot(nan2, a2)) { return 46; }
  var nl = math.vectors.vec2_lerp(nan2, a2, 0.5);
  if !is_nan(nl.y) { return 47; }
  var nan4 = math.vectors.vec4_new(nan, 0.0, 0.0, 0.0);
  var na4 = math.vectors.vec4_scale(nan4, 2.0);
  if !is_nan(na4.x) { return 48; }
  if !near(na4.w, 0.0, 1e-9) { return 49; }

  return 0;
}

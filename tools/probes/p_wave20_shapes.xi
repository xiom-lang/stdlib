// p_wave20_shapes.xi -- contract shape validation for wave 20 (geom vectors).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 20 applies to xiom.geom:
// 1. two-field component equality: `result.x == a.x + b.x && result.y == a.y + b.y`
// 2. three-field component equality
// 3. four-field component equality
// 4. scalar-result mirrored expression: `result == a.x * b.x + a.y * b.y`
// 5. cross-module call mirror: `result == math.lerp(a.x, b.x, t)`
// 6. component non-negativity on result fields (abs)
// 7. result-field bounds against every parameter field (min/max component)
// 8. non-negative length/distance bounds
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave20_shapes

use xiom.geom;
use xiom.geom.Vec2;
use xiom.geom.Vec3;
use xiom.geom.Vec4;
use xiom.math;

// Shapes 1-3: component-wise mirrors.
fn s_add2(a: Vec2, b: Vec2) -> Vec2
  ensures: result.x == a.x + b.x && result.y == a.y + b.y
{
  return geom.vec2_add(a, b);
}

fn s_mul3(a: Vec3, b: Vec3) -> Vec3
  ensures: result.x == a.x * b.x && result.y == a.y * b.y && result.z == a.z * b.z
{
  return geom.vec3_mul(a, b);
}

fn s_neg4(v: Vec4) -> Vec4
  ensures: result.x == -v.x && result.y == -v.y && result.z == -v.z && result.w == -v.w
{
  return geom.vec4_neg(v);
}

// Shape 4: scalar mirrored expression.
fn s_dot(a: Vec2, b: Vec2) -> Float64
  ensures: result == a.x * b.x + a.y * b.y
{
  return geom.vec2_dot(a, b);
}

// Shape 5: cross-module call mirror.
fn s_lerp(a: Vec2, b: Vec2, t: Float64) -> Float64
  ensures: result == math.lerp(a.x, b.x, t)
{
  return geom.vec2_lerp(a, b, t);
}

// Shape 6: component non-negativity.
fn s_abs(v: Vec4) -> Vec4
  ensures: result.x >= 0.0 && result.y >= 0.0 && result.z >= 0.0 && result.w >= 0.0
{
  return geom.vec4_abs(v);
}

// Shape 7: bounds against every parameter field.
fn s_min(v: Vec4) -> Float64
  ensures: result <= v.x && result <= v.y && result <= v.z && result <= v.w
{
  return geom.vec4_min_component(v);
}

// Shape 8: non-negative length.
fn s_len(v: Vec3) -> Float64
  ensures: result >= 0.0
{
  return geom.vec3_length(v);
}

fn main() -> Int {
  let a = geom.vec2_new(1.0, 2.0);
  let b = geom.vec2_new(3.0, 4.0);
  let s = geom.vec2_add(a, b);
  if s.x != 4.0 || s.y != 6.0 { return 1; }
  let d = geom.vec2_dot(a, b);
  if d != 11.0 { return 2; }
  let l = geom.vec2_lerp(a, b, 0.5);
  if l != 2.0 { return 3; }

  let v3 = geom.vec3_new(1.0, 2.0, 3.0);
  let w3 = geom.vec3_new(4.0, 5.0, 6.0);
  let m3 = geom.vec3_mul(v3, w3);
  if m3.x != 4.0 || m3.z != 18.0 { return 4; }
  let c3 = geom.vec3_cross(v3, w3);
  if c3.x != -3.0 || c3.y != 6.0 || c3.z != -3.0 { return 5; }
  let l3 = geom.vec3_length(geom.vec3_new(3.0, 4.0, 0.0));
  if l3 < 0.0 { return 6; }

  let v4 = geom.vec4_new(-1.0, 2.0, -3.0, 4.0);
  let ab = geom.vec4_abs(v4);
  if ab.x < 0.0 || ab.z < 0.0 { return 7; }
  let mn = geom.vec4_min_component(v4);
  if mn > v4.x || mn > v4.y || mn > v4.z || mn > v4.w { return 8; }
  let ng = geom.vec4_neg(v4);
  if ng.x != 1.0 || ng.z != 3.0 { return 9; }
  return 0;
}

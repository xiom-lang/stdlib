// XIOM - Geom: Vec
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the vector domain; the canonical Vec2/3/4
// types and operations live in geom.xi.

module xiom.geom.vec

// Depends on: xiom.geom

// ============================================================================
// Vector operations split from geom.xi: construction, arithmetic, projections,
// reflections, angles. TODO(compiler): implement.
// ============================================================================

// fn vec2(x: Float64, y: Float64) -> Vec2 - construct a 2D vector (home: geom.vec2_new).
// fn vec2_add(a: Vec2, b: Vec2) -> Vec2 - component-wise addition.
// fn vec2_sub(a: Vec2, b: Vec2) -> Vec2 - component-wise subtraction.
// fn vec2_scale(v: Vec2, s: Float64) -> Vec2 - multiply each component by scalar s.
// fn vec2_dot(a: Vec2, b: Vec2) -> Float64 - dot product.
// fn vec2_cross(a: Vec2, b: Vec2) -> Float64 - scalar cross product (signed area).
// fn vec2_len(v: Vec2) -> Float64 - Euclidean length.
// fn vec2_norm(v: Vec2) -> Vec2 - unit vector; zero vector if length is zero.
// fn vec2_dist(a: Vec2, b: Vec2) -> Float64 - Euclidean distance.
// fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Vec2 - linear interpolation.
// fn vec3_new(x: Float64, y: Float64, z: Float64) -> Vec3 - construct a 3D vector.
// fn vec3_add(a: Vec3, b: Vec3) -> Vec3 - component-wise addition.
// fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 - component-wise subtraction.
// fn vec3_scale(v: Vec3, s: Float64) -> Vec3 - multiply each component by scalar s.
// fn vec3_dot(a: Vec3, b: Vec3) -> Float64 - dot product.
// fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 - right-handed cross product.
// fn vec3_len(v: Vec3) -> Float64 - Euclidean length.
// fn vec3_norm(v: Vec3) -> Vec3 - unit vector; zero vector if length is zero.
// fn vec3_dist(a: Vec3, b: Vec3) -> Float64 - Euclidean distance.
// fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 - construct a 4D vector.
// fn vec4_add(a: Vec4, b: Vec4) -> Vec4 - component-wise addition.
// fn vec4_sub(a: Vec4, b: Vec4) -> Vec4 - component-wise subtraction.
// fn vec4_scale(v: Vec4, s: Float64) -> Vec4 - multiply each component by scalar s.
// fn vec4_dot(a: Vec4, b: Vec4) -> Float64 - dot product.
// fn vec4_len(v: Vec4) -> Float64 - Euclidean length.
// fn vec4_norm(v: Vec4) -> Vec4 - unit vector; zero vector if length is zero.
// fn vec_reflect(v: &Vec[Float64], n: &Vec[Float64]) -> Vec[Float64] - reflect v about unit normal n: v - 2*dot(v,n)*n.
// fn vec_project(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - scalar projection of a onto b.
// fn vec_angle(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - angle in radians between a and b.

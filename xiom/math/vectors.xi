// XIOM - Math: Vectors
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.vectors

// Depends on: xiom.math

// ============================================================================
// Fixed-size 2/3/4 component vectors and generic dynamic vectors. TODO(compiler): implement.
// ============================================================================

// type Vec2 - 2-component vector; struct { x: Float64; y: Float64 }.
// fn vec2_new(x: Float64, y: Float64) -> Vec2 - construct a 2D vector.
// fn vec2_add(a: Vec2, b: Vec2) -> Vec2 - component-wise addition.
// fn vec2_sub(a: Vec2, b: Vec2) -> Vec2 - component-wise subtraction.
// fn vec2_scale(v: Vec2, s: Float64) -> Vec2 - multiply each component by scalar s.
// fn vec2_dot(a: Vec2, b: Vec2) -> Float64 - dot product.
// fn vec2_len(v: Vec2) -> Float64 - Euclidean length.
// fn vec2_norm(v: Vec2) -> Vec2 - unit vector; zero vector if length is zero.
// fn vec2_dist(a: Vec2, b: Vec2) -> Float64 - Euclidean distance between a and b.
// fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Vec2 - component-wise linear interpolation.
// type Vec3 - 3-component vector; struct { x: Float64; y: Float64; z: Float64 }.
// fn vec3_new(x: Float64, y: Float64, z: Float64) -> Vec3 - construct a 3D vector.
// fn vec3_add(a: Vec3, b: Vec3) -> Vec3 - component-wise addition.
// fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 - component-wise subtraction.
// fn vec3_scale(v: Vec3, s: Float64) -> Vec3 - multiply each component by scalar s.
// fn vec3_dot(a: Vec3, b: Vec3) -> Float64 - dot product.
// fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 - right-handed cross product.
// fn vec3_len(v: Vec3) -> Float64 - Euclidean length.
// fn vec3_norm(v: Vec3) -> Vec3 - unit vector; zero vector if length is zero.
// type Vec4 - 4-component vector; struct { x: Float64; y: Float64; z: Float64; w: Float64 }.
// fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 - construct a 4D vector.
// fn vec4_add(a: Vec4, b: Vec4) -> Vec4 - component-wise addition.
// fn vec4_sub(a: Vec4, b: Vec4) -> Vec4 - component-wise subtraction.
// fn vec4_scale(v: Vec4, s: Float64) -> Vec4 - multiply each component by scalar s.
// fn vec4_dot(a: Vec4, b: Vec4) -> Float64 - dot product.
// fn vec4_len(v: Vec4) -> Float64 - Euclidean length.
// fn vec4_norm(v: Vec4) -> Vec4 - unit vector; zero vector if length is zero.
// fn vec_dot(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - dot product of equal-length dynamic vectors.
// fn vec_norm(v: &Vec[Float64]) -> Float64 - Euclidean length of a dynamic vector.
// fn vec_scale(v: &Vec[Float64], s: Float64) -> Vec[Float64] - multiply each component of v by scalar s.

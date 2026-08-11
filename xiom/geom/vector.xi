// XIOM - Geom: Vector
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.vector

// Depends on: xiom.geom

// ============================================================================
// Vector types and generic vector algebra. NOTE: current implementation lives
// in geom.xi REAL Vec2/3/4 + math/vectors.xi stub - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Vec2 - 2-component vector; struct { x: Float64; y: Float64 }.
// type Vec3 - 3-component vector; struct { x: Float64; y: Float64; z: Float64 }.
// type Vec4 - 4-component vector; struct { x: Float64; y: Float64; z: Float64; w: Float64 }.
// type VecN - dynamic vector; struct { data: Vec[Float64] }.
// fn v2_new(x: Float64, y: Float64) -> Vec2 - construct a 2D vector. TODO(compiler): implement.
// fn v3_new(x: Float64, y: Float64, z: Float64) -> Vec3 - construct a 3D vector. TODO(compiler): implement.
// fn v4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 - construct a 4D vector. TODO(compiler): implement.
// fn dot(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - dot product of equal-length vectors. TODO(compiler): implement.
// fn cross(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - 3D cross product. TODO(compiler): implement.
// fn cross2(a: Vec2, b: Vec2) -> Float64 - 2D cross product (signed area). TODO(compiler): implement.
// fn outer(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Vec[Float64]] - outer product matrix. TODO(compiler): implement.
// fn norm(v: &Vec[Float64]) -> Float64 - Euclidean length. TODO(compiler): implement.
// fn norm_sq(v: &Vec[Float64]) -> Float64 - squared Euclidean length. TODO(compiler): implement.
// fn normalize(v: &Vec[Float64]) -> Vec[Float64] - unit vector; zero vector if length is zero. TODO(compiler): implement.
// fn unit(v: &Vec[Float64]) -> Vec[Float64] - alias of normalize. TODO(compiler): implement.
// fn distance(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - Euclidean distance. TODO(compiler): implement.
// fn distance_sq(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - squared Euclidean distance. TODO(compiler): implement.
// fn angle(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - angle in radians between vectors. TODO(compiler): implement.
// fn project(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - projection of a onto b. TODO(compiler): implement.
// fn reject(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - component of a perpendicular to b. TODO(compiler): implement.
// fn lerp(a: &Vec[Float64], b: &Vec[Float64], t: Float64) -> Vec[Float64] - linear interpolation. TODO(compiler): implement.
// fn slerp(a: &Vec[Float64], b: &Vec[Float64], t: Float64) -> Vec[Float64] - spherical linear interpolation. TODO(compiler): implement.
// fn reflect(v: &Vec[Float64], normal: &Vec[Float64]) -> Vec[Float64] - reflect v about normal. TODO(compiler): implement.
// fn refract(v: &Vec[Float64], normal: &Vec[Float64], eta: Float64) -> Option[Vec[Float64]] - refract across an interface. TODO(compiler): implement.
// fn clamp(v: &Vec[Float64], lo: Float64, hi: Float64) -> Vec[Float64] - clamp each component. TODO(compiler): implement.
// fn component_min(v: &Vec[Float64]) -> Float64 - smallest component. TODO(compiler): implement.
// fn component_max(v: &Vec[Float64]) -> Float64 - largest component. TODO(compiler): implement.
// fn hadamard(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - component-wise product. TODO(compiler): implement.

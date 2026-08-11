// XIOM - Geom: Quat
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the quaternion domain; the canonical
// Quaternion type and operations live in geom.xi.

module xiom.geom.quat

// Depends on: xiom.geom

// ============================================================================
// Quaternion rotation algebra split from geom.xi. TODO(compiler): implement.
// ============================================================================

// type Quat - quaternion; struct { x: Float64; y: Float64; z: Float64; w: Float64 }, w is the scalar part.
// fn quat_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Quat - construct from components.
// fn quat_identity() -> Quat - identity quaternion (0, 0, 0, 1).
// fn quat_mul(a: Quat, b: Quat) -> Quat - Hamilton product, composing rotations.
// fn quat_conjugate(q: Quat) -> Quat - negate the vector part.
// fn quat_inv(q: Quat) -> Quat - inverse of a unit quaternion (the conjugate).
// fn quat_norm(q: Quat) -> Float64 - Euclidean length of the quaternion.
// fn quat_normalize(q: Quat) -> Quat - unit quaternion; identity if length is zero.
// fn quat_from_axis_angle(axis: &Vec[Float64], angle: Float64) -> Quat - quaternion rotating angle radians about axis.
// fn quat_to_euler(q: Quat) -> (Float64, Float64, Float64) - tuple is (yaw, pitch, roll) in radians.
// fn quat_slerp(a: Quat, b: Quat, t: Float64) -> Quat - spherical linear interpolation with constant angular velocity.
// fn quat_rotate(q: Quat, v: &Vec[Float64]) -> Vec[Float64] - rotate vector v by quaternion q.

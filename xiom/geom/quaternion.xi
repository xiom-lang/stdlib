// XIOM - Geom: Quaternion
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.quaternion

// Depends on: xiom.geom

// ============================================================================
// Quaternion rotation algebra: construction, composition, and interpolation.
// NOTE: current implementation lives in geom.xi REAL Quat + geom/quat.xi stub
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type Quat - quaternion; struct { x: Float64; y: Float64; z: Float64; w: Float64 }, w is the scalar part.
// fn quat_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Quat - construct from components. TODO(compiler): implement.
// fn quat_identity() -> Quat - identity quaternion (0, 0, 0, 1). TODO(compiler): implement.
// fn quat_from_axis_angle(axis: &Vec[Float64], angle: Float64) -> Quat - quaternion rotating angle about axis. TODO(compiler): implement.
// fn quat_from_euler(yaw: Float64, pitch: Float64, roll: Float64) -> Quat - quaternion from ZYX Euler angles. TODO(compiler): implement.
// fn quat_from_rotation_matrix(m: &Vec[Vec[Float64]]) -> Quat - quaternion equivalent of a rotation matrix. TODO(compiler): implement.
// fn quat_to_matrix(q: Quat) -> Vec[Vec[Float64]] - 3x3 rotation matrix from q. TODO(compiler): implement.
// fn quat_to_euler(q: Quat) -> (Float64, Float64, Float64) - tuple is (yaw, pitch, roll) in radians. TODO(compiler): implement.
// fn quat_mul(a: Quat, b: Quat) -> Quat - Hamilton product, composing rotations. TODO(compiler): implement.
// fn quat_conj(q: Quat) -> Quat - negate the vector part. TODO(compiler): implement.
// fn quat_inv(q: Quat) -> Quat - inverse of a unit quaternion (the conjugate). TODO(compiler): implement.
// fn quat_norm(q: Quat) -> Float64 - Euclidean length of the quaternion. TODO(compiler): implement.
// fn quat_normalize(q: Quat) -> Quat - unit quaternion; identity if length is zero. TODO(compiler): implement.
// fn quat_rotate(q: Quat, v: &Vec[Float64]) -> Vec[Float64] - rotate vector v by quaternion q. TODO(compiler): implement.
// fn quat_slerp(a: Quat, b: Quat, t: Float64) -> Quat - spherical linear interpolation. TODO(compiler): implement.
// fn quat_nlerp(a: Quat, b: Quat, t: Float64) -> Quat - normalized linear interpolation. TODO(compiler): implement.
// fn quat_angle(q: Quat) -> Float64 - rotation angle in radians. TODO(compiler): implement.
// fn quat_axis(q: Quat) -> Vec[Float64] - unit rotation axis of q. TODO(compiler): implement.
// fn quat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Quat - orientation looking from eye to target. TODO(compiler): implement.
// fn quat_between(a: &Vec[Float64], b: &Vec[Float64]) -> Quat - shortest rotation mapping a onto b. TODO(compiler): implement.

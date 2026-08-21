// XIOM -- 2D/3D Geometry Library (vectors, matrices, quaternions, primitives)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom

use xiom.geom.vector;
use xiom.geom.matrix;
use xiom.geom.quaternion;
use xiom.geom.linear;
use xiom.geom.geometry_2d;
use xiom.geom.geometry_3d;
use xiom.geom.geometry_extended;

use xiom.geom.vec;
use xiom.geom.mat;
use xiom.geom.quat;
use xiom.geom.collision;
use xiom.geom.curves;
use xiom.geom.polyhedra;

use xiom.math;

// ============================================================================
// Types -- 2D/3D vector, matrix, quaternion, and primitive types
// ============================================================================

// 2-component vector (x, y) -- used for 2D positions, directions, UVs.
pub type Vec2 = { x: Float64; y: Float64; }

// 3-component vector (x, y, z) -- core 3D math type.
pub type Vec3 = { x: Float64; y: Float64; z: Float64; }

// 4-component vector (x, y, z, w) -- homogeneous coords, RGBA colours.
pub type Vec4 = { x: Float64; y: Float64; z: Float64; w: Float64; }

// Quaternion (x, y, z, w) -- rotation representation; w is the scalar part.
pub type Quaternion = { x: Float64; y: Float64; z: Float64; w: Float64; }

// 2x2 column-major matrix.
pub type Mat2 = { m00: Float64; m01: Float64; m10: Float64; m11: Float64; }

// 3x3 column-major matrix.
pub type Mat3 = {
  m00: Float64; m01: Float64; m02: Float64;
  m10: Float64; m11: Float64; m12: Float64;
  m20: Float64; m21: Float64; m22: Float64;
}

// 4x4 column-major matrix -- core 3D transform type.
pub type Mat4 = {
  m00: Float64; m01: Float64; m02: Float64; m03: Float64;
  m10: Float64; m11: Float64; m12: Float64; m13: Float64;
  m20: Float64; m21: Float64; m22: Float64; m23: Float64;
  m30: Float64; m31: Float64; m32: Float64; m33: Float64;
}

// Axis-aligned bounding box defined by min and max corners.
pub type Aabb = { min: Vec3; max: Vec3; }

// Sphere primitive defined by centre point and radius.
pub type Sphere = { center: Vec3; radius: Float64; }

// Ray primitive: infinite line from origin along dir.
// dir should be normalised for consistent t values.
pub type Ray = { origin: Vec3; dir: Vec3; }

// ============================================================================
// Vec2 -- construction and arithmetic
// ============================================================================

// Create a new 2D vector.
pub fn vec2_new(x: Float64, y: Float64) -> Vec2 {
  return Vec2{ x: x; y: y; };
}

// Add two 2D vectors component-wise. O(1).
pub fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x + b.x; y: a.y + b.y; };
}

// Subtract b from a component-wise. O(1).
pub fn vec2_sub(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x - b.x; y: a.y - b.y; };
}

// Multiply two 2D vectors component-wise. O(1).
pub fn vec2_mul(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x * b.x; y: a.y * b.y; };
}

// Divide a by b component-wise. O(1).
pub fn vec2_div(a: Vec2, b: Vec2) -> Vec2 {
  return Vec2{ x: a.x / b.x; y: a.y / b.y; };
}

// Add scalar s to each component of v. O(1).
pub fn vec2_add_scalar(v: Vec2, s: Float64) -> Vec2 {
  return Vec2{ x: v.x + s; y: v.y + s; };
}

// Subtract scalar s from each component of v. O(1).
pub fn vec2_sub_scalar(v: Vec2, s: Float64) -> Vec2 {
  return Vec2{ x: v.x - s; y: v.y - s; };
}

// Multiply each component of v by scalar s. O(1).
pub fn vec2_mul_scalar(v: Vec2, s: Float64) -> Vec2 {
  return Vec2{ x: v.x * s; y: v.y * s; };
}

// Divide each component of v by scalar s. O(1).
pub fn vec2_div_scalar(v: Vec2, s: Float64) -> Vec2 {
  return Vec2{ x: v.x / s; y: v.y / s; };
}

// Dot product of two 2D vectors. O(1).
pub fn vec2_dot(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.x + a.y * b.y;
}

// 2D cross product (scalar): a.x * b.y - a.y * b.x. O(1).
// This is the signed area of the parallelogram spanned by a and b.
pub fn vec2_cross(a: Vec2, b: Vec2) -> Float64 {
  return a.x * b.y - a.y * b.x;
}

// Euclidean length (magnitude) of v. O(1).
pub fn vec2_length(v: Vec2) -> Float64 {
  return math.sqrt(v.x * v.x + v.y * v.y);
}

// Normalise v to unit length. Returns zero vector if length is zero. O(1).
pub fn vec2_normalize(v: Vec2) -> Vec2 {
  var len = vec2_length(v);
  if len == 0.0 { return Vec2{ x: 0.0; y: 0.0; }; }
  return Vec2{ x: v.x / len; y: v.y / len; };
}

// Euclidean distance between two 2D points. O(1).
pub fn vec2_distance(a: Vec2, b: Vec2) -> Float64 {
  return vec2_length(vec2_sub(a, b));
}

// Linearly interpolate between a and b by t. t=0 -> a, t=1 -> b. O(1).
pub fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Float64 {
  return math.lerp(a.x, b.x, t);
}

// ============================================================================
// Vec3 -- construction and arithmetic
// ============================================================================

// Create a new 3D vector.
pub fn vec3_new(x: Float64, y: Float64, z: Float64) -> Vec3 {
  return Vec3{ x: x; y: y; z: z; };
}

// Add two 3D vectors component-wise. O(1).
pub fn vec3_add(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x + b.x; y: a.y + b.y; z: a.z + b.z; };
}

// Subtract b from a component-wise. O(1).
pub fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x - b.x; y: a.y - b.y; z: a.z - b.z; };
}

// Multiply two 3D vectors component-wise (Hadamard product). O(1).
pub fn vec3_mul(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x * b.x; y: a.y * b.y; z: a.z * b.z; };
}

// Divide a by b component-wise. O(1).
pub fn vec3_div(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{ x: a.x / b.x; y: a.y / b.y; z: a.z / b.z; };
}

// Add scalar s to each component of v. O(1).
pub fn vec3_add_scalar(v: Vec3, s: Float64) -> Vec3 {
  return Vec3{ x: v.x + s; y: v.y + s; z: v.z + s; };
}

// Subtract scalar s from each component of v. O(1).
pub fn vec3_sub_scalar(v: Vec3, s: Float64) -> Vec3 {
  return Vec3{ x: v.x - s; y: v.y - s; z: v.z - s; };
}

// Multiply each component of v by scalar s. O(1).
pub fn vec3_mul_scalar(v: Vec3, s: Float64) -> Vec3 {
  return Vec3{ x: v.x * s; y: v.y * s; z: v.z * s; };
}

// Divide each component of v by scalar s. O(1).
pub fn vec3_div_scalar(v: Vec3, s: Float64) -> Vec3 {
  return Vec3{ x: v.x / s; y: v.y / s; z: v.z / s; };
}

// Dot product of two 3D vectors. O(1).
pub fn vec3_dot(a: Vec3, b: Vec3) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

// 3D cross product: a x b (right-handed). O(1).
pub fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 {
  return Vec3{
    x: a.y * b.z - a.z * b.y;
    y: a.z * b.x - a.x * b.z;
    z: a.x * b.y - a.y * b.x;
  };
}

// Euclidean length (magnitude) of v. O(1).
pub fn vec3_length(v: Vec3) -> Float64 {
  return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

// Normalise v to unit length. Returns zero vector if length is zero. O(1).
pub fn vec3_normalize(v: Vec3) -> Vec3 {
  var len = vec3_length(v);
  if len == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  return Vec3{ x: v.x / len; y: v.y / len; z: v.z / len; };
}

// Euclidean distance between two 3D points. O(1).
pub fn vec3_distance(a: Vec3, b: Vec3) -> Float64 {
  return vec3_length(vec3_sub(a, b));
}

// Linearly interpolate each component between a and b by t. O(1).
pub fn vec3_lerp(a: Vec3, b: Vec3, t: Float64) -> Vec3 {
  // clamp t for robustness
  var ct = t;
  if ct < 0.0 { ct = 0.0; };
  if ct > 1.0 { ct = 1.0; };
  return Vec3{
    x: a.x + (b.x - a.x) * ct;
    y: a.y + (b.y - a.y) * ct;
    z: a.z + (b.z - a.z) * ct;
  };
}

// ============================================================================
// Vec4 -- construction
// ============================================================================

// Create a new 4D vector.
pub fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 {
  return Vec4{ x: x; y: y; z: z; w: w; };
}

// ============================================================================
// Quaternion -- construction and operations
// ============================================================================

// Identity quaternion (no rotation). O(1).
pub fn quat_identity() -> Quaternion {
  return Quaternion{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
}

// Create a quaternion from an axis (must be normalised) and an angle (radians).
// Rotation is right-handed around the axis. O(1).
pub fn quat_new(axis: Vec3, angle: Float64) -> Quaternion {
  var half = angle * 0.5;
  var s = math.sin(half);
  return Quaternion{
    x: axis.x * s;
    y: axis.y * s;
    z: axis.z * s;
    w: math.cos(half);
  };
}

// Multiply two quaternions q1 * q2 (compose rotations, q2 applied first). O(1).
// Hamilton product: (w1w2 - v1-v2, w1v2 + w2v1 + v1xv2)
pub fn quat_mul(a: Quaternion, b: Quaternion) -> Quaternion {
  return Quaternion{
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y;
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x;
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w;
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z;
  };
}

// Normalise a quaternion to unit length. If length is zero, returns identity. O(1).
pub fn quat_normalize(q: Quaternion) -> Quaternion {
  var len = math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
  if len == 0.0 { return quat_identity(); }
  return Quaternion{
    x: q.x / len; y: q.y / len; z: q.z / len; w: q.w / len;
  };
}

// Conjugate of a quaternion. For unit quaternions this is the inverse. O(1).
pub fn quat_conjugate(q: Quaternion) -> Quaternion {
  return Quaternion{ x: -q.x; y: -q.y; z: -q.z; w: q.w; };
}

// Rotate a 3D vector by quaternion q (q must be normalised). O(1).
// Returns: v + 2.0 * q.xyz x (q.xyz x v + q.w * v)
pub fn quat_rotate_vec3(q: Quaternion, v: Vec3) -> Vec3 {
  var qv = Vec3{ x: q.x; y: q.y; z: q.z; };
  var t = vec3_mul_scalar(vec3_cross(qv, v), 2.0);
  var u = vec3_cross(qv, t);
  var w_term = vec3_mul_scalar(t, q.w); // already w * t = q.w * 2 * cross(qv,v)
  // Correct: v' = v + 2*(q.w*(qvxv) + qvx(qvxv))
  return vec3_add(v, vec3_mul_scalar(vec3_add(vec3_mul_scalar(vec3_cross(qv, v), q.w), vec3_cross(qv, vec3_cross(qv, v))), 2.0));
}

// Create a quaternion from Euler angles (ZYX intrinsic = yaw-pitch-roll in radians).
// yaw: rotation around Z, pitch: around Y, roll: around X.
pub fn quat_from_euler(yaw: Float64, pitch: Float64, roll: Float64) -> Quaternion {
  var cy = math.cos(yaw * 0.5);
  var sy = math.sin(yaw * 0.5);
  var cp = math.cos(pitch * 0.5);
  var sp = math.sin(pitch * 0.5);
  var cr = math.cos(roll * 0.5);
  var sr = math.sin(roll * 0.5);
  return Quaternion{
    w: cy * cp * cr + sy * sp * sr;
    x: cy * cp * sr - sy * sp * cr;
    y: sy * cp * sr + cy * sp * cr;
    z: sy * cp * cr - cy * sp * sr;
  };
}

// ============================================================================
// Mat4 -- 4x4 transform matrices (column-major)
// ============================================================================

// 4x4 identity matrix. O(1).
pub fn mat4_identity() -> Mat4 {
  return Mat4{
    m00: 1.0; m01: 0.0; m02: 0.0; m03: 0.0;
    m10: 0.0; m11: 1.0; m12: 0.0; m13: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0; m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Multiply two 4x4 matrices: a * b. Row x column dot products. O(64 ops).
pub fn mat4_mul(a: Mat4, b: Mat4) -> Mat4 {
  return Mat4{
    m00: a.m00 * b.m00 + a.m01 * b.m10 + a.m02 * b.m20 + a.m03 * b.m30;
    m01: a.m00 * b.m01 + a.m01 * b.m11 + a.m02 * b.m21 + a.m03 * b.m31;
    m02: a.m00 * b.m02 + a.m01 * b.m12 + a.m02 * b.m22 + a.m03 * b.m32;
    m03: a.m00 * b.m03 + a.m01 * b.m13 + a.m02 * b.m23 + a.m03 * b.m33;
    m10: a.m10 * b.m00 + a.m11 * b.m10 + a.m12 * b.m20 + a.m13 * b.m30;
    m11: a.m10 * b.m01 + a.m11 * b.m11 + a.m12 * b.m21 + a.m13 * b.m31;
    m12: a.m10 * b.m02 + a.m11 * b.m12 + a.m12 * b.m22 + a.m13 * b.m32;
    m13: a.m10 * b.m03 + a.m11 * b.m13 + a.m12 * b.m23 + a.m13 * b.m33;
    m20: a.m20 * b.m00 + a.m21 * b.m10 + a.m22 * b.m20 + a.m23 * b.m30;
    m21: a.m20 * b.m01 + a.m21 * b.m11 + a.m22 * b.m21 + a.m23 * b.m31;
    m22: a.m20 * b.m02 + a.m21 * b.m12 + a.m22 * b.m22 + a.m23 * b.m32;
    m23: a.m20 * b.m03 + a.m21 * b.m13 + a.m22 * b.m23 + a.m23 * b.m33;
    m30: a.m30 * b.m00 + a.m31 * b.m10 + a.m32 * b.m20 + a.m33 * b.m30;
    m31: a.m30 * b.m01 + a.m31 * b.m11 + a.m32 * b.m21 + a.m33 * b.m31;
    m32: a.m30 * b.m02 + a.m31 * b.m12 + a.m32 * b.m22 + a.m33 * b.m32;
    m33: a.m30 * b.m03 + a.m31 * b.m13 + a.m32 * b.m23 + a.m33 * b.m33;
  };
}

// Translation matrix. O(1).
pub fn mat4_translate(tx: Float64, ty: Float64, tz: Float64) -> Mat4 {
  return Mat4{
    m00: 1.0; m01: 0.0; m02: 0.0; m03: tx;
    m10: 0.0; m11: 1.0; m12: 0.0; m13: ty;
    m20: 0.0; m21: 0.0; m22: 1.0; m23: tz;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Scale matrix (non-uniform). O(1).
pub fn mat4_scale(sx: Float64, sy: Float64, sz: Float64) -> Mat4 {
  return Mat4{
    m00: sx;  m01: 0.0; m02: 0.0; m03: 0.0;
    m10: 0.0; m11: sy;  m12: 0.0; m13: 0.0;
    m20: 0.0; m21: 0.0; m22: sz;  m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Rotation around X axis by angle radians (right-handed). O(1).
pub fn mat4_rotate_x(angle: Float64) -> Mat4 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat4{
    m00: 1.0; m01: 0.0; m02: 0.0; m03: 0.0;
    m10: 0.0; m11: c;   m12: -s;  m13: 0.0;
    m20: 0.0; m21: s;   m22: c;   m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Rotation around Y axis by angle radians (right-handed). O(1).
pub fn mat4_rotate_y(angle: Float64) -> Mat4 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat4{
    m00: c;   m01: 0.0; m02: s;   m03: 0.0;
    m10: 0.0; m11: 1.0; m12: 0.0; m13: 0.0;
    m20: -s;  m21: 0.0; m22: c;   m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Rotation around Z axis by angle radians (right-handed). O(1).
pub fn mat4_rotate_z(angle: Float64) -> Mat4 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat4{
    m00: c;   m01: -s;  m02: 0.0; m03: 0.0;
    m10: s;   m11: c;   m12: 0.0; m13: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0; m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Perspective projection matrix (right-handed, reverse Z [-1,1] NDC).
// fov: vertical field of view in radians, aspect: width/height,
// near/far: clipping planes. O(1).
pub fn mat4_perspective(fov: Float64, aspect: Float64, near: Float64, far: Float64) -> Mat4 {
  var f = 1.0 / math.tan(fov * 0.5);
  var nf = 1.0 / (near - far);
  return Mat4{
    m00: f / aspect; m01: 0.0; m02: 0.0;           m03: 0.0;
    m10: 0.0;        m11: f;   m12: 0.0;           m13: 0.0;
    m20: 0.0;        m21: 0.0; m22: (far + near) * nf; m23: (2.0 * far * near) * nf;
    m30: 0.0;        m31: 0.0; m32: -1.0;          m33: 0.0;
  };
}

// Look-at view matrix: camera at eye, looking at target, with up vector.
// Right-handed coordinate system. O(1).
pub fn mat4_look_at(eye: Vec3, target: Vec3, up: Vec3) -> Mat4 {
  var f = vec3_normalize(vec3_sub(target, eye));
  var r = vec3_normalize(vec3_cross(f, up));
  var u = vec3_cross(r, f);
  return Mat4{
    m00: r.x;  m01: r.y;  m02: r.z;  m03: -vec3_dot(r, eye);
    m10: u.x;  m11: u.y;  m12: u.z;  m13: -vec3_dot(u, eye);
    m20: -f.x; m21: -f.y; m22: -f.z; m23: vec3_dot(f, eye);
    m30: 0.0;  m31: 0.0;  m32: 0.0;  m33: 1.0;
  };
}

// Transform a Vec3 point by a 4x4 matrix (x,y,z,1 homogeneous). O(16 ops).
pub fn mat4_transform_vec3(m: Mat4, v: Vec3) -> Vec3 {
  var w = m.m30 * v.x + m.m31 * v.y + m.m32 * v.z + m.m33;
  if w == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  return Vec3{
    x: (m.m00 * v.x + m.m01 * v.y + m.m02 * v.z + m.m03) / w;
    y: (m.m10 * v.x + m.m11 * v.y + m.m12 * v.z + m.m13) / w;
    z: (m.m20 * v.x + m.m21 * v.y + m.m22 * v.z + m.m23) / w;
  };
}

// ============================================================================
// Mat3 -- 3x3 matrices (column-major)
// ============================================================================

// 3x3 identity matrix. O(1).
pub fn mat3_identity() -> Mat3 {
  return Mat3{
    m00: 1.0; m01: 0.0; m02: 0.0;
    m10: 0.0; m11: 1.0; m12: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0;
  };
}

// Multiply two 3x3 matrices: a * b. O(27 ops).
pub fn mat3_mul(a: Mat3, b: Mat3) -> Mat3 {
  return Mat3{
    m00: a.m00 * b.m00 + a.m01 * b.m10 + a.m02 * b.m20;
    m01: a.m00 * b.m01 + a.m01 * b.m11 + a.m02 * b.m21;
    m02: a.m00 * b.m02 + a.m01 * b.m12 + a.m02 * b.m22;
    m10: a.m10 * b.m00 + a.m11 * b.m10 + a.m12 * b.m20;
    m11: a.m10 * b.m01 + a.m11 * b.m11 + a.m12 * b.m21;
    m12: a.m10 * b.m02 + a.m11 * b.m12 + a.m12 * b.m22;
    m20: a.m20 * b.m00 + a.m21 * b.m10 + a.m22 * b.m20;
    m21: a.m20 * b.m01 + a.m21 * b.m11 + a.m22 * b.m21;
    m22: a.m20 * b.m02 + a.m21 * b.m12 + a.m22 * b.m22;
  };
}

// ============================================================================
// Aabb -- axis-aligned bounding box
// ============================================================================

// Create an AABB from min and max corners.
pub fn aabb_new(min: Vec3, max: Vec3) -> Aabb {
  return Aabb{ min: min; max: max; };
}

// Test whether a point is inside the AABB (inclusive). O(1).
pub fn aabb_contains_point(box: Aabb, point: Vec3) -> Bool {
  return point.x >= box.min.x && point.x <= box.max.x
      && point.y >= box.min.y && point.y <= box.max.y
      && point.z >= box.min.z && point.z <= box.max.z;
}

// Test whether two AABBs intersect. O(1).
pub fn aabb_intersects_aabb(a: Aabb, b: Aabb) -> Bool {
  if a.max.x < b.min.x || a.min.x > b.max.x { return false; };
  if a.max.y < b.min.y || a.min.y > b.max.y { return false; };
  if a.max.z < b.min.z || a.min.z > b.max.z { return false; };
  return true;
}

// ============================================================================
// Sphere
// ============================================================================

// Create a sphere from centre and radius.
pub fn sphere_new(center: Vec3, radius: Float64) -> Sphere {
  return Sphere{ center: center; radius: radius; };
}

// Test whether a point is inside the sphere (inclusive). O(1).
pub fn sphere_contains_point(s: Sphere, point: Vec3) -> Bool {
  var d = vec3_distance(s.center, point);
  return d <= s.radius;
}

// ============================================================================
// Ray -- ray casting
// ============================================================================

// Create a ray from origin and direction.
pub fn ray_new(origin: Vec3, dir: Vec3) -> Ray {
  return Ray{ origin: origin; dir: dir; };
}

// Ray-sphere intersection. Returns Some(t) for the nearest hit, or None.
// t is the distance from origin along dir to the intersection point.
// Uses quadratic formula; only returns the smaller positive t. O(1).
pub fn ray_intersect_sphere(r: Ray, s: Sphere) -> Option[Float64] {
  var oc = vec3_sub(r.origin, s.center);
  var a = vec3_dot(r.dir, r.dir);
  var b = 2.0 * vec3_dot(oc, r.dir);
  var c = vec3_dot(oc, oc) - s.radius * s.radius;
  var disc = b * b - 4.0 * a * c;
  if disc < 0.0 {
    return Option[Float64]{ is_some: false; value: 0.0; };
  }
  var sqrt_disc = math.sqrt(disc);
  var t0 = (-b - sqrt_disc) / (2.0 * a);
  var t1 = (-b + sqrt_disc) / (2.0 * a);
  // return smallest positive t
  if t0 > 0.0 { return Option[Float64]{ is_some: true; value: t0; }; }
  if t1 > 0.0 { return Option[Float64]{ is_some: true; value: t1; }; }
  return Option[Float64]{ is_some: false; value: 0.0; };
}

// Ray-AABB intersection (slab method). Returns Some(t_near) for intersection,
// or None if the ray misses the box. O(1).
// See: "An Efficient and Robust Ray-Box Intersection Algorithm" by Williams et al.
pub fn ray_intersect_aabb(r: Ray, box: Aabb) -> Option[Float64] {
  var tmin = (box.min.x - r.origin.x) / r.dir.x;
  var tmax = (box.max.x - r.origin.x) / r.dir.x;
  if tmin > tmax {
    var tmp = tmin; tmin = tmax; tmax = tmp;
  }
  var tymin = (box.min.y - r.origin.y) / r.dir.y;
  var tymax = (box.max.y - r.origin.y) / r.dir.y;
  if tymin > tymax {
    var tmp = tymin; tymin = tymax; tymax = tmp;
  }
  if tmin > tymax || tymin > tmax { return Option[Float64]{ is_some: false; value: 0.0; }; }
  if tymin > tmin { tmin = tymin; }
  if tymax < tmax { tmax = tymax; }
  var tzmin = (box.min.z - r.origin.z) / r.dir.z;
  var tzmax = (box.max.z - r.origin.z) / r.dir.z;
  if tzmin > tzmax {
    var tmp = tzmin; tzmin = tzmax; tzmax = tmp;
  }
  if tmin > tzmax || tzmin > tmax { return Option[Float64]{ is_some: false; value: 0.0; }; }
  if tzmin > tmin { tmin = tzmin; }
  if tzmax < tmax { tmax = tzmax; }
  if tmin < 0.0 { tmin = tmax; }
  if tmin < 0.0 { return Option[Float64]{ is_some: false; value: 0.0; }; }
  return Option[Float64]{ is_some: true; value: tmin; };
}

// ============================================================================
// Vec2 -- component-wise extras, negation, reflection, refraction
// ============================================================================

// Negate a 2D vector (component-wise -v). O(1).
pub fn vec2_neg(v: Vec2) -> Vec2 {
  return Vec2{ x: -v.x; y: -v.y; };
}

// Reflect a 2D incident vector about a surface normal (normal must be unit).
// Formula: i - 2 * dot(i, n) * n. Degenerate (zero) normal returns incident. O(1).
pub fn vec2_reflect(incident: Vec2, normal: Vec2) -> Vec2 {
  var nl = vec2_length(normal);
  if nl == 0.0 { return incident; }
  var n = vec2_div_scalar(normal, nl);
  var d = vec2_dot(incident, n);
  return vec2_sub(incident, vec2_mul_scalar(n, 2.0 * d));
}

// Refract a 2D vector across an interface with relative index eta.
// Returns None on total internal reflection (k < 0). Both vectors should be
// unit length. Formula: eta*i - (eta*dot(i,n) + sqrt(k)) * n, k = 1 - eta2(1 - dot2). O(1).
pub fn vec2_refract(incident: Vec2, normal: Vec2, eta: Float64) -> Option[Vec2] {
  var idotn = vec2_dot(incident, normal);
  var k = 1.0 - eta * eta * (1.0 - idotn * idotn);
  if k < 0.0 {
    return None;
  }
  var rk = math.sqrt(k);
  var scale = eta * idotn + rk;
  var t = vec2_sub(vec2_mul_scalar(incident, eta), vec2_mul_scalar(normal, scale));
  return Some(t);
}

// Project a onto b: b * dot(a,b) / dot(b,b). Returns zero if b is degenerate. O(1).
pub fn vec2_project(a: Vec2, b: Vec2) -> Vec2 {
  var bb = vec2_dot(b, b);
  if bb == 0.0 { return Vec2{ x: 0.0; y: 0.0; }; }
  var s = vec2_dot(a, b) / bb;
  return vec2_mul_scalar(b, s);
}

// Reject a from b: a - project(a,b), the component of a perpendicular to b. O(1).
pub fn vec2_reject(a: Vec2, b: Vec2) -> Vec2 {
  return vec2_sub(a, vec2_project(a, b));
}

// Angle (radians) between two 2D vectors in [0, PI]. Returns 0 if either is zero.
// Uses acos of the clamped dot product of the normalised vectors. O(1).
pub fn vec2_angle_between(a: Vec2, b: Vec2) -> Float64 {
  var la = vec2_length(a);
  var lb = vec2_length(b);
  if la == 0.0 || lb == 0.0 { return 0.0; }
  var c = vec2_dot(a, b) / (la * lb);
  if c > 1.0 { c = 1.0; }
  if c < -1.0 { c = -1.0; }
  return math.acos(c);
}

// Squared Euclidean distance between two 2D points (avoids sqrt). O(1).
pub fn vec2_distance_squared(a: Vec2, b: Vec2) -> Float64 {
  var dx = a.x - b.x;
  var dy = a.y - b.y;
  return dx * dx + dy * dy;
}

// Unclamped linear interpolation between a and b by t (t may leave [0,1]). O(1).
pub fn vec2_lerp_unclamped(a: Vec2, b: Vec2, t: Float64) -> Vec2 {
  return Vec2{
    x: a.x + (b.x - a.x) * t;
    y: a.y + (b.y - a.y) * t;
  };
}

// Normalised linear interpolation (nlerp): lerp then normalise the result. O(1).
// Cheaper than slerp; not constant angular velocity.
pub fn vec2_nlerp(a: Vec2, b: Vec2, t: Float64) -> Vec2 {
  var v = vec2_lerp_unclamped(a, b, t);
  return vec2_normalize(v);
}

// Rotate a 2D vector counter-clockwise by angle (radians) about the origin.
// Formula: (x*cos - y*sin, x*sin + y*cos). O(1).
pub fn vec2_rotate(v: Vec2, angle: Float64) -> Vec2 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Vec2{ x: v.x * c - v.y * s; y: v.x * s + v.y * c; };
}

// Rotate v around an arbitrary center point by angle (radians). O(1).
// Translates to the origin, rotates, then translates back.
pub fn vec2_rotate_around(v: Vec2, center: Vec2, angle: Float64) -> Vec2 {
  var translated = vec2_sub(v, center);
  var rotated = vec2_rotate(translated, angle);
  return vec2_add(rotated, center);
}

// Return a vector perpendicular to v: (-y, x). This is v rotated by +90 degrees. O(1).
pub fn vec2_perpendicular(v: Vec2) -> Vec2 {
  return Vec2{ x: -v.y; y: v.x; };
}

// Unit vector from an angle (radians): (cos(angle), sin(angle)). O(1).
pub fn vec2_from_angle(angle: Float64) -> Vec2 {
  return Vec2{ x: math.cos(angle); y: math.sin(angle); };
}

// True if the length of v is within epsilon of 1.0. O(1).
pub fn vec2_is_unit(v: Vec2, epsilon: Float64) -> Bool {
  return f64_approx_eq(vec2_length(v), 1.0, epsilon);
}

// True if every component of v is exactly zero. O(1).
pub fn vec2_is_zero(v: Vec2) -> Bool {
  return v.x == 0.0 && v.y == 0.0;
}

// True if every corresponding component of a and b differs by at most epsilon. O(1).
pub fn vec2_approx_eq(a: Vec2, b: Vec2, epsilon: Float64) -> Bool {
  return f64_approx_eq(a.x, b.x, epsilon)
      && f64_approx_eq(a.y, b.y, epsilon);
}

// Smallest component of a 2D vector. O(1).
pub fn vec2_min_component(v: Vec2) -> Float64 {
  if v.x < v.y { return v.x; }
  return v.y;
}

// Largest component of a 2D vector. O(1).
pub fn vec2_max_component(v: Vec2) -> Float64 {
  if v.x > v.y { return v.x; }
  return v.y;
}

// Component-wise absolute value of a 2D vector. O(1).
pub fn vec2_abs(v: Vec2) -> Vec2 {
  return Vec2{
    x: math.abs_float(v.x);
    y: math.abs_float(v.y);
  };
}

// Clamp the length of v to max_len. Vectors shorter than max_len are unchanged.
// If max_len <= 0 the zero vector is returned. O(1).
pub fn vec2_clamp_length(v: Vec2, max_len: Float64) -> Vec2 {
  var len = vec2_length(v);
  if len <= max_len { return v; }
  if len == 0.0 { return Vec2{ x: 0.0; y: 0.0; }; }
  return vec2_mul_scalar(v, max_len / len);
}

// ============================================================================
// Vec3 -- negation, reflection, refraction, projection, angle, orthogonals
// ============================================================================

// Negate a 3D vector (component-wise -v). O(1).
pub fn vec3_neg(v: Vec3) -> Vec3 {
  return Vec3{ x: -v.x; y: -v.y; z: -v.z; };
}

// Reflect a 3D incident vector about a surface normal (normal must be unit).
// Formula: i - 2 * dot(i, n) * n. Degenerate (zero) normal returns incident. O(1).
pub fn vec3_reflect(incident: Vec3, normal: Vec3) -> Vec3 {
  var nl = vec3_length(normal);
  if nl == 0.0 { return incident; }
  var n = vec3_div_scalar(normal, nl);
  var d = vec3_dot(incident, n);
  return vec3_sub(incident, vec3_mul_scalar(n, 2.0 * d));
}

// Refract a 3D vector across an interface with relative index eta.
// Returns None on total internal reflection (k < 0). Both vectors should be
// unit length. Formula: eta*i - (eta*dot(i,n) + sqrt(k)) * n, k = 1 - eta2(1 - dot2). O(1).
pub fn vec3_refract(incident: Vec3, normal: Vec3, eta: Float64) -> Option[Vec3] {
  var idotn = vec3_dot(incident, normal);
  var k = 1.0 - eta * eta * (1.0 - idotn * idotn);
  if k < 0.0 {
    return None;
  }
  var rk = math.sqrt(k);
  var scale = eta * idotn + rk;
  var t = vec3_sub(vec3_mul_scalar(incident, eta), vec3_mul_scalar(normal, scale));
  return Some(t);
}

// Project a onto b: b * dot(a,b) / dot(b,b). Returns zero if b is degenerate. O(1).
pub fn vec3_project(a: Vec3, b: Vec3) -> Vec3 {
  var bb = vec3_dot(b, b);
  if bb == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  var s = vec3_dot(a, b) / bb;
  return vec3_mul_scalar(b, s);
}

// Reject a from b: a - project(a,b), the component of a perpendicular to b. O(1).
pub fn vec3_reject(a: Vec3, b: Vec3) -> Vec3 {
  return vec3_sub(a, vec3_project(a, b));
}

// Angle (radians) between two 3D vectors in [0, PI]. Returns 0 if either is zero.
// Uses acos of the clamped dot product of the normalised vectors. O(1).
pub fn vec3_angle_between(a: Vec3, b: Vec3) -> Float64 {
  var la = vec3_length(a);
  var lb = vec3_length(b);
  if la == 0.0 || lb == 0.0 { return 0.0; }
  var c = vec3_dot(a, b) / (la * lb);
  if c > 1.0 { c = 1.0; }
  if c < -1.0 { c = -1.0; }
  return math.acos(c);
}

// Squared Euclidean distance between two 3D points (avoids sqrt). O(1).
pub fn vec3_distance_squared(a: Vec3, b: Vec3) -> Float64 {
  var dx = a.x - b.x;
  var dy = a.y - b.y;
  var dz = a.z - b.z;
  return dx * dx + dy * dy + dz * dz;
}

// Unclamped linear interpolation between a and b by t (t may leave [0,1]). O(1).
// Contrast with vec3_lerp which clamps t into [0,1].
pub fn vec3_lerp_unclamped(a: Vec3, b: Vec3, t: Float64) -> Vec3 {
  return Vec3{
    x: a.x + (b.x - a.x) * t;
    y: a.y + (b.y - a.y) * t;
    z: a.z + (b.z - a.z) * t;
  };
}

// Normalised linear interpolation (nlerp): lerp then normalise the result. O(1).
// Cheaper than slerp; not constant angular velocity.
pub fn vec3_nlerp(a: Vec3, b: Vec3, t: Float64) -> Vec3 {
  var v = vec3_lerp_unclamped(a, b, t);
  return vec3_normalize(v);
}

// Return any vector perpendicular to v (unit length), using the
// smallest-absolute-component zero method to avoid cancellation.
// Returns the zero vector when v is zero. O(1).
pub fn vec3_orthogonal(v: Vec3) -> Vec3 {
  var ax = math.abs_float(v.x);
  var ay = math.abs_float(v.y);
  var az = math.abs_float(v.z);
  if ax <= ay && ax <= az {
    return vec3_normalize(Vec3{ x: 0.0; y: v.z; z: -v.y; });
  }
  if ay <= az {
    return vec3_normalize(Vec3{ x: -v.z; y: 0.0; z: v.x; });
  }
  return vec3_normalize(Vec3{ x: v.y; y: -v.x; z: 0.0; });
}

// True if the length of v is within epsilon of 1.0. O(1).
pub fn vec3_is_unit(v: Vec3, epsilon: Float64) -> Bool {
  return f64_approx_eq(vec3_length(v), 1.0, epsilon);
}

// True if every component of v is exactly zero. O(1).
pub fn vec3_is_zero(v: Vec3) -> Bool {
  return v.x == 0.0 && v.y == 0.0 && v.z == 0.0;
}

// True if every corresponding component of a and b differs by at most epsilon. O(1).
pub fn vec3_approx_eq(a: Vec3, b: Vec3, epsilon: Float64) -> Bool {
  return f64_approx_eq(a.x, b.x, epsilon)
      && f64_approx_eq(a.y, b.y, epsilon)
      && f64_approx_eq(a.z, b.z, epsilon);
}

// Smallest component of a 3D vector. O(1).
pub fn vec3_min_component(v: Vec3) -> Float64 {
  if v.x < v.y && v.x < v.z { return v.x; }
  if v.y < v.z { return v.y; }
  return v.z;
}

// Largest component of a 3D vector. O(1).
pub fn vec3_max_component(v: Vec3) -> Float64 {
  if v.x > v.y && v.x > v.z { return v.x; }
  if v.y > v.z { return v.y; }
  return v.z;
}

// Component-wise absolute value of a 3D vector. O(1).
pub fn vec3_abs(v: Vec3) -> Vec3 {
  return Vec3{
    x: math.abs_float(v.x);
    y: math.abs_float(v.y);
    z: math.abs_float(v.z);
  };
}

// Clamp the length of v to max_len. Vectors shorter than max_len are unchanged.
// If max_len <= 0 the zero vector is returned. O(1).
pub fn vec3_clamp_length(v: Vec3, max_len: Float64) -> Vec3 {
  var len = vec3_length(v);
  if len <= max_len { return v; }
  if len == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  return vec3_mul_scalar(v, max_len / len);
}

// ============================================================================
// Vec4 -- component-wise operations, negation, and conversions
// ============================================================================

// Multiply two 4D vectors component-wise (Hadamard product). O(1).
pub fn vec4_mul_component(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x * b.x; y: a.y * b.y; z: a.z * b.z; w: a.w * b.w; };
}

// Divide a by b component-wise. O(1).
pub fn vec4_div_component(a: Vec4, b: Vec4) -> Vec4 {
  return Vec4{ x: a.x / b.x; y: a.y / b.y; z: a.z / b.z; w: a.w / b.w; };
}

// Multiply each component of v by scalar s. O(1).
pub fn vec4_scale(v: Vec4, s: Float64) -> Vec4 {
  return Vec4{ x: v.x * s; y: v.y * s; z: v.z * s; w: v.w * s; };
}

// Negate a 4D vector (component-wise -v). O(1).
pub fn vec4_neg(v: Vec4) -> Vec4 {
  return Vec4{ x: -v.x; y: -v.y; z: -v.z; w: -v.w; };
}

// True if every corresponding component of a and b differs by at most epsilon. O(1).
pub fn vec4_approx_eq(a: Vec4, b: Vec4, epsilon: Float64) -> Bool {
  return f64_approx_eq(a.x, b.x, epsilon)
      && f64_approx_eq(a.y, b.y, epsilon)
      && f64_approx_eq(a.z, b.z, epsilon)
      && f64_approx_eq(a.w, b.w, epsilon);
}

// Smallest component of a 4D vector. O(1).
pub fn vec4_min_component(v: Vec4) -> Float64 {
  var m = v.x;
  if v.y < m { m = v.y; }
  if v.z < m { m = v.z; }
  if v.w < m { m = v.w; }
  return m;
}

// Largest component of a 4D vector. O(1).
pub fn vec4_max_component(v: Vec4) -> Float64 {
  var m = v.x;
  if v.y > m { m = v.y; }
  if v.z > m { m = v.z; }
  if v.w > m { m = v.w; }
  return m;
}

// Component-wise absolute value of a 4D vector. O(1).
pub fn vec4_abs(v: Vec4) -> Vec4 {
  return Vec4{
    x: math.abs_float(v.x);
    y: math.abs_float(v.y);
    z: math.abs_float(v.z);
    w: math.abs_float(v.w);
  };
}

// Drop the w component of a 4D vector to produce a 3D vector. O(1).
pub fn vec3_from_vec4(v: Vec4) -> Vec3 {
  return Vec3{ x: v.x; y: v.y; z: v.z; };
}

// Build a 4D vector from a 3D vector plus an explicit w component. O(1).
pub fn vec4_from_vec3(v: Vec3, w: Float64) -> Vec4 {
  return Vec4{ x: v.x; y: v.y; z: v.z; w: w; };
}

// ============================================================================
// Mat2 -- 2x2 matrices (column-major)
// ============================================================================

// 2x2 identity matrix. O(1).
pub fn mat2_identity() -> Mat2 {
  return Mat2{
    m00: 1.0; m01: 0.0;
    m10: 0.0; m11: 1.0;
  };
}

// Multiply two 2x2 matrices: a * b. O(8 ops).
pub fn mat2_mul(a: Mat2, b: Mat2) -> Mat2 {
  return Mat2{
    m00: a.m00 * b.m00 + a.m01 * b.m10;
    m01: a.m00 * b.m01 + a.m01 * b.m11;
    m10: a.m10 * b.m00 + a.m11 * b.m10;
    m11: a.m10 * b.m01 + a.m11 * b.m11;
  };
}

// Transpose a 2x2 matrix in place. O(1).
pub fn mat2_transpose(m: Mat2) -> Mat2 {
  return Mat2{
    m00: m.m00; m01: m.m10;
    m10: m.m01; m11: m.m11;
  };
}

// Determinant of a 2x2 matrix: m00*m11 - m01*m10. O(1).
pub fn mat2_determinant(m: Mat2) -> Float64 {
  return m.m00 * m.m11 - m.m01 * m.m10;
}

// Inverse of a 2x2 matrix via the adjugate / determinant formula.
// Returns None when the determinant is (near) zero, so the matrix is singular. O(1).
pub fn mat2_inverse(m: Mat2) -> Option[Mat2] {
  var det = mat2_determinant(m);
  if math.abs_float(det) < 0.000001 * 0.000001 {
    return None;
  }
  var inv_det = 1.0 / det;
  return Some(Mat2{
    m00: m.m11 * inv_det;
    m01: -m.m01 * inv_det;
    m10: -m.m10 * inv_det;
    m11: m.m00 * inv_det;
  });
}

// Uniform 2x2 scale matrix with factor s. O(1).
pub fn mat2_scale(s: Float64) -> Mat2 {
  return Mat2{
    m00: s; m01: 0.0;
    m10: 0.0; m11: s;
  };
}

// 2x2 rotation matrix by angle radians (counter-clockwise). O(1).
pub fn mat2_rotation(angle: Float64) -> Mat2 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat2{
    m00: c; m01: -s;
    m10: s; m11: c;
  };
}

// Transform a 2D vector by a 2x2 matrix: M * v. O(4 ops).
pub fn mat2_transform_vec2(m: Mat2, v: Vec2) -> Vec2 {
  return Vec2{
    x: m.m00 * v.x + m.m01 * v.y;
    y: m.m10 * v.x + m.m11 * v.y;
  };
}

// ============================================================================
// Mat3 -- 3x3 matrices (column-major)
// ============================================================================

// Transpose a 3x3 matrix. O(1).
pub fn mat3_transpose(m: Mat3) -> Mat3 {
  return Mat3{
    m00: m.m00; m01: m.m10; m02: m.m20;
    m10: m.m01; m11: m.m11; m12: m.m21;
    m20: m.m02; m21: m.m12; m22: m.m22;
  };
}

// Determinant of a 3x3 matrix by cofactor expansion along the first row. O(9 ops).
pub fn mat3_determinant(m: Mat3) -> Float64 {
  return m.m00 * (m.m11 * m.m22 - m.m12 * m.m21)
       - m.m01 * (m.m10 * m.m22 - m.m12 * m.m20)
       + m.m02 * (m.m10 * m.m21 - m.m11 * m.m20);
}

// Inverse of a 3x3 matrix via the adjugate / determinant formula.
// Returns None when the determinant is (near) zero, so the matrix is singular. O(27 ops).
pub fn mat3_inverse(m: Mat3) -> Option[Mat3] {
  var det = mat3_determinant(m);
  if math.abs_float(det) < 0.000001 * 0.000001 {
    return None;
  }
  var inv_det = 1.0 / det;
  return Some(Mat3{
    m00: (m.m11 * m.m22 - m.m12 * m.m21) * inv_det;
    m01: (m.m02 * m.m21 - m.m01 * m.m22) * inv_det;
    m02: (m.m01 * m.m12 - m.m02 * m.m11) * inv_det;
    m10: (m.m12 * m.m20 - m.m10 * m.m22) * inv_det;
    m11: (m.m00 * m.m22 - m.m02 * m.m20) * inv_det;
    m12: (m.m02 * m.m10 - m.m00 * m.m12) * inv_det;
    m20: (m.m10 * m.m21 - m.m11 * m.m20) * inv_det;
    m21: (m.m01 * m.m20 - m.m00 * m.m21) * inv_det;
    m22: (m.m00 * m.m11 - m.m01 * m.m10) * inv_det;
  });
}

// Transform a 3D vector by a 3x3 matrix: M * v. O(9 ops).
pub fn mat3_transform_vec3(m: Mat3, v: Vec3) -> Vec3 {
  return Vec3{
    x: m.m00 * v.x + m.m01 * v.y + m.m02 * v.z;
    y: m.m10 * v.x + m.m11 * v.y + m.m12 * v.z;
    z: m.m20 * v.x + m.m21 * v.y + m.m22 * v.z;
  };
}

// Uniform 3x3 scale matrix with factor s. O(1).
pub fn mat3_scale(s: Float64) -> Mat3 {
  return Mat3{
    m00: s; m01: 0.0; m02: 0.0;
    m10: 0.0; m11: s; m12: 0.0;
    m20: 0.0; m21: 0.0; m22: s;
  };
}

// Non-uniform 3x3 scale matrix with per-axis factors. O(1).
pub fn mat3_scale_xyz(x: Float64, y: Float64, z: Float64) -> Mat3 {
  return Mat3{
    m00: x; m01: 0.0; m02: 0.0;
    m10: 0.0; m11: y; m12: 0.0;
    m20: 0.0; m21: 0.0; m22: z;
  };
}

// 3x3 rotation around the X axis by angle radians (right-handed). O(1).
pub fn mat3_rotation_x(angle: Float64) -> Mat3 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat3{
    m00: 1.0; m01: 0.0; m02: 0.0;
    m10: 0.0; m11: c;   m12: -s;
    m20: 0.0; m21: s;   m22: c;
  };
}

// 3x3 rotation around the Y axis by angle radians (right-handed). O(1).
pub fn mat3_rotation_y(angle: Float64) -> Mat3 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat3{
    m00: c;   m01: 0.0; m02: s;
    m10: 0.0; m11: 1.0; m12: 0.0;
    m20: -s;  m21: 0.0; m22: c;
  };
}

// 3x3 rotation around the Z axis by angle radians (right-handed). O(1).
pub fn mat3_rotation_z(angle: Float64) -> Mat3 {
  var c = math.cos(angle);
  var s = math.sin(angle);
  return Mat3{
    m00: c;   m01: -s;  m02: 0.0;
    m10: s;   m11: c;   m12: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0;
  };
}

// Rotation matrix from a (unit) quaternion. The quaternion is normalised first.
// Formula: the standard 3x3 rotation matrix derived from q. O(27 ops).
pub fn mat3_from_quat(q: Quaternion) -> Mat3 {
  var nq = quat_normalize(q);
  var x = nq.x;
  var y = nq.y;
  var z = nq.z;
  var w = nq.w;
  var xx = x * x; var yy = y * y; var zz = z * z;
  var xy = x * y; var xz = x * z; var yz = y * z;
  var wx = w * x; var wy = w * y; var wz = w * z;
  return Mat3{
    m00: 1.0 - 2.0 * (yy + zz);
    m01: 2.0 * (xy - wz);
    m02: 2.0 * (xz + wy);
    m10: 2.0 * (xy + wz);
    m11: 1.0 - 2.0 * (xx + zz);
    m12: 2.0 * (yz - wx);
    m20: 2.0 * (xz - wy);
    m21: 2.0 * (yz + wx);
    m22: 1.0 - 2.0 * (xx + yy);
  };
}

// ============================================================================
// Mat4 -- full 4x4 matrix operations (column-major)
// ============================================================================

// Transpose a 4x4 matrix. O(1).
pub fn mat4_transpose(m: Mat4) -> Mat4 {
  return Mat4{
    m00: m.m00; m01: m.m10; m02: m.m20; m03: m.m30;
    m10: m.m01; m11: m.m11; m12: m.m21; m13: m.m31;
    m20: m.m02; m21: m.m12; m22: m.m22; m23: m.m32;
    m30: m.m03; m31: m.m13; m32: m.m23; m33: m.m33;
  };
}

// Determinant of a 4x4 matrix by cofactor expansion along the first row. O(48 ops).
// Uses 3x3 sub-determinants of the three lower rows.
pub fn mat4_determinant(m: Mat4) -> Float64 {
  // Minor of (0,0): rows 1-3, cols 1-3
  var m00 = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
  // Minor of (0,1): rows 1-3, cols 0,2,3
  var m01 = m.m10 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m32 - m.m22 * m.m30);
  // Minor of (0,2): rows 1-3, cols 0,1,3
  var m02 = m.m10 * (m.m21 * m.m33 - m.m23 * m.m31)
          - m.m11 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m31 - m.m21 * m.m30);
  // Minor of (0,3): rows 1-3, cols 0,1,2
  var m03 = m.m10 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m11 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m12 * (m.m20 * m.m31 - m.m21 * m.m30);
  // Cofactor signs alternate: + - + -
  return m.m00 * m00 - m.m01 * m01 + m.m02 * m02 - m.m03 * m03;
}

// Inverse of a 4x4 matrix via the adjugate method (cofactor transpose / det).
// Returns None when |det| < 1e-12, so the matrix is singular. O(150 ops).
pub fn mat4_inverse(m: Mat4) -> Option[Mat4] {
  var m00 = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
  var m01 = m.m10 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m32 - m.m22 * m.m30);
  var m02 = m.m10 * (m.m21 * m.m33 - m.m23 * m.m31)
          - m.m11 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m31 - m.m21 * m.m30);
  var m03 = m.m10 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m11 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m12 * (m.m20 * m.m31 - m.m21 * m.m30);

  var det = m.m00 * m00 - m.m01 * m01 + m.m02 * m02 - m.m03 * m03;
  if math.abs_float(det) < 0.000001 * 0.000001 {
    return None;
  }
  var inv_det = 1.0 / det;

  // Cofactor matrix transposed (adjugate), each divided by det.
  // Row 0 of the inverse = column 0 of the cofactor matrix.
  var c00 = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
  var c01 = -(m.m10 * (m.m22 * m.m33 - m.m23 * m.m32)
            - m.m12 * (m.m20 * m.m33 - m.m23 * m.m30)
            + m.m13 * (m.m20 * m.m32 - m.m22 * m.m30));
  var c02 = m.m10 * (m.m21 * m.m33 - m.m23 * m.m31)
          - m.m11 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m31 - m.m21 * m.m30);
  var c03 = -(m.m10 * (m.m21 * m.m32 - m.m22 * m.m31)
            - m.m11 * (m.m20 * m.m32 - m.m22 * m.m30)
            + m.m12 * (m.m20 * m.m31 - m.m21 * m.m30));

  var c10 = -(m.m01 * (m.m22 * m.m33 - m.m23 * m.m32)
            - m.m02 * (m.m21 * m.m33 - m.m23 * m.m31)
            + m.m03 * (m.m21 * m.m32 - m.m22 * m.m31));
  var c11 = m.m00 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m02 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m03 * (m.m20 * m.m32 - m.m22 * m.m30);
  var c12 = -(m.m00 * (m.m21 * m.m33 - m.m23 * m.m31)
            - m.m01 * (m.m20 * m.m33 - m.m23 * m.m30)
            + m.m03 * (m.m20 * m.m31 - m.m21 * m.m30));
  var c13 = m.m00 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m01 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m02 * (m.m20 * m.m31 - m.m21 * m.m30);

  var c20 = m.m01 * (m.m12 * m.m33 - m.m13 * m.m32)
          - m.m02 * (m.m11 * m.m33 - m.m13 * m.m31)
          + m.m03 * (m.m11 * m.m32 - m.m12 * m.m31);
  var c21 = -(m.m00 * (m.m12 * m.m33 - m.m13 * m.m32)
            - m.m02 * (m.m10 * m.m33 - m.m13 * m.m30)
            + m.m03 * (m.m10 * m.m32 - m.m12 * m.m30));
  var c22 = m.m00 * (m.m11 * m.m33 - m.m13 * m.m31)
          - m.m01 * (m.m10 * m.m33 - m.m13 * m.m30)
          + m.m03 * (m.m10 * m.m31 - m.m11 * m.m30);
  var c23 = -(m.m00 * (m.m11 * m.m32 - m.m12 * m.m31)
            - m.m01 * (m.m10 * m.m32 - m.m12 * m.m30)
            + m.m02 * (m.m10 * m.m31 - m.m11 * m.m30));

  var c30 = -(m.m01 * (m.m12 * m.m23 - m.m13 * m.m22)
            - m.m02 * (m.m11 * m.m23 - m.m13 * m.m21)
            + m.m03 * (m.m11 * m.m22 - m.m12 * m.m21));
  var c31 = m.m00 * (m.m12 * m.m23 - m.m13 * m.m22)
          - m.m02 * (m.m10 * m.m23 - m.m13 * m.m20)
          + m.m03 * (m.m10 * m.m22 - m.m12 * m.m20);
  var c32 = -(m.m00 * (m.m11 * m.m23 - m.m13 * m.m21)
            - m.m01 * (m.m10 * m.m23 - m.m13 * m.m20)
            + m.m03 * (m.m10 * m.m21 - m.m11 * m.m20));
  var c33 = m.m00 * (m.m11 * m.m22 - m.m12 * m.m21)
          - m.m01 * (m.m10 * m.m22 - m.m12 * m.m20)
          + m.m02 * (m.m10 * m.m21 - m.m11 * m.m20);

  return Some(Mat4{
    m00: c00 * inv_det;
    m01: c10 * inv_det;
    m02: c20 * inv_det;
    m03: c30 * inv_det;
    m10: c01 * inv_det;
    m11: c11 * inv_det;
    m12: c21 * inv_det;
    m13: c31 * inv_det;
    m20: c02 * inv_det;
    m21: c12 * inv_det;
    m22: c22 * inv_det;
    m23: c32 * inv_det;
    m30: c03 * inv_det;
    m31: c13 * inv_det;
    m32: c23 * inv_det;
    m33: c33 * inv_det;
  });
}

// Transform a Vec4 (homogeneous) by a 4x4 matrix: M * v, no perspective divide. O(16 ops).
pub fn mat4_transform_vec4(m: Mat4, v: Vec4) -> Vec4 {
  return Vec4{
    x: m.m00 * v.x + m.m01 * v.y + m.m02 * v.z + m.m03 * v.w;
    y: m.m10 * v.x + m.m11 * v.y + m.m12 * v.z + m.m13 * v.w;
    z: m.m20 * v.x + m.m21 * v.y + m.m22 * v.z + m.m23 * v.w;
    w: m.m30 * v.x + m.m31 * v.y + m.m32 * v.z + m.m33 * v.w;
  };
}

// Transform a point (w=1) by a 4x4 matrix, including perspective divide.
// If the transformed w is zero, returns the zero vector. O(16 ops).
pub fn mat4_transform_point(m: Mat4, p: Vec3) -> Vec3 {
  var w = m.m30 * p.x + m.m31 * p.y + m.m32 * p.z + m.m33;
  if w == 0.0 { return Vec3{ x: 0.0; y: 0.0; z: 0.0; }; }
  return Vec3{
    x: (m.m00 * p.x + m.m01 * p.y + m.m02 * p.z + m.m03) / w;
    y: (m.m10 * p.x + m.m11 * p.y + m.m12 * p.z + m.m13) / w;
    z: (m.m20 * p.x + m.m21 * p.y + m.m22 * p.z + m.m23) / w;
  };
}

// Transform a direction (w=0) by a 4x4 matrix: rotation/scale only,
// translation is ignored and no perspective divide is applied. O(9 ops).
pub fn mat4_transform_direction(m: Mat4, d: Vec3) -> Vec3 {
  return Vec3{
    x: m.m00 * d.x + m.m01 * d.y + m.m02 * d.z;
    y: m.m10 * d.x + m.m11 * d.y + m.m12 * d.z;
    z: m.m20 * d.x + m.m21 * d.y + m.m22 * d.z;
  };
}

// Scale matrix (non-uniform) from three axis factors. Same as mat4_scale. O(1).
pub fn mat4_from_scale(x: Float64, y: Float64, z: Float64) -> Mat4 {
  return mat4_scale(x, y, z);
}

// Translation matrix from a Vec3 offset. O(1).
pub fn mat4_from_translation(t: Vec3) -> Mat4 {
  return mat4_translate(t.x, t.y, t.z);
}

// Translation matrix from three components. Same as mat4_translate. O(1).
pub fn mat4_translation_xyz(x: Float64, y: Float64, z: Float64) -> Mat4 {
  return mat4_translate(x, y, z);
}

// Rotation around the X axis. Same as mat4_rotate_x. O(1).
pub fn mat4_from_rotation_x(angle: Float64) -> Mat4 {
  return mat4_rotate_x(angle);
}

// Rotation around the Y axis. Same as mat4_rotate_y. O(1).
pub fn mat4_from_rotation_y(angle: Float64) -> Mat4 {
  return mat4_rotate_y(angle);
}

// Rotation around the Z axis. Same as mat4_rotate_z. O(1).
pub fn mat4_from_rotation_z(angle: Float64) -> Mat4 {
  return mat4_rotate_z(angle);
}

// Rotation matrix from a (unit) quaternion. The quaternion is normalised first.
// Formula: the standard 4x4 rotation matrix derived from q. O(27 ops).
pub fn mat4_from_quat(q: Quaternion) -> Mat4 {
  var nq = quat_normalize(q);
  var x = nq.x;
  var y = nq.y;
  var z = nq.z;
  var w = nq.w;
  var xx = x * x; var yy = y * y; var zz = z * z;
  var xy = x * y; var xz = x * z; var yz = y * z;
  var wx = w * x; var wy = w * y; var wz = w * z;
  return Mat4{
    m00: 1.0 - 2.0 * (yy + zz);
    m01: 2.0 * (xy - wz);
    m02: 2.0 * (xz + wy);
    m03: 0.0;
    m10: 2.0 * (xy + wz);
    m11: 1.0 - 2.0 * (xx + zz);
    m12: 2.0 * (yz - wx);
    m13: 0.0;
    m20: 2.0 * (xz - wy);
    m21: 2.0 * (yz + wx);
    m22: 1.0 - 2.0 * (xx + yy);
    m23: 0.0;
    m30: 0.0;
    m31: 0.0;
    m32: 0.0;
    m33: 1.0;
  };
}

// Rotation matrix about an arbitrary axis (unit length) by angle radians.
// Uses the Rodrigues formula. The axis is normalised first. O(30 ops).
pub fn mat4_rotation_axis_angle(axis: Vec3, angle: Float64) -> Mat4 {
  var n = vec3_normalize(axis);
  var c = math.cos(angle);
  var s = math.sin(angle);
  var t = 1.0 - c;
  var x = n.x;
  var y = n.y;
  var z = n.z;
  return Mat4{
    m00: t * x * x + c;
    m01: t * x * y - s * z;
    m02: t * x * z + s * y;
    m03: 0.0;
    m10: t * x * y + s * z;
    m11: t * y * y + c;
    m12: t * y * z - s * x;
    m13: 0.0;
    m20: t * x * z - s * y;
    m21: t * y * z + s * x;
    m22: t * z * z + c;
    m23: 0.0;
    m30: 0.0;
    m31: 0.0;
    m32: 0.0;
    m33: 1.0;
  };
}

// Orthographic projection matrix (right-handed, standard OpenGL mapping).
// Maps [l,r]x[b,t]x[n,f] to NDC [-1,1]^3. l != r, b != t, n != f required. O(1).
pub fn mat4_orthographic(l: Float64, r: Float64, b: Float64, t: Float64, n: Float64, f: Float64) -> Mat4 {
  var rl = r - l;
  var tb = t - b;
  var fd = f - n;
  return Mat4{
    m00: 2.0 / rl;
    m01: 0.0;
    m02: 0.0;
    m03: -(r + l) / rl;
    m10: 0.0;
    m11: 2.0 / tb;
    m12: 0.0;
    m13: -(t + b) / tb;
    m20: 0.0;
    m21: 0.0;
    m22: -2.0 / fd;
    m23: -(f + n) / fd;
    m30: 0.0;
    m31: 0.0;
    m32: 0.0;
    m33: 1.0;
  };
}

// True if every element of m is within epsilon of the identity matrix. O(16 ops).
pub fn mat4_is_identity(m: Mat4, eps: Float64) -> Bool {
  return mat4_approx_eq(m, mat4_identity(), eps);
}

// True if every corresponding element of a and b differs by at most epsilon. O(16 ops).
pub fn mat4_approx_eq(a: Mat4, b: Mat4, eps: Float64) -> Bool {
  return f64_approx_eq(a.m00, b.m00, eps)
      && f64_approx_eq(a.m01, b.m01, eps)
      && f64_approx_eq(a.m02, b.m02, eps)
      && f64_approx_eq(a.m03, b.m03, eps)
      && f64_approx_eq(a.m10, b.m10, eps)
      && f64_approx_eq(a.m11, b.m11, eps)
      && f64_approx_eq(a.m12, b.m12, eps)
      && f64_approx_eq(a.m13, b.m13, eps)
      && f64_approx_eq(a.m20, b.m20, eps)
      && f64_approx_eq(a.m21, b.m21, eps)
      && f64_approx_eq(a.m22, b.m22, eps)
      && f64_approx_eq(a.m23, b.m23, eps)
      && f64_approx_eq(a.m30, b.m30, eps)
      && f64_approx_eq(a.m31, b.m31, eps)
      && f64_approx_eq(a.m32, b.m32, eps)
      && f64_approx_eq(a.m33, b.m33, eps);
}

// ============================================================================
// Quaternion -- full rotation operations
// ============================================================================

// Create a quaternion from an axis and angle (radians). The axis is normalised
// first, so any (non-zero) axis is accepted. Rotation is right-handed. O(1).
pub fn quat_from_axis_angle(axis: Vec3, angle: Float64) -> Quaternion {
  var n = vec3_normalize(axis);
  var half = angle * 0.5;
  var s = math.sin(half);
  return Quaternion{
    x: n.x * s;
    y: n.y * s;
    z: n.z * s;
    w: math.cos(half);
  };
}

// Rotate a 3D vector by a quaternion: q * v * q^-1 (q must be unit length).
// Same as quat_rotate_vec3, provided under the mul_vec3 name. O(1).
pub fn quat_mul_vec3(q: Quaternion, v: Vec3) -> Vec3 {
  return quat_rotate_vec3(q, v);
}

// Inverse of a quaternion: the conjugate of the normalised quaternion.
// For a unit quaternion the conjugate is exactly the inverse. O(1).
pub fn quat_inverse(q: Quaternion) -> Quaternion {
  var nq = quat_normalize(q);
  return quat_conjugate(nq);
}

// Dot product of two quaternions (4-vector dot). O(4 ops).
pub fn quat_dot(a: Quaternion, b: Quaternion) -> Float64 {
  return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

// Length (magnitude) of a quaternion. O(4 ops + sqrt).
pub fn quat_length(q: Quaternion) -> Float64 {
  return math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
}

// True if the length of q is within epsilon of 1.0. O(1).
pub fn quat_is_unit(q: Quaternion, eps: Float64) -> Bool {
  return f64_approx_eq(quat_length(q), 1.0, eps);
}

// Spherical linear interpolation between two quaternions by t in [0,1].
// Handles the shortest path by negating b when dot(a,b) < 0, clamps the dot to
// [-1,1], and falls back to nlerp when a and b are nearly parallel. O(1).
pub fn quat_slerp(a: Quaternion, b: Quaternion, t: Float64) -> Quaternion {
  if t <= 0.0 { return a; }
  if t >= 1.0 { return b; }
  var dot = quat_dot(a, b);
  var bb = b;
  var cd = dot;
  if cd < 0.0 {
    bb = Quaternion{ x: -b.x; y: -b.y; z: -b.z; w: -b.w; };
    cd = -cd;
  }
  if cd > 1.0 { cd = 1.0; }
  if cd < -1.0 { cd = -1.0; }
  if cd > 0.9995 {
    return quat_nlerp(a, bb, t);
  }
  var theta = math.acos(cd);
  var sin_theta = math.sin(theta);
  var wa = math.sin((1.0 - t) * theta) / sin_theta;
  var wb = math.sin(t * theta) / sin_theta;
  return Quaternion{
    x: wa * a.x + wb * bb.x;
    y: wa * a.y + wb * bb.y;
    z: wa * a.z + wb * bb.z;
    w: wa * a.w + wb * bb.w;
  };
}

// Normalised linear interpolation between two quaternions (fast, not constant
// angular velocity). t is clamped into [0,1]. O(1).
pub fn quat_nlerp(a: Quaternion, b: Quaternion, t: Float64) -> Quaternion {
  var ct = t;
  if ct < 0.0 { ct = 0.0; }
  if ct > 1.0 { ct = 1.0; }
  return quat_normalize(Quaternion{
    x: a.x + (b.x - a.x) * ct;
    y: a.y + (b.y - a.y) * ct;
    z: a.z + (b.z - a.z) * ct;
    w: a.w + (b.w - a.w) * ct;
  });
}

// Extract the quaternion from a rotation matrix using the standard trace method.
// Handles all three largest-diagonal cases to avoid degenerate sqrt. O(1).
pub fn quat_from_mat4(m: &Mat4) -> Quaternion {
  var trace = m.m00 + m.m11 + m.m22;
  if trace > 0.0 {
    var s = math.sqrt(trace + 1.0) * 2.0;
    var inv_s = 1.0 / s;
    return Quaternion{
      x: (m.m21 - m.m12) * inv_s;
      y: (m.m02 - m.m20) * inv_s;
      z: (m.m10 - m.m01) * inv_s;
      w: 0.25 * s;
    };
  }
  if m.m00 > m.m11 && m.m00 > m.m22 {
    var s = math.sqrt(1.0 + m.m00 - m.m11 - m.m22) * 2.0;
    var inv_s = 1.0 / s;
    return Quaternion{
      x: 0.25 * s;
      y: (m.m01 + m.m10) * inv_s;
      z: (m.m02 + m.m20) * inv_s;
      w: (m.m21 - m.m12) * inv_s;
    };
  }
  if m.m11 > m.m22 {
    var s = math.sqrt(1.0 + m.m11 - m.m00 - m.m22) * 2.0;
    var inv_s = 1.0 / s;
    return Quaternion{
      x: (m.m01 + m.m10) * inv_s;
      y: 0.25 * s;
      z: (m.m12 + m.m21) * inv_s;
      w: (m.m02 - m.m20) * inv_s;
    };
  }
  var s = math.sqrt(1.0 + m.m22 - m.m00 - m.m11) * 2.0;
  var inv_s = 1.0 / s;
  return Quaternion{
    x: (m.m02 + m.m20) * inv_s;
    y: (m.m12 + m.m21) * inv_s;
    z: 0.25 * s;
    w: (m.m10 - m.m01) * inv_s;
  };
}

// 4x4 rotation matrix from a quaternion. Same result as mat4_from_quat. O(1).
pub fn quat_to_mat4(q: Quaternion) -> Mat4 {
  return mat4_from_quat(q);
}

// 3x3 rotation matrix from a quaternion. Same result as mat3_from_quat. O(1).
pub fn quat_to_mat3(q: Quaternion) -> Mat3 {
  return mat3_from_quat(q);
}

// Roll (rotation around X, radians) extracted from a quaternion.
// Conventions match quat_from_euler (ZYX intrinsic). O(1).
pub fn quat_roll(q: Quaternion) -> Float64 {
  return math.atan2(2.0 * (q.w * q.x + q.y * q.z), 1.0 - 2.0 * (q.x * q.x + q.y * q.y));
}

// Pitch (rotation around Y, radians) extracted from a quaternion.
// Conventions match quat_from_euler (ZYX intrinsic). Input to asin is clamped. O(1).
pub fn quat_pitch(q: Quaternion) -> Float64 {
  var sp = 2.0 * (q.w * q.y - q.z * q.x);
  if sp > 1.0 { sp = 1.0; }
  if sp < -1.0 { sp = -1.0; }
  return math.asin(sp);
}

// Yaw (rotation around Z, radians) extracted from a quaternion.
// Conventions match quat_from_euler (ZYX intrinsic). O(1).
pub fn quat_yaw(q: Quaternion) -> Float64 {
  return math.atan2(2.0 * (q.w * q.z + q.x * q.y), 1.0 - 2.0 * (q.y * q.y + q.z * q.z));
}

// Angle (radians) between two rotation quaternions in [0, 2*PI].
// Returns 2*acos(clamped dot) over the shortest arc. O(1).
pub fn quat_angle_between(a: Quaternion, b: Quaternion) -> Float64 {
  var dot = quat_dot(a, b);
  if dot < -1.0 { dot = -1.0; }
  if dot > 1.0 { dot = 1.0; }
  return 2.0 * math.acos(dot);
}

// ============================================================================
// Aabb -- query and combination helpers
// ============================================================================

// Create an AABB from min and max corners. Same as aabb_new. O(1).
pub fn aabb_from_min_max(min: Vec3, max: Vec3) -> Aabb {
  return aabb_new(min, max);
}

// Centre point of an AABB: (min + max) / 2. O(1).
pub fn aabb_center(box: Aabb) -> Vec3 {
  return Vec3{
    x: (box.min.x + box.max.x) * 0.5;
    y: (box.min.y + box.max.y) * 0.5;
    z: (box.min.z + box.max.z) * 0.5;
  };
}

// Size (extent per axis) of an AABB: max - min. O(1).
pub fn aabb_size(box: Aabb) -> Vec3 {
  return vec3_sub(box.max, box.min);
}

// Half-extents of an AABB: size / 2. O(1).
pub fn aabb_half_extents(box: Aabb) -> Vec3 {
  var s = vec3_sub(box.max, box.min);
  return Vec3{ x: s.x * 0.5; y: s.y * 0.5; z: s.z * 0.5; };
}

// True if the sphere intersects the AABB. Uses the closest-point test:
// the squared distance from the sphere centre to the box must not exceed r2. O(1).
pub fn aabb_intersects_sphere(box: Aabb, s: Sphere) -> Bool {
  var cp = aabb_closest_point(box, s.center);
  return vec3_distance_squared(cp, s.center) <= s.radius * s.radius;
}

// Closest point on (or inside) the AABB to p: p clamped into [min, max]. O(1).
pub fn aabb_closest_point(box: Aabb, p: Vec3) -> Vec3 {
  return Vec3{
    x: math.clamp(p.x, box.min.x, box.max.x);
    y: math.clamp(p.y, box.min.y, box.max.y);
    z: math.clamp(p.z, box.min.z, box.max.z);
  };
}

// Surface area of an AABB: 2*(w*h + h*d + w*d). O(1).
pub fn aabb_surface_area(box: Aabb) -> Float64 {
  var s = vec3_sub(box.max, box.min);
  return 2.0 * (s.x * s.y + s.y * s.z + s.x * s.z);
}

// Volume of an AABB: w*h*d. O(1).
pub fn aabb_volume(box: Aabb) -> Float64 {
  var s = vec3_sub(box.max, box.min);
  return s.x * s.y * s.z;
}

// Expand the AABB to include point p (grow min/max component-wise). O(1).
pub fn aabb_expand(box: Aabb, p: Vec3) -> Aabb {
  return Aabb{
    min: Vec3{
      x: math.min_float(box.min.x, p.x);
      y: math.min_float(box.min.y, p.y);
      z: math.min_float(box.min.z, p.z);
    };
    max: Vec3{
      x: math.max_float(box.max.x, p.x);
      y: math.max_float(box.max.y, p.y);
      z: math.max_float(box.max.z, p.z);
    };
  };
}

// Smallest AABB that contains both a and b (component-wise min/max). O(1).
pub fn aabb_union(a: Aabb, b: Aabb) -> Aabb {
  return Aabb{
    min: Vec3{
      x: math.min_float(a.min.x, b.min.x);
      y: math.min_float(a.min.y, b.min.y);
      z: math.min_float(a.min.z, b.min.z);
    };
    max: Vec3{
      x: math.max_float(a.max.x, b.max.x);
      y: math.max_float(a.max.y, b.max.y);
      z: math.max_float(a.max.z, b.max.z);
    };
  };
}

// Overlap of two AABBs. Returns None when the boxes do not intersect.
// The result is the intersection volume between them. O(1).
pub fn aabb_intersection(a: Aabb, b: Aabb) -> Option[Aabb] {
  if !aabb_intersects_aabb(a, b) {
    return None;
  }
  return Some(Aabb{
    min: Vec3{
      x: math.max_float(a.min.x, b.min.x);
      y: math.max_float(a.min.y, b.min.y);
      z: math.max_float(a.min.z, b.min.z);
    };
    max: Vec3{
      x: math.min_float(a.max.x, b.max.x);
      y: math.min_float(a.max.y, b.max.y);
      z: math.min_float(a.max.z, b.max.z);
    };
  });
}

// ============================================================================
// Sphere -- query and combination helpers
// ============================================================================

// True if two spheres intersect (or touch): distance <= r_a + r_b. O(1).
pub fn sphere_intersects_sphere(a: Sphere, b: Sphere) -> Bool {
  var d2 = vec3_distance_squared(a.center, b.center);
  var r = a.radius + b.radius;
  return d2 <= r * r;
}

// True if a sphere intersects an AABB. Delegates to aabb_intersects_sphere. O(1).
pub fn sphere_intersects_aabb(s: Sphere, box: Aabb) -> Bool {
  return aabb_intersects_sphere(box, s);
}

// Closest point on the sphere surface to p. If p equals the centre, the centre
// (an arbitrary surface direction) is returned. O(1).
pub fn sphere_closest_point(s: Sphere, p: Vec3) -> Vec3 {
  var d = vec3_sub(p, s.center);
  var len = vec3_length(d);
  if len == 0.0 { return s.center; }
  var n = vec3_mul_scalar(d, 1.0 / len);
  return vec3_add(s.center, vec3_mul_scalar(n, s.radius));
}

// Surface area of a sphere: 4*PI*r2. O(1).
pub fn sphere_surface_area(s: Sphere) -> Float64 {
  return 4.0 * math.PI * s.radius * s.radius;
}

// Volume of a sphere: (4/3)*PI*r3. O(1).
pub fn sphere_volume(s: Sphere) -> Float64 {
  return 4.0 / 3.0 * math.PI * s.radius * s.radius * s.radius;
}

// Expand the sphere so it contains point p. If p is already inside, the sphere
// is returned unchanged. O(1).
pub fn sphere_expand(s: Sphere, p: Vec3) -> Sphere {
  var d = vec3_distance(s.center, p);
  if d <= s.radius {
    return s;
  }
  return sphere_new(s.center, d);
}

// ============================================================================
// Ray -- evaluation and intersection helpers
// ============================================================================

// Point on the ray at parameter t: origin + dir * t. O(1).
pub fn ray_at(r: Ray, t: Float64) -> Vec3 {
  return vec3_add(r.origin, vec3_mul_scalar(r.dir, t));
}

// Origin of the ray. O(1).
pub fn ray_origin(r: Ray) -> Vec3 {
  return r.origin;
}

// Direction of the ray. O(1).
pub fn ray_dir(r: Ray) -> Vec3 {
  return r.dir;
}

// Ray-plane intersection. Returns Some(t) where t is the ray parameter of the
// hit, or None if the ray is parallel to the plane or the hit lies behind the
// origin. plane_normal need not be unit. O(1).
pub fn ray_intersect_plane(r: Ray, plane_point: Vec3, plane_normal: Vec3) -> Option[Float64] {
  var denom = vec3_dot(r.dir, plane_normal);
  if math.abs_float(denom) < 0.000001 * 0.000001 {
    return None;
  }
  var t = vec3_dot(vec3_sub(plane_point, r.origin), plane_normal) / denom;
  if t < 0.0 {
    return None;
  }
  return Some(t);
}

// Distance from a point p to the ray line (not the segment). Uses the 3D
// cross-product formula |(p - o) x d| / |d|. Returns 0 if the direction is degenerate. O(1).
pub fn ray_distance_to_point(r: Ray, p: Vec3) -> Float64 {
  var v = vec3_sub(p, r.origin);
  var denom = vec3_length(r.dir);
  if denom == 0.0 {
    return vec3_length(v);
  }
  var c = vec3_cross(v, r.dir);
  return vec3_length(c) / denom;
}

// ============================================================================
// Plane -- infinite plane primitive
// ============================================================================

// Plane defined by a point on the plane and its normal direction.
// The normal need not be unit length; signed distances then scale accordingly.
pub type Plane = { point: Vec3; normal: Vec3; }

// Create a plane from a point on it and a normal direction. O(1).
pub fn plane_new(point: Vec3, normal: Vec3) -> Plane {
  return Plane{ point: point; normal: normal; };
}

// Signed distance from a point to the plane (positive on the normal side).
// Assumes the plane normal is unit length. O(1).
pub fn plane_signed_distance(p: &Plane, pt: Vec3) -> Float64 {
  return vec3_dot(vec3_sub(pt, p.point), p.normal);
}

// Absolute distance from a point to the plane. Assumes a unit normal. O(1).
pub fn plane_distance_to_point(p: &Plane, pt: Vec3) -> Float64 {
  var d = plane_signed_distance(p, pt);
  return math.abs_float(d);
}

// Ray-plane intersection against a Plane. Returns Some(t) or None.
// This is an alias of ray_intersect_plane using the plane's fields. O(1).
pub fn plane_intersect_ray(p: &Plane, r: Ray) -> Option[Float64] {
  return ray_intersect_plane(r, p.point, p.normal);
}

// ============================================================================
// Scalar helpers -- comparisons and angle conversions
// ============================================================================

// True if |a - b| <= eps. The canonical epsilon comparison. O(1).
pub fn f64_approx_eq(a: Float64, b: Float64, eps: Float64) -> Bool {
  return math.abs_float(a - b) <= eps;
}

// Convert degrees to radians: d * PI / 180. O(1).
pub fn f64_deg_to_rad(d: Float64) -> Float64 {
  return d * math.PI / 180.0;
}

// Convert radians to degrees: r * 180 / PI. O(1).
pub fn f64_rad_to_deg(r: Float64) -> Float64 {
  return r * 180.0 / math.PI;
}

// Convert degrees to radians (Float32 API: same formula, Float64 arithmetic). O(1).
pub fn f32_deg_to_rad(d: Float64) -> Float64 {
  return d * math.PI / 180.0;
}

// Convert radians to degrees (Float32 API: same formula, Float64 arithmetic). O(1).
pub fn f32_rad_to_deg(r: Float64) -> Float64 {
  return r * 180.0 / math.PI;
}

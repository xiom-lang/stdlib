// XIOM — 2D/3D Geometry Library (vectors, matrices, quaternions, primitives)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom

use xiom.math;

// ============================================================================
// Types — 2D/3D vector, matrix, quaternion, and primitive types
// ============================================================================

// 2-component vector (x, y) — used for 2D positions, directions, UVs.
pub type Vec2 = { x: Float64; y: Float64; }

// 3-component vector (x, y, z) — core 3D math type.
pub type Vec3 = { x: Float64; y: Float64; z: Float64; }

// 4-component vector (x, y, z, w) — homogeneous coords, RGBA colours.
pub type Vec4 = { x: Float64; y: Float64; z: Float64; w: Float64; }

// Quaternion (x, y, z, w) — rotation representation; w is the scalar part.
pub type Quaternion = { x: Float64; y: Float64; z: Float64; w: Float64; }

// 2×2 column-major matrix.
pub type Mat2 = { m00: Float64; m01: Float64; m10: Float64; m11: Float64; }

// 3×3 column-major matrix.
pub type Mat3 = {
  m00: Float64; m01: Float64; m02: Float64;
  m10: Float64; m11: Float64; m12: Float64;
  m20: Float64; m21: Float64; m22: Float64;
}

// 4×4 column-major matrix — core 3D transform type.
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
// Vec2 — construction and arithmetic
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

// Linearly interpolate between a and b by t. t=0 → a, t=1 → b. O(1).
pub fn vec2_lerp(a: Vec2, b: Vec2, t: Float64) -> Float64 {
  return math.lerp(a.x, b.x, t);
}

// ============================================================================
// Vec3 — construction and arithmetic
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

// 3D cross product: a × b (right-handed). O(1).
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
// Vec4 — construction
// ============================================================================

// Create a new 4D vector.
pub fn vec4_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Vec4 {
  return Vec4{ x: x; y: y; z: z; w: w; };
}

// ============================================================================
// Quaternion — construction and operations
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
// Hamilton product: (w1w2 - v1·v2, w1v2 + w2v1 + v1×v2)
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
// Returns: v + 2.0 * q.xyz × (q.xyz × v + q.w * v)
pub fn quat_rotate_vec3(q: Quaternion, v: Vec3) -> Vec3 {
  var qv = Vec3{ x: q.x; y: q.y; z: q.z; };
  var t = vec3_mul_scalar(vec3_cross(qv, v), 2.0);
  var u = vec3_cross(qv, t);
  var w_term = vec3_mul_scalar(t, q.w); // already w * t = q.w * 2 * cross(qv,v)
  // Correct: v' = v + 2*(q.w*(qv×v) + qv×(qv×v))
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
// Mat4 — 4×4 transform matrices (column-major)
// ============================================================================

// 4×4 identity matrix. O(1).
pub fn mat4_identity() -> Mat4 {
  return Mat4{
    m00: 1.0; m01: 0.0; m02: 0.0; m03: 0.0;
    m10: 0.0; m11: 1.0; m12: 0.0; m13: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0; m23: 0.0;
    m30: 0.0; m31: 0.0; m32: 0.0; m33: 1.0;
  };
}

// Multiply two 4×4 matrices: a * b. Row × column dot products. O(64 ops).
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

// Transform a Vec3 point by a 4×4 matrix (x,y,z,1 homogeneous). O(16 ops).
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
// Mat3 — 3×3 matrices (column-major)
// ============================================================================

// 3×3 identity matrix. O(1).
pub fn mat3_identity() -> Mat3 {
  return Mat3{
    m00: 1.0; m01: 0.0; m02: 0.0;
    m10: 0.0; m11: 1.0; m12: 0.0;
    m20: 0.0; m21: 0.0; m22: 1.0;
  };
}

// Multiply two 3×3 matrices: a * b. O(27 ops).
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
// Aabb — axis-aligned bounding box
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
// Ray — ray casting
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

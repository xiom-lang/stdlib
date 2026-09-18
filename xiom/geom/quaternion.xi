// XIOM - Geom: Quaternion
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.geom.quaternion

// Depends on: xiom.geom

// ============================================================================
// Quaternion rotation algebra: construction, composition, and interpolation.
// NOTE: current implementation lives in geom.xi REAL Quat + geom/quat.xi stub
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
//
// Functions whose names differ from the canonical geom.xi operations delegate
// through the geom.xi Quaternion type (Quat <-> Quaternion conversion);
// same-name functions are implemented locally. The rotation-matrix
// conversions operate on dynamic Vec[Vec[Float64]] (copied locally before
// element access - BUG 26 #1).
// ============================================================================

use xiom.geom;
use xiom.math;

// Quaternion (x, y, z, w); w is the scalar part.
/// Quaternion (x, y, z, w); w is the scalar part.
pub type Quat = { x: Float64; y: Float64; z: Float64; w: Float64; }

// Construct a quaternion from components. Implemented locally (name collision
// with geom.quat_new which takes axis/angle). O(1).
/// Construct a quaternion from components. Implemented locally (name collision
/// with geom.quat_new which takes axis/angle). O(1).
pub fn quat_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Quat {
  return Quat{ x: x; y: y; z: z; w: w; };
}

// Identity quaternion (no rotation). Implemented locally (name collision). O(1).
/// Identity quaternion (no rotation). Implemented locally (name collision). O(1).
pub fn quat_identity() -> Quat {
  return Quat{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
}

// Quaternion rotating angle (radians) about the (non-zero) axis direction.
// The axis is normalised first. Implemented locally (name collision). O(1).
/// Quaternion rotating angle (radians) about the (non-zero) axis direction.
/// The axis is normalised first. Implemented locally (name collision). O(1).
pub fn quat_from_axis_angle(axis: &Vec[Float64], angle: Float64) -> Quat {
  var ax = 0.0;
  var ay = 0.0;
  var az = 0.0;
  if axis.len() >= 1 { ax = axis[0]; }
  if axis.len() >= 2 { ay = axis[1]; }
  if axis.len() >= 3 { az = axis[2]; }
  var alen = math.sqrt(ax * ax + ay * ay + az * az);
  if alen == 0.0 { return quat_identity(); }
  var inv = 1.0 / alen;
  var half = angle * 0.5;
  var s = math.sin(half);
  return Quat{
    x: ax * inv * s;
    y: ay * inv * s;
    z: az * inv * s;
    w: math.cos(half);
  };
}

// Quaternion from ZYX intrinsic Euler angles (yaw around Z, pitch around Y,
// roll around X), in radians. Implemented locally (name collision with
// geom.quat_from_euler). O(1).
/// Quaternion from ZYX intrinsic Euler angles (yaw around Z, pitch around Y,
/// roll around X), in radians. Implemented locally (name collision with
/// geom.quat_from_euler). O(1).
pub fn quat_from_euler(yaw: Float64, pitch: Float64, roll: Float64) -> Quat {
  var cy = math.cos(yaw * 0.5);
  var sy = math.sin(yaw * 0.5);
  var cp = math.cos(pitch * 0.5);
  var sp = math.sin(pitch * 0.5);
  var cr = math.cos(roll * 0.5);
  var sr = math.sin(roll * 0.5);
  return Quat{
    x: cy * cp * sr - sy * sp * cr;
    y: sy * cp * sr + cy * sp * cr;
    z: sy * cp * cr - cy * sp * sr;
    w: cy * cp * cr + sy * sp * sr;
  };
}

// Quaternion equivalent of a 3x3 rotation matrix (trace method). The matrix
// is copied locally before element access. Returns the identity quaternion
// for a non-3x3 input. O(1).
/// Quaternion equivalent of a 3x3 rotation matrix (trace method). The matrix
/// is copied locally before element access. Returns the identity quaternion
/// for a non-3x3 input. O(1).
pub fn quat_from_rotation_matrix(m: &Vec[Vec[Float64]]) -> Quat {
  var id = Quat{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    sc.push(m[i]);
    i = i + 1;
  }
  if sc.len() != 3 { return id; }
  if sc[0].len() != 3 { return id; }
  var trace = sc[0][0] + sc[1][1] + sc[2][2];
  if trace > 0.0 {
    var s = math.sqrt(trace + 1.0) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: (sc[2][1] - sc[1][2]) * inv_s;
      y: (sc[0][2] - sc[2][0]) * inv_s;
      z: (sc[1][0] - sc[0][1]) * inv_s;
      w: 0.25 * s;
    };
  }
  if sc[0][0] > sc[1][1] && sc[0][0] > sc[2][2] {
    var s = math.sqrt(1.0 + sc[0][0] - sc[1][1] - sc[2][2]) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: 0.25 * s;
      y: (sc[0][1] + sc[1][0]) * inv_s;
      z: (sc[0][2] + sc[2][0]) * inv_s;
      w: (sc[2][1] - sc[1][2]) * inv_s;
    };
  }
  if sc[1][1] > sc[2][2] {
    var s = math.sqrt(1.0 + sc[1][1] - sc[0][0] - sc[2][2]) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: (sc[0][1] + sc[1][0]) * inv_s;
      y: 0.25 * s;
      z: (sc[1][2] + sc[2][1]) * inv_s;
      w: (sc[0][2] - sc[2][0]) * inv_s;
    };
  }
  var s = math.sqrt(1.0 + sc[2][2] - sc[0][0] - sc[1][1]) * 2.0;
  var inv_s = 1.0 / s;
  return Quat{
    x: (sc[0][2] + sc[2][0]) * inv_s;
    y: (sc[1][2] + sc[2][1]) * inv_s;
    z: 0.25 * s;
    w: (sc[1][0] - sc[0][1]) * inv_s;
  };
}

// 3x3 rotation matrix (row-major Vec[Vec[Float64]]) from a quaternion. The
// quaternion is normalised first. O(1).
/// 3x3 rotation matrix (row-major Vec[Vec[Float64]]) from a quaternion. The
/// quaternion is normalised first. O(1).
pub fn quat_to_matrix(q: Quat) -> Vec[Vec[Float64]] {
  var nq = quat_normalize(q);
  var x = nq.x;
  var y = nq.y;
  var z = nq.z;
  var w = nq.w;
  var xx = x * x;
  var yy = y * y;
  var zz = z * z;
  var xy = x * y;
  var xz = x * z;
  var yz = y * z;
  var wx = w * x;
  var wy = w * y;
  var wz = w * z;
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(1.0 - 2.0 * (yy + zz));
  r0.push(2.0 * (xy - wz));
  r0.push(2.0 * (xz + wy));
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(2.0 * (xy + wz));
  r1.push(1.0 - 2.0 * (xx + zz));
  r1.push(2.0 * (yz - wx));
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(2.0 * (xz - wy));
  r2.push(2.0 * (yz + wx));
  r2.push(1.0 - 2.0 * (xx + yy));
  out.push(r2);
  return out;
}

// Extract (yaw, pitch, roll) in radians, matching quat_from_euler (ZYX
// intrinsic). Implemented locally: module-qualified results inside a tuple
// literal mis-type as Int in this compiler (BUG). O(1).
/// Extract (yaw, pitch, roll) in radians, matching quat_from_euler (ZYX
/// intrinsic). Implemented locally: module-qualified results inside a tuple
/// literal mis-type as Int in this compiler (BUG). O(1).
pub fn quat_to_euler(q: Quat) -> (Float64, Float64, Float64) {
  var yaw = math.atan2(2.0 * (q.w * q.z + q.x * q.y), 1.0 - 2.0 * (q.y * q.y + q.z * q.z));
  var sp = 2.0 * (q.w * q.y - q.z * q.x);
  if sp > 1.0 { sp = 1.0; }
  if sp < -1.0 { sp = -1.0; }
  var pitch = math.asin(sp);
  var roll = math.atan2(2.0 * (q.w * q.x + q.y * q.z), 1.0 - 2.0 * (q.x * q.x + q.y * q.y));
  return (yaw, pitch, roll);
}

// Hamilton product a * b (compose rotations; b applied first). Implemented
// locally (name collision with geom.quat_mul). O(1).
/// Hamilton product a * b (compose rotations; b applied first). Implemented
/// locally (name collision with geom.quat_mul). O(1).
pub fn quat_mul(a: Quat, b: Quat) -> Quat {
  return Quat{
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y;
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x;
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w;
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z;
  };
}

// Conjugate of a quaternion: negate the vector part. Delegates to
// geom.quat_conjugate (name differs). O(1).
/// Conjugate of a quaternion: negate the vector part. Delegates to
/// geom.quat_conjugate (name differs). O(1).
pub fn quat_conj(q: Quat) -> Quat {
  var gq = geom.quat_conjugate(Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; });
  return Quat{ x: gq.x; y: gq.y; z: gq.z; w: gq.w; };
}

// Inverse of a unit quaternion (the conjugate). Delegates to geom.quat_inverse
// (name differs). O(1).
/// Inverse of a unit quaternion (the conjugate). Delegates to geom.quat_inverse
/// (name differs). O(1).
pub fn quat_inv(q: Quat) -> Quat {
  var gq = geom.quat_inverse(Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; });
  return Quat{ x: gq.x; y: gq.y; z: gq.z; w: gq.w; };
}

// Euclidean length of a quaternion. Delegates to geom.quat_length (name
// differs). O(1).
/// Euclidean length of a quaternion. Delegates to geom.quat_length (name
/// differs). O(1).
pub fn quat_norm(q: Quat) -> Float64 {
  return geom.quat_length(Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; });
}

// Unit quaternion; identity if the length is zero. Implemented locally (name
// collision with geom.quat_normalize). O(1).
/// Unit quaternion; identity if the length is zero. Implemented locally (name
/// collision with geom.quat_normalize). O(1).
pub fn quat_normalize(q: Quat) -> Quat {
  var len = quat_norm(q);
  if len == 0.0 { return quat_identity(); }
  return Quat{ x: q.x / len; y: q.y / len; z: q.z / len; w: q.w / len; };
}

// Rotate the 3D vector v by quaternion q. Delegates to geom.quat_rotate_vec3
// through the canonical types. O(1).
/// Rotate the 3D vector v by quaternion q. Delegates to geom.quat_rotate_vec3
/// through the canonical types. O(1).
pub fn quat_rotate(q: Quat, v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if v.len() < 3 {
    return out;
  }
  var gq = Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; };
  var gv = Vec3{ x: v[0]; y: v[1]; z: v[2]; };
  var res = geom.quat_rotate_vec3(gq, gv);
  out.push(res.x);
  out.push(res.y);
  out.push(res.z);
  return out;
}

// Spherical linear interpolation between a and b by t in [0,1] along the
// shortest arc. Implemented locally (name collision with geom.quat_slerp). O(1).
/// Spherical linear interpolation between a and b by t in [0,1] along the
/// shortest arc. Implemented locally (name collision with geom.quat_slerp). O(1).
pub fn quat_slerp(a: Quat, b: Quat, t: Float64) -> Quat {
  if t <= 0.0 { return a; }
  if t >= 1.0 { return b; }
  var dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
  var bb = b;
  var cd = dot;
  if cd < 0.0 {
    bb = Quat{ x: -b.x; y: -b.y; z: -b.z; w: -b.w; };
    cd = -cd;
  }
  if cd > 1.0 { cd = 1.0; }
  if cd < -1.0 { cd = -1.0; }
  if cd > 0.9995 {
    var ct = t;
    if ct < 0.0 { ct = 0.0; }
    if ct > 1.0 { ct = 1.0; }
    var n = Quat{
      x: a.x + (bb.x - a.x) * ct;
      y: a.y + (bb.y - a.y) * ct;
      z: a.z + (bb.z - a.z) * ct;
      w: a.w + (bb.w - a.w) * ct;
    };
    return quat_normalize(n);
  }
  var theta = math.acos(cd);
  var sin_theta = math.sin(theta);
  var wa = math.sin((1.0 - t) * theta) / sin_theta;
  var wb = math.sin(t * theta) / sin_theta;
  return Quat{
    x: wa * a.x + wb * bb.x;
    y: wa * a.y + wb * bb.y;
    z: wa * a.z + wb * bb.z;
    w: wa * a.w + wb * bb.w;
  };
}

// Normalised linear interpolation between a and b by t (t clamped to [0,1]).
// Implemented locally (name collision with geom.quat_nlerp). O(1).
/// Normalised linear interpolation between a and b by t (t clamped to [0,1]).
/// Implemented locally (name collision with geom.quat_nlerp). O(1).
pub fn quat_nlerp(a: Quat, b: Quat, t: Float64) -> Quat {
  var ct = t;
  if ct < 0.0 { ct = 0.0; }
  if ct > 1.0 { ct = 1.0; }
  var n = Quat{
    x: a.x + (b.x - a.x) * ct;
    y: a.y + (b.y - a.y) * ct;
    z: a.z + (b.z - a.z) * ct;
    w: a.w + (b.w - a.w) * ct;
  };
  return quat_normalize(n);
}

// Rotation angle of q in radians, in [0, PI]. 0 for the identity. O(1).
/// Rotation angle of q in radians, in [0, PI]. 0 for the identity. O(1).
pub fn quat_angle(q: Quat) -> Float64 {
  var w = q.w;
  if w > 1.0 { w = 1.0; }
  if w < -1.0 { w = -1.0; }
  return 2.0 * math.acos(w);
}

// Unit rotation axis of q (direction of the vector part). Returns the zero
// vector when q represents no rotation. O(1).
/// Unit rotation axis of q (direction of the vector part). Returns the zero
/// vector when q represents no rotation. O(1).
pub fn quat_axis(q: Quat) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var len = math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
  if len == 0.0 {
    out.push(0.0);
    out.push(0.0);
    out.push(0.0);
    return out;
  }
  var inv = 1.0 / len;
  out.push(q.x * inv);
  out.push(q.y * inv);
  out.push(q.z * inv);
  return out;
}

// Orientation quaternion looking from eye towards target with the given up
// direction (right-handed). Returns the identity for a degenerate look. O(1).
/// Orientation quaternion looking from eye towards target with the given up
/// direction (right-handed). Returns the identity for a degenerate look. O(1).
pub fn quat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Quat {
  var id = Quat{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
  var ex = 0.0;
  var ey = 0.0;
  var ez = 0.0;
  if eye.len() >= 1 { ex = eye[0]; }
  if eye.len() >= 2 { ey = eye[1]; }
  if eye.len() >= 3 { ez = eye[2]; }
  var tx = 0.0;
  var ty = 0.0;
  var tz = 0.0;
  if target.len() >= 1 { tx = target[0]; }
  if target.len() >= 2 { ty = target[1]; }
  if target.len() >= 3 { tz = target[2]; }
  var ux = 0.0;
  var uy = 0.0;
  var uz = 0.0;
  if up.len() >= 1 { ux = up[0]; }
  if up.len() >= 2 { uy = up[1]; }
  if up.len() >= 3 { uz = up[2]; }
  var fx = tx - ex;
  var fy = ty - ey;
  var fz = tz - ez;
  var fl = math.sqrt(fx * fx + fy * fy + fz * fz);
  if fl == 0.0 { return id; }
  var f_inv = 1.0 / fl;
  fx = fx * f_inv;
  fy = fy * f_inv;
  fz = fz * f_inv;
  var rx = fy * uz - fz * uy;
  var ry = fz * ux - fx * uz;
  var rz = fx * uy - fy * ux;
  var rl = math.sqrt(rx * rx + ry * ry + rz * rz);
  if rl == 0.0 { return id; }
  var r_inv = 1.0 / rl;
  rx = rx * r_inv;
  ry = ry * r_inv;
  rz = rz * r_inv;
  var sx = ry * fz - rz * fy;
  var sy = rz * fx - rx * fz;
  var sz = rx * fy - ry * fx;
  // Orientation matrix (columns r, u, -f) maps camera -Z to the world
  // forward f. The trace-method formulas below use the row-major elements
  // m00 = r.x, m01 = u.x, m02 = -f.x, etc.
  var nx = -fx;
  var ny = -fy;
  var nz = -fz;
  var trace = rx + sy + nz;
  if trace > 0.0 {
    var s = math.sqrt(trace + 1.0) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: (sz - ny) * inv_s;
      y: (nx - rz) * inv_s;
      z: (ry - sx) * inv_s;
      w: 0.25 * s;
    };
  }
  if rx > sy && rx > nz {
    var s = math.sqrt(1.0 + rx - sy - nz) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: 0.25 * s;
      y: (sx + ry) * inv_s;
      z: (nx + rz) * inv_s;
      w: (sz - ny) * inv_s;
    };
  }
  if sy > nz {
    var s = math.sqrt(1.0 + sy - rx - nz) * 2.0;
    var inv_s = 1.0 / s;
    return Quat{
      x: (sx + ry) * inv_s;
      y: 0.25 * s;
      z: (ny + sz) * inv_s;
      w: (nx - rz) * inv_s;
    };
  }
  var s = math.sqrt(1.0 + nz - rx - sy) * 2.0;
  var inv_s = 1.0 / s;
  return Quat{
    x: (nx + rz) * inv_s;
    y: (ny + sz) * inv_s;
    z: 0.25 * s;
    w: (ry - sx) * inv_s;
  };
}

// Shortest rotation quaternion mapping the unit direction a onto the unit
// direction b. Returns the identity when a or b is degenerate. O(1).
/// Shortest rotation quaternion mapping the unit direction a onto the unit
/// direction b. Returns the identity when a or b is degenerate. O(1).
pub fn quat_between(a: &Vec[Float64], b: &Vec[Float64]) -> Quat {
  var id = Quat{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
  var ax = 0.0;
  var ay = 0.0;
  var az = 0.0;
  if a.len() >= 1 { ax = a[0]; }
  if a.len() >= 2 { ay = a[1]; }
  if a.len() >= 3 { az = a[2]; }
  var bx = 0.0;
  var by = 0.0;
  var bz = 0.0;
  if b.len() >= 1 { bx = b[0]; }
  if b.len() >= 2 { by = b[1]; }
  if b.len() >= 3 { bz = b[2]; }
  var al = math.sqrt(ax * ax + ay * ay + az * az);
  var bl = math.sqrt(bx * bx + by * by + bz * bz);
  if al == 0.0 || bl == 0.0 { return id; }
  var a_inv = 1.0 / al;
  var b_inv = 1.0 / bl;
  ax = ax * a_inv;
  ay = ay * a_inv;
  az = az * a_inv;
  bx = bx * b_inv;
  by = by * b_inv;
  bz = bz * b_inv;
  var d = ax * bx + ay * by + az * bz;
  if d > 1.0 { d = 1.0; }
  if d < -1.0 { d = -1.0; }
  var cx = ay * bz - az * by;
  var cy = az * bx - ax * bz;
  var cz = ax * by - ay * bx;
  var cl = math.sqrt(cx * cx + cy * cy + cz * cz);
  if cl < 0.000000000001 {
    if d >= 0.0 { return id; }
    // Opposite directions: rotate 180 degrees about any perpendicular axis.
    var px = 1.0;
    var py = 0.0;
    var pz = 0.0;
    if math.abs_float(ax) < 0.9 {
      px = 0.0;
      py = 1.0;
      pz = 0.0;
    }
    var ox = py * az - pz * ay;
    var oy = pz * ax - px * az;
    var oz = px * ay - py * ax;
    var ol = math.sqrt(ox * ox + oy * oy + oz * oz);
    if ol == 0.0 { return id; }
    var o_inv = 1.0 / ol;
    return Quat{ x: ox * o_inv; y: oy * o_inv; z: oz * o_inv; w: 0.0; };
  }
  var c_inv = 1.0 / cl;
  var half = math.acos(d) * 0.5;
  var s = math.sin(half);
  return Quat{
    x: cx * c_inv * s;
    y: cy * c_inv * s;
    z: cz * c_inv * s;
    w: math.cos(half);
  };
}

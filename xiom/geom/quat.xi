// XIOM - Geom: Quat
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
// Home: geom.xi - this sublib splits the quaternion domain; the canonical
// Quaternion type and operations live in geom.xi.

module xiom.geom.quat

// Depends on: xiom.geom

// ============================================================================
// Quaternion rotation algebra split from geom.xi. TODO(compiler): implement.
//
// The canonical geom.xi Quaternion type is used for delegation: functions
// whose names differ from geom.xi delegate via a Quat <-> Quaternion
// conversion; same-name functions are implemented locally to avoid ambiguity.
// ============================================================================

use xiom.geom;
use xiom.math;

// Quaternion (x, y, z, w); w is the scalar part.
pub type Quat = { x: Float64; y: Float64; z: Float64; w: Float64; }

// Construct a quaternion from components. Implemented locally (name collision
// with geom.quat_new which takes axis/angle). O(1).
pub fn quat_new(x: Float64, y: Float64, z: Float64, w: Float64) -> Quat {
  return Quat{ x: x; y: y; z: z; w: w; };
}

// Identity quaternion (no rotation). Implemented locally (name collision). O(1).
pub fn quat_identity() -> Quat {
  return Quat{ x: 0.0; y: 0.0; z: 0.0; w: 1.0; };
}

// Hamilton product a * b (compose rotations; b applied first). Implemented
// locally (name collision with geom.quat_mul). O(1).
pub fn quat_mul(a: Quat, b: Quat) -> Quat {
  return Quat{
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y;
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x;
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w;
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z;
  };
}

// Conjugate of a quaternion: negate the vector part. Implemented locally
// (name collision with geom.quat_conjugate). O(1).
pub fn quat_conjugate(q: Quat) -> Quat {
  return Quat{ x: -q.x; y: -q.y; z: -q.z; w: q.w; };
}

// Inverse of a unit quaternion (the conjugate). Delegates to geom.quat_inverse
// through the canonical Quaternion type. O(1).
pub fn quat_inv(q: Quat) -> Quat {
  var gq = geom.quat_inverse(Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; });
  return Quat{ x: gq.x; y: gq.y; z: gq.z; w: gq.w; };
}

// Euclidean length of a quaternion. Delegates to geom.quat_length. O(1).
pub fn quat_norm(q: Quat) -> Float64 {
  return geom.quat_length(Quaternion{ x: q.x; y: q.y; z: q.z; w: q.w; });
}

// Unit quaternion; identity if the length is zero. Implemented locally (name
// collision with geom.quat_normalize). O(1).
pub fn quat_normalize(q: Quat) -> Quat {
  var len = quat_norm(q);
  if len == 0.0 { return quat_identity(); }
  return Quat{ x: q.x / len; y: q.y / len; z: q.z / len; w: q.w / len; };
}

// Quaternion rotating angle (radians) about the (non-zero) axis direction.
// The axis is normalised first. Implemented locally (name collision). O(1).
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

// Extract (yaw, pitch, roll) in radians, matching geom.quat_from_euler (ZYX
// intrinsic). Implemented locally: module-qualified results inside a tuple
// literal mis-type as Int in this compiler (BUG). O(1).
pub fn quat_to_euler(q: Quat) -> (Float64, Float64, Float64) {
  var yaw = math.atan2(2.0 * (q.w * q.z + q.x * q.y), 1.0 - 2.0 * (q.y * q.y + q.z * q.z));
  var sp = 2.0 * (q.w * q.y - q.z * q.x);
  if sp > 1.0 { sp = 1.0; }
  if sp < -1.0 { sp = -1.0; }
  var pitch = math.asin(sp);
  var roll = math.atan2(2.0 * (q.w * q.x + q.y * q.z), 1.0 - 2.0 * (q.x * q.x + q.y * q.y));
  return (yaw, pitch, roll);
}

// Spherical linear interpolation between a and b by t in [0,1] along the
// shortest arc. Implemented locally (name collision with geom.quat_slerp). O(1).
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

// Rotate the 3D vector v by quaternion q. Delegates to geom.quat_rotate_vec3
// through the canonical types. O(1).
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

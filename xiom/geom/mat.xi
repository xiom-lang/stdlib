// XIOM - Geom: Mat
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Home: geom.xi - this sublib splits the matrix domain; the canonical Mat2/3/4
// types and operations live in geom.xi.

module xiom.geom.mat

// Depends on: xiom.geom

// ============================================================================
// Matrix operations split from geom.xi: identity, products, determinants,
// inverses, and 4x4 affine/projection transforms. TODO(compiler): implement.
//
// IMPORTANT (compiler): by-ref nested float Vec element reads (BUG 26 #1)
// return garbage, so every `&Vec[Vec[Float64]]` parameter is copied into a
// local matrix with single-level row copies first, and element access uses
// direct double indexing on that local copy. All returned matrices are built
// with fresh row allocations.
// ============================================================================

use xiom.geom;
use xiom.math;

// n x n identity matrix. O(n^2).
pub fn mat_identity(n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Matrix product a * b. Returns an empty matrix when the inner dimensions do
// not match. O(n^3).
pub fn mat_mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var ra = ac.len();
  if ra == 0 { return out; }
  var ca = ac[0].len();
  var rb = bc.len();
  if rb == 0 { return out; }
  var cb = bc[0].len();
  if ca != rb { return out; }
  i = 0;
  while i < ra {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cb {
      var s = 0.0;
      var k = 0;
      while k < ca {
        s = s + ac[i][k] * bc[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Determinant of a square matrix via Gaussian elimination with partial
// pivoting. Returns NaN for a non-square matrix and 0 for a singular one. O(n^3).
pub fn mat_det(m: &Vec[Vec[Float64]]) -> Float64 {
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    sc.push(m[i]);
    i = i + 1;
  }
  var mc = Vec[Vec[Float64]].new();
  i = 0;
  while i < sc.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < sc[i].len() {
      row.push(sc[i][j]);
      j = j + 1;
    }
    mc.push(row);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return 0.0; }
  if mc[0].len() != n { return 0.0 / 0.0; }
  var det = 1.0;
  var sign = 1.0;
  var k = 0;
  while k < n {
    var p = k;
    var pk = math.abs_float(mc[k][k]);
    var t = k + 1;
    while t < n {
      var av = math.abs_float(mc[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return 0.0;
    }
    if p != k {
      var jj = 0;
      while jj < n {
        var tv = mc[p][jj];
        mc[p][jj] = mc[k][jj];
        mc[k][jj] = tv;
        jj = jj + 1;
      }
      sign = -sign;
    }
    var piv = mc[k][k];
    var r = k + 1;
    while r < n {
      var f = mc[r][k] / piv;
      var j = k + 1;
      while j < n {
        mc[r][j] = mc[r][j] - f * mc[k][j];
        j = j + 1;
      }
      r = r + 1;
    }
    det = det * piv;
    k = k + 1;
  }
  return det * sign;
}

// Inverse of a square matrix via Gauss-Jordan elimination with partial
// pivoting. None when the matrix is singular or non-square. O(n^3).
pub fn mat_inv(m: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] {
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    sc.push(m[i]);
    i = i + 1;
  }
  var mc = Vec[Vec[Float64]].new();
  i = 0;
  while i < sc.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < sc[i].len() {
      row.push(sc[i][j]);
      j = j + 1;
    }
    mc.push(row);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return None; }
  if mc[0].len() != n { return None; }
  var aug = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(mc[i][j]);
      j = j + 1;
    }
    j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    aug.push(row);
    i = i + 1;
  }
  var k = 0;
  while k < n {
    var p = k;
    var pk = math.abs_float(aug[k][k]);
    var t = k + 1;
    while t < n {
      var av = math.abs_float(aug[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return None;
    }
    if p != k {
      var jj = 0;
      while jj < 2 * n {
        var tv = aug[p][jj];
        aug[p][jj] = aug[k][jj];
        aug[k][jj] = tv;
        jj = jj + 1;
      }
    }
    var piv = aug[k][k];
    var j = 0;
    while j < 2 * n {
      aug[k][j] = aug[k][j] / piv;
      j = j + 1;
    }
    var r = 0;
    while r < n {
      if r != k {
        var f = aug[r][k];
        if f != 0.0 {
          var jj = 0;
          while jj < 2 * n {
            aug[r][jj] = aug[r][jj] - f * aug[k][jj];
            jj = jj + 1;
          }
        }
      }
      r = r + 1;
    }
    k = k + 1;
  }
  var out = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(aug[i][n + j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return Some(out);
}

// Transpose of a matrix. Empty matrix for a ragged input. O(n*m).
pub fn mat_transpose(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var r = mc.len();
  if r == 0 { return out; }
  var c = mc[0].len();
  var j = 0;
  while j < c {
    var col = Vec[Float64].new();
    i = 0;
    while i < r {
      col.push(mc[i][j]);
      i = i + 1;
    }
    out.push(col);
    j = j + 1;
  }
  return out;
}

// Compose the 4x4 matrix m with a translation (x, y, z): returns T * m where
// T is the translation matrix, so the translation is applied after m.
// Empty matrix unless m is 4x4. O(64).
pub fn mat_translate(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  if mc.len() != 4 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != 4 { return Vec[Vec[Float64]].new(); }
  var out = Vec[Vec[Float64]].new();
  i = 0;
  while i < 4 {
    var row = Vec[Float64].new();
    var j = 0;
    while j < 4 {
      var v = mc[i][j];
      if i == 0 { v = v + x * mc[3][j]; }
      if i == 1 { v = v + y * mc[3][j]; }
      if i == 2 { v = v + z * mc[3][j]; }
      row.push(v);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Compose the 4x4 matrix m with a rotation of angle (radians) about the axis
// direction: returns R * m where R is the Rodrigues rotation matrix (the axis
// is normalised first). Empty matrix unless m is 4x4. O(64).
pub fn mat_rotate(m: &Vec[Vec[Float64]], angle: Float64, axis: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  if mc.len() != 4 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != 4 { return Vec[Vec[Float64]].new(); }
  var ax = 0.0;
  var ay = 0.0;
  var az = 0.0;
  if axis.len() >= 1 { ax = axis[0]; }
  if axis.len() >= 2 { ay = axis[1]; }
  if axis.len() >= 3 { az = axis[2]; }
  var alen = math.sqrt(ax * ax + ay * ay + az * az);
  if alen == 0.0 {
    var out = Vec[Vec[Float64]].new();
    i = 0;
    while i < 4 {
      var row = Vec[Float64].new();
      var j = 0;
      while j < 4 {
        row.push(mc[i][j]);
        j = j + 1;
      }
      out.push(row);
      i = i + 1;
    }
    return out;
  }
  var inv = 1.0 / alen;
  var x = ax * inv;
  var y = ay * inv;
  var z = az * inv;
  var c = math.cos(angle);
  var s = math.sin(angle);
  var t = 1.0 - c;
  var out = Vec[Vec[Float64]].new();
  i = 0;
  while i < 4 {
    var row = Vec[Float64].new();
    var j = 0;
    while j < 4 {
      var r0j = t * x * mc[0][j] + (t * x * y - s * z) * mc[1][j] + (t * x * z + s * y) * mc[2][j];
      var r1j = (t * x * y + s * z) * mc[0][j] + (t * y * y + c) * mc[1][j] + (t * y * z - s * x) * mc[2][j];
      var r2j = (t * x * z - s * y) * mc[0][j] + (t * y * z + s * x) * mc[1][j] + (t * z * z + c) * mc[2][j];
      if i == 0 { row.push(r0j); }
      if i == 1 { row.push(r1j); }
      if i == 2 { row.push(r2j); }
      if i == 3 {
        row.push(mc[3][j]);
      }
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Compose the 4x4 matrix m with a scale (x, y, z): returns S * m where S is
// the scale matrix, applied after m. Empty matrix unless m is 4x4. O(64).
pub fn mat_scale(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  if mc.len() != 4 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != 4 { return Vec[Vec[Float64]].new(); }
  var out = Vec[Vec[Float64]].new();
  i = 0;
  while i < 4 {
    var row = Vec[Float64].new();
    var j = 0;
    while j < 4 {
      var sx = x;
      if i == 1 { sx = y; }
      if i == 2 { sx = z; }
      if i == 3 { sx = 1.0; }
      row.push(sx * mc[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Right-handed look-at view matrix: camera at eye looking at target with up
// direction. Column-major 4x4. O(1).
pub fn mat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Vec[Vec[Float64]] {
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
  if fl == 0.0 { fl = 1.0; }
  fx = fx / fl;
  fy = fy / fl;
  fz = fz / fl;
  var rx = fy * uz - fz * uy;
  var ry = fz * ux - fx * uz;
  var rz = fx * uy - fy * ux;
  var rl = math.sqrt(rx * rx + ry * ry + rz * rz);
  if rl == 0.0 { rl = 1.0; }
  rx = rx / rl;
  ry = ry / rl;
  rz = rz / rl;
  var sx = ry * fz - rz * fy;
  var sy = rz * fx - rx * fz;
  var sz = rx * fy - ry * fx;
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(rx);
  r0.push(ry);
  r0.push(rz);
  r0.push(-(rx * ex + ry * ey + rz * ez));
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(sx);
  r1.push(sy);
  r1.push(sz);
  r1.push(-(sx * ex + sy * ey + sz * ez));
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(-fx);
  r2.push(-fy);
  r2.push(-fz);
  r2.push(fx * ex + fy * ey + fz * ez);
  out.push(r2);
  var r3 = Vec[Float64].new();
  r3.push(0.0);
  r3.push(0.0);
  r3.push(0.0);
  r3.push(1.0);
  out.push(r3);
  return out;
}

// Perspective projection matrix (right-handed, standard OpenGL mapping).
// fovy is the vertical field of view in radians; near/far must differ. 4x4. O(1).
pub fn mat_perspective(fovy: Float64, aspect: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] {
  var f = 1.0 / math.tan(fovy * 0.5);
  var nf = 1.0 / (near - far);
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(f / aspect);
  r0.push(0.0);
  r0.push(0.0);
  r0.push(0.0);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(0.0);
  r1.push(f);
  r1.push(0.0);
  r1.push(0.0);
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(0.0);
  r2.push(0.0);
  r2.push((far + near) * nf);
  r2.push((2.0 * far * near) * nf);
  out.push(r2);
  var r3 = Vec[Float64].new();
  r3.push(0.0);
  r3.push(0.0);
  r3.push(-1.0);
  r3.push(0.0);
  out.push(r3);
  return out;
}

// Orthographic projection matrix mapping [left,right] x [bottom,top] x
// [near,far] to NDC [-1,1]^3. 4x4. O(1).
pub fn mat_ortho(left: Float64, right: Float64, bottom: Float64, top: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] {
  var rl = right - left;
  var tb = top - bottom;
  var fd = far - near;
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(2.0 / rl);
  r0.push(0.0);
  r0.push(0.0);
  r0.push(-(right + left) / rl);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(0.0);
  r1.push(2.0 / tb);
  r1.push(0.0);
  r1.push(-(top + bottom) / tb);
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(0.0);
  r2.push(0.0);
  r2.push(-2.0 / fd);
  r2.push(-(far + near) / fd);
  out.push(r2);
  var r3 = Vec[Float64].new();
  r3.push(0.0);
  r3.push(0.0);
  r3.push(0.0);
  r3.push(1.0);
  out.push(r3);
  return out;
}

// Transform the point p (3 or 4 components, w defaults to 1) by the 4x4
// matrix m including the perspective divide. Returns the zero vector when the
// transformed w is zero. Empty vector for a non-4x4 matrix. O(16).
pub fn mat_transform_point(m: &Vec[Vec[Float64]], p: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  if mc.len() != 4 { return out; }
  if mc[0].len() != 4 { return out; }
  var px = 0.0;
  var py = 0.0;
  var pz = 0.0;
  var pw = 1.0;
  if p.len() >= 1 { px = p[0]; }
  if p.len() >= 2 { py = p[1]; }
  if p.len() >= 3 { pz = p[2]; }
  if p.len() >= 4 { pw = p[3]; }
  var w = mc[3][0] * px + mc[3][1] * py + mc[3][2] * pz + mc[3][3] * pw;
  if w == 0.0 {
    out.push(0.0);
    out.push(0.0);
    out.push(0.0);
    return out;
  }
  var inv_w = 1.0 / w;
  out.push((mc[0][0] * px + mc[0][1] * py + mc[0][2] * pz + mc[0][3] * pw) * inv_w);
  out.push((mc[1][0] * px + mc[1][1] * py + mc[1][2] * pz + mc[1][3] * pw) * inv_w);
  out.push((mc[2][0] * px + mc[2][1] * py + mc[2][2] * pz + mc[2][3] * pw) * inv_w);
  return out;
}

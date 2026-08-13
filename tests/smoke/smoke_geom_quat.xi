// Smoke: xiom.geom.quat + xiom.geom.quaternion.
// Returns 0 on success; prints the failing tag on failure.
use xiom.geom.quat;
use xiom.geom.quaternion;
use xiom.io;
use xiom.convert;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // ---- quat: construction and identity ------------------------------------
  var q = quat.quat_new(0.0, 0.0, 0.0, 1.0);
  if q.w != 1.0 || q.x != 0.0 { io.println("quat-new"); return 1; }
  var qi = quat.quat_identity();
  if qi.w != 1.0 || qi.x != 0.0 || qi.y != 0.0 || qi.z != 0.0 { io.println("quat-id"); return 2; }
  var qm = quat.quat_mul(q, qi);
  if !near(qm.w, 1.0) || !near(qm.x, 0.0) { io.println("quat-mul-id"); return 3; }
  var qc = quat.quat_conjugate(quat.quat_new(1.0, 2.0, 3.0, 4.0));
  if qc.x != -1.0 || qc.y != -2.0 || qc.z != -3.0 || qc.w != 4.0 { io.println("quat-conj"); return 4; }
  if !near(quat.quat_norm(quat.quat_new(1.0, 2.0, 2.0, 0.0)), 3.0) { io.println("quat-norm"); return 5; }
  var qn = quat.quat_normalize(quat.quat_new(3.0, 0.0, 0.0, 0.0));
  if !near(qn.x, 1.0) || !near(qn.w, 0.0) { io.println("quat-normalize"); return 6; }
  var qnz = quat.quat_normalize(quat.quat_new(0.0, 0.0, 0.0, 0.0));
  if !near(qnz.w, 1.0) { io.println("quat-normalize-zero"); return 7; }
  var qinv = quat.quat_inv(quat.quat_new(0.0, 0.0, 0.7071067812, 0.7071067812));
  if !near(qinv.z, -0.7071067812) || !near(qinv.w, 0.7071067812) { io.println("quat-inv"); return 8; }

  // ---- quat: axis/angle and rotate ----------------------------------------
  var zaxis = Vec[Float64].new();
  zaxis.push(0.0); zaxis.push(0.0); zaxis.push(1.0);
  var qaa = quat.quat_from_axis_angle(&zaxis, 1.5707963268);
  if !near(qaa.z, 0.7071067812) || !near(qaa.w, 0.7071067812) { io.println("quat-axis-angle"); return 9; }
  var vx = Vec[Float64].new();
  vx.push(1.0); vx.push(0.0); vx.push(0.0);
  var rv = quat.quat_rotate(qaa, &vx);
  var rvx: Float64 = rv[0];
  var rvy: Float64 = rv[1];
  var rvz: Float64 = rv[2];
  if !near(rvx, 0.0) || !near(rvy, 1.0) || !near(rvz, 0.0) { io.println("quat-rotate"); return 10; }

  // ---- quat: euler and slerp ----------------------------------------------
  var eul = quat.quat_to_euler(qi);
  if !near(eul.0, 0.0) || !near(eul.1, 0.0) || !near(eul.2, 0.0) { io.println("quat-euler"); return 11; }
  var qsl = quat.quat_slerp(qi, qi, 0.5);
  if !near(qsl.w, 1.0) { io.println("quat-slerp"); return 12; }

  // ---- quaternion: construction -------------------------------------------
  var qn2 = quaternion.quat_new(0.0, 0.0, 0.0, 1.0);
  if qn2.w != 1.0 { io.println("q2-new"); return 13; }
  var qnid = quaternion.quat_identity();
  if qnid.w != 1.0 { io.println("q2-id"); return 14; }
  var qaa2 = quaternion.quat_from_axis_angle(&zaxis, 1.5707963268);
  if !near(qaa2.z, 0.7071067812) || !near(qaa2.w, 0.7071067812) { io.println("q2-axis-angle"); return 15; }
  var qe = quaternion.quat_from_euler(0.0, 0.0, 0.0);
  if !near(qe.w, 1.0) || !near(qe.x, 0.0) { io.println("q2-from-euler"); return 16; }
  var qem = quaternion.quat_from_euler(1.5707963268, 0.0, 0.0);
  if !near(qem.z, 0.7071067812) || !near(qem.w, 0.7071067812) { io.println("q2-euler-yaw"); return 17; }

  // ---- quaternion: rotation matrix round-trip ------------------------------
  var qrot = quaternion.quat_from_axis_angle(&zaxis, 1.5707963268);
  var mq = quaternion.quat_to_matrix(qrot);
  var qback = quaternion.quat_from_rotation_matrix(&mq);
  if !near(qback.z, 0.7071067812) || !near(qback.w, 0.7071067812) { io.println("q2-mat-roundtrip"); return 18; }
  var id3 = Vec[Vec[Float64]].new();
  var idr0 = Vec[Float64].new();
  idr0.push(1.0); idr0.push(0.0); idr0.push(0.0);
  id3.push(idr0);
  var idr1 = Vec[Float64].new();
  idr1.push(0.0); idr1.push(1.0); idr1.push(0.0);
  id3.push(idr1);
  var idr2 = Vec[Float64].new();
  idr2.push(0.0); idr2.push(0.0); idr2.push(1.0);
  id3.push(idr2);
  var qfid = quaternion.quat_from_rotation_matrix(&id3);
  if !near(qfid.w, 1.0) { io.println("q2-from-mat-id"); return 19; }

  // ---- quaternion: mul/conj/inv/norm/normalize -----------------------------
  var qm2 = quaternion.quat_mul(qn2, qnid);
  if !near(qm2.w, 1.0) { io.println("q2-mul"); return 20; }
  var qcj = quaternion.quat_conj(quaternion.quat_new(1.0, 2.0, 3.0, 4.0));
  if qcj.x != -1.0 || qcj.y != -2.0 || qcj.z != -3.0 || qcj.w != 4.0 { io.println("q2-conj"); return 21; }
  var qiv = quaternion.quat_inv(quaternion.quat_new(0.0, 0.0, 0.7071067812, 0.7071067812));
  if !near(qiv.z, -0.7071067812) { io.println("q2-inv"); return 22; }
  if !near(quaternion.quat_norm(quaternion.quat_new(1.0, 2.0, 2.0, 0.0)), 3.0) { io.println("q2-norm"); return 23; }
  var qnz2 = quaternion.quat_normalize(quaternion.quat_new(3.0, 0.0, 0.0, 0.0));
  if !near(qnz2.x, 1.0) { io.println("q2-normalize"); return 24; }
  var qrv = quaternion.quat_rotate(qaa2, &vx);
  var qrvx: Float64 = qrv[0];
  var qrvy: Float64 = qrv[1];
  if !near(qrvx, 0.0) || !near(qrvy, 1.0) { io.println("q2-rotate"); return 25; }

  // ---- quaternion: euler/slerp/nlerp/angle/axis ----------------------------
  var qe2 = quaternion.quat_to_euler(qnid);
  if !near(qe2.0, 0.0) || !near(qe2.1, 0.0) || !near(qe2.2, 0.0) { io.println("q2-euler"); return 26; }
  var qsl2 = quaternion.quat_slerp(qnid, qnid, 0.5);
  if !near(qsl2.w, 1.0) { io.println("q2-slerp"); return 27; }
  var qnl = quaternion.quat_nlerp(qnid, qnid, 0.5);
  if !near(qnl.w, 1.0) { io.println("q2-nlerp"); return 28; }
  var qang = quaternion.quat_angle(qaa2);
  if !near(qang, 1.5707963268) { io.println("q2-angle"); return 29; }
  var qax = quaternion.quat_axis(qaa2);
  var qaxx: Float64 = qax[0];
  var qaxy: Float64 = qax[1];
  var qaxz: Float64 = qax[2];
  if !near(qaxx, 0.0) || !near(qaxy, 0.0) || !near(qaxz, 1.0) { io.println("q2-axis"); return 30; }

  // ---- quaternion: look_at and between -------------------------------------
  var eye = Vec[Float64].new();
  eye.push(5.0); eye.push(0.0); eye.push(0.0);
  var tgt = Vec[Float64].new();
  tgt.push(0.0); tgt.push(0.0); tgt.push(0.0);
  var up = Vec[Float64].new();
  up.push(0.0); up.push(1.0); up.push(0.0);
  var qla = quaternion.quat_look_at(&eye, &tgt, &up);
  var fwd = Vec[Float64].new();
  fwd.push(0.0); fwd.push(0.0); fwd.push(-1.0);
  var lrf = quaternion.quat_rotate(qla, &fwd);
  var lfx: Float64 = lrf[0];
  var lfy: Float64 = lrf[1];
  var lfz: Float64 = lrf[2];
  if !near(lfx, -1.0) || !near(lfy, 0.0) || !near(lfz, 0.0) { io.println("q2-lookat"); return 31; }
  var xa = Vec[Float64].new();
  xa.push(1.0); xa.push(0.0); xa.push(0.0);
  var yb = Vec[Float64].new();
  yb.push(0.0); yb.push(1.0); yb.push(0.0);
  var qbt = quaternion.quat_between(&xa, &yb);
  var br = quaternion.quat_rotate(qbt, &xa);
  var brx: Float64 = br[0];
  var bry: Float64 = br[1];
  if !near(brx, 0.0) || !near(bry, 1.0) { io.println("q2-between"); return 32; }
  var qbtax = quaternion.quat_axis(qbt);
  var qbx: Float64 = qbtax[0];
  var qby: Float64 = qbtax[1];
  var qbz: Float64 = qbtax[2];
  if !near(qbx, 0.0) || !near(qby, 0.0) || !near(qbz, 1.0) { io.println("q2-between-axis"); return 33; }

  io.println("OK");
  return 0;
}

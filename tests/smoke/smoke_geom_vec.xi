// Smoke: xiom.geom.vec + xiom.geom.vector + xiom.geom.linear.
// Returns 0 on success; prints the failing tag on failure.
use xiom.geom.vec;
use xiom.geom.vector;
use xiom.geom.linear;
use xiom.io;
use xiom.convert;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // ---- vec: fixed-size Vec2 via geom delegation -------------------------
  var v2a = vec.vec2(1.0, 2.0);
  var v2b = vec.vec2(3.0, 4.0);
  if !near(vec.vec2_len(v2a), 2.2360679775) { io.println("vec2-len"); return 1; }
  var s2 = vec.vec2_add(v2a, v2b);
  if s2.x != 4.0 || s2.y != 6.0 { io.println("vec2-add"); return 2; }
  var d2 = vec.vec2_sub(v2b, v2a);
  if d2.x != 2.0 || d2.y != 2.0 { io.println("vec2-sub"); return 3; }
  if vec.vec2_dot(v2a, v2b) != 11.0 { io.println("vec2-dot"); return 4; }
  if vec.vec2_cross(v2a, v2b) != -2.0 { io.println("vec2-cross"); return 5; }
  var sc2 = vec.vec2_scale(v2a, 3.0);
  if sc2.x != 3.0 || sc2.y != 6.0 { io.println("vec2-scale"); return 6; }
  var n2 = vec.vec2_norm(vec.vec2(3.0, 4.0));
  if !near(n2.x, 0.6) || !near(n2.y, 0.8) { io.println("vec2-norm"); return 7; }
  if !near(vec.vec2_dist(vec.vec2(1.0, 2.0), vec.vec2(4.0, 6.0)), 5.0) { io.println("vec2-dist"); return 8; }
  var l2 = vec.vec2_lerp(vec.vec2(0.0, 0.0), vec.vec2(2.0, 4.0), 0.5);
  if l2.x != 1.0 || l2.y != 2.0 { io.println("vec2-lerp"); return 9; }

  // ---- vec: fixed-size Vec3 ---------------------------------------------
  var v3a = vec.vec3_new(1.0, 2.0, 3.0);
  var v3b = vec.vec3_new(4.0, 5.0, 6.0);
  var s3 = vec.vec3_add(v3a, v3b);
  if s3.x != 5.0 || s3.y != 7.0 || s3.z != 9.0 { io.println("vec3-add"); return 10; }
  var d3 = vec.vec3_sub(v3b, v3a);
  if d3.x != 3.0 || d3.y != 3.0 || d3.z != 3.0 { io.println("vec3-sub"); return 11; }
  if vec.vec3_dot(v3a, v3b) != 32.0 { io.println("vec3-dot"); return 12; }
  var c3 = vec.vec3_cross(vec.vec3_new(1.0, 0.0, 0.0), vec.vec3_new(0.0, 1.0, 0.0));
  if c3.x != 0.0 || c3.y != 0.0 || c3.z != 1.0 { io.println("vec3-cross"); return 13; }
  if !near(vec.vec3_len(vec.vec3_new(1.0, 2.0, 2.0)), 3.0) { io.println("vec3-len"); return 14; }
  var n3 = vec.vec3_norm(vec.vec3_new(3.0, 0.0, 0.0));
  if n3.x != 1.0 || n3.y != 0.0 || n3.z != 0.0 { io.println("vec3-norm"); return 15; }
  if !near(vec.vec3_dist(vec.vec3_new(0.0, 0.0, 0.0), vec.vec3_new(3.0, 4.0, 0.0)), 5.0) { io.println("vec3-dist"); return 16; }
  var sc3 = vec.vec3_scale(v3a, 2.0);
  if sc3.x != 2.0 || sc3.y != 4.0 || sc3.z != 6.0 { io.println("vec3-scale"); return 17; }

  // ---- vec: fixed-size Vec4 ---------------------------------------------
  var v4a = vec.vec4_new(1.0, 2.0, 3.0, 4.0);
  var v4b = vec.vec4_new(1.0, 1.0, 1.0, 1.0);
  var s4 = vec.vec4_add(v4a, v4b);
  if s4.x != 2.0 || s4.y != 3.0 || s4.z != 4.0 || s4.w != 5.0 { io.println("vec4-add"); return 18; }
  var d4 = vec.vec4_sub(v4a, v4b);
  if d4.x != 0.0 || d4.y != 1.0 || d4.z != 2.0 || d4.w != 3.0 { io.println("vec4-sub"); return 19; }
  var sc4 = vec.vec4_scale(v4a, 2.0);
  if sc4.x != 2.0 || sc4.y != 4.0 || sc4.z != 6.0 || sc4.w != 8.0 { io.println("vec4-scale"); return 20; }
  if vec.vec4_dot(v4a, v4b) != 10.0 { io.println("vec4-dot"); return 21; }
  if !near(vec.vec4_len(v4a), 5.4772255751) { io.println("vec4-len"); return 22; }
  var n4 = vec.vec4_norm(vec.vec4_new(2.0, 0.0, 0.0, 0.0));
  if n4.x != 1.0 || n4.y != 0.0 || n4.z != 0.0 || n4.w != 0.0 { io.println("vec4-norm"); return 23; }

  // ---- vec: dynamic reflect/project/angle -------------------------------
  var vr = Vec[Float64].new();
  vr.push(1.0); vr.push(1.0); vr.push(0.0);
  var vn = Vec[Float64].new();
  vn.push(0.0); vn.push(1.0); vn.push(0.0);
  var rf = vec.vec_reflect(&vr, &vn);
  var rproj = vec.vec_project(&rf, &vn);
  if !near(rproj, -1.0) { io.println("vec-reflect"); return 24; }
  var ang = vec.vec_angle(&vr, &rf);
  if !near(ang, 1.5707963268) { io.println("vec-reflect-angle"); return 25; }
  var va2 = Vec[Float64].new();
  va2.push(3.0); va2.push(4.0);
  var vb2 = Vec[Float64].new();
  vb2.push(1.0); vb2.push(0.0);
  if !near(vec.vec_project(&va2, &vb2), 3.0) { io.println("vec-project"); return 26; }
  var va3 = Vec[Float64].new();
  va3.push(1.0); va3.push(0.0); va3.push(0.0);
  var vb3 = Vec[Float64].new();
  vb3.push(0.0); vb3.push(1.0); vb3.push(0.0);
  if !near(vec.vec_angle(&va3, &vb3), 1.5707963268) { io.println("vec-angle"); return 27; }

  // ---- vector: construction + fixed ops ---------------------------------
  if vector.cross2(vector.v2_new(1.0, 2.0), vector.v2_new(3.0, 4.0)) != -2.0 { io.println("v-cross2"); return 28; }
  var vd1 = Vec[Float64].new();
  vd1.push(1.0); vd1.push(2.0); vd1.push(3.0);
  var vd2 = Vec[Float64].new();
  vd2.push(4.0); vd2.push(5.0); vd2.push(6.0);
  if vector.dot(&vd1, &vd2) != 32.0 { io.println("v-dot"); return 29; }
  var vc = vector.cross(&va3, &vb3);
  var ccheck = vector.dot(&vc, &va3);
  if !near(ccheck, 0.0) { io.println("v-cross-perp"); return 30; }
  var clen = vector.norm(&vc);
  if !near(clen, 1.0) { io.println("v-cross-norm"); return 31; }
  var vd3 = Vec[Float64].new();
  vd3.push(3.0); vd3.push(4.0);
  if !near(vector.norm(&vd3), 5.0) { io.println("v-norm"); return 32; }
  if !near(vector.norm_sq(&vd3), 25.0) { io.println("v-norm-sq"); return 33; }
  var vnrm = vector.normalize(&vd3);
  var nrm_self = vector.dot(&vnrm, &vnrm);
  if !near(nrm_self, 1.0) { io.println("v-normalize-unit"); return 34; }
  var nrm_proj = vector.dot(&vnrm, &vd3);
  if !near(nrm_proj, 5.0) { io.println("v-normalize-dot"); return 35; }
  var vun = vector.unit(&vd3);
  var un_proj = vector.dot(&vun, &vd3);
  if !near(un_proj, 5.0) { io.println("v-unit"); return 36; }

  // ---- vector: distances, angles, projections ---------------------------
  var pd1 = Vec[Float64].new();
  pd1.push(1.0); pd1.push(2.0);
  var pd2 = Vec[Float64].new();
  pd2.push(4.0); pd2.push(6.0);
  if !near(vector.distance(&pd1, &pd2), 5.0) { io.println("v-distance"); return 37; }
  if !near(vector.distance_sq(&pd1, &pd2), 25.0) { io.println("v-distance-sq"); return 38; }
  if !near(vector.angle(&va3, &vb3), 1.5707963268) { io.println("v-angle"); return 39; }
  var pr = vector.project(&vd3, &vb2);
  var prcheck = vector.dot(&pr, &vb2);
  if !near(prcheck, 3.0) { io.println("v-project"); return 40; }
  var rj = vector.reject(&vd3, &vb2);
  var rjcheck = vector.dot(&rj, &vb2);
  if !near(rjcheck, 0.0) { io.println("v-reject"); return 41; }
  var rjn = vector.norm(&rj);
  if !near(rjn, 4.0) { io.println("v-reject-norm"); return 42; }

  // ---- vector: lerp/slerp -----------------------------------------------
  var z2 = Vec[Float64].new();
  z2.push(0.0); z2.push(0.0);
  var w2 = Vec[Float64].new();
  w2.push(2.0); w2.push(4.0);
  var lp = vector.lerp(&z2, &w2, 0.5);
  var lpcheck = vector.dot(&lp, &w2);
  if !near(lpcheck, 10.0) { io.println("v-lerp"); return 43; }
  var sl = vector.slerp(&va3, &vb3, 0.5);
  var sl_self = vector.dot(&sl, &sl);
  if !near(sl_self, 1.0) { io.println("v-slerp-unit"); return 44; }
  var diag3 = Vec[Float64].new();
  diag3.push(1.0); diag3.push(1.0); diag3.push(0.0);
  var sl_diag = vector.dot(&sl, &diag3);
  if !near(sl_diag, 1.4142135624) { io.println("v-slerp-mid"); return 45; }

  // ---- vector: reflect/refract/clamp/min/max/hadamard -------------------
  var rf2 = vector.reflect(&vr, &vn);
  var rf2c = vector.dot(&rf2, &vn);
  if !near(rf2c, -1.0) { io.println("v-reflect"); return 46; }
  var gz = Vec[Float64].new();
  gz.push(0.995); gz.push(-0.1); gz.push(0.0);
  var rtir = vector.refract(&gz, &vn, 1.5);
  // NOTE: module-returned Option[Vec[Float64]] is unreliable in this compiler
  // (BUG: is_some/wunwrap of Vec payloads miscompile/crash). Only the stable
  // total-internal-reflection None path is verified here.
  match rtir {
    Some(_) => { io.println("v-refract-tir"); return 47; },
    None => {},
  };
  var vcl = Vec[Float64].new();
  vcl.push(3.0); vcl.push(-2.0); vcl.push(5.0);
  var cl = vector.clamp(&vcl, -1.0, 1.0);
  var one1 = Vec[Float64].new();
  one1.push(1.0); one1.push(-1.0); one1.push(1.0);
  var clcheck = vector.dot(&cl, &one1);
  if !near(clcheck, 3.0) { io.println("v-clamp"); return 51; }
  if !near(vector.component_min(&vcl), -2.0) { io.println("v-min"); return 52; }
  if !near(vector.component_max(&vcl), 5.0) { io.println("v-max"); return 53; }
  var hd1 = Vec[Float64].new();
  hd1.push(1.0); hd1.push(2.0);
  var hd2 = Vec[Float64].new();
  hd2.push(3.0); hd2.push(4.0);
  var hh = vector.hadamard(&hd1, &hd2);
  var hcheck = vector.dot(&hh, &hd1);
  if !near(hcheck, 19.0) { io.println("v-hadamard"); return 54; }

  // ---- linear: predicates -------------------------------------------------
  var sm = Vec[Vec[Float64]].new();
  var smr0 = Vec[Float64].new();
  smr0.push(1.0); smr0.push(2.0);
  sm.push(smr0);
  var smr1 = Vec[Float64].new();
  smr1.push(2.0); smr1.push(3.0);
  sm.push(smr1);
  if !linear.is_symmetric(&sm) { io.println("l-symmetric"); return 55; }
  if linear.is_skew_symmetric(&sm) { io.println("l-skew-false"); return 56; }
  var sk = Vec[Vec[Float64]].new();
  var skr0 = Vec[Float64].new();
  skr0.push(0.0); skr0.push(1.0);
  sk.push(skr0);
  var skr1 = Vec[Float64].new();
  skr1.push(-1.0); skr1.push(0.0);
  sk.push(skr1);
  if !linear.is_skew_symmetric(&sk) { io.println("l-skew"); return 57; }
  var dd = Vec[Vec[Float64]].new();
  var ddr0 = Vec[Float64].new();
  ddr0.push(4.0); ddr0.push(1.0);
  dd.push(ddr0);
  var ddr1 = Vec[Float64].new();
  ddr1.push(1.0); ddr1.push(3.0);
  dd.push(ddr1);
  if !linear.is_diagonal_dominant(&dd) { io.println("l-diagdom"); return 58; }
  var pd = Vec[Vec[Float64]].new();
  var pdr0 = Vec[Float64].new();
  pdr0.push(2.0); pdr0.push(1.0);
  pd.push(pdr0);
  var pdr1 = Vec[Float64].new();
  pdr1.push(1.0); pdr1.push(2.0);
  pd.push(pdr1);
  if !linear.is_positive_definite(&pd) { io.println("l-pd"); return 59; }
  var notpd = Vec[Vec[Float64]].new();
  var npr0 = Vec[Float64].new();
  npr0.push(1.0); npr0.push(2.0);
  notpd.push(npr0);
  var npr1 = Vec[Float64].new();
  npr1.push(2.0); npr1.push(1.0);
  notpd.push(npr1);
  if linear.is_positive_definite(&notpd) { io.println("l-pd-false"); return 60; }

  // ---- linear: orthogonalization -----------------------------------------
  var pts = Vec[Vec[Float64]].new();
  var pr0 = Vec[Float64].new();
  pr0.push(1.0); pr0.push(1.0);
  pts.push(pr0);
  var pr1 = Vec[Float64].new();
  pr1.push(0.0); pr1.push(1.0);
  pts.push(pr1);
  var gs = linear.gram_schmidt(&pts);
  if !linear.is_orthogonal(&gs) { io.println("l-gram-schmidt"); return 61; }
  var pts2 = Vec[Vec[Float64]].new();
  var p20 = Vec[Float64].new();
  p20.push(1.0); p20.push(0.0);
  pts2.push(p20);
  var p21 = Vec[Float64].new();
  p21.push(1.0); p21.push(1.0);
  pts2.push(p21);
  var ort = linear.orthogonalize(&pts2);
  if !linear.is_orthogonal(&ort) { io.println("l-orthogonalize"); return 62; }
  var cm = Vec[Vec[Float64]].new();
  var cmr0 = Vec[Float64].new();
  cmr0.push(3.0); cmr0.push(0.0);
  cm.push(cmr0);
  var cmr1 = Vec[Float64].new();
  cmr1.push(0.0); cmr1.push(4.0);
  cm.push(cmr1);
  var nc = linear.normalize_columns(&cm);
  if !linear.is_orthogonal(&nc) { io.println("l-norm-cols"); return 63; }
  var rm = Vec[Vec[Float64]].new();
  var rmr0 = Vec[Float64].new();
  rmr0.push(3.0); rmr0.push(4.0);
  rm.push(rmr0);
  var nr = linear.normalize_rows(&rm);
  var nrr = nr[0];
  var nrcheck = vector.dot(&nrr, &nrr);
  if !near(nrcheck, 1.0) { io.println("l-norm-rows"); return 64; }

  // ---- linear: matrix functions -------------------------------------------
  // Matrix element reads of module-returned matrices use single-level row
  // reads + dot with basis vectors (BUG 26 #1: direct double indexing of
  // by-ref/module-returned nested Vecs is corrupt).
  var b00 = Vec[Float64].new();
  b00.push(1.0); b00.push(0.0);
  var b01 = Vec[Float64].new();
  b01.push(0.0); b01.push(1.0);
  var zz = Vec[Vec[Float64]].new();
  var zr0 = Vec[Float64].new();
  zr0.push(0.0); zr0.push(0.0);
  zz.push(zr0);
  var zr1 = Vec[Float64].new();
  zr1.push(0.0); zr1.push(0.0);
  zz.push(zr1);
  var e0 = linear.matrix_exponential(&zz);
  var e0r0 = e0[0];
  if !near(vector.dot(&e0r0, &b00), 1.0) || !near(vector.dot(&e0r0, &b01), 0.0) { io.println("l-expm-zero"); return 65; }
  var ii = Vec[Vec[Float64]].new();
  var ir0 = Vec[Float64].new();
  ir0.push(1.0); ir0.push(0.0);
  ii.push(ir0);
  var ir1 = Vec[Float64].new();
  ir1.push(0.0); ir1.push(1.0);
  ii.push(ir1);
  var l0 = linear.matrix_logarithm(&ii);
  var l0r0 = l0[0];
  var l0r1 = l0[1];
  if !near(vector.dot(&l0r0, &b00), 0.0) || !near(vector.dot(&l0r0, &b01), 0.0) { io.println("l-logm-id"); return 66; }
  if !near(vector.dot(&l0r1, &b00), 0.0) { io.println("l-logm-id-b"); return 67; }
  var dg = Vec[Vec[Float64]].new();
  var dgr0 = Vec[Float64].new();
  dgr0.push(4.0); dgr0.push(0.0);
  dg.push(dgr0);
  var dgr1 = Vec[Float64].new();
  dgr1.push(0.0); dgr1.push(9.0);
  dg.push(dgr1);
  var sq = linear.matrix_sqrt(&dg);
  var sqr0 = sq[0];
  var sqr1 = sq[1];
  if !near(vector.dot(&sqr0, &b00), 2.0) || !near(vector.dot(&sqr0, &b01), 0.0) { io.println("l-sqrtm"); return 68; }
  if !near(vector.dot(&sqr1, &b01), 3.0) { io.println("l-sqrtm-b"); return 69; }
  var mp = Vec[Vec[Float64]].new();
  var mpr0 = Vec[Float64].new();
  mpr0.push(1.0); mpr0.push(2.0);
  mp.push(mpr0);
  var mpr1 = Vec[Float64].new();
  mpr1.push(3.0); mpr1.push(4.0);
  mp.push(mpr1);
  var p2 = linear.matrix_power(&mp, 2);
  var p2r0 = p2[0];
  var p2r1 = p2[1];
  if !near(vector.dot(&p2r0, &b00), 7.0) || !near(vector.dot(&p2r0, &b01), 10.0) { io.println("l-matrix-power"); return 70; }
  if !near(vector.dot(&p2r1, &b00), 15.0) || !near(vector.dot(&p2r1, &b01), 22.0) { io.println("l-matrix-power-b"); return 71; }
  var p0 = linear.matrix_power(&mp, 0);
  var p0r0 = p0[0];
  var p0r1 = p0[1];
  if !near(vector.dot(&p0r0, &b00), 1.0) || !near(vector.dot(&p0r0, &b01), 0.0) { io.println("l-matrix-power0"); return 72; }
  if !near(vector.dot(&p0r1, &b01), 1.0) { io.println("l-matrix-power0-b"); return 73; }

  // ---- linear: skew conversions -------------------------------------------
  var skv = Vec[Float64].new();
  skv.push(1.0); skv.push(2.0); skv.push(3.0);
  var skm = linear.vec_to_skew(&skv);
  var skr0 = skm[0];
  var skr1 = skm[1];
  var skr2 = skm[2];
  var e30 = Vec[Float64].new();
  e30.push(1.0); e30.push(0.0); e30.push(0.0);
  var e31 = Vec[Float64].new();
  e31.push(0.0); e31.push(1.0); e31.push(0.0);
  var e32 = Vec[Float64].new();
  e32.push(0.0); e32.push(0.0); e32.push(1.0);
  if !near(vector.dot(&skr0, &e31), -3.0) || !near(vector.dot(&skr0, &e32), 2.0) { io.println("l-vec2skew"); return 74; }
  if !near(vector.dot(&skr1, &e30), 3.0) || !near(vector.dot(&skr2, &e30), -2.0) { io.println("l-vec2skew-b"); return 75; }
  var back = linear.skew_to_vec(&skm);
  var b0: Float64 = back[0];
  var b1: Float64 = back[1];
  var b2: Float64 = back[2];
  if !near(b0, 1.0) || !near(b1, 2.0) || !near(b2, 3.0) { io.println("l-skew2vec"); return 76; }

  io.println("OK");
  return 0;
}

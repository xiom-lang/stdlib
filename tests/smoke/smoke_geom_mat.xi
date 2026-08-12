// Smoke: xiom.geom.mat + xiom.geom.matrix.
// Returns 0 on success; prints the failing tag on failure.
use xiom.geom.mat;
use xiom.geom.matrix;
use xiom.geom.vector;
use xiom.io;
use xiom.convert;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // ---- matrix: fixed-size structs -----------------------------------------
  var m2 = matrix.mat2_new(1.0, 2.0, 3.0, 4.0);
  if m2.m00 != 1.0 || m2.m01 != 2.0 || m2.m10 != 3.0 || m2.m11 != 4.0 { io.println("mat2-new"); return 1; }
  var m3 = matrix.mat3_new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);
  if m3.m00 != 1.0 || m3.m11 != 5.0 || m3.m22 != 9.0 { io.println("mat3-new"); return 2; }
  var m4 = matrix.mat4_new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0);
  if m4.m00 != 1.0 || m4.m03 != 4.0 || m4.m30 != 13.0 || m4.m33 != 16.0 { io.println("mat4-new"); return 3; }

  // Basis vectors for the mat module row+dot reads (the matrix module's
  // returned matrices cannot be read smoke-side - BUG - so its results are
  // verified via det/trace/rank scalars below).
  var b00 = Vec[Float64].new();
  b00.push(1.0); b00.push(0.0);
  var b01 = Vec[Float64].new();
  b01.push(0.0); b01.push(1.0);

  // ---- matrix: identity/zero/one ------------------------------------------
  var id = matrix.identity(2);
  if !near(matrix.det(&id), 1.0) || !near(matrix.trace(&id), 2.0) { io.println("m-identity"); return 4; }
  if matrix.rank(&id) != 2 { io.println("m-identity-rank"); return 5; }
  var zr = matrix.zero(2, 2);
  if !near(matrix.det(&zr), 0.0) || !near(matrix.trace(&zr), 0.0) { io.println("m-zero"); return 6; }
  var on = matrix.one(1, 2);
  if matrix.rank(&on) != 1 { io.println("m-one"); return 7; }

  // ---- matrix: basic arithmetic -------------------------------------------
  var a = Vec[Vec[Float64]].new();
  var ar0 = Vec[Float64].new();
  ar0.push(1.0); ar0.push(2.0);
  a.push(ar0);
  var ar1 = Vec[Float64].new();
  ar1.push(3.0); ar1.push(4.0);
  a.push(ar1);
  var b = Vec[Vec[Float64]].new();
  var br0 = Vec[Float64].new();
  br0.push(5.0); br0.push(6.0);
  b.push(br0);
  var br1 = Vec[Float64].new();
  br1.push(7.0); br1.push(8.0);
  b.push(br1);
  var sm = matrix.add(&a, &b);
  if !near(matrix.trace(&sm), 18.0) || !near(matrix.det(&sm), -8.0) { io.println("m-add"); return 8; }
  var sb = matrix.sub(&b, &a);
  if !near(matrix.trace(&sb), 8.0) || matrix.rank(&sb) != 1 { io.println("m-sub"); return 9; }
  var pr = matrix.mul(&a, &b);
  if !near(matrix.trace(&pr), 69.0) || !near(matrix.det(&pr), 4.0) { io.println("m-mul"); return 10; }
  var sc = matrix.scalar_mul(&a, 2.0);
  if !near(matrix.trace(&sc), 10.0) || !near(matrix.det(&sc), -8.0) { io.println("m-scalar"); return 11; }
  var tp = matrix.transpose(&a);
  if !near(matrix.trace(&tp), 5.0) || !near(matrix.det(&tp), -2.0) { io.println("m-transpose"); return 12; }

  // ---- matrix: det/trace/inverse ------------------------------------------
  if !near(matrix.det(&a), -2.0) { io.println("m-det"); return 13; }
  var sing = Vec[Vec[Float64]].new();
  var sgr0 = Vec[Float64].new();
  sgr0.push(1.0); sgr0.push(2.0);
  sing.push(sgr0);
  var sgr1 = Vec[Float64].new();
  sgr1.push(2.0); sgr1.push(4.0);
  sing.push(sgr1);
  if !near(matrix.det(&sing), 0.0) { io.println("m-det-sing"); return 14; }
  if !near(matrix.trace(&a), 5.0) { io.println("m-trace"); return 15; }
  var inv = matrix.inverse(&a);
  if !inv.is_some() { io.println("m-inv-none"); return 16; }
  var invs = matrix.inverse(&sing);
  if invs.is_some() { io.println("m-inv-sing"); return 17; }

  // ---- matrix: cofactor/minor/adjugate ------------------------------------
  if !near(matrix.minor(&a, 0, 0), 4.0) { io.println("m-minor"); return 18; }
  if !near(matrix.cofactor(&a, 1, 0), -2.0) { io.println("m-cofactor"); return 19; }
  var adj = matrix.adjugate(&a);
  if !near(matrix.trace(&adj), 5.0) || !near(matrix.det(&adj), -2.0) { io.println("m-adjugate"); return 20; }

  // ---- matrix: rank/nullity -----------------------------------------------
  var id3 = matrix.identity(3);
  if matrix.rank(&id3) != 3 { io.println("m-rank-id"); return 21; }
  if matrix.rank(&sing) != 1 { io.println("m-rank-sing"); return 22; }
  if matrix.nullity(&id3) != 0 { io.println("m-nullity-id"); return 23; }
  if matrix.nullity(&sing) != 1 { io.println("m-nullity-sing"); return 24; }

  // ---- matrix: eigenvalues/eigenvectors -----------------------------------
  var sym = Vec[Vec[Float64]].new();
  var sr0 = Vec[Float64].new();
  sr0.push(3.0); sr0.push(1.0);
  sym.push(sr0);
  var sr1 = Vec[Float64].new();
  sr1.push(1.0); sr1.push(3.0);
  sym.push(sr1);
  var ev = matrix.eigenvalues(&sym);
  var e0v: Float64 = ev[0];
  var e1v: Float64 = ev[1];
  if !near(e0v, 4.0) || !near(e1v, 2.0) { io.println("m-eig"); return 25; }
  var evv = matrix.eigenvectors(&sym);
  if matrix.rank(&evv) != 2 { io.println("m-eigvec"); return 26; }

  // ---- matrix: diagonal/diag_mul/hadamard/kronecker -----------------------
  var dg = matrix.diagonal(&sym);
  var d0: Float64 = dg[0];
  if !near(d0, 3.0) { io.println("m-diagonal"); return 27; }
  var onesd = Vec[Float64].new();
  onesd.push(1.0); onesd.push(1.0);
  var dm = matrix.diag_mul(&a, &onesd);
  if !near(matrix.trace(&dm), 5.0) || !near(matrix.det(&dm), -2.0) { io.println("m-diagmul"); return 28; }
  var hd = matrix.hadamard(&a, &b);
  if !near(matrix.trace(&hd), 37.0) || !near(matrix.det(&hd), -92.0) { io.println("m-hadamard"); return 29; }
  var swap = Vec[Vec[Float64]].new();
  var swr0 = Vec[Float64].new();
  swr0.push(0.0); swr0.push(1.0);
  swap.push(swr0);
  var swr1 = Vec[Float64].new();
  swr1.push(1.0); swr1.push(0.0);
  swap.push(swr1);
  var kr = matrix.kronecker(&a, &swap);
  if !near(matrix.trace(&kr), 0.0) || !near(matrix.det(&kr), 4.0) { io.println("m-kronecker"); return 30; }

  // ---- matrix: factorizations (len/shape checks; tuple content extraction
  // is unreliable in this compiler - BUG) -----------------------------------
  var lu = matrix.lu_decompose(&a);
  var l = lu.0;
  var u = lu.1;
  if l.len() != 2 || u.len() != 2 { io.println("m-lu-len"); return 31; }
  var qr = matrix.qr_decompose(&a);
  var q = qr.0;
  var r = qr.1;
  if q.len() != 2 || r.len() != 2 { io.println("m-qr-len"); return 32; }
  var svd = matrix.svd_decompose(&sym);
  var svdu = svd.0;
  var svds = svd.1;
  var svdv = svd.2;
  if svdu.len() != 2 || svds.len() != 2 || svdv.len() != 2 { io.println("m-svd-len"); return 33; }
  var spd = Vec[Vec[Float64]].new();
  var spdr0 = Vec[Float64].new();
  spdr0.push(4.0); spdr0.push(2.0);
  spd.push(spdr0);
  var spdr1 = Vec[Float64].new();
  spdr1.push(2.0); spdr1.push(3.0);
  spd.push(spdr1);
  var chol = matrix.cholesky(&spd);
  if !chol.is_some() { io.println("m-chol-none"); return 34; }
  var notspd = Vec[Vec[Float64]].new();
  var npr0 = Vec[Float64].new();
  npr0.push(1.0); npr0.push(2.0);
  notspd.push(npr0);
  var npr1 = Vec[Float64].new();
  npr1.push(2.0); npr1.push(1.0);
  notspd.push(npr1);
  var cholb = matrix.cholesky(&notspd);
  if cholb.is_some() { io.println("m-chol-notspd"); return 35; }

  // ---- matrix: solvers ----------------------------------------------------
  var sys = Vec[Vec[Float64]].new();
  var sysr0 = Vec[Float64].new();
  sysr0.push(2.0); sysr0.push(1.0);
  sys.push(sysr0);
  var sysr1 = Vec[Float64].new();
  sysr1.push(1.0); sysr1.push(3.0);
  sys.push(sysr1);
  var rhs = Vec[Float64].new();
  rhs.push(3.0); rhs.push(5.0);
  var x = matrix.solve_linear(&sys, &rhs);
  var x0: Float64 = x[0];
  var x1: Float64 = x[1];
  if !near(x0, 0.8) || !near(x1, 1.4) { io.println("m-solve"); return 36; }
  var la = Vec[Vec[Float64]].new();
  var lar0 = Vec[Float64].new();
  lar0.push(1.0); lar0.push(1.0);
  la.push(lar0);
  var lar1 = Vec[Float64].new();
  lar1.push(1.0); lar1.push(2.0);
  la.push(lar1);
  var lar2 = Vec[Float64].new();
  lar2.push(1.0); lar2.push(3.0);
  la.push(lar2);
  var lb = Vec[Float64].new();
  lb.push(1.0); lb.push(2.0); lb.push(2.0);
  var ls = matrix.least_squares(&la, &lb);
  var ls0: Float64 = ls[0];
  var ls1: Float64 = ls[1];
  if !near(ls0, 0.6666666667) || !near(ls1, 0.5) { io.println("m-leastsq"); return 37; }
  if !near(matrix.condition_number(&sym), 2.0) { io.println("m-condnum"); return 38; }

  // ---- mat: identity/mul/det/inverse/transpose ----------------------------
  var mi = mat.mat_identity(2);
  var mir0 = mi[0];
  if !near(vector.dot(&mir0, &b00), 1.0) { io.println("mat-id"); return 39; }
  var mp = mat.mat_mul(&a, &b);
  var mpr0 = mp[0];
  var mpr1 = mp[1];
  if !near(vector.dot(&mpr0, &b00), 19.0) || !near(vector.dot(&mpr0, &b01), 22.0) { io.println("mat-mul"); return 40; }
  if !near(vector.dot(&mpr1, &b00), 43.0) || !near(vector.dot(&mpr1, &b01), 50.0) { io.println("mat-mul-b"); return 41; }
  if !near(mat.mat_det(&a), -2.0) { io.println("mat-det"); return 42; }
  if !near(mat.mat_det(&sing), 0.0) { io.println("mat-det-sing"); return 43; }
  var minv = mat.mat_inv(&a);
  if !minv.is_some() { io.println("mat-inv-none"); return 44; }
  var minvs = mat.mat_inv(&sing);
  if minvs.is_some() { io.println("mat-inv-sing"); return 45; }
  var mtp = mat.mat_transpose(&a);
  var mtpr0 = mtp[0];
  if !near(vector.dot(&mtpr0, &b00), 1.0) || !near(vector.dot(&mtpr0, &b01), 3.0) { io.println("mat-transpose"); return 46; }

  // ---- mat: affine composition + transform ---------------------------------
  var mi4 = mat.mat_identity(4);
  var tr = mat.mat_translate(&mi4, 1.0, 2.0, 3.0);
  var origin = Vec[Float64].new();
  origin.push(0.0); origin.push(0.0); origin.push(0.0);
  var trp = mat.mat_transform_point(&tr, &origin);
  var trx: Float64 = trp[0];
  var tryv: Float64 = trp[1];
  var trz: Float64 = trp[2];
  if !near(trx, 1.0) || !near(tryv, 2.0) || !near(trz, 3.0) { io.println("mat-translate"); return 47; }
  var scm = mat.mat_scale(&mi4, 2.0, 3.0, 4.0);
  var onept = Vec[Float64].new();
  onept.push(1.0); onept.push(1.0); onept.push(1.0);
  var scp = mat.mat_transform_point(&scm, &onept);
  var scx: Float64 = scp[0];
  var scy: Float64 = scp[1];
  var scz: Float64 = scp[2];
  if !near(scx, 2.0) || !near(scy, 3.0) || !near(scz, 4.0) { io.println("mat-scale"); return 48; }
  var zaxis = Vec[Float64].new();
  zaxis.push(0.0); zaxis.push(0.0); zaxis.push(1.0);
  var rot = mat.mat_rotate(&mi4, 1.5707963268, &zaxis);
  var px = Vec[Float64].new();
  px.push(1.0); px.push(0.0); px.push(0.0);
  var rotp = mat.mat_transform_point(&rot, &px);
  var rxx: Float64 = rotp[0];
  var rxy: Float64 = rotp[1];
  if !near(rxx, 0.0) || !near(rxy, 1.0) { io.println("mat-rotate"); return 49; }
  var eye = Vec[Float64].new();
  eye.push(0.0); eye.push(0.0); eye.push(5.0);
  var tgt = Vec[Float64].new();
  tgt.push(0.0); tgt.push(0.0); tgt.push(0.0);
  var up = Vec[Float64].new();
  up.push(0.0); up.push(1.0); up.push(0.0);
  var la = mat.mat_look_at(&eye, &tgt, &up);
  var lae = mat.mat_transform_point(&la, &eye);
  var lax: Float64 = lae[0];
  var lay: Float64 = lae[1];
  var laz: Float64 = lae[2];
  if !near(lax, 0.0) || !near(lay, 0.0) || !near(laz, 0.0) { io.println("mat-lookat"); return 50; }
  var lat = mat.mat_transform_point(&la, &tgt);
  var latz: Float64 = lat[2];
  if !near(latz, -5.0) { io.println("mat-lookat-t"); return 51; }
  var persp = mat.mat_perspective(1.5707963268, 1.0, 0.1, 10.0);
  var nearpt = Vec[Float64].new();
  nearpt.push(0.0); nearpt.push(0.0); nearpt.push(-0.1);
  var nz = mat.mat_transform_point(&persp, &nearpt);
  var nzv: Float64 = nz[2];
  if !near(nzv, -1.0) { io.println("mat-persp-near"); return 52; }
  var farpt = Vec[Float64].new();
  farpt.push(0.0); farpt.push(0.0); farpt.push(-10.0);
  var fz = mat.mat_transform_point(&persp, &farpt);
  var fzv: Float64 = fz[2];
  if !near(fzv, 1.0) { io.println("mat-persp-far"); return 53; }
  var ortho = mat.mat_ortho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
  var corner = Vec[Float64].new();
  corner.push(1.0); corner.push(1.0); corner.push(-1.0);
  var oc = mat.mat_transform_point(&ortho, &corner);
  var ocx: Float64 = oc[0];
  var ocy: Float64 = oc[1];
  var ocz: Float64 = oc[2];
  if !near(ocx, 1.0) || !near(ocy, 1.0) || !near(ocz, 1.0) { io.println("mat-ortho"); return 54; }

  io.println("OK");
  return 0;
}

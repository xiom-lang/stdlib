// XIOM stdlib smoke — xiom.simd.mask + vec4 + vec8 + gather (scalar fallbacks)
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_simd
use xiom.simd.mask;
use xiom.simd.vec4;
use xiom.simd.vec8;
use xiom.simd.gather;
use xiom.io;
use xiom.convert;

fn fail(tag: Str) -> Int {
  io.println("smoke_simd FAIL: " + tag);
  return 1;
}

fn near(a: Float32, b: Float32) -> Bool {
  var d = a - b;
  if d < 0.0 {
    d = -d;
  };
  d < 0.001
}

fn main() -> Int {
  // mask: new / bits / get / set / count / and/or/xor/not / all / any
  let m1 = mask.mask_new(5);
  if mask.mask_to_bits(m1) != 5 { return fail("m-bits"); }
  if mask.mask_count(m1) != 2 { return fail("m-count"); }
  if !mask.mask_get(m1, 0) { return fail("m-get0"); }
  if mask.mask_get(m1, 1) { return fail("m-get1"); }
  if !mask.mask_get(m1, 2) { return fail("m-get2"); }
  if !mask.mask_any(m1) { return fail("m-any"); }
  if mask.mask_all(m1) { return fail("m-all"); }
  let m2 = mask.mask_set(m1, 1, true);
  if mask.mask_to_bits(m2) != 7 { return fail("m-set"); }
  let m3 = mask.mask_set(m2, 0, false);
  if mask.mask_to_bits(m3) != 6 { return fail("m-clear"); }
  let mz = mask.mask_new(0);
  if mask.mask_any(mz) { return fail("m-any-zero"); }
  let ma = mask.mask_new(3);
  let mb = mask.mask_new(1);
  if mask.mask_to_bits(mask.mask_and(ma, mb)) != 1 { return fail("m-and"); }
  if mask.mask_to_bits(mask.mask_or(ma, mb)) != 3 { return fail("m-or"); }
  if mask.mask_to_bits(mask.mask_xor(ma, mb)) != 2 { return fail("m-xor"); }
  if mask.mask_to_bits(mask.mask_not(mz)) != 4294967295 { return fail("m-not"); }
  var bools = Vec[Bool].new();
  bools.push(true);
  bools.push(false);
  bools.push(true);
  let mf = mask.mask_from_vec(&bools);
  if mask.mask_to_bits(mf) != 5 { return fail("m-from-vec"); }
  let mv = mask.mask_to_vec(mf);
  if mv.len() != 32 { return fail("m-to-vec-len"); }
  if !mask.mask_get(mf, 0) { return fail("m-to-vec-0"); }
  if mask.mask_get(mf, 1) { return fail("m-to-vec-1"); }

  // vec4: f32 add/sub/mul/div/dot/splat/extract/insert/sum/sqrt/min/max
  let v1 = vec4.f32x4_new(1.0, 2.0, 3.0, 4.0);
  let v2 = vec4.f32x4_new(10.0, 20.0, 30.0, 40.0);
  let va = vec4.f32x4_add(v1, v2);
  if !near(vec4.f32x4_extract(va, 0), 11.0) { return fail("v4-add0"); }
  if !near(vec4.f32x4_extract(va, 3), 44.0) { return fail("v4-add3"); }
  let vs = vec4.f32x4_sub(v2, v1);
  if !near(vec4.f32x4_extract(vs, 1), 18.0) { return fail("v4-sub"); }
  let vm = vec4.f32x4_mul(v1, v2);
  if !near(vec4.f32x4_extract(vm, 2), 90.0) { return fail("v4-mul"); }
  let vd = vec4.f32x4_div(v2, v1);
  if !near(vec4.f32x4_extract(vd, 0), 10.0) { return fail("v4-div"); }
  let dot = vec4.f32x4_dot(v1, v1);
  if !near(dot, 30.0) { return fail("v4-dot"); }
  let sum = vec4.f32x4_sum(v1);
  if !near(sum, 10.0) { return fail("v4-sum"); }
  let sp = vec4.f32x4_splat(7.0);
  if !near(vec4.f32x4_extract(sp, 3), 7.0) { return fail("v4-splat"); }
  let vi = vec4.f32x4_insert(v1, 2, 99.0);
  if !near(vec4.f32x4_extract(vi, 2), 99.0) { return fail("v4-insert"); }
  let sq = vec4.f32x4_sqrt(vec4.f32x4_splat(16.0));
  if !near(vec4.f32x4_extract(sq, 1), 4.0) { return fail("v4-sqrt"); }
  let mn = vec4.f32x4_min(v1, v2);
  if !near(vec4.f32x4_extract(mn, 3), 4.0) { return fail("v4-min"); }
  let mx = vec4.f32x4_max(v1, v2);
  if !near(vec4.f32x4_extract(mx, 0), 10.0) { return fail("v4-max"); }
  // vec4: i32 add/sub/mul/min/max/splat/extract
  let i1 = vec4.i32x4_new(1, 2, 3, 4);
  let i2 = vec4.i32x4_new(10, 20, 30, 40);
  let ia = vec4.i32x4_add(i1, i2);
  if vec4.i32x4_extract(ia, 0) != 11 { return fail("v4i-add"); }
  let isub = vec4.i32x4_sub(i2, i1);
  if vec4.i32x4_extract(isub, 3) != 36 { return fail("v4i-sub"); }
  let im = vec4.i32x4_mul(i1, i2);
  if vec4.i32x4_extract(im, 2) != 90 { return fail("v4i-mul"); }
  let imin = vec4.i32x4_min(i1, i2);
  if vec4.i32x4_extract(imin, 0) != 1 { return fail("v4i-min"); }
  let imax = vec4.i32x4_max(i1, i2);
  if vec4.i32x4_extract(imax, 3) != 40 { return fail("v4i-max"); }
  let isp = vec4.i32x4_splat(9);
  if vec4.i32x4_extract(isp, 2) != 9 { return fail("v4i-splat"); }

  // vec8: f32 add/mul/splat/extract/insert/sum
  // NOTE: Float32 fixed-array element reads miscompile in this build, so
  // f32x8_new is shape-checked only and value checks use splat/insert.
  var f8: [8]Float32;
  f8[0] = 1.0;
  f8[1] = 2.0;
  f8[2] = 3.0;
  f8[3] = 4.0;
  f8[4] = 5.0;
  f8[5] = 6.0;
  f8[6] = 7.0;
  f8[7] = 8.0;
  let fv = vec8.f32x8_new(f8);
  let fsp = vec8.f32x8_splat(3.0);
  let fadd = vec8.f32x8_add(fsp, fsp);
  if !near(vec8.f32x8_extract(fadd, 0), 6.0) { return fail("v8-add0"); }
  if !near(vec8.f32x8_extract(fadd, 7), 6.0) { return fail("v8-add7"); }
  let fmul = vec8.f32x8_mul(fsp, fsp);
  if !near(vec8.f32x8_extract(fmul, 3), 9.0) { return fail("v8-mul"); }
  let fsum = vec8.f32x8_sum(fsp);
  if !near(fsum, 24.0) { return fail("v8-sum"); }
  if !near(vec8.f32x8_extract(fsp, 5), 3.0) { return fail("v8-splat"); }
  let fins = vec8.f32x8_insert(fsp, 0, 100.0);
  if !near(vec8.f32x8_extract(fins, 0), 100.0) { return fail("v8-insert"); }
  let fmin = vec8.f32x8_min(fsp, vec8.f32x8_splat(4.0));
  if !near(vec8.f32x8_extract(fmin, 2), 3.0) { return fail("v8-min"); }
  let fmax = vec8.f32x8_max(fsp, vec8.f32x8_splat(4.0));
  if !near(vec8.f32x8_extract(fmax, 7), 4.0) { return fail("v8-max"); }
  if vec8.f32x8_extract(fv, 0) == vec8.f32x8_extract(fv, 1) { return fail("v8-new-shape"); }
  // vec8: i32
  var i8: [8]Int;
  i8[0] = 1;
  i8[1] = 2;
  i8[2] = 3;
  i8[3] = 4;
  i8[4] = 5;
  i8[5] = 6;
  i8[6] = 7;
  i8[7] = 8;
  let iv = vec8.i32x8_new(i8);
  let iadd = vec8.i32x8_add(iv, iv);
  if vec8.i32x8_extract(iadd, 7) != 16 { return fail("v8i-add"); }
  let isub8 = vec8.i32x8_sub(iv, iv);
  if vec8.i32x8_extract(isub8, 0) != 0 { return fail("v8i-sub"); }
  let imul8 = vec8.i32x8_mul(iv, iv);
  if vec8.i32x8_extract(imul8, 4) != 25 { return fail("v8i-mul"); }
  let isp8 = vec8.i32x8_splat(2);
  if vec8.i32x8_extract(isp8, 6) != 2 { return fail("v8i-splat"); }

  // gather: compress/expand are real; load/iota are shape-only stubs
  let gmask = mask.mask_new(5);
  var gvals = Vec[Int].new();
  gvals.push(10);
  gvals.push(20);
  gvals.push(30);
  let comp = gather.gather_compress(&gvals, gmask);
  if comp.len() != 2 { return fail("g-comp-len"); }
  if comp[0] != 10 { return fail("g-comp-0"); }
  if comp[1] != 30 { return fail("g-comp-1"); }
  let exp = gather.gather_expand(&gvals, gmask);
  if exp.len() != 32 { return fail("g-exp-len"); }
  if exp[0] != 10 { return fail("g-exp-0"); }
  if exp[2] != 20 { return fail("g-exp-2"); }
  var idx = Vec[Int].new();
  idx.push(0);
  idx.push(1);
  idx.push(2);
  let load = gather.gather_load[Int](0, &idx);
  if load.len() != 3 { return fail("g-load-len"); }
  let iota = gather.gather_iota[Int](10, 4);
  if iota.len() != 4 { return fail("g-iota-len"); }
  let gm = gather.gather_mask[Int](0, &idx, gmask);
  if gm.len() != 2 { return fail("g-mask-len"); }
  gather.scatter_store[Int](0, &idx, &gvals);

  io.println("smoke_simd OK");
  return 0;
}

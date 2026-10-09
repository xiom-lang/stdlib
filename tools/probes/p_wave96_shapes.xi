// p_wave96_shapes.xi -- wave 96 shape validation: array + sort + bits
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-96 clause guards:
//   (a) xiom.array: the N==0 identities on len/is_empty/fold/array_sum/
//       array_max/array_min/array_count/array_find/array_equal plus the
//       non-empty controls;
//   (b) xiom.array.fixed / xiom.array.dynamic: array_len/get/first/last
//       N==0 and bounds guards, array_slice empty/bounded-length claims,
//       the array_zip N<=M direction (the M<N direction is a filed
//       finding), array_pop/search empty guards, the array_resize
//       post-length and array_concat length-sum claims, array_is_empty
//       branch pins;
//   (c) xiom.sort / xiom.sort.intro: the len<=1 is_sorted identities and
//       the nth_element bounds guard;
//   (d) xiom.bits: the out-of-range no-op guards on bit_set/clear/toggle,
//       k==0 rotation identity, zero-value pins on bit_reverse/byte_swaps,
//       the len<=0 identity on get/set_bit_range, the is_pow2 boundary
//       pins and the pack little/big-endian bit-position pins.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave96_shapes

use xiom.array;
use xiom.array.fixed as afix;
use xiom.array.dynamic as adyn;
use xiom.sort;
use xiom.sort.intro as intro;
use xiom.bits;

fn cmp_i(a: &Int, b: &Int) -> Int {
  if *a < *b { return -1; }
  if *a > *b { return 1; }
  return 0;
}

fn main() -> Int {
  // ---- setup
  let a0: [0]Int = [];
  let a1 = [5];
  let a2 = [1, 2];
  let a3 = [1, 2, 3];
  let b2 = [7, 8];
  let b3 = [1, 2, 3];
  let c3 = [1, 2, 4];

  // ---- array: len / is_empty
  let l0 = array.len(&a0);
  if l0 != 0 { return 1; }
  let l3 = array.len(&a3);
  if l3 != 3 { return 2; }
  let ie0 = array.is_empty(&a0);
  if ie0 == false { return 3; }
  let ie3 = array.is_empty(&a3);
  if ie3 { return 4; }

  // ---- array: sum
  let su0 = array.array_sum(&a0);
  if su0 != 0 { return 7; }
  let su3 = array.array_sum(&a3);
  if su3 != 6 { return 8; }

  // ---- array: max / min / count / find / equal
  let mx0 = array.array_max(&a0);
  if mx0.is_some { return 9; }
  let mx3 = array.array_max(&a3);
  match mx3 {
    Some(v) => { if v != 3 { return 10; } },
    None => { return 11; },
  }
  let mn0 = array.array_min(&a0);
  if mn0.is_some { return 12; }
  let mn3 = array.array_min(&a3);
  match mn3 {
    Some(v2) => { if v2 != 1 { return 13; } },
    None => { return 14; },
  }
  let ct0 = array.array_count(&a0, 1);
  if ct0 != 0 { return 15; }
  let ct3 = array.array_count(&a3, 2);
  if ct3 != 1 { return 16; }
  let fd0 = array.array_find(&a0, 1);
  if fd0.is_some { return 17; }
  let fd3 = array.array_find(&a3, 2);
  match fd3 {
    Some(v3) => { if v3 != 1 { return 18; } },
    None => { return 19; },
  }
  let eq0 = array.array_equal(&a0, &a0);
  if eq0 == false { return 20; }
  let eq3 = array.array_equal(&a3, &b3);
  if eq3 == false { return 21; }
  let eq4 = array.array_equal(&a3, &c3);
  if eq4 { return 22; }

  // ---- fixed: len / get / first / last
  let fl0 = afix.array_len(&a0);
  if fl0 != 0 { return 23; }
  let fl3 = afix.array_len(&a3);
  if fl3 != 3 { return 24; }
  let fg0 = afix.array_get(&a3, -1);
  if fg0.is_some { return 25; }
  let fg1 = afix.array_get(&a3, 3);
  if fg1.is_some { return 26; }
  let fg2 = afix.array_get(&a3, 1);
  match fg2 {
    Some(v4) => { if v4 != 2 { return 27; } },
    None => { return 28; },
  }
  let ff0 = afix.array_first(&a0);
  if ff0.is_some { return 29; }
  let ff3 = afix.array_first(&a3);
  if ff3.is_none { return 30; }
  let fla0 = afix.array_last(&a0);
  if fla0.is_some { return 31; }
  let fla3 = afix.array_last(&a3);
  if fla3.is_none { return 32; }

  // ---- fixed: slice / zip
  let fs0 = afix.array_slice(&a3, 2, 2);
  if fs0.len() != 0 { return 33; }
  let fs1 = afix.array_slice(&a3, 1, 3);
  if fs1.len() != 2 { return 34; }
  let fs2 = afix.array_slice(&a0, 0, 0);
  if fs2.len() != 0 { return 35; }
  let fz0 = afix.array_zip(&a2, &a3);
  if fz0.len() != 2 { return 36; }
  let fz1 = afix.array_zip(&a3, &a3);
  if fz1.len() != 3 { return 37; }

  // ---- dynamic: pop / resize / concat / search / is_empty
  var ve = Vec[Int].new();
  let dp0 = adyn.array_pop(&ve);
  if dp0.is_some { return 38; }
  var v1 = Vec[Int].new();
  v1.push(9);
  let dp1 = adyn.array_pop(&v1);
  if dp1.is_none { return 39; }
  var vr = Vec[Int].new();
  vr.push(1);
  adyn.array_resize(&vr, 4, 9);
  if vr.len() != 4 { return 40; }
  adyn.array_resize(&vr, 0, 9);
  if vr.len() != 0 { return 41; }
  var dv3 = Vec[Int].new();
  dv3.push(1); dv3.push(2); dv3.push(3);
  var dv2 = Vec[Int].new();
  dv2.push(7); dv2.push(8);
  let cc0 = adyn.array_concat(&dv3, &dv2);
  if cc0.len() != 5 { return 42; }
  let cc1 = adyn.array_concat(&ve, &dv2);
  if cc1.len() != 2 { return 43; }
  let ds0 = adyn.array_search(&ve, 1);
  if ds0.is_some { return 44; }
  let ds1 = adyn.array_search(&dv3, 3);
  if ds1.is_none { return 45; }
  let de0 = adyn.array_is_empty(&ve);
  if de0 == false { return 46; }
  let de3 = adyn.array_is_empty(&dv3);
  if de3 { return 47; }

  // ---- sort: is_sorted identities / nth_element bounds
  var s1 = Vec[Int].new();
  s1.push(5);
  let so0 = sort.is_sorted(&s1);
  if so0 == false { return 48; }
  var su = Vec[Int].new();
  su.push(2); su.push(1);
  let so1 = sort.is_sorted(&su);
  if so1 { return 49; }
  let sob0 = sort.is_sorted_by(&s1, cmp_i);
  if sob0 == false { return 50; }
  let sob1 = sort.is_sorted_by(&su, cmp_i);
  if sob1 { return 51; }
  var sn = Vec[Int].new();
  sn.push(3); sn.push(1); sn.push(2);
  let ne0 = sort.nth_element(&mut sn, 7);
  if ne0.is_some { return 52; }
  var sn2 = Vec[Int].new();
  sn2.push(3); sn2.push(1); sn2.push(2);
  let ne1 = sort.nth_element(&mut sn2, -1);
  if ne1.is_some { return 53; }
  var si1 = Vec[Int].new();
  si1.push(5);
  let io0 = intro.is_sorted(&si1);
  if io0 == false { return 54; }
  let iob0 = intro.is_sorted_by(&si1, cmp_i);
  if iob0 == false { return 55; }

  // ---- bits: guarded no-ops and pins
  let bs0 = bits.bit_set(0, 3);
  if bs0 != 8 { return 56; }
  let bs1 = bits.bit_set(5, 64);
  if bs1 != 5 { return 57; }
  let bs2 = bits.bit_set(5, -1);
  if bs2 != 5 { return 58; }
  let bc0 = bits.bit_clear(1, 0);
  if bc0 != 0 { return 59; }
  let bc1 = bits.bit_clear(5, 64);
  if bc1 != 5 { return 60; }
  let bt0 = bits.bit_toggle(0, 0);
  if bt0 != 1 { return 61; }
  let bt1 = bits.bit_toggle(3, 64);
  if bt1 != 3 { return 62; }
  let rl0 = bits.rot_left(5, 0);
  if rl0 != 5 { return 63; }
  let rl1 = bits.rot_left(5, 64);
  if rl1 != 5 { return 64; }
  let rr0 = bits.rot_right(5, 0);
  if rr0 != 5 { return 65; }
  let br0 = bits.bit_reverse(0);
  if br0 != 0 { return 66; }
  let bx0 = bits.byte_swap16(0);
  if bx0 != 0 { return 67; }
  let bx1 = bits.byte_swap16(256);
  if bx1 != 1 { return 68; }
  let bx2 = bits.byte_swap32(0);
  if bx2 != 0 { return 69; }
  let bx3 = bits.byte_swap64(0);
  if bx3 != 0 { return 70; }
  let gr0 = bits.get_bit_range(7, 0, 0);
  if gr0 != 0 { return 71; }
  let sr0 = bits.set_bit_range(7, 0, 0, 3);
  if sr0 != 7 { return 72; }
  let ip0 = bits.is_pow2(0);
  if ip0 { return 73; }
  let ip1 = bits.is_pow2(1);
  if ip1 == false { return 74; }
  let ip2 = bits.is_pow2(3);
  if ip2 { return 75; }
  let ip3 = bits.is_pow2(4);
  if ip3 == false { return 76; }
  let p10 = bits.pack_u16_le(0, 0);
  if p10 != 0 { return 77; }
  let p11 = bits.pack_u16_le(0, 1);
  if p11 != 256 { return 78; }
  let p12 = bits.pack_u16_le(1, 0);
  if p12 != 1 { return 79; }
  let p20 = bits.pack_u16_be(0, 1);
  if p20 != 256 { return 80; }
  let p21 = bits.pack_u16_be(1, 0);
  if p21 != 1 { return 81; }
  let p30 = bits.pack_u32_le(0, 0, 0, 0);
  if p30 != 0 { return 82; }
  let p31 = bits.pack_u32_le(0, 0, 0, 1);
  if p31 != 16777216 { return 83; }
  let p32 = bits.pack_u32_le(1, 0, 0, 0);
  if p32 != 1 { return 84; }
  let p40 = bits.pack_u32_be(0, 0, 0, 1);
  if p40 != 1 { return 85; }
  let p41 = bits.pack_u32_be(1, 0, 0, 0);
  if p41 != 16777216 { return 86; }

  return 0;
}

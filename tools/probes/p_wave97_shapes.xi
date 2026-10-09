// p_wave97_shapes.xi -- wave 97 shape validation: bits submodules + hash + fraction
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-97 clause guards:
//   (a) xiom.bits.bitfield: the width<=0 / offset<0 no-op guards on
//       bitfield_set/clear/insert, the sign_extend width<=0 and width>=64
//       identities, and the strengthened get/mask/extract guards;
//   (b) xiom.bits.rotation + xiom.bits.popcount + xiom.bits.bitwise: the
//       k==0 rotation identities, masked-rotate mask==0 no-op, the
//       next/prev_pow2 boundaries, the zero/byte pins on bit_reverse and
//       byte_swap, and the pow2 boundaries (the sibling-import split was
//       merged back in 2026-10-09 after m242 fixed the triplicate
//       duplicate-export resolution, compiler relay pin-protocol note);
//   (c) xiom.hash: the empty-input identity pins on fnv1a32/fnv1a64,
//       crc32_ieee, hash_bytes_to_hex, murmur3_32, xxhash64, the
//       combine_hashes zero pin and string_hash (djb2) empty pin;
//   (d) xiom.num.fraction: the zero/NaN from_float pins, the sign/normal
//       invariant pins on add/sub/mul/div, reduce's zero normalization,
//       to_float/to_str/is_zero pins and the compare branch pins.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave97_shapes

use xiom.bits.bitfield as bf;
use xiom.bits.rotation as rot;
use xiom.bits.popcount as pc;
use xiom.bits.bitwise as bw;
use xiom.hash as hsh;
use xiom.num.fraction as fr;

fn main() -> Int {
  // ---- bitfield: set / clear / insert guards
  let bs0 = bf.bitfield_set(0, 0, 0, 7);
  if bs0 != 0 { return 1; }
  let bs1 = bf.bitfield_set(5, -1, 4, 3);
  if bs1 != 5 { return 2; }
  let bs2 = bf.bitfield_set(0, 0, 4, 15);
  if bs2 != 15 { return 3; }
  let bc0 = bf.bitfield_clear(7, 0, 0);
  if bc0 != 7 { return 4; }
  let bc1 = bf.bitfield_clear(7, -1, 4);
  if bc1 != 7 { return 5; }
  let bi0 = bf.bitfield_insert(0, 5, 0, 8);
  if bi0 != 5 { return 6; }
  let bi1 = bf.bitfield_insert(5, 3, -1, 4);
  if bi1 != 5 { return 7; }
  let bi2 = bf.bitfield_insert(5, 3, 0, 0);
  if bi2 != 5 { return 8; }

  // ---- bitfield: sign_extend
  let se0 = bf.bitfield_sign_extend(5, -1);
  if se0 != 0 { return 9; }
  let se1 = bf.bitfield_sign_extend(5, 0);
  if se1 != 0 { return 10; }
  let se2 = bf.bitfield_sign_extend(5, 64);
  if se2 != 5 { return 11; }
  let se3 = bf.bitfield_sign_extend(1, 1);
  if se3 != -1 { return 12; }

  // ---- bitfield: strengthened get / mask / extract
  let bg0 = bf.bitfield_get(5, 0, 0);
  if bg0 != 0 { return 13; }
  let bg1 = bf.bitfield_get(5, -1, 8);
  if bg1 != 0 { return 14; }
  let bm0 = bf.bitfield_mask(0);
  if bm0 != 0 { return 15; }
  let bm1 = bf.bitfield_mask(64);
  if bm1 != -1 { return 16; }
  let be0 = bf.bitfield_extract_u(5, 0, 0);
  if be0 != 0 { return 17; }

  // ---- rotation: k == 0 identities
  let rl0 = rot.rotate_left(7, 0);
  if rl0 != 7 { return 18; }
  let rl1 = rot.rotate_left(7, 64);
  if rl1 != 7 { return 19; }
  let rr0 = rot.rotate_right(7, 0);
  if rr0 != 7 { return 20; }
  let ri0 = rot.rol_imm(7, 0);
  if ri0 != 7 { return 21; }
  let ri1 = rot.ror_imm(7, 0);
  if ri1 != 7 { return 22; }
  let rb0 = rot.bit_rotate_left(7, 0);
  if rb0 != 7 { return 23; }
  let rb1 = rot.bit_rotate_right(7, 0);
  if rb1 != 7 { return 24; }
  let mr0 = rot.masked_rotate_left(7, 3, 0);
  if mr0 != 7 { return 25; }
  let mr1 = rot.masked_rotate_right(7, 3, 0);
  if mr1 != 7 { return 26; }

  // ---- popcount: pow2 boundaries / rotations
  let np0 = pc.next_pow2(0);
  if np0 != 1 { return 27; }
  let np1 = pc.next_pow2(1);
  if np1 != 1 { return 28; }
  let pp0 = pc.prev_pow2(0);
  if pp0 != 0 { return 29; }
  let pp1 = pc.prev_pow2(1);
  if pp1 != 1 { return 30; }
  let pr0 = pc.rotate_left(7, 0);
  if pr0 != 7 { return 31; }
  let pr1 = pc.rotate_right(7, 0);
  if pr1 != 7 { return 32; }

  // ---- hash: empty-input pins
  var eb = Vec[UInt8].new();
  let f32 = hsh.fnv1a32(&eb);
  if f32 != 0x811C9DC5 { return 43; }
  let f64 = hsh.fnv1a64(&eb);
  if f64 != 0xCBF29CE484222325 { return 44; }
  let ci0 = hsh.crc32_ieee(&eb);
  if ci0 != 0 { return 45; }
  let hx0 = hsh.hash_bytes_to_hex(&eb);
  if hx0.len() != 0 { return 46; }
  let cb0 = hsh.combine_hashes(0, 0);
  if cb0 != 0x9e3779b9 { return 47; }
  let sh0 = hsh.string_hash("");
  if sh0 != 5381 { return 48; }
  let mu0 = hsh.murmur3_32(&eb, 0);
  if mu0 != 0 { return 49; }
  let xx0 = hsh.xxhash64(&eb, 0);
  if xx0 != 0xEF46DB3751D8E999 { return 50; }

  // ---- hash: non-empty controls
  var one = Vec[UInt8].new();
  one.push(97);
  let f32c = hsh.fnv1a32(&one);
  if f32c == 0x811C9DC5 { return 51; }
  let hx1 = hsh.hash_bytes_to_hex(&one);
  if hx1.len() != 2 { return 52; }

  // ---- fraction: from_float zero / NaN
  let fz0 = fr.fraction_from_float(0.0);
  if fz0.num != 0 { return 53; }
  if fz0.den != 1 { return 54; }
  let nanv = 0.0 / 0.0;
  let fz1 = fr.fraction_from_float(nanv);
  if fz1.num != 0 { return 55; }
  if fz1.den != 1 { return 56; }

  // ---- fraction: arithmetic invariants
  let fa0 = fr.fraction_add(fr.fraction_new(1, 2), fr.fraction_new(1, 3));
  if fa0.den <= 0 { return 57; }
  if fa0.num != 5 { return 58; }
  if fa0.den != 6 { return 59; }
  let fs0 = fr.fraction_sub(fr.fraction_new(1, 2), fr.fraction_new(1, 2));
  if fs0.num != 0 { return 60; }
  let fm0 = fr.fraction_mul(fr.fraction_new(0, 1), fr.fraction_new(3, 4));
  if fm0.num != 0 { return 61; }
  let fd0 = fr.fraction_div(fr.fraction_new(1, 2), fr.fraction_new(0, 1));
  if fd0.is_none == false { return 62; }
  let fd1 = fr.fraction_div(fr.fraction_new(1, 2), fr.fraction_new(1, 4));
  if fd1.is_none { return 63; }

  // ---- fraction: reduce / to_float / to_str / is_zero / compare
  let fr0 = fr.fraction_reduce(fr.fraction_new(2, 4));
  if fr0.num != 1 { return 64; }
  if fr0.den != 2 { return 65; }
  let fr1 = fr.fraction_reduce(fr.fraction_new(0, 5));
  if fr1.num != 0 { return 66; }
  if fr1.den != 1 { return 67; }
  let tf0 = fr.fraction_to_float(fr.fraction_new(1, 2));
  if tf0 != 0.5 { return 68; }
  let tf1 = fr.fraction_to_float(fr.fraction_new(0, 1));
  if tf1 != 0.0 { return 69; }
  let ts0 = fr.fraction_to_str(fr.fraction_new(0, 1));
  if ts0 != "0/1" { return 70; }
  let ts1 = fr.fraction_to_str(fr.fraction_new(3, 4));
  if ts1 != "3/4" { return 71; }
  let iz0 = fr.fraction_is_zero(fr.fraction_new(0, 5));
  if iz0 == false { return 72; }
  let iz1 = fr.fraction_is_zero(fr.fraction_new(1, 2));
  if iz1 { return 73; }
  let cm0 = fr.fraction_compare(fr.fraction_new(1, 2), fr.fraction_new(1, 3));
  if cm0 != 1 { return 74; }
  let cm1 = fr.fraction_compare(fr.fraction_new(0, 1), fr.fraction_new(0, 1));
  if cm1 != 0 { return 75; }
  let cm2 = fr.fraction_compare(fr.fraction_new(0, 1), fr.fraction_new(1, 2));
  if cm2 != -1 { return 76; }

  // ---- bitwise: reverse / swap / rotate / pow2
  let wr0 = bw.bit_reverse(0);
  if wr0 != 0 { return 77; }
  let wb0 = bw.bit_reverse_byte(0);
  if wb0 != 0 { return 78; }
  let wb1 = bw.bit_reverse_byte(1);
  if wb1 != 128 { return 79; }
  let ws0 = bw.byte_swap(0);
  if ws0 != 0 { return 80; }
  let ws1 = bw.byte_swap(256);
  if ws1 != 281474976710656 { return 81; }
  let wl0 = bw.rotate_left(7, 0);
  if wl0 != 7 { return 82; }
  let wrr0 = bw.rotate_right(7, 0);
  if wrr0 != 7 { return 83; }
  let wp0 = bw.is_power_of_two_bit(0);
  if wp0 { return 84; }
  let wp1 = bw.is_power_of_two_bit(1);
  if wp1 == false { return 85; }
  let wp2 = bw.is_power_of_two_bit(3);
  if wp2 { return 86; }

  return 0;
}

// p_b2728_shapes.xi -- B-27/B-28 locks: ffi write_*_at offsets + Vec.with_len capacity
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the two bindings-reported stdlib defects (REL-20261014-1208-bindings):
//   B-27: ffi.write_u32_at / write_u64_at must honor their byte offset
//   (write_f32_at was correct; the u32/u64 pair wrote at base+0 only).
//   B-28: Vec.with_len(n) must hold capacity for n*8 bytes -- the
//   reserve cap==0 seed now runs BEFORE the doubling loop, so with_len
//   never overruns its allocation (ASan-visible on the fidelityfx
//   suite before the fix).
// Values are read back through the little-endian ptr readers and the
// element accessors. Returns 0 when every case holds.

module p_b2728_shapes

use xiom.ffi as ffi;

fn main() -> Int {
  // B-27: mixed-width descriptor write/readback at real offsets
  // (Vec-backed main-heap buffer; ffi.alloc outside a confined block
  // routes to the guard arena and the pointer would dangle)
  var slots = Vec[UInt8].with_len(64);
  var base = 0;
  unsafe { base = slots.data as Int; }
  ffi.write_u32_at(base, 0, 2160);
  ffi.write_u64_at(base, 16, 2000);
  ffi.write_u32_at(base, 24, 100);
  ffi.write_u32_at(base, 28, 110);
  ffi.write_u32_at(base, 32, 120);
  ffi.write_f32_at(base, 36, 1.5);
  unsafe {
    let p = base as *UInt8;
    let r0 = ffi.ptr_read_u32_le(p);
    if r0 != 2160 { return 1; }
    let r16 = ffi.ptr_read_u64_le(p + 16);
    if r16 != 2000 { return 2; }
    let r24 = ffi.ptr_read_u32_le(p + 24);
    if r24 != 100 { return 3; }
    let r28 = ffi.ptr_read_u32_le(p + 28);
    if r28 != 110 { return 4; }
    let r32 = ffi.ptr_read_u32_le(p + 32);
    if r32 != 120 { return 5; }
    let fp = (p + 36) as *mut Float32;
    let rf = *fp;
    if rf != 1.5 { return 6; }
  }

  // NOTE (wave 135): the guard-free alloc/free roundtrip row that stood
  // here was REMOVED -- on the v0.64.4 pin `ffi.free` call sites lower to
  // plain @free (REL-20261013-1445), so freeing guard-arena memory spins
  // (confirmed by a hung out/scratch_guard.xi run). That lock belongs to
  // the compiler-side call-site-lowering acceptance on the next pin; a
  // hanging row must never ship in a probe (run_smokes has no timeout).

  // B-28: with_len holds capacity for n*8 bytes; full element roundtrip
  var v = Vec[UInt8].with_len(16);
  if v.cap < 16 { return 7; }
  var i = 0;
  while i < 16 {
    v[i] = (i + 1) as UInt8;
    i = i + 1;
  }
  var j = 0;
  while j < 16 {
    let b = v[j];
    if b != ((j + 1) as UInt8) { return 8; }
    j = j + 1;
  }
  var w = Vec[UInt8].with_len(1000);
  if w.cap < 1000 { return 9; }

  return 0;
}

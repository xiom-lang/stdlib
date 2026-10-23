// p_guard_copy_out_if_arena.xi -- C07 runtime helper link + main-heap passthrough
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// REL-20261023-0242-compiler: v0.65.0 codegen calls
// xiom_guard_copy_out_if_arena(src, copy_len, alloc_len) before every
// confined-block Vec Copy-Out. The helper must exist (link) and must return
// main-heap pointers unchanged -- the unconditional copy was the engine
// capture-readback 1.4 GB leak. NULL stays NULL.
// Returns 0 when every case holds.

module p_guard_copy_out_if_arena

use xiom.collections;
use xiom.ffi as ffi;

extern "C" {
  fn xiom_guard_copy_out_if_arena(src: *UInt8, copy_len: Int64, alloc_len: Int64) -> *UInt8;
}

fn main() -> Int {
  // NULL passthrough.
  var z: *UInt8 = 0 as *UInt8;
  unsafe { z = xiom_guard_copy_out_if_arena(0 as *UInt8, 8, 8); }
  var zi: Int = 0;
  unsafe { zi = z as Int; }
  if zi != 0 { return 1; }

  // A Vec created outside a confined block lives on the main heap; the
  // helper must return the same pointer and allocate nothing.
  var v = Vec[UInt8].with_len(8);
  var i = 0;
  while i < 8 {
    v[i] = (i + 1) as UInt8;
    i = i + 1;
  }
  var p: *UInt8 = 0 as *UInt8;
  unsafe { p = v.data as *UInt8; }
  var same: *UInt8 = 0 as *UInt8;
  unsafe { same = xiom_guard_copy_out_if_arena(p, 8, 8); }
  var pi: Int = 0;
  var si: Int = 0;
  unsafe {
    pi = p as Int;
    si = same as Int;
  }
  if si != pi { return 2; }

  // The passthrough did not disturb the source.
  if v[0] != 1 as UInt8 { return 3; }
  if v[7] != 8 as UInt8 { return 3; }

  // An arena-owned buffer (created inside the confined block) must be
  // copied out to the main heap, not returned in place.
  var acode: Int = 0;
  unsafe {
    var av = Vec[UInt8].with_len(8);
    var ai = 0;
    while ai < 8 {
      av[ai] = (ai + 1) as UInt8;
      ai = ai + 1;
    }
    var ap = av.data as *UInt8;
    var cp = xiom_guard_copy_out_if_arena(ap, 8, 8);
    var api: Int = ap as Int;
    var cpi: Int = cp as Int;
    if cpi == 0 { acode = 4; }
    if acode == 0 {
      if cpi == api { acode = 5; }
    }
    if acode == 0 {
      if cp[0] != 1 as UInt8 { acode = 6; }
    }
    if cpi != 0 {
      ffi.free(cp);
    }
  }
  if acode != 0 { return acode; }

  return 0;
}

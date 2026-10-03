// p_uint32_high_bit_compare.xi -- direct UInt32 call-result compares misread
// high-bit values.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding (official v0.62.3): an INLINE comparison of a module-qualified
// UInt32-returning call is wrong when the returned value has bit 31 set.
// `adler32_combine(1, 2, -1)` returns UInt32 0xFFFFFFFF; while the control
// (bound to a local) compares correctly, the inline `!=` reports unequal.
// The same inline-compare workaround family is documented for UInt16/UInt8
// (wave-61 icmp_checksum note); this is the UInt32 instance, caught during
// wave-63 probe authoring. Expected: rc 0 once fixed; rc 1 while open.
module p_uint32_high_bit_compare

use xiom.hash.adler;

fn main() -> Int {
  // Control: the zlib-convention value bound first compares correctly.
  let r = adler.adler32_combine(1 as UInt32, 2 as UInt32, 0 - 1);
  if r != 0xFFFFFFFF as UInt32 {
    return 2;
  }
  // Inline call compare: reports unequal on the buggy codegen.
  if adler.adler32_combine(1 as UInt32, 2 as UInt32, 0 - 1) != 0xFFFFFFFF as UInt32 {
    return 1;
  }
  return 0;
}

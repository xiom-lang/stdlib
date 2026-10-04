// p_regress_uint32_compare.xi -- promoted regression lock (was a known failure)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locked by the v0.62.4 pin (fix m186 "inline module-qualified UInt32
// compare widens unsigned"). Before the fix, an INLINE comparison of a
// module-qualified UInt32-returning call with bit 31 set was misread:
// adler32_combine(1, 2, -1) returns 0xFFFFFFFF, and the inline `!=`
// reported unequal while a let-bound control compared correctly.
// Expected: rc 0 on v0.62.4 and later; pre-m186 pins return 1.
module p_regress_uint32_compare

use xiom.hash.adler;

fn main() -> Int {
  // Control: the zlib-convention value bound first compares correctly.
  let r = adler.adler32_combine(1 as UInt32, 2 as UInt32, 0 - 1);
  if r != 0xFFFFFFFF as UInt32 {
    return 2;
  }
  // Inline call compare: the m186-fixed path.
  if adler.adler32_combine(1 as UInt32, 2 as UInt32, 0 - 1) != 0xFFFFFFFF as UInt32 {
    return 1;
  }
  return 0;
}

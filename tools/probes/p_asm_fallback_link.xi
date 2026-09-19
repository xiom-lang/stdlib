// p_asm_fallback_link.xi -- no-NASM runtime fallback must stay linkable.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// xiom.mem and xiom.ffi.c declare the xiom_asm_mem* symbols in their own
// extern blocks. Those symbols are defined by the NASM objects only when the
// compiler is built with the `nasm` feature; the standard dev recipe
// (`cargo build --locked -p xiom`, default features) passes -DXIOM_NO_ASM and
// relies on the C fallbacks in runtime/xiom_runtime.c. If those fallbacks are
// `static`, direct stdlib callers fail at link time with
// `undefined symbol: xiom_asm_memcpy`. This probe round-trips copy/set/
// compare so the fallback linkage stays locked.
module p_asm_fallback_link
use xiom.mem;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(p: *UInt8);
}

fn main() -> Int {
  unsafe {
    var a = malloc(8);
    var b = malloc(8);
    var i = 0;
    while i < 8 {
      a[i] = (65 + i) as UInt8;
      b[i] = 0;
      i = i + 1;
    }
    mem.mem_copy(b, a, 8);
    if mem.mem_compare(a, b, 8) != 0 { return 1; }
    mem.mem_set(b, 90, 4);
    if b[0] != 90 || b[3] != 90 { return 2; }
    if b[4] != 69 { return 3; }
    free(a);
    free(b);
  }
  return 0;
}

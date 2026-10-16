// p_ffi_guard_free_spin.xi -- REL-20261013-1445 acceptance lock: ffi.alloc +
// ptr write/read + ffi.free in ONE confined block. On the pre-m313 pins this
// lowered the free to bare libc free on a guard-arena pointer (VEH retry
// spin, 100% CPU, no output); with the stdlib half (wave 124: arena-aware
// xiom_guard_free) + the compiler half (m313: ffi.free call sites lower
// through the module wrapper) it prints v=7 and exits immediately.
// Rows: null alloc -> 20; value mismatch -> 1; prints "v=7" and exits 0.
module p_ffi_guard_free_spin
use xiom.ffi;
use xiom.io;

fn main() -> Int {
  var observed = 0;
  var wrote = false;
  unsafe {
    let p = ffi.alloc(8);
    if p == null {
      return 20;
    };
    ffi.ptr_write_u64_le(p, 7);
    observed = ffi.ptr_read_u64_le(p);
    ffi.free(p);
    wrote = true;
  };
  if !wrote {
    return 2;
  };
  if observed != 7 {
    return 1;
  };
  io.println("v=7");
  0
}

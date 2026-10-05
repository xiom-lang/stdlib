// smoke_guard_alloc_wrap.xi -- fault-injection lock for the arena-audit
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Compiler-lane request for the v0.63.0 sync: calling xiom_guard_alloc at
// wrapping sizes (size + 15 > LLONG_MAX) must return NULL -- no memset, no
// out-of-bounds slab write. The arena is active inside the unsafe block, so
// these calls take the guard-heap alignment path; before the runtime bound
// check the LLONG_MAX call computed a negative aligned offset and returned a
// bogus in-slab pointer. Control: a normal size still allocates.
// v0.64.0 (m193): the runtime symbol is now declared directly; the
// xiom_guard_alloc_probe shim workaround is retired here.
// Returns 0 when every case holds.

module smoke_guard_alloc_wrap

extern "C" {
  fn xiom_guard_alloc(size: Int) -> Int;
}

fn wrap_alloc(size: Int) -> Int
  requires: true
{
  unsafe {
    var p = xiom_guard_alloc(size);
    if p == 0 {
      return 1;
    }
    return 0;
  }
  return 2;
}

fn main() -> Int {
  // LLONG_MAX: (size + 15) wraps immediately.
  if wrap_alloc(9223372036854775807) != 1 { return 1; }
  // LLONG_MAX - 8: still above the LLONG_MAX - 16 bound.
  if wrap_alloc(9223372036854775799) != 1 { return 2; }
  // LLONG_MAX - 15: boundary + 1 (size + 15 == LLONG_MAX, no wrap yet but
  // out of the supported arena range).
  if wrap_alloc(9223372036854775792) != 1 { return 3; }
  // Control: a normal allocation still succeeds.
  if wrap_alloc(64) != 0 { return 4; }

  return 0;
}

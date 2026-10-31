// p_guard_uaf.xi -- guard-page use-after-free witness (REL-20261031-1949-compiler-2).
// Allocate in a confined block's guard arena, let the block exit (the arena is
// released wholesale), then read the escaped address inside a second confined
// block. The read must fault and be contained; a silent value means the UAF is
// not detected. This is the runtime path the t8 SAFE_SUBSET/UNSAFE_BOUNDARY UAF
// track can use while ASan IR instrumentation is compiler-owned.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_guard_uaf

use xiom.io;
use xiom.error;

extern "C" {
  fn xiom_guard_alloc(size: Int) -> Int;
}

fn alloc_escape() -> Int
  requires: true
{
  unsafe {
    let p = xiom_guard_alloc(16);
    return p;
  }
  return 0;
}

fn read_after_release(p: Int) -> Int
  requires: true
{
  unsafe {
    let q = p as *UInt8;
    return *q as Int;
  }
  return 0;
}

fn main() -> Int {
  let p = alloc_escape();
  if p == 0 { return 1; }
  let v = read_after_release(p);
  if !error.faulted() { return 2; }
  error.take_fault();
  if v != 0 { return 3; }
  io.println("GUARD-UAF-OK");
  return 0;
}

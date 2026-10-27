// p_wave289_vec8.xi -- Vec element-stride correctness (REL-20261026-2142).
// Locks with_len zero-fill, Bool/Int vectors, UInt8 push/reserve growth, and
// the 4 MiB with_len buffer. The RSS win is measured externally once the
// compiler vec_slot_size change lands; this probe is the correctness gate.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave289_vec8

use xiom.collections;

fn main() -> Int {
  let u = Vec[UInt8].with_len(16);
  if u.len() != 16 { return 1; }
  var i = 0;
  while i < 16 {
    if u[i] != 0 as UInt8 { return 2; }
    i = i + 1;
  }

  let b = Vec[Bool].with_len(8);
  if b.len() != 8 { return 3; }

  let n = Vec[Int].with_len(16);
  if n.len() != 16 { return 4; }
  if n[0] != 0 { return 5; }
  if n[15] != 0 { return 6; }

  var p = Vec[UInt8].new();
  var j = 0;
  while j < 5 {
    p.push((j + 1) as UInt8);
    j = j + 1;
  }
  if p.len() != 5 { return 7; }
  if p[4] != 5 as UInt8 { return 8; }
  p.reserve(100);
  if p.len() != 5 { return 9; }
  var k = 5;
  while k < 100 {
    p.push(k as UInt8);
    k = k + 1;
  }
  if p.len() != 100 { return 10; }
  if p[99] != 99 as UInt8 { return 11; }

  let big = Vec[UInt8].with_len(4 * 1024 * 1024);
  if big.len() != 4194304 { return 12; }
  if big[0] != 0 as UInt8 { return 13; }
  if big[4194303] != 0 as UInt8 { return 14; }

  return 0;
}

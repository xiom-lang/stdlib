// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_wave3_opt
use xiom.io;

// A: payload len with a constant bound.
fn wa(s: Str) -> Option[Str]
  ensures: result is Some => result.value.len() >= 0
{
  return Some(s);
}

// B: payload len compared to a Str param len (should also hold).
fn wb(s: Str) -> Option[Str]
  ensures: result is Some => result.value.len() <= s.len()
{
  return Some(s);
}

fn main() -> Int {
  match wa("abc") { Some(v) => { if v.len() != 3 { return 1; } }, None => { return 2; } }
  io.println("A OK");
  match wb("abc") { Some(v) => { if v.len() != 3 { return 3; } }, None => { return 4; } }
  io.println("B OK");
  return 0;
}

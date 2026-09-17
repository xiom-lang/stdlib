// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_interim_shape
use xiom.crypto;
use xiom.io;
use xiom.convert;
// replicates the interim: single OS draw on first use (flag-gated), then
// legacy LCG-style generation; consumers call 3x + byte compares.
var _seeded_flag: Bool = false;
fn seeded_draw() -> Vec[UInt8] {
  if !_seeded_flag {
    _seeded_flag = true;
    var seed = crypto.os_secure_random_bytes(8);
    if seed.len() != 8 { io.println("seed-len"); }
  };
  var out = Vec[UInt8].new();
  var i = 0;
  while i < 32 { out.push(42); i = i + 1; }
  return out;
}
fn sum(b: &Vec[UInt8]) -> Int {
  var s = 0;
  var i = 0;
  while i < b.len() { s = s + (b[i] as Int); i = i + 1; }
  return s;
}
fn main() -> Int {
  var a = seeded_draw();
  var b = seeded_draw();
  var c = seeded_draw();
  if sum(&a) == 0 { io.println("a-zero"); return 1; }
  if sum(&b) != sum(&a) { io.println("b-differs"); return 2; }
  if c.len() != 32 { io.println("c-len"); return 3; }
  io.println("interim-shape-OK");
  return 0;
}

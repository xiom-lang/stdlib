// p_simd_vec4f_lanes.xi -- Vec4f get/set lane storage and lane math.
// Locks the stdlib element-based lane fix 2e99c81 against the m377
// scalar-pointee ABI. Expected rc 0 on v0.64.8 and later.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_simd_vec4f_lanes

use xiom.simd;
use xiom.io;

fn main() -> Int {
  let v = simd.Vec4f.new(1.5, 2.5, 3.5, 4.5);
  if v.get(0) != 1.5 { io.println("g0"); return 1; }
  if v.get(1) != 2.5 { io.println("g1"); return 2; }
  if v.get(2) != 3.5 { io.println("g2"); return 3; }
  if v.get(3) != 4.5 { io.println("g3"); return 4; }

  v.set(0, 10.25);
  v.set(1, 20.25);
  v.set(2, 30.25);
  v.set(3, 40.25);
  if v.get(0) != 10.25 { io.println("s0=" + v.get(0).to_str()); return 5; }
  if v.get(1) != 20.25 { io.println("s1=" + v.get(1).to_str()); return 6; }
  if v.get(2) != 30.25 { io.println("s2=" + v.get(2).to_str()); return 7; }
  if v.get(3) != 40.25 { io.println("s3=" + v.get(3).to_str()); return 8; }

  let w = simd.Vec4f.new(1.0, 2.0, 3.0, 4.0);
  let s = w.add(v);
  if s.get(0) != 11.25 { return 9; }
  if s.get(1) != 22.25 { return 10; }
  if s.get(2) != 33.25 { return 11; }
  if s.get(3) != 44.25 { return 12; }
  io.println("vec4f lanes ok");
  return 0;
}

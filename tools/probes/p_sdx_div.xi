// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_sdx_div
use xiom.text.similarity;
use xiom.io;
fn main() -> Int {
  io.println("sim-empty=[" + similarity.soundex("") + "]");
  io.println("sim-robert=[" + similarity.soundex("Robert") + "]");
  io.println("sim-rupert=[" + similarity.soundex("Rupert") + "]");
  return 0;
}

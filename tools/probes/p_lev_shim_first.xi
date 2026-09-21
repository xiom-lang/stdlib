// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_lev_shim_first
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var d = xiom.string.levenshtein.levenshtein_distance("kitten", "sitting");
  io.println("lev=" + convert.int_to_string(d));
  return 0;
}

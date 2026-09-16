// XIOM stdlib smoke test -- xiom.convert
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_convert
use xiom.convert;

fn main() -> Int {
  var fs = convert.float_to_string(3.14);
  if convert.int_to_string(42) == "42" && fs != "" {
    return 0;
  }
  return 1;
}

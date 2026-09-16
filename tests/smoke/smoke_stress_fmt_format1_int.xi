// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_fmt_format1_int
use xiom.fmt;

fn main() -> Int {
  var result = fmt.format1("value: {}", 42.to_str());
  if result.len() > 0 { return 0; } else { return 1; }
}

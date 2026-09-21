// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_core_option_map
use xiom.core;

fn main() -> Int {
  let s = Some(10);
  let mapped = s.map(fn(x: Int) -> Int { return x * 3; });
  match mapped {
    Some(v) => { if v != 30 { return 1; } },
    None => { return 2; },
  };

  let n: Option[Int] = None;
  let mapped_none = n.map(fn(x: Int) -> Int { return x * 3; });
  if mapped_none.is_some { return 3; }

  return 0;
}

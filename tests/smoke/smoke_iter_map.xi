// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_iter_map
use xiom.iter;

fn main() -> Int {
  var r = iter.range(1, 6);
  var items = r.map(fn(x: Int) -> Int { return x * 2; }).collect();
  if items.len() != 5 { return 1; }
  match items.get(0) { Some(v) => { if v != 2 { return 2; } }, None => { return 3; }, };
  match items.get(4) { Some(v) => { if v != 10 { return 4; } }, None => { return 5; }, };

  return 0;
}

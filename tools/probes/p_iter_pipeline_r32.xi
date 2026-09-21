// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_iter_pipeline_r32
use xiom.iter;
use xiom.io;

fn main() -> Int {
  var a = iter.range(1, 50).collect();
  io.println("A range.collect.len=" + a.len());

  var b = iter.range(1, 50).filter(fn(x: &Int) -> Bool { return *x % 3 == 0; }).collect();
  io.println("B +filter.len=" + b.len());

  var c = iter.range(1, 50)
    .filter(fn(x: &Int) -> Bool { return *x % 3 == 0; })
    .map(fn(x: Int) -> Int { return x * x; })
    .collect();
  io.println("C +map.len=" + c.len());

  var d = iter.range(1, 50)
    .filter(fn(x: &Int) -> Bool { return *x % 3 == 0; })
    .map(fn(x: Int) -> Int { return x * x; })
    .filter(fn(x: &Int) -> Bool { return *x < 2000; })
    .collect();
  io.println("D +filter2.len=" + d.len());

  var result = iter.range(1, 50)
    .filter(fn(x: &Int) -> Bool { return *x % 3 == 0; })
    .map(fn(x: Int) -> Int { return x * x; })
    .filter(fn(x: &Int) -> Bool { return *x < 2000; })
    .take(5)
    .collect();
  io.println("E +take.collect.len=" + result.len());
  if result.len() > 0 { io.println("E[0]=" + result[0]); }
  if result.len() > 4 { io.println("E[4]=" + result[4]); }

  return 0;
}

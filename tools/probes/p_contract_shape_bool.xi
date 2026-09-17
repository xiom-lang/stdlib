// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_contract_shape_bool
use xiom.io;

type Box = { count: Int; }

fn box_len(b: &Box) -> Int {
  return b.count;
}

fn box_is_empty(b: &Box) -> Bool
  ensures: result == (box_len(b) == 0)
{
  return b.count == 0;
}

fn main() -> Int {
  var a = Box{ count: 0; };
  if !box_is_empty(&a) { return 1; }
  var b = Box{ count: 3; };
  if box_is_empty(&b) { return 2; }
  io.println("BOOL SHAPE OK");
  return 0;
}

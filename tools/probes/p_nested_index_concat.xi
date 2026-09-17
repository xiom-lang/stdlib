// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_nested_index_concat
use xiom.io;

fn main() -> Int {
  var r = Vec[Str].new();
  r.push("a"); r.push("b");
  var rows = Vec[Vec[Str]].new();
  rows.push(r);

  // Single-index Vec[Str] element in concat.
  var s1 = "";
  s1 = s1 + r[0];
  io.println("single=[" + s1 + "]");

  // Nested-index element in concat (the CSV flat() shape).
  var s2 = "";
  s2 = s2 + rows[0][0];
  io.println("nested-assign=[" + s2 + "]");

  // Nested-index element inline in a concat expression.
  io.println("nested-inline=[" + rows[0][1] + "]");

  if s1 != "a" { io.println("single mismatch"); return 1; }
  if s2 != "a" { io.println("nested mismatch"); return 2; }
  return 0;
}

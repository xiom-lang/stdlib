// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_cap_mirror
use xiom.io.console;
type M2 = { start: Int; end: Int; text: Str; }
type C2 = { groups: Vec[Option[M2]]; }
fn get2(c: C2, i: Int) -> Option[M2] {
  if i < 0 || i >= c.groups.len() { return None; }
  c.groups[i]
}
fn main() -> Int {
  var g = Vec[Option[M2]].new();
  g.push(Some(M2{ start: 0; end: 3; text: "abc"; }));
  var c = C2{ groups: g; };
  console.console_write_line("built");
  console.console_flush();
  var e = get2(c, 0);
  console.console_write_line("get done is_some=" + (if e.is_some { "true" } else { "false" }));
  console.console_flush();
  if e.is_some {
    var m = e.unwrap();
    console.console_write_line("text=[" + m.text + "]");
    console.console_flush();
  }
  var e2 = get2(c, 1);
  console.console_write_line("get1 is_some=" + (if e2.is_some { "true" } else { "false" }));
  console.console_flush();
  return 0;
}

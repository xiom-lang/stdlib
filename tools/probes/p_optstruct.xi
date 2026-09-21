// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_optstruct
use xiom.io;
type Rec = { family: Str; host: Str; port: Int; }
fn make(s: Str, p: Int) -> Option[Rec] {
  var r = Rec{ family: "hostname"; host: s; port: p; };
  return Some(r);
}
fn make2(s: Str, p: Int) -> Option[Rec] {
  return Some(Rec{ family: "hostname"; host: s; port: p; });
}
fn main() -> Int {
  var a = make("example.com", 8080);
  match a {
    None => { io.println("none"); return 1; }
    Some(r) => { io.println("m1 host=[" + r.host + "] port=" + r.port + " fam=[" + r.family + "]"); }
  }
  var b = make2("x.y", 53);
  match b {
    None => { io.println("none2"); return 2; }
    Some(r) => { io.println("m2 host=[" + r.host + "] port=" + r.port); }
  }
  return 0;
}

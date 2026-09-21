// p_match_vec_codegen.xi -- minimal repro: building a Vec inside a match arm
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// over a Result[Vec[...]] payload trips clang codegen:
//   %tmpNNN defined with type %struct.Vec but ... (llvm: type mismatch)
// The named-local form (`if r.is_err` + `r.value`) compiles and runs.
module p_match_vec_codegen
use xiom.net.ip6 as net6;
use xiom.io;

pub fn conv_match(s: Str) -> Option[Vec[UInt16]] {
  let r = net6.ip6_parse(s);
  match r {
    Ok(b) => {
      var groups = Vec[UInt16].new();
      var i = 0;
      while i + 1 < b.len() {
        let hi = b[i] as Int;
        let lo = b[i + 1] as Int;
        groups.push(((hi << 8) | lo) as UInt16);
        i = i + 2;
      };
      return Some(groups);
    },
    Err(_) => { return None; },
  }
}

pub fn conv_named(s: Str) -> Option[Vec[UInt16]] {
  let r = net6.ip6_parse(s);
  if r.is_err {
    return None;
  };
  let b = r.value;
  var groups = Vec[UInt16].new();
  var i = 0;
  while i + 1 < b.len() {
    let hi = b[i] as Int;
    let lo = b[i + 1] as Int;
    groups.push(((hi << 8) | lo) as UInt16);
    i = i + 2;
  };
  return Some(groups);
}

fn main() -> Int {
  let a = conv_named("::1");
  if !a.is_some { io.println("named none"); return 1; };
  let b = conv_match("::1");
  if !b.is_some { io.println("match none"); return 2; };
  io.println("P_MATCH_VEC_CODEGEN OK");
  io.flush_stdout();
  0
}

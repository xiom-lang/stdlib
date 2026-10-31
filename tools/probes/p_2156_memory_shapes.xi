// p_2156_memory_shapes.xi -- exact shapes used for the 2156 memory numbers.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Modes: struct | vecstr | repeat | cstring (first argv, default struct).
// PROBE_ITERS overrides the default 2000 (corpus) for the measurement runs.
// Measure with tools/json_peak.ps1, e.g.:
//   json_peak.ps1 -Exe out/p_2156_memory_shapes.exe -Iters 20000
//   json_peak.ps1 -Exe out/p_2156_memory_shapes.exe -Iters 20000 -Modes vecstr
// The struct shape is Rec {a,b,c: Str}, each field a fresh str_concat of a
// 1-byte literal and i.to_str(); vecstr pushes 8 fresh Str per outer
// iteration; repeat is str_repeat("ab",16); cstring is
// to_cstring("hello") -> from_cstring -> free.

module p_2156_memory_shapes

use xiom.string;
use xiom.env;
use xiom.convert.parse;
use xiom.convert.cstring as cs;
use xiom.io;

extern "C" {
  fn free(ptr: *UInt8);
}

type Rec = { a: Str; b: Str; c: Str; }

fn main() -> Int {
  var mode = "struct";
  let argv = env.args();
  if argv.len() > 1 { mode = argv[1]; }
  var n = 2000;
  let nr = parse_int(env.var_or("PROBE_ITERS", "2000"));
  if nr.is_ok { n = nr.value; }

  var i = 0;
  var acc = 0;
  while i < n {
    if mode == "struct" {
      var r = Rec {
        a: string.str_concat("x", i.to_str()),
        b: string.str_concat("y", i.to_str()),
        c: string.str_concat("z", i.to_str()),
      };
      acc = acc + r.a.len() + r.b.len() + r.c.len();
    } elif mode == "vecstr" {
      var v: Vec[Str] = Vec[Str].new();
      var j = 0;
      while j < 8 {
        v.push(string.str_concat("item", j.to_str()));
        j = j + 1;
      }
      acc = acc + v.len();
    } elif mode == "repeat" {
      let s = string.str_repeat("ab", 16);
      acc = acc + s.len();
    } elif mode == "cstring" {
      let p = cs.to_cstring("hello");
      let s = cs.from_cstring(p);
      unsafe { free(p as *UInt8); }
      acc = acc + s.len();
    } else {
      io.println("unknown mode: " + mode);
      return 2;
    }
    i = i + 1;
  }
  io.println("done mode=" + mode + " acc=" + acc.to_str());
  return 0;
}

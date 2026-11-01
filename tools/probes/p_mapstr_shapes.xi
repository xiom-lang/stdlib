// p_mapstr_shapes.xi -- 2337 Map/Set Str payload ownership witness.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// One StringStrMap, N fresh 2 KiB keys + 2 KiB values (default N=2000,
// PROBE_ITERS overrides; the compiler probe uses 5000). Measure with
// tools/json_peak.ps1. Before the ownership contract the key/value Str
// payloads are retained (~27/55 MB at 5k); with #[owns_return] on the map
// and #[consumes_str] on put plus the compiler half, the peak should be
// near the 10 MB payload floor (the compiler's ideal ~20 MB at 2 KiB each).

module p_mapstr_shapes

use xiom.collect.stringmap;
use xiom.string;
use xiom.env;
use xiom.convert.parse;
use xiom.io;

fn main() -> Int {
  var n = 2000;
  let nr = parse_int(env.var_or("PROBE_ITERS", "2000"));
  if nr.is_ok { n = nr.value; }

  var m = stringmap.string_str_map_new();
  var i = 0;
  var acc = 0;
  while i < n {
    let k = string.str_repeat("k", 2048);
    let v = string.str_repeat("v", 2048);
    stringmap.string_str_map_put_owned(&mut m, k, v);
    acc = acc + stringmap.string_str_map_size(&m);
    i = i + 1;
  }
  io.println("done mapstr n=" + n.to_str() + " size=" + stringmap.string_str_map_size(&m).to_str() + " acc=" + acc.to_str());
  return 0;
}


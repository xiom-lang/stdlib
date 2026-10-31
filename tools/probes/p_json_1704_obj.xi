// p_json_1704_obj.xi -- gate-9 pre-wire: the 1704 JSON build/parse/stringify
// loop, 10k iterations. This is the workload PULSE measures under a peak-RSS
// sampler (`tools/json_peak.ps1`); the probe itself only locks correctness and
// the loop shape, so it stays green before and after the compiler drop glue
// lands. Run the sampler to compare peak RSS at 1k/10k/20k.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_1704_obj

use xiom.io;
use xiom.env;
use xiom.convert.parse;
use xiom.serialize.json;

fn main() -> Int {
  var n = 10000;
  let nr = parse_int(env.var_or("PROBE_ITERS", "10000"));
  if nr.is_ok { n = nr.value; }
  var iter = 0;
  var acc = 0;
  while iter < n {
    var b = json.json_object_builder_new();
    b.put("a", json.json_number((iter % 7) as Float64));
    b.put("s", json.json_string("wave-1704"));
    let s = json.json_stringify(b.build());
    let p = json.json_parse(s);
    if p.is_err { return 1; }
    acc = acc + s.len();
    iter = iter + 1;
  }
  // The payload is at least 20 bytes; keep the loop from being elided.
  if acc < n * 20 { return 2; }
  return 0;
}

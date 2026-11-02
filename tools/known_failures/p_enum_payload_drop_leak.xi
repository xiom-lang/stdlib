// p_enum_payload_drop_leak.xi -- minimal compiler repro for the gate-9
// (REL-20261020-1704) residual: drop of an owned aggregate payload nested in
// an enum variant does not release the payload, and a recursive enum never
// bottoms out, so resident memory grows with every construction.
//
// JSON-free on purpose: the leak reproduces with local enum types, so it is not
// specific to xiom.serialize.json or to the duplicated JsonValue definition.
// Only the two shapes the optimizer cannot scalar-replace are kept: a
// Vec[Int] / Vec[enum-with-scalar-payload] loop is folded away entirely (flat
// 4.4 MB at 1M iters), which is why they are not controls here.
//
// Evidence, official v0.65.5 windows-x64 archive
// (exe sha256 02f294a9...), tools/json_peak.ps1 (K32GetProcessMemoryInfo):
//
//   mode      workload                         40k    100k   KB/iter
//   bigenum   Vec[Big] (Str | Vec[Int])        10.0    18.4     0.14
//   recenum   Vec[R]   (Str | Vec[R])         34.5    79.6     0.75
//   (baseline)                                 4.4     4.4
//
// Recenum is also linear at 20k (19.5 MB), but a run that short can finish
// before the sampler's first successful read; the 40k/100k pair is the stable
// witness.
//
// The same class in the JSON workload is larger: on one binary the phase
// matrix measured Vec[JsonValue] 1.73, Map[Str,JsonValue] 1.87, and the full
// gate probe is linear at 4.04 KB/iter (45.1/85.9/408.8 MB at 10k/20k/100k;
// 812.8 MB at 200k). Magnitude varies with module shape/optimizer state; the
// growth is the invariant.
//
// The same probe is byte-identical under --release and --no-contracts, and a
// scalar JsonValue.Number loop and stringify are flat, so this is not contract
// or debug instrumentation and not the render path.
//
// Measure:
//   xiom --force tools/known_failures/p_enum_payload_drop_leak.xi -o out/p_enum.exe
//   $env:PROBE_MODE="recenum"; $env:PROBE_ITERS="40000"
//   ./tools/json_peak.ps1 -Exe out/p_enum.exe -Iters 40000
// or run under --sanitize=address/leak to get the allocation stacks.
//
// Expected: run rc 0. Resident memory grows linearly; the leak is the defect.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_enum_payload_drop_leak

use xiom.io;
use xiom.env;
use xiom.convert;
use xiom.convert.parse;

// Non-recursive enum with an owned aggregate payload.
type Big = enum {
  S(s: Str),
  V(v: Vec[Int]),
}

// Recursive enum: the JsonValue shape (Array/Vec and Object/Map variants).
type R = enum {
  Leaf(s: Str),
  Node(items: Vec[R]),
}

fn main() -> Int {
  var n = 40000;
  let nr = parse_int(env.var_or("PROBE_ITERS", "40000"));
  if nr.is_ok { n = nr.value; }
  let mode = env.var_or("PROBE_MODE", "recenum");
  var acc = 0;
  var iter = 0;

  if mode == "bigenum" {
    while iter < n {
      var v = Vec[Big].new();
      v.push(Big.S("wave-1704"));
      var inner = Vec[Int].new();
      inner.push(iter);
      v.push(Big.V(inner));
      match v[0] {
        Big.S(s) => { acc = acc + s.len(); }
        Big.V(x) => { acc = acc + x.len(); }
      }
      match v[1] {
        Big.S(s) => { acc = acc + s.len(); }
        Big.V(x) => { if x.len() > 0 { acc = acc + x[0]; } }
      }
      iter = iter + 1;
    }
  } else {
    // recenum (default): the Vec[JsonValue] shape from the gate probe.
    while iter < n {
      var v = Vec[R].new();
      v.push(R.Leaf("wave-1704"));
      var inner = Vec[R].new();
      inner.push(R.Leaf("wave-1704"));
      v.push(R.Node(inner));
      match v[0] {
        R.Leaf(s) => { acc = acc + s.len(); }
        R.Node(items) => { acc = acc + items.len(); }
      }
      match v[1] {
        R.Leaf(s) => { acc = acc + s.len(); }
        R.Node(items) => {
          if items.len() > 0 {
            match items[0] {
              R.Leaf(s) => { acc = acc + s.len(); }
              R.Node(_) => { acc = acc + 1; }
            }
          }
        }
      }
      iter = iter + 1;
    }
  }

  // Observable output keeps the construction live.
  io.println(convert.int_to_string(acc));
  if acc < n { return 2; }
  return 0;
}

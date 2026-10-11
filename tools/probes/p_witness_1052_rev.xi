// p_witness_1052_rev.xi -- reversed-order co-import lock for
// REL-20261011-1052-stdlib (metro BEFORE farm). metrohash64 must pin its
// own value in BOTH import orders; pre-fix the winner was farm's _K0/_K1/
// _K2 regardless of order.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_witness_1052_rev

use xiom.hash.metro as metro;
use xiom.hash.farm as farm;

fn main() -> Int {
  let eb = Vec[UInt8].new();
  let a = metro.metrohash64(&eb, 0 as UInt64);
  if a != 0x13c52518f4db1e2a as UInt64 { return 33; }
  let f = farm.farmhash64(&eb);
  if f != 0 as UInt64 { return 18; }
  return 0;
}

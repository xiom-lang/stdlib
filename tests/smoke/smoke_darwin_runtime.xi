// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Darwin runtime lock (2026-10-15, v0.64.6 queue):
//  - Float128 soft-float libcalls executed with RUNTIME values (cpu_count
//    is an extern call, so nothing constant-folds): exercises the darwin
//    vector-ABI wrappers (REL-20261010-1609-pulse-2) and the fixed
//    opposite-sign addsub path on every platform.
//  - macOS free-memory contract: sysinfo_free_memory() must not report the
//    old -1 "unknown" sentinel (host_statistics64 fallback,
//    REL-20261010-1549-pulse-7 follow-up).
module smoke_darwin_runtime
use xiom.os;
use xiom.os.sysinfo;
use xiom.platform;

fn main() -> Int {
  var n64 = platform.cpu_count() as Float64;   // runtime value, >= 1
  var a: Float128 = n64 as Float128;           // __extenddftf2 at runtime
  var h: Float128 = 0.5 as Float128;
  var zero: Float128 = 0.0 as Float128;

  // opposite-sign addsub shapes (sub + mixed-sign add)
  if (a - h) + h != a { return 10; }
  if (a + h) - h != a { return 11; }
  if (h - a) + a != h { return 12; }
  if (a + a) - a != a { return 13; }
  if zero - a + a != zero { return 14; }
  // mul/div sanity
  if a * h / h != a { return 15; }
  if a / a != (1.0 as Float128) { return 16; }
  // conversions at runtime
  var back = (a + h) as Float64;
  if back != n64 + 0.5 { return 17; }
  // NOTE: Float128 -> Int128 casts are NOT exercised here on purpose --
  // on win64 the lowering links __fixdfti (double -> i128), a runtime
  // symbol the archive does not ship yet (recorded separately, 2026-10-15).
  // comparisons via equality only (ordering ops on Float128 are covered
  // by the compiler-side locks)
  if a == h { return 19; }
  // macOS free-memory: -1 means the darwin fallback is missing
  if platform.is_macos() {
    if sysinfo_free_memory() < 0 { return 20; }
  }
  return 0;
}

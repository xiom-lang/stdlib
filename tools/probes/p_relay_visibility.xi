// p_relay_visibility.xi -- aggregate-module visibility + monotonic clock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the package-relay fixes (2026-09-23):
// 1. `use xiom.string;` alone resolves `str_compare` (the porter shape that
//    hit error[T001] undefined variable); `xiom.string.compare.str_compare`
//    still works and delegates to the same implementation.
// 2. `use xiom.convert;` alone resolves the Int `to_string` formatter
//    (INT_MIN-safe); `xiom.convert.tostring.to_string` delegates to it.
// 3. `xiom.time.monotonic_ms()` exists and is non-decreasing (the
//    monotonic-ms capability the package docs recorded as missing).
// Returns 0 when every shape compiles and holds.

module p_relay_visibility

use xiom.string;
use xiom.convert;
use xiom.convert.tostring;
use xiom.time;

fn main() -> Int {
  // 1. parent-module comparison visibility.
  if str_compare("a", "b") >= 0 { return 1; }
  if str_compare("b", "a") <= 0 { return 2; }
  if str_compare("same", "same") != 0 { return 3; }
  let c1 = xiom.string.compare.str_compare("a", "b");
  if c1 != str_compare("a", "b") { return 4; }
  if string.str_compare("x", "y") >= 0 { return 5; }

  // 2. parent-module Int formatter visibility + INT_MIN exactness.
  if to_string(123) != "123" { return 6; }
  if convert.to_string(-7) != "-7" { return 7; }
  let im = to_string(-9223372036854775807 - 1);
  if im.len() != 20 { return 8; }
  let ts = tostring.to_string(42);
  if ts != "42" { return 9; }

  // 3. monotonic clock shape.
  let t0 = time.monotonic_ms();
  let t1 = time.monotonic_ms();
  if t1 < t0 { return 10; }
  if time.monotonic_ms() < 0 { return 11; }
  return 0;
}

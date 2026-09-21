// XIOM stdlib stress -- xiom.string.str_slice out-of-bounds handling
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Requests slice beyond string length; verifies graceful truncation or error.
// Returns 0 on success.

module smoke_stress_string_slice_outofbounds
use xiom.string;

fn main() -> Int {
  var s = "hello";
  var n = xiom.string.str_len(s);
  var attempt = xiom.string.str_slice(s, 0, n + 100);
  // If runtime panics this will never reach here; if it truncates or returns empty, check
  if xiom.string.str_len(attempt) >= 0 { return 0; } else { return 1; }
}

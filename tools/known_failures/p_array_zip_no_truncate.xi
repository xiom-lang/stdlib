// p_array_zip_no_truncate.xi -- array_zip does not truncate to the shorter array
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`array_zip([1,2,3], [7,8])` returns two pairs, per the
// documented "truncated to the shorter array").
// Observed on compiler v0.64.1: rc 1 -- the result has THREE pairs (N, not
// min(N, M)); the `if M < count { count = M; }` branch is never taken, so
// with M < N the function reads b[M] out of bounds. With M == 0 it still
// emits N pairs. Only the N <= M direction truncates correctly.
// Found while probing the wave-96 array clauses; the array_zip clause is
// restricted to the N <= M direction until this resolves, and any fixed
// array_zip/zip consumer with unequal lengths must not be trusted.

module p_array_zip_no_truncate

use xiom.array.fixed as afix;

fn main() -> Int {
  let a3 = [1, 2, 3];
  let b2 = [7, 8];
  let z = afix.array_zip(&a3, &b2);
  if z.len() != 2 { return 1; }
  return 0;
}

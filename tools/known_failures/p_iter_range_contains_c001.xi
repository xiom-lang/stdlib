// p_iter_range_contains_c001.xi -- C001 classifier run-to-run nondeterminism
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding (official v0.62.3 and v0.62.4; same codegen family as the
// closure work): this direct-form iter-range reducer flips between compiling
// and failing C001 ("'contains' receiver does not expose a concrete
// Vec/Slice/Array element type") for identical invocations. Six consecutive
// compiles of this exact file on v0.62.4 gave 3 failures and 3 passes; the
// registry lane's 20-run stress measured smoke_iter_range 8/20 and
// smoke_iter_find_all_any 12/20 on v0.62.4 (8/20 and 10/20 on v0.62.3).
// smoke_iter_range also flaps under the 8-worker corpus runner while direct
// compiles pass. Consistent with classifier state derived from
// HashMap-iteration order; the wave-62 "cleared" C001 state was
// probabilistic, not fixed. The two smokes are carve-outs in the release
// gate (tools/known_failures/gate-exclusions.txt); ci/heavy keep the full
// corpus. Expected: rc 0 once the classifier is deterministic.
module p_iter_range_contains_c001

use xiom.iter;

fn main() -> Int {
  if iter.range(0, 0).sum() != 0 { return 1; }
  if iter.range(1, 5).sum() != 10 { return 2; }
  if iter.range(0, 10).sum() != 45 { return 3; }
  if !iter.range(1, 5).contains(3) { return 4; }
  if iter.range(1, 5).contains(5) { return 5; }
  if iter.range(1, 5).len() != 4 { return 6; }
  return 0;
}

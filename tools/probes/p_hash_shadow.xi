// p_hash_shadow.xi -- REL-20261011-1053 lock: zero-arg scalar .hash() must
// dispatch to the stdlib Int.hash/Bool.hash methods, not the builtin identity.
// Expected rc 0 on v0.64.8+.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_hash_shadow

use xiom.hash;

fn main() -> Int {
  let e0 = Int.hash(0);
  if e0 != (7567884774754821 as UInt64) { return 1; }
  let e1 = Bool.hash(false);
  if e1 != (177573 as UInt64) { return 2; }
  let bf: Bool = false;
  if bf.hash() != (177573 as UInt64) { return 3; }
  let i7: Int = 7;
  if i7.hash() != Int.hash(7) { return 4; }
  return 0;
}

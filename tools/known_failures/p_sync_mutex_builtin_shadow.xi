// p_sync_mutex_builtin_shadow.xi -- the compiler's builtin Mutex barrier
// (v0.56 I3 deadlock detection: zero-arg `Mutex.new()`, `Mutex.lock/unlock`
// on an Int receiver) shadows the stdlib generic `xiom.sync.Mutex[T]` at
// name resolution time, so the documented public Mutex API is unreachable
// from user code on v0.64.2:
//   - `sync.Mutex.new(42)`  -> T001 "'new' expects 0 argument(s), found 1"
//   - `sync.Mutex.new()`    -> compiles, but binds the builtin (returns a
//                              nonzero Int, not a Mutex[T])
// Same family as the wave-106 module-private collision (REL-20261011-1052)
// and the scalar `.hash()` shadowing (REL-20261011-1053): a compiler builtin
// wins over the stdlib declaration.
// Expected post-fix: this compiles and returns 0 (the stdlib Mutex[T] is
// reachable through `sync.Mutex...` qualification, or the builtin is renamed
// behind an explicit intrinsic).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_sync_mutex_builtin_shadow

use xiom.sync;

fn main() -> Int {
  var m = sync.Mutex.new(42);
  let g = m.lock();
  if g.get() != 42 { return 1; }
  g.drop();
  if m.into_inner() != 42 { return 2; }
  return 0;
}
